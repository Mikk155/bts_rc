/*
 * HECU Standard M249 SAW Light Machine Gun
 * Author: Rizulix
*/
// Rewrited by Rizulix for bts_rc (december 2024)

namespace CM249
{

enum m249_e
{
    SLOWIDLE = 0,
    IDLE2,
    RELOAD_START,
    RELOAD_END,
    HOLSTER,
    DRAW,
    SHOOT1,
    SHOOT2,
    SHOOT3
};

enum bodygroups_e
{
    BODY = 0,
    HANDS,
    ROUNDS
};

// Weapon info
int MAX_CARRY = 150;
int MAX_CLIP = 100;
// int DEFAULT_GIVE = Math.RandomLong( 19, 100 );
int AMMO_GIVE = MAX_CLIP;
int AMMO_DROP = AMMO_GIVE;
int WEIGHT = 20;
// Weapon HUD
int SLOT = 5;
int POSITION = 4;
// Vars
int DAMAGE = 15;
Vector SHELL( 14.0f, 8.0f, -10.0f );

// Spread thing
const CCVar@ g_M249WideSpread = CCVar( "m249_wide_spread", 0, "", ConCommandFlag::AdminOnly ); // as_command m249_wide_spread
// Knockback thing
const CCVar@ g_M249Knockback = CCVar( "m249_knockback", 1, "", ConCommandFlag::AdminOnly ); // as_command m249_knockback

class weapon_bts_saw : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon
{
    private CBasePlayer@ m_pPlayer { get const { return get_player(); } }

    private bool m_fHasHEV
    {
        get const { return g_PlayerClass[m_pPlayer] == HELMET; }
    }
    private bool m_bAlternatingEject;
    private int m_iTracerCount;
    private int m_iShell;
    private int m_iLink;

    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, self.GetW_Model( "models/bts_rc/weapons/v_saw.mdl" ) );
        self.m_iDefaultAmmo = Math.RandomLong( 19, MAX_CLIP );
        self.FallInit();

        m_iTracerCount = 0;
        m_bAlternatingEject = false;
    }

    void Precache()
    {
        self.PrecacheCustomModels();
        g_Game.PrecacheModel( "models/bts_rc/weapons/v_saw.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/v_saw.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/p_saw.mdl" );
        g_Game.PrecacheModel( "models/w_saw_clip.mdl" );

        m_iShell = g_Game.PrecacheModel( "models/bts_rc/weapons/saw_shell.mdl" );
        m_iLink = g_Game.PrecacheModel( "models/saw_link.mdl" );

        g_Game.PrecacheOther( "ammo_bts_saw" );

        g_SoundSystem.PrecacheSound( "bts_rc/weapons/gun_fire4.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );

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
        self.DefaultDeploy( self.GetV_Model( "models/bts_rc/weapons/v_saw.mdl" ), self.GetP_Model( "models/bts_rc/weapons/p_saw.mdl" ), DRAW, "saw", 0, pev.body );
        self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
        return true;
    }

    void Holster( int skiplocal = 0 )
    {
        SetThink( null );
        BaseClass.Holster( skiplocal );
    }

    void ItemPostFrame()
    {
        BaseClass.ItemPostFrame();

        // Speed up player reload anim
        // Surely no one will change anim_extensions :clueless:
        if( m_pPlayer.pev.sequence == 172 || m_pPlayer.pev.sequence == 176 ) // ref_reload_saw, crouch_reload_saw
            m_pPlayer.pev.framerate = 2.0f;
    }

    bool PlayEmptySound()
    {
        if( self.m_bPlayEmptySound )
        {
            self.m_bPlayEmptySound = false;
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/357_cock1.wav", 0.8f, ATTN_NORM, 0, PITCH_NORM );
        }
        return false;
    }

    void PrimaryAttack()
    {
        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
            return;
        }

        m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

        --self.m_iClip;
        m_bAlternatingEject = !m_bAlternatingEject;

        m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
        pev.effects |= EF_MUZZLEFLASH;

        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

        Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
        Vector vecSrc = m_pPlayer.GetGunPosition();
        Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
        Vector vecSpread;

        if( ( m_pPlayer.pev.button & IN_DUCK ) != 0 )
            vecSpread = g_M249WideSpread.GetBool() ? VECTOR_CONE_3DEGREES : VECTOR_CONE_2DEGREES;
        else if( ( m_pPlayer.pev.button & ( IN_MOVERIGHT | IN_MOVELEFT | IN_FORWARD | IN_BACK) ) != 0 )
            vecSpread = g_M249WideSpread.GetBool() ? VECTOR_CONE_15DEGREES : VECTOR_CONE_10DEGREES;
        else
            vecSpread = g_M249WideSpread.GetBool() ? VECTOR_CONE_6DEGREES : VECTOR_CONE_4DEGREES;

        {
            float x, y;
            g_Utility.GetCircularGaussianSpread( x, y );

            Vector vecDir = vecAiming + x * vecSpread.x * g_Engine.v_right + y * vecSpread.y * g_Engine.v_up;
            Vector vecEnd = vecSrc + vecDir * 8192.0f;

            TraceResult tr;
            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
            self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, DAMAGE, m_pPlayer.pev );
            Sparks::Sparks( tr.pHit, tr.iHitgroup, tr.vecEndPos );
            BloodSplash::Create( tr.pHit, tr.iHitgroup, tr.vecEndPos );

            // each 2 bullets
            if( ( m_iTracerCount++ % 2 ) == 0 )
            {
                Vector vecTracerSrc = vecSrc + Vector( 0.0f, 0.0f, -4.0f ) + g_Engine.v_right * 2.0f + g_Engine.v_forward * 16.0f;
                NetworkMessage tracer( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecTracerSrc );
                    tracer.WriteByte( TE_TRACER );
                    tracer.WriteCoord( vecTracerSrc.x );
                    tracer.WriteCoord( vecTracerSrc.y );
                    tracer.WriteCoord( vecTracerSrc.z );
                    tracer.WriteCoord( tr.vecEndPos.x );
                    tracer.WriteCoord( tr.vecEndPos.y );
                    tracer.WriteCoord( tr.vecEndPos.z );
                tracer.End();
            }

            if( tr.flFraction < 1.0f && tr.pHit !is null )
            {
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if( ( pHit is null || pHit.IsBSPModel() ) && !pHit.pev.FlagBitSet( FL_WORLDBRUSH ) )
                    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
            }
        }

        self.SendWeaponAnim( Math.RandomLong( SHOOT1, SHOOT3 ), 0, pev.body );
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/gun_fire4.wav", VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );
        m_pPlayer.pev.punchangle.x = m_fHasHEV ? Math.RandomFloat( -2.0f, 2.0f ) : Math.RandomFloat( -10.0f, 2.0f );
        m_pPlayer.pev.punchangle.y = m_fHasHEV ? Math.RandomFloat( -1.0f, 1.0f ) : Math.RandomFloat( -2.0f, 1.0f );

        Vector vecForward, vecRight, vecUp;
        g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
        Vector vecOrigin = m_pPlayer.GetGunPosition() + vecForward * SHELL.x + vecRight * SHELL.y + vecUp * SHELL.z;
        Vector vecVelocity = m_pPlayer.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
        g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, m_pPlayer.pev.v_angle.y, m_bAlternatingEject ? m_iLink : m_iShell, TE_BOUNCE_SHELL );

        if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType) <= 0 && m_fHasHEV )
            m_pPlayer.SetSuitUpdate("!HEV_AMO0", false, 0 );

        self.m_flNextPrimaryAttack = g_Engine.time + ( m_fHasHEV ? 0.099f : 0.1f );
        self.m_flTimeWeaponIdle = g_Engine.time + 0.2f;

        if( g_M249Knockback.GetBool() )
        {
            Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

            const float flZVel = m_pPlayer.pev.velocity.z;

            Vector vecInvPushDir = g_Engine.v_forward * ( m_fHasHEV ? 60.0f : 35.0f );
            float flNewZVel = g_EngineFuncs.CVarGetFloat( "sv_maxspeed" );

            if( vecInvPushDir.z >= 10.0f )
                flNewZVel = vecInvPushDir.z;

            // Yeah... no deathmatch knockback
            m_pPlayer.pev.velocity = m_pPlayer.pev.velocity - vecInvPushDir;
            m_pPlayer.pev.velocity.z = flZVel;
        }
    }

    void Reload()
    {
        if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType) <= 0 )
            return;

        self.DefaultReload( MAX_CLIP, RELOAD_START, 1.0f, pev.body );
        self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 3.78f;
        SetThink( ThinkFunction( this.FinishAnim ) );
        pev.nextthink = g_Engine.time + 1.33f;
        BaseClass.Reload();
    }

    void WeaponIdle()
    {
        self.ResetEmptySound();
        m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

        if( self.m_flTimeWeaponIdle > g_Engine.time )
            return;

        const float flNextIdle = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0.0f, 1.0f );
        if( flNextIdle <= 0.95f )
        {
            self.SendWeaponAnim( SLOWIDLE, 0, pev.body );
            self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;
        }
        else
        {
            self.SendWeaponAnim( IDLE2, 0, pev.body );
            self.m_flTimeWeaponIdle = g_Engine.time + 6.16f;
        }
    }

    private int RecalculateBody()
    {
        if( self.m_iClip <= 0 )
            return 8;
        else if( self.m_iClip > 0 && self.m_iClip < 8 )
            return 9 - self.m_iClip;
        else
            return 0;
    }

    private void FinishAnim()
    {
        SetThink( null );
        self.SendWeaponAnim( RELOAD_END, 0, pev.body );
    }
}

class ammo_bts_saw : ScriptBasePlayerAmmoEntity
{
    private int m_iAmount = AMMO_GIVE;

    void Spawn()
    {
        if( pev.ClassNameIs( "ammo_bts_dsaw" ) )
            m_iAmount = Math.RandomLong( 25, 30 );

        Precache();
        g_EntityFuncs.SetModel( self, "models/w_saw_clip.mdl" );
        BaseClass.Spawn();
    }

    void Precache()
    {
        g_Game.PrecacheModel( "models/w_saw_clip.mdl" );
        g_SoundSystem.PrecacheSound( "hlclassic/items/9mmclip1.wav" );
    }

    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( m_iAmount, "556", MAX_CARRY ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1.0f, ATTN_NORM );
            return true;
        }

        return false;
    }
}
}
