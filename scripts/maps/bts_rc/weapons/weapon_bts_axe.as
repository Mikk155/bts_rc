/*
* Emergency Fire Axe
*/
// Rewrited by Rizulix for bts_rc (january 2025)

namespace HL_AXE
{

enum axe_e
{
    IDLE = 0,
    DRAW,
    HOLSTER,
    ATTACK1HIT,
    ATTACK1MISS,
    ATTACK2MISS,
    ATTACK2HIT,
    ATTACK3MISS,
    ATTACK3HIT
};

enum bodygroups_e
{
    STUDIO = 0,
    HANDS
};

// Weapon info
int MAX_CARRY = -1;
int MAX_CLIP = WEAPON_NOCLIP;
int DEFAULT_GIVE = 0;
int AMMO_DROP = MAX_CLIP;
int WEIGHT = 10;
// Weapon HUD
int SLOT = 0;
int POSITION = 8;
// Vars
float RANGE = 32.0f;
float DAMAGE = 20.0f;

class weapon_bts_axe : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon
{
    private CBasePlayer@ m_pPlayer { get const { return get_player(); } }

    private bool m_fHasHEV
    {
        get const { return g_PlayerClass[m_pPlayer] == HELMET; }
    }
    private TraceResult m_trHit;
    private int m_iSwing;

    int GetBodygroup()
    {
        pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( "models/bts_rc/weapons/v_axe.mdl" ), pev.body, HANDS, g_PlayerClass[m_pPlayer] );
        return pev.body;
    }

    void Spawn()
    {
        Precache();
        self.m_flCustomDmg = pev.dmg;
        g_EntityFuncs.SetModel( self, self.GetW_Model( "models/bts_rc/weapons/w_axe.mdl" ) );
        self.m_iDefaultAmmo = DEFAULT_GIVE;
        self.FallInit();

        m_iSwing = 0;
    }

    void Precache()
    {
        self.PrecacheCustomModels();
        g_Game.PrecacheModel( "models/bts_rc/weapons/w_axe.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/v_axe.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/p_axe.mdl" );

        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_miss1.wav" );

        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hit1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hit2.wav" );

        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hitbod1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hitbod2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hitbod3.wav" );

        g_Game.PrecacheGeneric( "sprites/bts_rc/wepspr.spr" );
        g_Game.PrecacheGeneric( "sprites/bts_rc/weapons/" + pev.classname + ".txt" );
    }

    bool AddToPlayer( CBasePlayer@ pPlayer )
    {
        if( !BaseClass.AddToPlayer( pPlayer ) )
            return false;

        NetworkMessage weapon( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
            weapon.WriteLong( g_ItemRegistry.GetIdForName( pev.classname ) );
        weapon.End();
        return true;
    }

    bool GetItemInfo( ItemInfo& out info )
    {
        info.iMaxAmmo1 = MAX_CARRY;
        info.iAmmo1Drop = AMMO_DROP;
        info.iMaxAmmo2 = -1;
        info.iAmmo2Drop = -1;
        info.iMaxClip = MAX_CLIP;
        info.iSlot = SLOT;
        info.iPosition = POSITION;
        info.iId = g_ItemRegistry.GetIdForName( pev.classname );
        info.iFlags = WEAPON_DEFAULT_FLAGS;
        info.iWeight = WEIGHT;
        return true;
    }

    bool Deploy()
    {
        self.DefaultDeploy( self.GetV_Model( "models/bts_rc/weapons/v_axe.mdl" ), self.GetP_Model( "models/bts_rc/weapons/p_axe.mdl" ), DRAW, "crowbar", 0, GetBodygroup() );
        self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
        return true;
    }

    void Holster( int skiplocal = 0 )
    {
        SetThink( null );
        BaseClass.Holster( skiplocal );
    }

    void PrimaryAttack()
    {
        if( !Swing( true ) )
        {
            SetThink( ThinkFunction( this.SwingAgain ) );
            pev.nextthink = g_Engine.time + 0.1f;
        }
    }

    private bool Swing( bool fFirst )
    {
        bool fDidHit = false;

        TraceResult tr;

        Math.MakeVectors( m_pPlayer.pev.v_angle );
        Vector vecSrc   = m_pPlayer.GetGunPosition();
        Vector vecEnd   = vecSrc + g_Engine.v_forward * RANGE;

        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

        if( tr.flFraction >= 1.0f )
        {
            g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
            if( tr.flFraction < 1.0f )
            {
                // Calculate the point of intersection of the line (or hull) and the object we hit
                // This is and approximation of the "best" intersection
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if( pHit is null || pHit.IsBSPModel() )
                    g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
                vecEnd = tr.vecEndPos; // This is the point on the actual surface (the hull could have hit space)
            }
        }

        if( tr.flFraction >= 1.0f )
        {
            if( fFirst )
            {
                // miss
                switch( ( m_iSwing++ ) % 3 )
                {
                    case 0: self.SendWeaponAnim( ATTACK1MISS, 0, GetBodygroup() ); break;
                    case 1: self.SendWeaponAnim( ATTACK2MISS, 0, GetBodygroup() ); break;
                    case 2: self.SendWeaponAnim( ATTACK3MISS, 0, GetBodygroup() ); break;
                }
                self.m_flNextPrimaryAttack = g_Engine.time + ( m_fHasHEV ? 0.5f : 0.75f );
                self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

                // play wiff or swish sound
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_miss1.wav", 1.0f, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 0xF ) );

                // player "shoot" animation
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
            }
        }
        else
        {
            // hit
            fDidHit = true;

            CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

            switch( ( ( m_iSwing++ ) % 2 ) + 1 )
            {
                case 0: self.SendWeaponAnim( ATTACK1HIT, 0, GetBodygroup() ); break;
                case 1: self.SendWeaponAnim( ATTACK2HIT, 0, GetBodygroup() ); break;
                case 2: self.SendWeaponAnim( ATTACK3HIT, 0, GetBodygroup() ); break;
            }

            self.m_flNextPrimaryAttack = g_Engine.time + ( m_fHasHEV ? 0.25f : 0.5f );
            self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

            // player "shoot" animation
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

            // AdamR: Custom damage option
            float flDamage = DAMAGE;
            if( self.m_flCustomDmg > 0.0f )
                flDamage = self.m_flCustomDmg;
            // AdamR: End

            g_WeaponFuncs.ClearMultiDamage();

            if( self.m_flNextPrimaryAttack + 1.0f < g_Engine.time )
                pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB ); // first swing does full damage
            else
                pEntity.TraceAttack( m_pPlayer.pev, flDamage * 0.5f, g_Engine.v_forward, tr, DMG_CLUB ); // subsequent swings do 50% (Changed -Sniper) (Half)

            g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

            // play thwack, smack, or dong sound
            float flVol = 1.0f;
            bool fHitWorld = true;

            // for monsters or breakable entity smacking speed function
            if( pEntity !is null )
            {
                if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
                {
                    // aone
                    if( pEntity.IsPlayer() ) // lets pull them
                        pEntity.pev.velocity = pEntity.pev.velocity + ( pev.origin - pEntity.pev.origin ).Normalize() * 120.0f;
                    // end aone

                    // play thwack or smack sound
                    switch( Math.RandomLong( 1, 3 ) )
                    {
                        case 3:
                            g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_hitbod3.wav", 1.0f, ATTN_NORM );
                        break;
                        case 2:
                            g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_hitbod2.wav", 1.0f, ATTN_NORM );
                        break;
                        default:
                            g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_hitbod1.wav", 1.0f, ATTN_NORM );
                        break;
                    }

                    m_pPlayer.m_iWeaponVolume = 128;

                    if( !pEntity.IsAlive() )
                        return true;
                    else
                        flVol = 0.1f;

                    fHitWorld = false;
                }
            }

            // play texture hit sound
            // UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

            if( fHitWorld )
            {
                g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2.0f, BULLET_PLAYER_CROWBAR );

                // also play crowbar strike
                switch( Math.RandomLong( 1, 2 ) )
                {
                    case 2:
                        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_hit2.wav", 1.0f, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
                    break;
                    default:
                        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/axe_hit1.wav", 1.0f, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
                    break;
                }
            }

            // delay the decal a bit
            m_trHit = tr;
            SetThink( ThinkFunction( this.Smack ) );
            pev.nextthink = g_Engine.time + 0.2f;

            m_pPlayer.m_iWeaponVolume = int( flVol * 512 );
        }
        return fDidHit;
    }

    private void SwingAgain()
    {
        Swing( false );
    }

    private void Smack()
    {
        g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
    }
}
}
