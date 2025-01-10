/*
* Mossberg 500 w/ Torchlight Attached
* Models: ZikShadow
* Scripts: Mikk, RaptorSKA
* Sound: RaptorSKA
* Sprites: ZikShadow
*/
// Rewrited by Rizulix for bts_rc (december 2024)

#include "../utils/player_class"

namespace HL_SBSHOTGUN
{

enum sbshotgun_e
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
string W_MODEL = "models/bts_rc/weapons/w_sbshotgun.mdl";
string V_MODEL = "models/bts_rc/weapons/v_sbshotgun.mdl";
string P_MODEL = "models/bts_rc/weapons/p_sbshotgun.mdl";
string A_MODEL = "models/hlclassic/w_shotbox.mdl";
string B_MODEL = "models/bts_rc/furniture/w_flashlightbattery.mdl";
// Sounds
string SHOOT_SND = "bts_rc/weapons/sbshotgun_fire1.wav";
string EMPTY_SND = "hlclassic/weapons/357_cock1.wav";
array<string> SOUNDS = {
    "bts_rc/weapons/spas12_foley.wav",
    "bts_rc/weapons/spas_idle4.wav",
    "bts_rc/weapons/fidget_3.wav",
    "bts_rc/weapons/fidget_4.wav",
};
string SWITCH_SND = "bts_rc/items/flashlight1.wav";
string RELOAD_SND = "bts_rc/items/battery_reload.wav";
string RELOAD1_S = "bts_rc/weapons/reload1.wav";
string RELOAD3_S = "bts_rc/weapons/reload3.wav";
string SCOCK1_S = "bts_rc/weapons/scock1.wav";
// Weapon info
int MAX_CARRY = 30;
int MAX_CARRY2 = 10;
int MAX_CLIP = 6;
int MAX_CLIP2 = WEAPON_NOCLIP;
// int DEFAULT_GIVE = Math.RandomLong( 1, 6 );
// int DEFAULT_GIVE2 = Math.RandomLong( 1, 2 );
int AMMO_GIVE = MAX_CLIP;
int AMMO_GIVE2 = 1;
int AMMO_DROP = AMMO_GIVE;
int AMMO_DROP2 = AMMO_GIVE2;
int WEIGHT = 15;
int FLAGS = ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY;
int ID; // assigned on register
string AMMO_TYPE = "buckshot";
string AMMO_TYPE2 = "bts:battery";
// Weapon HUD
int SLOT = 2;
int POSITION = 6;
// Vars
int DAMAGE = 16;
int PELLETS = 4;
float DRAIN_TIME = 0.8f;
string BATTERY_KV = "$i_sbshottyBattery";
Vector CONE( 0.08716f, 0.04362f, 0.0f );
Vector SHELL( 14.0f, 6.0f, -34.0f );

class weapon_bts_sbshotgun : ScriptBasePlayerWeaponEntity
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
    private int m_iFlashBattery
    {
        get const { return int( m_pPlayer.GetUserData()[ BATTERY_KV ] ); }
        set       { m_pPlayer.GetUserData()[ BATTERY_KV ] = value; }
    }
    private float m_flTimeWeaponReload;
    private float m_flFlashLightTime;
    private float m_flRestoreAfter = 0.0f;
    private int m_iCurrentBaterry;
    private int m_fInReloadState;
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
        self.m_iDefaultAmmo = Math.RandomLong( 1, MAX_CLIP );
        self.m_iDefaultSecAmmo = Math.RandomLong( 1, 2 );
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

        m_iShell = g_Game.PrecacheModel( "models/hlclassic/shotgunshell.mdl" );

        g_Game.PrecacheOther( GetAmmoName() );
        g_Game.PrecacheOther( GetBatteryName() );

        g_SoundSystem.PrecacheSound( SHOOT_SND );
        g_SoundSystem.PrecacheSound( EMPTY_SND );

        for( uint i = 0; i < SOUNDS.length(); i++ )
            g_SoundSystem.PrecacheSound( SOUNDS[i] );

        g_SoundSystem.PrecacheSound( SWITCH_SND );
        g_SoundSystem.PrecacheSound( RELOAD_SND );

        g_SoundSystem.PrecacheSound( RELOAD1_S );
        g_SoundSystem.PrecacheSound( RELOAD3_S );
        g_SoundSystem.PrecacheSound( SCOCK1_S );

        g_Game.PrecacheGeneric( "sprites/bts_rc/w_beretta.spr" );
        g_Game.PrecacheGeneric( "sprites/bts_rc/ammo_battery.spr" );
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
        info.iMaxAmmo2 = MAX_CARRY2;
        info.iAmmo2Drop = AMMO_DROP2;
        info.iMaxClip = MAX_CLIP;
        info.iSlot = SLOT;
        info.iPosition = POSITION;
        info.iId = g_ItemRegistry.GetIdForName( pev.classname );
        info.iFlags = FLAGS;
        info.iWeight = WEIGHT;
        return true;
    }

    bool CanDeploy()
    {
        return true;
    }

    bool Deploy()
    {
        m_iCurrentBaterry = m_iFlashBattery;
        m_pPlayer.pev.effects &= ~EF_DIMLIGHT; // just to be sure
        m_pPlayer.m_iHideHUD &= ~HIDEHUD_FLASHLIGHT;

        NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, m_pPlayer.edict() );
            msg.WriteByte( 0 );
            msg.WriteByte( m_iCurrentBaterry );
        msg.End();

        self.DefaultDeploy( self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), DRAW, "shotgun", 0, GetBodygroup() );
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
        return true;
    }

    void Holster( int skiplocal = 0 )
    {
        SetThink( null );
        g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, RELOAD_SND );

        if ( m_pPlayer.FlashlightIsOn() )
            FlashlightTurnOff();

        m_fInReloadState = 0;
        m_flRestoreAfter = 0.0f;
        self.m_fInReload = false;
        m_iFlashBattery = m_iCurrentBaterry;
        m_pPlayer.m_iHideHUD |= HIDEHUD_FLASHLIGHT;
        BaseClass.Holster( skiplocal );
    }

    void ItemPostFrame()
    {
        if( m_flFlashLightTime != 0.0f && m_flFlashLightTime <= g_Engine.time )
        {
            if( m_pPlayer.FlashlightIsOn() )
            {
                if( m_iCurrentBaterry != 0 )
                {
                    m_flFlashLightTime = g_Engine.time + DRAIN_TIME;
                    --m_iCurrentBaterry;

                    if( m_iCurrentBaterry == 0 )
                        FlashlightTurnOff();
                }
            }
            else
            {
                m_flFlashLightTime = 0.0f;
            }

            NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::FlashBat, m_pPlayer.edict() );
                msg.WriteByte( m_iCurrentBaterry );
            msg.End();
        }

        if( m_flRestoreAfter > 0.0f && m_flRestoreAfter <= g_Engine.time )
        {
            m_flRestoreAfter = 0.0f;
            m_pPlayer.pev.effects |= EF_DIMLIGHT;
        }
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

        // force reload end (PUMP)
        if( FinishReload( true ) )
            return;

        m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

        --self.m_iClip;

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

            vecDir = vecAiming + x * CONE.x * g_Engine.v_right + y * CONE.y * g_Engine.v_up;
            vecEnd = vecSrc + vecDir * 2048.0f;

            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
            self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 2048.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, DAMAGE, m_pPlayer.pev );
            Sparks::Sparks(tr.pHit, tr.iHitgroup, tr.vecEndPos );

            if( tr.flFraction < 1.0f && tr.pHit !is null )
            {
                @pHit = g_EntityFuncs.Instance( tr.pHit );
                if( ( pHit is null || pHit.IsBSPModel() ) && !pHit.pev.FlagBitSet( FL_WORLDBRUSH ) )
                    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
            }
        }

        self.SendWeaponAnim( SHOOT, 0, GetBodygroup() );
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SHOOT_SND, Math.RandomFloat( 0.92f, 1.0f ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
        m_pPlayer.pev.punchangle.x = m_fHasHEV ? -5.0f : -11.0f;

        Vector vecForward, vecRight, vecUp;
        g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
        Vector vecOrigin = m_pPlayer.GetGunPosition() + vecForward * SHELL.x + vecRight * SHELL.y + vecUp * SHELL.z;
        Vector vecVelocity = m_pPlayer.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
        g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, m_pPlayer.pev.v_angle.y, m_iShell, TE_BOUNCE_SHOTSHELL );

        if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && m_fHasHEV )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + ( m_fHasHEV ? 0.85f : 1.0f );
        self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;

        if( !m_fHasHEV )
        {
            const float flZVel = m_pPlayer.pev.velocity.z;
            m_pPlayer.pev.velocity = m_pPlayer.pev.velocity + g_Engine.v_forward * -64.0f; // Knockback!
            m_pPlayer.pev.velocity.z = flZVel;
        }

        if( self.m_iClip != 0 )
        {
            SetThink( ThinkFunction( PumpWeapon ) );
            pev.nextthink = g_Engine.time + 0.5f;
        }
    }

    void SecondaryAttack()
    {
        if( self.m_fInReload )
            return;

        if( m_iCurrentBaterry == 0 )
        {
            self.PlayEmptySound();
            self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
            return;
        }

        if( m_pPlayer.FlashlightIsOn() )
            FlashlightTurnOff();
        else
            FlashlightTurnOn();

        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.5f;
    }

    void TertiaryAttack()
    {
        if( m_iCurrentBaterry != 0 || m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0 )
            return;

        // force reload end (PUMP)
        if( FinishReload( true ) )
            return;

        SetThink( null );
        m_fInReloadState = 0;
        m_flRestoreAfter = 0.0f;
        self.m_fInReload = false;
        m_flFlashLightTime = 0.0f;

        SetThink( ThinkFunction( BaterryRechargeStart ) );
        pev.nextthink = g_Engine.time + ( 10.0f / 30.0f );

        self.SendWeaponAnim( HOLSTER, 0, GetBodygroup() );
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 20.0f; // just block
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

        if( m_pPlayer.FlashlightIsOn() )
        {
            m_pPlayer.pev.effects &= ~EF_DIMLIGHT;
            m_flRestoreAfter = -1.0f;
        }

        switch( m_fInReloadState )
        {
        case 0:
            self.SendWeaponAnim( START_RELOAD, 0, GetBodygroup() );
            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 1.0f;
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

    private void BaterryRechargeStart()
    {
        SetThink( ThinkFunction( BaterryRechargeEnd ) );
        pev.nextthink = g_Engine.time + 4.0f;

        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, RELOAD_SND, 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
    }

    private void BaterryRechargeEnd()
    {
        SetThink( null );

        self.SendWeaponAnim( DRAW, 0, GetBodygroup() );
        m_iFlashBattery = m_iCurrentBaterry = 100;

        NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::FlashBat, m_pPlayer.edict() );
            msg.WriteByte( m_iCurrentBaterry );
        msg.End();

        m_pPlayer.m_flNextAttack = 0.5f;
        m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + ( 12.0f / 24.0f );
    }

    private void FlashlightTurnOn()
    {
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SWITCH_SND, 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
        m_pPlayer.pev.effects |= EF_DIMLIGHT;

        NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, m_pPlayer.edict() );
            msg.WriteByte( 1 );
            msg.WriteByte( m_iCurrentBaterry );
        msg.End();

        m_flFlashLightTime = g_Engine.time + DRAIN_TIME;
    }

    private void FlashlightTurnOff()
    {
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SWITCH_SND, 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
        m_pPlayer.pev.effects &= ~EF_DIMLIGHT;

        NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, m_pPlayer.edict() );
            msg.WriteByte( 0 );
            msg.WriteByte( m_iCurrentBaterry );
        msg.End();

        m_flFlashLightTime = 0.0f;
    }

    private bool FinishReload( bool fCondition )
    {
        if ( self.m_fInReload )
        {
            if ( m_fInReloadState != 0 )
            {
                if ( fCondition )
                {
                    if( m_flRestoreAfter == -1.0f )
                        m_flRestoreAfter = g_Engine.time + 1.0f;

                    m_fInReloadState = 0;
                    self.m_fInReload = false;
                    self.SendWeaponAnim( PUMP, 0, GetBodygroup() );
                    g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, SCOCK1_S, 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 0x1f ) );
                    self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.85f; // pump after
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

class ammo_bts_sbshotgun : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, A_MODEL );
        BaseClass.Spawn();
    }

    void Precache()
    {
        g_Game.PrecacheModel( A_MODEL );
        g_SoundSystem.PrecacheSound( "hlclassic/items/9mmclip1.wav" );
    }

    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( AMMO_GIVE, AMMO_TYPE, MAX_CARRY ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1.0f, ATTN_NORM );
            return true;
        }
        return false;
    }
}

class ammo_bts_sbshotgun_battery : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, B_MODEL );
        BaseClass.Spawn();
    }

    void Precache()
    {
        g_Game.PrecacheModel( B_MODEL );
        g_SoundSystem.PrecacheSound( "bts_rc/items/battery_pickup1.wav" );
    }

    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( AMMO_GIVE2, AMMO_TYPE2, MAX_CARRY2 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "bts_rc/items/battery_pickup1.wav", 1.0f, ATTN_NORM );
            return true;
        }
        return false;
    }
}

string GetName()
{
    return "weapon_bts_sbshotgun";
}

string GetAmmoName()
{
    return "ammo_bts_sbshotgun";
}

string GetBatteryName()
{
    return "ammo_bts_sbshotgun_battery";
}

void Register()
{
    #if SERVER
        weapons.insertLast( GetName() );
    #endif

    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SBSHOTGUN::weapon_bts_sbshotgun", GetName() );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SBSHOTGUN::ammo_bts_sbshotgun", GetAmmoName() );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SBSHOTGUN::ammo_bts_sbshotgun_battery", GetBatteryName() );
    ID = g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", AMMO_TYPE, AMMO_TYPE2, GetAmmoName(), GetBatteryName() );
}

}
