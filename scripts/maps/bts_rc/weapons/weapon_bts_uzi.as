/*
* Uzi ( Single )
*/
// Rewrited by Rizulix for bts_rc (december 2024)

namespace BTS_UZI
{

enum btsuzi_e
{
    IDLE1 = 0,
    IDLE2,
    IDLE3,
    RELOAD,
    DRAW,
    SHOOT,
    DRAW2,
    HHHHH,
    AKIMBO_PULL,
    AKIMBO_IDLE,
    AKIMBO_RELOAD_RIGHT,
    AKIMBO_RELOAD_LEFT,
    AKIMBO_RELOAD_BOTH,
    AKIMBO_SHOOT_LEFT,
    AKIMBO_SHOOT_RIGHT,
    AKIMBO_SHOOT_BOTH,
    AKIMBO_DEPLOY
};

enum bodygroups_e
{
    UZI = 0,
    HANDS
};

// Weapon info
int MAX_CARRY = 120;
int MAX_CLIP = 20;
// int DEFAULT_GIVE = Math.RandomLong( 6, 20 );
int AMMO_GIVE = MAX_CLIP;
int AMMO_DROP = AMMO_GIVE;
int WEIGHT = 10;
int FLAGS = 0;
// Weapon HUD
int SLOT = 1;
int POSITION = 11;
// Vars
int DAMAGE = 12;
Vector HEV_CONE( 0.015f, 0.015f, 0.015f );
Vector NOHEV_CONE( 0.0175f, 0.0175f, 0.0175f );
Vector SHELL( 32.0f, 6.0f, -12.0f );

class weapon_bts_uzi : ScriptBasePlayerWeaponEntity
{
    private CBasePlayer@ m_pPlayer
    {
        get const { return cast<CBasePlayer>( self.m_hPlayer.GetEntity() ); }
        set       { self.m_hPlayer = EHandle( @value ); }
    }
    private bool m_fHasHEV
    {
        get const { return g_PlayerClass[m_pPlayer] == HELMET; }
    }
    private int m_iShell;

    int GetBodygroup()
    {
        pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( "models/bts_rc/weapons/v_uzi.mdl" ), pev.body, HANDS, g_PlayerClass[m_pPlayer] );
        return pev.body;
    }

    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, self.GetW_Model( "models/bts_rc/weapons/w_uzi.mdl" ) );
        self.m_iDefaultAmmo = Math.RandomLong( 6, MAX_CLIP );
        self.FallInit();
    }

    void Precache()
    {
        self.PrecacheCustomModels();
        g_Game.PrecacheModel( "models/bts_rc/weapons/w_uzi.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/v_uzi.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/p_uzi.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/w_uzi_clip.mdl" );

        m_iShell = g_Game.PrecacheModel( "models/hlclassic/shell.mdl" );

        g_Game.PrecacheOther( "ammo_bts_uzi" );

        g_SoundSystem.PrecacheSound( "bts_rc/weapons/uzi_fire1.wav" );
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
        info.iFlags = FLAGS;
        info.iWeight = WEIGHT;
        return true;
    }

    bool Deploy()
    {
        self.DefaultDeploy( self.GetV_Model( "models/bts_rc/weapons/v_uzi.mdl" ), self.GetP_Model( "models/bts_rc/weapons/p_uzi.mdl" ), DRAW, "mp5", 0, GetBodygroup() );
        self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;
        self.m_flTimeWeaponIdle = g_Engine.time + 1.25f;
        return true;
    }

    void Holster( int skiplocal = 0 )
    {
        BaseClass.Holster( skiplocal );
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
        Fire( m_fHasHEV ? HEV_CONE : NOHEV_CONE, 0.07f );
    }

    void Reload()
    {
        if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        self.DefaultReload( MAX_CLIP, RELOAD, 2.75f, GetBodygroup() );
        self.m_flTimeWeaponIdle = g_Engine.time + 3.0f;
        BaseClass.Reload();
    }

    void WeaponIdle()
    {
        self.ResetEmptySound();
        m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

        if( self.m_flTimeWeaponIdle > g_Engine.time )
            return;

        switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 3 ) )
        {
            case 0: self.SendWeaponAnim( IDLE1, 0, GetBodygroup() ); break;
            case 1: self.SendWeaponAnim( IDLE2, 0, GetBodygroup() ); break;
            default: self.SendWeaponAnim( IDLE3, 0, GetBodygroup() ); break;
        }

        self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 7.0f, 9.0f );
    }

    private void Fire( const Vector& in vecSpread, float flCycleTime )
    {
        // don't fire underwater
        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.2f;
            return;
        }

        m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

        --self.m_iClip;

        m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
        pev.effects |= EF_MUZZLEFLASH;

        // player "shoot" animation
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

        Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
        Vector vecSrc = m_pPlayer.GetGunPosition();
        Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

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

            if( tr.flFraction < 1.0f && tr.pHit !is null )
            {
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if( ( pHit is null || pHit.IsBSPModel() ) && !pHit.pev.FlagBitSet( FL_WORLDBRUSH ) )
                    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
            }
        }

        self.SendWeaponAnim( SHOOT, 0, GetBodygroup() );
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/uzi_fire1.wav", Math.RandomFloat( 0.92f, 1.0f ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

        if( m_fHasHEV )
        {
            m_pPlayer.pev.punchangle.x = -2.25f;
        }
        else
        {
            if( !m_pPlayer.pev.FlagBitSet( FL_ONGROUND ) )
                m_pPlayer.pev.punchangle.x = float( Math.RandomLong( -5, 3 ));
            else if( m_pPlayer.pev.velocity.Length2D() > 0 )
                m_pPlayer.pev.punchangle.x = float( Math.RandomLong( -4, 3 ));
            else if( m_pPlayer.pev.FlagBitSet( FL_DUCKING ) )
                m_pPlayer.pev.punchangle.x = float( Math.RandomLong( -3, 2 ));
            else
                m_pPlayer.pev.punchangle.x = float( Math.RandomLong( -3, 3 ));
        }

        Vector vecForward, vecRight, vecUp;
        g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
        Vector vecOrigin = m_pPlayer.GetGunPosition() + vecForward * SHELL.x + vecRight * SHELL.y + vecUp * SHELL.z;
        Vector vecVelocity = m_pPlayer.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
        g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, m_pPlayer.pev.v_angle.y, m_iShell, TE_BOUNCE_SHELL );

        if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && m_fHasHEV )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        self.m_flNextPrimaryAttack = g_Engine.time + flCycleTime;
        self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0f, 15.0f );
    }
}

class ammo_bts_uzi : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/w_uzi_clip.mdl" );
        BaseClass.Spawn();
    }

    void Precache()
    {
        g_Game.PrecacheModel( "models/bts_rc/weapons/w_uzi_clip.mdl" );
        g_SoundSystem.PrecacheSound( "hlclassic/items/9mmclip1.wav" );
    }

    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( AMMO_GIVE, "9mm", MAX_CARRY ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1.0f, ATTN_NORM );
            return true;
        }
        return false;
    }
}
}
