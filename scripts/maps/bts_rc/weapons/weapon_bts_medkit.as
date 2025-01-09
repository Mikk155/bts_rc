/* 
* Custom Player Medkit 
* Credits: kmkz
*/

namespace BTS_MEDKIT
{

enum medkit_e
{
    IDLE = 0,
    LONGIDLE,
    LONGUSE,
    SHORTUSE,
    HOLSTER,
    DRAW,
};

enum reviving_e
{
    REVIVING_NO = 0,
    REVIVING_INPROGRESS,
    REVIVING_END,
};

const int MAX_CARRY = 100;
const int MAX_CLIP = WEAPON_NOCLIP;
const int MAX_DROP = 10;
const int DEFAULT_GIVE = 50;

const string SOUND_HEAL = "items/medshot5.wav";
const string SOUND_REVIVE = "items/suitchargeok1.wav";
const string SOUND_REVIVED = "items/r_item1.wav"; //replace with real revived sound

class weapon_bts_medkit : ScriptBasePlayerWeaponEntity
{
    private CBasePlayer@ m_pPlayer = null;
    int iReviving = REVIVING_NO;
    float m_flRechargeTime;
    TraceResult m_trHit;
    
    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, self.GetW_Model( "models/w_medkit.mdl") );
        self.m_flCustomDmg  = self.pev.dmg;

        self.m_iDefaultAmmo = DEFAULT_GIVE;

        self.FallInit();// get ready to fall down.
    }

    void Precache()
    {
        self.PrecacheCustomModels();

        g_Game.PrecacheModel( "models/v_medkit.mdl" );
        g_Game.PrecacheModel( "models/w_medkit.mdl" );
        g_Game.PrecacheModel( "models/p_medkit.mdl" );

        g_SoundSystem.PrecacheSound( SOUND_HEAL );
        g_SoundSystem.PrecacheSound( SOUND_REVIVE );
    }

    bool GetItemInfo( ItemInfo& out info )
    {
        info.iMaxAmmo1  = WEAPON_NOCLIP;
        info.iAmmo1Drop = -1;
        info.iMaxAmmo2  = -1;
        info.iAmmo2Drop = -1;
        info.iMaxClip   = WEAPON_NOCLIP;
        info.iSlot      = 0;
        info.iPosition  = 10;
        info.iFlags     = 0;
        info.iWeight    = 0;

        return true;
    }
    
    bool AddToPlayer(CBasePlayer@ pPlayer)
    {
        if ( !BaseClass.AddToPlayer( pPlayer ) )
            return false;

        @m_pPlayer = pPlayer;
        NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
        message.WriteLong( self.m_iId );
        message.End();
        return true;
    }

    bool Deploy()
    {
        return self.DefaultDeploy( self.GetV_Model( "models/v_medkit.mdl" ), self.GetP_Model( "models/p_medkit.mdl" ), DRAW, "trip" );
    }

    void Holster( int skiplocal /* = 0 */ )
    {
        self.m_fInReload = false;// cancel any reload in progress.
        
        iReviving = REVIVING_NO;
        
        m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5; 

        m_pPlayer.pev.viewmodel = "";
        
        SetThink( null );
    }

    void PrimaryAttack()
    {
        Medshot();

        self.m_flNextPrimaryAttack = g_Engine.time + 0.5; //0.25
    }
    
    void Medshot()
    {
        TraceResult tr;

        Math.MakeVectors( m_pPlayer.pev.v_angle );
        Vector vecSrc   = m_pPlayer.GetGunPosition();
        Vector vecEnd   = vecSrc + g_Engine.v_forward * 32;

        //Reload();

        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

        if ( tr.flFraction >= 1.0 )
        {
            g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
            if ( tr.flFraction < 1.0 )
            {
                // Calculate the point of intersection of the line (or hull) and the object we hit
                // This is and approximation of the "best" intersection
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if ( pHit is null || pHit.IsBSPModel() )
                    g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
                vecEnd = tr.vecEndPos;  // This is the point on the actual surface (the hull could have hit space)
            }
        }

        if ( tr.flFraction >= 1.0 )
        {
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "items/medshotno1.wav", 1.0f, ATTN_NORM);

            // miss
            self.m_flNextPrimaryAttack = g_Engine.time + 1.5;
            //m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
        }
        else
        {
            CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
            int iClassify = pEntity.GetClassification(0);
            // hit
            if (pEntity !is null)
            {
                self.SendWeaponAnim( SHORTUSE, 0, 0 ); //GetBodygroup
                
                // player "shoot" animation
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
                
                float flDamage = -10;

                g_WeaponFuncs.ClearMultiDamage();
                
                if ( (pEntity.IsPlayer() && (pEntity.IsPlayerAlly() )) || (pEntity.IsMonster() && pEntity.IsPlayerAlly() && !pEntity.IsMachine()))
                {
                    float health_amount;
                
                    pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_MEDKITHEAL ); 
                    if (pEntity.pev.health < pEntity.pev.max_health) 
                    {
                        health_amount = 10;
                    
                        if ((pEntity.pev.health + health_amount) < pEntity.pev.max_health) 
                        {
                            pEntity.pev.health = (pEntity.pev.health + health_amount);

                        /*  int iAmmo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
                            m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, iAmmo - 10 );
                        */
                        }
                        else
                        {
                            pEntity.pev.health = pEntity.pev.max_health;
                        }
                    }
                }               
                else
                {
                    g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "items/medshotno1.wav", 1.0f, ATTN_NORM);
                }           
                bool fHitWorld = true;

            // play texture hit sound
            // UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

                if( fHitWorld == true )
                {
                    g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SOUND_HEAL, 1.0f, ATTN_NORM ); 
                }
            
            m_trHit = tr;
            }
        }
    }   

    void SecondaryAttack()
    {
        CBaseEntity@ pEntity;
                
        Math.MakeVectors(m_pPlayer.pev.v_angle);
        Vector vecSrc = m_pPlayer.GetGunPosition();
        Vector vecEnd = vecSrc + g_Engine.v_forward * 32;
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "items/medshotno1.wav", 1.0f, ATTN_NORM);
        
        @pEntity = g_EntityFuncs.FindEntityInSphere(m_pPlayer, vecEnd, 64.0, "*", "classname");
        
        if (pEntity !is null && pEntity.IsRevivable() && pEntity.IsPlayerAlly() && !pEntity.IsMachine() ) 
        {
            if (iReviving == REVIVING_NO)
            {
                iReviving = REVIVING_END;
                self.SendWeaponAnim( LONGUSE, 0, 0 );
                self.m_flTimeWeaponIdle = g_Engine.time + 2.1f;
                self.m_flNextSecondaryAttack = g_Engine.time + 2.1f;
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SOUND_REVIVE , 1.0f, ATTN_NORM);
                return;
            }
            
            if (iReviving == REVIVING_END)
            {
                iReviving = REVIVING_NO;
                self.SendWeaponAnim( SHORTUSE, 0, 0 );
                self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
                self.m_flNextSecondaryAttack = g_Engine.time + 1.0f;
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SOUND_REVIVED , 1.0f, ATTN_NORM);
                
                if (pEntity.IsPlayer() )
                {
                    CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEntity);
                    pPlayer.Revive();
                }
                else if (pEntity.IsMonster())
                {
                    CBaseMonster@ pMonster = cast<CBaseMonster@>(pEntity);
                    pMonster.Revive();
                }
                return;
            }
            
        }
        
        //tr;
    
        /*Reload();

        g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr);

        if (tr.flFraction >= 1.0)
        {
            g_Utility.TraceHull(vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr);
            if (tr.flFraction < 1.0)
            {
                CBaseEntity@ pHit = g_EntityFuncs.Instance(tr.pHit);
                if (pHit is null || pHit.IsBSPModel())
                    g_Utility.FindHullIntersection(vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict());
                vecEnd = tr.vecEndPos;
            }
        }

        if (tr.flFraction >= 1.0)
        {
            g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "items/medshotno1.wav", 1.0f, ATTN_NORM);
            // Miss
            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.25;
        }
        else
        {
            CBaseEntity@ pEntity = g_EntityFuncs.Instance(tr.pHit);

            if (pEntity !is null && pEntity.IsAlive() )
            {
                // Revive the entity if it is dead
                if (pEntity.pev.health <= 0)
                {
                    bool m_isRevived = false;

                    if (pEntity.IsPlayer() && pEntity.IsPlayerAlly())
                    {
                        CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEntity);
                        pPlayer.Revive();
                        m_isRevived = true;
                    }
                    else if (pEntity.IsMonster() && pEntity.IsPlayerAlly())
                    {
                        CBaseMonster@ pMonster = cast<CBaseMonster@>(pEntity);
                        pMonster.Revive();
                        m_isRevived = true;
                    }

                    // If revive was successful, deduct ammo
                    if (m_isRevived)
                    {
                        int iAmmo = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType);
                        if (iAmmo >= 50)  // Ensure there is enough ammo to deduct
                        {
                            m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, iAmmo - 50);
                        }

                        // Play sound effect for revive
                        g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "items/suitchargeok1.wav", 1.0f, ATTN_NORM);
                    }
                }
                else
                {
                    g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "items/medshotno1.wav", 1.0f, ATTN_NORM);
                }

                m_trHit = tr;
                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 3.0f; // Delay before the next attack
            }
        }*/
    }


    void WeaponIdle()
    {
        self.ResetEmptySound();

        m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

        if( self.m_flTimeWeaponIdle > g_Engine.time )
            return;

        int iAnim;
        switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 3 ) )
        {
        case 0: 
            iAnim = IDLE;   
            break;
        
        case 1:
            iAnim = LONGIDLE;
            break;
            
        default:
            iAnim = IDLE;
            break;
        }

        iReviving = REVIVING_NO;
        self.SendWeaponAnim( iAnim, 0, 0 );
        self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  6, 8 );// how long till we do this again.
    }
/*
    void Reload()
    {
        if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) >= MAX_CARRY )
            return;
        
        while ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < MAX_CARRY && m_flRechargeTime < g_Engine.time )
        {
            int iAmmo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
            m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ++iAmmo );
            m_flRechargeTime += 5.0;
        }
    }
*/
}

string GetName()
{
    return "weapon_bts_medkit";
}

string GetAmmoName()
{
    return "ammo_medkit";
}

void Register()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_MEDKIT::weapon_bts_medkit", GetName() );
    g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", "", "", GetAmmoName() );
}

}