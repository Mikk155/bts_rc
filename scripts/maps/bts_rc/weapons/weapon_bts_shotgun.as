/* 
* Black Mesa/HECU Standard SPAS-12 Shotgun
* Sleeve Difference Code: KernCore, Mikk155
*/
// Rewrited by Rizulix for bts_rc (december 2024)

namespace HL_SHOTGUN
{

enum shotgun_e
{
    IDLE = 0,
    SHOOT,
    SHOOT2,
    RELOAD,
    PUMP,
    START_RELOAD,
    DRAW,
    HOLSTER,
    IDLE4,
    IDLE_DEEP
};

enum bodygroups_e
{
    STUDIO0 = 0,
    STUDIO1,
    HANDS
};

// Models
string W_MODEL = "models/bts_rc/weapons/w_shotgun.mdl";
string V_MODEL = "models/bts_rc/weapons/v_shotgun.mdl";
string P_MODEL = "models/bts_rc/weapons/p_shotgun.mdl";
string A_MODEL = "models/hlclassic/w_shotbox.mdl";
string D_MODEL = "models/w_shotshell.mdl";
// Sounds
string SHOOT_SND = "hlclassic/weapons/sbarrel1.wav";
string SHOOT2_SND = "bts_rc/weapons/spas12_dbarrel1.wav";
string EMPTY_SND = "hlclassic/weapons/357_cock1.wav";
array<string> SOUNDS = {
    "bts_rc/weapons/spas12_foley.wav",
    "bts_rc/weapons/spas_idle4.wav",
    "bts_rc/weapons/fidget_3.wav",
    "bts_rc/weapons/fidget_4.wav",
};
string RELOAD1_S = "hlclassic/weapons/reload1.wav";
string RELOAD3_S = "hlclassic/weapons/reload3.wav";
string SCOCK1_S = "hlclassic/weapons/scock1.wav";
// Weapon info
int MAX_CARRY = 30;
int MAX_CLIP = 8;
// int DEFAULT_GIVE = Math.RandomLong( 2, 8 );
int AMMO_GIVE = MAX_CLIP;
int AMMO_DROP = AMMO_GIVE;
int WEIGHT = 15;
int FLAGS = 0;
int ID; // assigned on register
string AMMO_TYPE = "buckshot";
// Weapon HUD
int SLOT = 2;
int POSITION = 7;
// Vars
int DAMAGE = 17;
int PELLETS = 4;
Vector SINGLE_CONE( 0.08716f, 0.04362f, 0.0f );
Vector DOUBLE_CONE( 0.17365f, 0.04362f, 0.0f );
Vector SHELL( 14.0f, 6.0f, -34.0f );

class weapon_bts_shotgun : ScriptBasePlayerWeaponEntity
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
    private float m_flTimeWeaponReload = 0.0f;
    private int m_fInReloadState = 0;
    private int m_iShell;

    int GetBodygroup()
    {
        pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), pev.body, HANDS, g_PlayerClass[m_pPlayer] );
        return pev.body;
    }

    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, self.GetW_Model( W_MODEL ) );
        self.m_iDefaultAmmo = Math.RandomLong( 2, MAX_CLIP );
        self.FallInit();

        m_fInReloadState = 0;
        m_flTimeWeaponReload = 0.0f;
    }

    void Precache()
    {
        self.PrecacheCustomModels();
        g_Game.PrecacheModel( W_MODEL );
        g_Game.PrecacheModel( V_MODEL );
        g_Game.PrecacheModel( P_MODEL );
        g_Game.PrecacheModel( A_MODEL );
        g_Game.PrecacheModel( D_MODEL );

        m_iShell = g_Game.PrecacheModel( "models/hlclassic/shotgunshell.mdl" );

        g_Game.PrecacheOther( GetAmmoName() );
        g_Game.PrecacheOther( GetDAmmoName() );

        g_SoundSystem.PrecacheSound( SHOOT_SND );
        g_SoundSystem.PrecacheSound( SHOOT2_SND );
        g_SoundSystem.PrecacheSound( EMPTY_SND );

        for( uint i = 0; i < SOUNDS.length(); i++ )
            g_SoundSystem.PrecacheSound( SOUNDS[i] );

        g_SoundSystem.PrecacheSound( RELOAD1_S );
        g_SoundSystem.PrecacheSound( RELOAD3_S );
        g_SoundSystem.PrecacheSound( SCOCK1_S );

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
        self.DefaultDeploy( self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), DRAW, "shotgun", 0, GetBodygroup() );
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
        return true;
    }

    void Holster( int skiplocal = 0 )
    {
        SetThink( null );
        m_fInReloadState = 0;
        BaseClass.Holster( skiplocal );
    }

    void ItemPostFrame()
    {
        BaseClass.ItemPostFrame();

        if( self.m_fInReload && m_fInReloadState != 0 )
            self.Reload();
    }

    bool PlayEmptySound()
    {
        if( self.m_bPlayEmptySound )
        {
            self.m_bPlayEmptySound = false;
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, EMPTY_SND, 0.8f, ATTN_NORM, 0, PITCH_NORM );
        }
        return false;
    }

    void PrimaryAttack()
    {
        // don't fire underwater
        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
            return;
        }

        if( self.m_iClip <= 0 )
        {
            self.Reload();
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.75f;
            return;
        }

        if( FinishReload( true ) )
                return;

        m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

        self.m_iClip -= 1;

        m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
        pev.effects |= EF_MUZZLEFLASH;

        // player "shoot" animation
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

        Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
        Vector vecSrc = m_pPlayer.GetGunPosition();
        Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

        float x, y;
        Vector vecDir, vecEnd;
        TraceResult tr;
        CBaseEntity@ pHit;
        for( int i = 0; i < PELLETS; i++ )
        {
            g_Utility.GetCircularGaussianSpread( x, y );

            vecDir = vecAiming + x * SINGLE_CONE.x * g_Engine.v_right + y * SINGLE_CONE.y * g_Engine.v_up;
            vecEnd = vecSrc + vecDir * 2048.0f;

            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
            self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 2048.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, DAMAGE, m_pPlayer.pev );
            Sparks::Sparks( tr.pHit, tr.iHitgroup, tr.vecEndPos );
            BloodSplash::Create( tr.pHit, tr.iHitgroup, tr.vecEndPos );

            if( tr.flFraction < 1.0f && tr.pHit !is null )
            {
                @pHit = g_EntityFuncs.Instance( tr.pHit );
                if( ( pHit is null || pHit.IsBSPModel() ) && !pHit.pev.FlagBitSet( FL_WORLDBRUSH ) )
                    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
            }
        }

        self.SendWeaponAnim( SHOOT, 0, GetBodygroup() );
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SHOOT_SND, Math.RandomFloat( 0.95f, 1.0f ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0x1f ) );
        m_pPlayer.pev.punchangle.x = m_fHasHEV ? -5.0f : -11.0f;

        Vector vecForward, vecRight, vecUp;
        g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
        Vector vecOrigin = m_pPlayer.GetGunPosition() + vecForward * SHELL.x + vecRight * SHELL.y + vecUp * SHELL.z;
        Vector vecVelocity = m_pPlayer.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
        g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, m_pPlayer.pev.v_angle.y, m_iShell, TE_BOUNCE_SHOTSHELL );

        if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && m_fHasHEV )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        if( !m_fHasHEV )
        {
            const float flZVel = m_pPlayer.pev.velocity.z;
            m_pPlayer.pev.velocity = m_pPlayer.pev.velocity + g_Engine.v_forward * -64.0f; // Knockback!
            m_pPlayer.pev.velocity.z = flZVel;
        }

        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + ( m_fHasHEV ? 0.85f : 1.0f );
        self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;

        if( self.m_iClip != 0 )
        {
            SetThink( ThinkFunction( PumpWeapon ) );
            pev.nextthink = g_Engine.time + 0.5f;
        }
    }

    void SecondaryAttack()
    {
        // don't fire underwater
        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
            return;
        }

        if( self.m_iClip <= 1 )
        {
            self.Reload();
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.75f;
            return;
        }

        if( FinishReload( true ) )
                return;

        m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

        self.m_iClip -= 2;

        m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
        pev.effects |= EF_MUZZLEFLASH;

        // player "shoot" animation
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

        Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
        Vector vecSrc = m_pPlayer.GetGunPosition();
        Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

        float x, y;
        Vector vecDir, vecEnd;
        TraceResult tr;
        CBaseEntity@ pHit;
        for( int i = 0; i < PELLETS * 2; i++ )
        {
            g_Utility.GetCircularGaussianSpread( x, y );

            vecDir = vecAiming + x * DOUBLE_CONE.x * g_Engine.v_right + y * DOUBLE_CONE.y * g_Engine.v_up;
            vecEnd = vecSrc + vecDir * 2048.0f;

            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
            self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 2048.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, DAMAGE, m_pPlayer.pev );

            if( tr.flFraction < 1.0f && tr.pHit !is null )
            {
                @pHit = g_EntityFuncs.Instance( tr.pHit );
                if( ( pHit is null || pHit.IsBSPModel() ) && !pHit.pev.FlagBitSet( FL_WORLDBRUSH ) )
                    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
            }
        }

        self.SendWeaponAnim( SHOOT2, 0, GetBodygroup() );
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SHOOT2_SND, Math.RandomFloat( 0.98f, 1.0f ), ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
        m_pPlayer.pev.punchangle.x = m_fHasHEV ? -10.0f : -24.0f;

        Vector vecForward, vecRight, vecUp;
        g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
        Vector vecOrigin = m_pPlayer.GetGunPosition() + vecForward * SHELL.x + vecRight * SHELL.y + vecUp * SHELL.z;
        Vector vecVelocity = m_pPlayer.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
        Vector vecVelocity2 = m_pPlayer.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
        g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, m_pPlayer.pev.v_angle.y, m_iShell, TE_BOUNCE_SHOTSHELL );
        g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity2, m_pPlayer.pev.v_angle.y, m_iShell, TE_BOUNCE_SHOTSHELL );

        if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && m_fHasHEV )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.5f;
        self.m_flTimeWeaponIdle = g_Engine.time + 6.0f;

        if( !m_fHasHEV )
        {
            const float flZVel = m_pPlayer.pev.velocity.z;
            m_pPlayer.pev.velocity = m_pPlayer.pev.velocity + g_Engine.v_forward * -128.0f; // Knockback!
            m_pPlayer.pev.velocity.z = flZVel;
        }

        if( self.m_iClip != 0 )
        {
            SetThink( ThinkFunction( PumpWeapon ) );
            pev.nextthink = g_Engine.time + 0.95f;
        }
    }

    void Reload()
    {
        if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        // don't reload until recoil is done
        if( self.m_flNextPrimaryAttack > g_Engine.time )
            return;

        if( m_flTimeWeaponReload > g_Engine.time )
            return;

        switch( m_fInReloadState )
        {
        case 0:
            self.SendWeaponAnim( START_RELOAD, 0, GetBodygroup() );
            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.0f;
            m_flTimeWeaponReload = g_Engine.time + 0.6f;
            m_fInReloadState = 1;
            break;
        case 1:
            self.SendWeaponAnim( RELOAD, 0, GetBodygroup() );
            switch( Math.RandomLong( 0, 1 ) )
            {
                case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, RELOAD1_S, 1.0f, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) ); break;
                case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, RELOAD3_S, 1.0f, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) ); break;
            }
            m_flTimeWeaponReload = g_Engine.time + ( m_fHasHEV ? 0.5f : 0.64f );
            m_fInReloadState = 2;
            BaseClass.Reload();
            break;
        case 2:
            // Add them to the clip
            self.m_iClip += 1;
            m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
            m_fInReloadState = 1;
            break;
        }

        self.m_fInReload = true;
        self.m_flTimeWeaponIdle = g_Engine.time + 1.5f;
    }

    void FinishReload()
    {
        FinishReload( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 );
    }

    void WeaponIdle()
    {
        self.ResetEmptySound();
        m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

        if( self.m_flTimeWeaponIdle > g_Engine.time )
            return;

        switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
        {
            case 0:
            self.SendWeaponAnim( IDLE_DEEP, 0, GetBodygroup() );
            self.m_flTimeWeaponIdle = g_Engine.time + 5.0f; // ( 60.0f / 12.0f );
            break;

            case 1:
            self.SendWeaponAnim( IDLE, 0, GetBodygroup() );
            self.m_flTimeWeaponIdle = g_Engine.time + 2.22f; // ( 20.0f / 9.0f );
            break;

            case 2:
            self.SendWeaponAnim( IDLE4, 0, GetBodygroup() );
            self.m_flTimeWeaponIdle = g_Engine.time + 2.22f; // ( 20.0f / 9.0f );
            break;
        }
    }

    private void PumpWeapon()
    {
        SetThink( null );
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, SCOCK1_S, 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 0x1f ) );
    }

    private bool FinishReload( bool fCondition )
    {
        if ( self.m_fInReload )
        {
            if ( m_fInReloadState != 0 )
            {
                if ( fCondition )
                {
                    m_fInReloadState = 0;
                    self.m_fInReload = false;
                    self.SendWeaponAnim( PUMP, 0, GetBodygroup() );
                    g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, SCOCK1_S, 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 0x1f ) );
                    self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.85f; // pump after
                    self.m_flTimeWeaponIdle = g_Engine.time + 1.5f;
                    return true;
                }
            }
            else
            {
                BaseClass.FinishReload();
                return true;
            }
        }
        return false;
    }
}

class ammo_bts_shotgun : ScriptBasePlayerAmmoEntity
{
    private string m_szModel = A_MODEL;
    private int m_iAmount = AMMO_GIVE;

    void Spawn()
    {
        if( pev.ClassNameIs( GetDAmmoName() ) )
        {
            m_szModel = D_MODEL;
            m_iAmount = 3;
        }

        Precache();
        g_EntityFuncs.SetModel( self, m_szModel );
        BaseClass.Spawn();
    }

    void Precache()
    {
        g_Game.PrecacheModel( m_szModel );
        g_SoundSystem.PrecacheSound( "hlclassic/items/9mmclip1.wav" );
    }

    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( m_iAmount, AMMO_TYPE, MAX_CARRY ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1.0f, ATTN_NORM );
            return true;
        }
        return false;
    }
}

string GetName()
{
    return "weapon_bts_shotgun";
}

string GetAmmoName()
{
    return "ammo_bts_shotgun";
}

string GetDAmmoName()
{
    return "ammo_bts_shotshell";
}

void Register()
{
#if SERVER
    weapons.insertLast( GetName() );
#endif

    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SHOTGUN::weapon_bts_shotgun", GetName() );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SHOTGUN::ammo_bts_shotgun", GetAmmoName() );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SHOTGUN::ammo_bts_shotgun", GetDAmmoName() );
    ID = g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", AMMO_TYPE, "", GetAmmoName(), "" );
}

}
