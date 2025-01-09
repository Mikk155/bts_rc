/*
* Glock 17 w/ Torchlight
* Author: Mikk, KernCore, RaptorSKA
*/
// Rewrited by Rizulix for bts_rc (december 2024)

#include "../utils/player_class"

namespace BTS_GLOCK17F
{

enum btsg17f_e
{
    IDLE1 = 0,
    IDLE2,
    IDLE3,
    SHOOT,
    SHOOT_EMPTY,
    RELOAD_EMPTY,
    RELOAD,
    DRAW,
    HOLSTER,
    ADD_SILENCER
};

enum bodygroups_e
{
    STUDIO0 = 0,
    STUDIO1,
    HANDS,
    SILENCER
};

enum modes_e
{
    SEMI_AUTO = 0,
    FULL_AUTO
};

// Models
string W_MODEL = "models/hlclassic/w_9mmhandgun.mdl";
string V_MODEL = "models/bts_rc/weapons/v_glock17f.mdl";
string P_MODEL = "models/hlclassic/p_9mmhandgun.mdl";
string A_MODEL = "models/hlclassic/w_9mmclip.mdl";
// Sounds
string SHOOT_SND = "bts_rc/weapons/glock_fire1.wav";
string EMPTY_SND = "hlclassic/weapons/357_cock1.wav";
array<string> SOUNDS = {
    "hlclassic/items/9mmclip1.wav",
    "hlclassic/items/9mmclip2.wav"
};
string SWITCH_SND = "bts_rc/items/flashlight1.wav";
string RELOAD_SND = "bts_rc/items/battery_reload.wav";
// Weapon info
int MAX_CARRY = 120;
int MAX_CARRY2 = 2;
int MAX_CLIP = 17;
int MAX_CLIP2 = WEAPON_NOCLIP;
// int DEFAULT_GIVE = Math.RandomLong( 8, 17 );
// int DEFAULT_GIVE2 = Math.RandomLong( 1, 2 );
int AMMO_GIVE = MAX_CLIP;
int AMMO_DROP = AMMO_GIVE;
int WEIGHT = 10;
int FLAGS = 0;
int ID; // assigned on register
string AMMO_TYPE = "9mm";
string AMMO_TYPE2 = "bts:g17f/battery";
// Weapon HUD
int SLOT = 1;
int POSITION = 7;
// Vars
int DAMAGE = 12;
float DRAIN_TIME = 0.8f;
string BATTERY_KV = "$i_g17fBattery";
Vector CONE( 0.01f, 0.01f, 0.01f );
Vector SHELL( 32.0f, 6.0f, -12.0f );

class weapon_bts_glock17f : ScriptBasePlayerWeaponEntity
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
    private float m_flFlashLightTime;
    private float m_flRestoreAfter = 0.0f;
    private int m_iCurrentBaterry;
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
        self.m_iDefaultAmmo = Math.RandomLong( 8, MAX_CLIP );
        self.m_iDefaultSecAmmo = Math.RandomLong( 1, 2 );
        self.FallInit();
    }

    void Precache()
    {
        self.PrecacheCustomModels();
        g_Game.PrecacheModel( W_MODEL );
        g_Game.PrecacheModel( V_MODEL );
        g_Game.PrecacheModel( P_MODEL );
        g_Game.PrecacheModel( A_MODEL );

        m_iShell = g_Game.PrecacheModel( "models/hlclassic/shell.mdl" );

        g_Game.PrecacheOther( GetAmmoName() );

        g_SoundSystem.PrecacheSound( SHOOT_SND );
        g_SoundSystem.PrecacheSound( EMPTY_SND );

        for( uint i = 0; i < SOUNDS.length(); i++ )
            g_SoundSystem.PrecacheSound( SOUNDS[i] );

        g_SoundSystem.PrecacheSound( SWITCH_SND );
        g_SoundSystem.PrecacheSound( RELOAD_SND );

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
        m_iCurrentBaterry = m_iFlashBattery;
        m_pPlayer.pev.effects &= ~EF_DIMLIGHT; // just to be sure
        m_pPlayer.m_iHideHUD &= ~HIDEHUD_FLASHLIGHT;

        NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, m_pPlayer.edict() );
            msg.WriteByte( 0 );
            msg.WriteByte( m_iCurrentBaterry );
        msg.End();

        self.DefaultDeploy( self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), DRAW, "onehanded", 0, GetBodygroup() );
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
        return true;
    }

    void Holster( int skiplocal = 0 )
    {
        SetThink( null );

        if ( m_pPlayer.FlashlightIsOn() )
            FlashlightTurnOff();

        m_flRestoreAfter = 0.0f;
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

        if( m_flRestoreAfter != 0.0f && m_flRestoreAfter <= g_Engine.time )
        {
            m_flRestoreAfter = 0.0f;
            m_pPlayer.pev.effects |= EF_DIMLIGHT;
        }
        BaseClass.ItemPostFrame();
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
        if( self.m_iClip <= 0 )
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

            Vector vecDir = vecAiming + x * CONE.x * g_Engine.v_right + y * CONE.y * g_Engine.v_up;
            Vector vecEnd = vecSrc + vecDir * 8192.0f;

            TraceResult tr;
            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
            self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, DAMAGE, m_pPlayer.pev );
            Sparks::Sparks(tr.pHit, tr.iHitgroup, tr.vecEndPos );

            if( tr.flFraction < 1.0f && tr.pHit !is null )
            {
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if( ( pHit is null || pHit.IsBSPModel() ) && !pHit.pev.FlagBitSet( FL_WORLDBRUSH ) )
                    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
            }
        }

        self.SendWeaponAnim( self.m_iClip != 0 ? SHOOT : SHOOT_EMPTY, 0, GetBodygroup() );
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SHOOT_SND, Math.RandomFloat( 0.92f, 1.0f ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
        m_pPlayer.pev.punchangle.x = m_fHasHEV ? -2.0f : -2.65f;

        Vector vecForward, vecRight, vecUp;
        g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
        Vector vecOrigin = m_pPlayer.GetGunPosition() + vecForward * SHELL.x + vecRight * SHELL.y + vecUp * SHELL.z;
        Vector vecVelocity = m_pPlayer.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
        g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, m_pPlayer.pev.v_angle.y, m_iShell, TE_BOUNCE_SHELL );

        if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && m_fHasHEV )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + ( m_fHasHEV ? 0.3f : 0.325f );
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
    }

    void SecondaryAttack()
    {
        if( m_iCurrentBaterry == 0 )
            return;

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

        SetThink( null );
        m_flRestoreAfter = 0.0f;
        self.m_fInReload = false;
        m_flFlashLightTime = 0.0f;

        SetThink( ThinkFunction( BaterryRechargeStart ) );
        pev.nextthink = g_Engine.time + ( 15.0f / 16.0f );

        self.SendWeaponAnim( HOLSTER, 0, GetBodygroup() );
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 20.0f; // just block
    }

    void Reload()
    {
        if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        float flNextAttack = self.m_flNextPrimaryAttack - ( m_fHasHEV ? 0.3f : 0.325f );
        if( flNextAttack > g_Engine.time ) // uggly hax
            return;

        if( m_pPlayer.FlashlightIsOn() )
        {
            m_pPlayer.pev.effects &= ~EF_DIMLIGHT;
            m_flRestoreAfter = g_Engine.time + 1.6f;
        }

        self.DefaultReload( MAX_CLIP, self.m_iClip != 0 ? RELOAD : RELOAD_EMPTY, 1.5f, GetBodygroup() );
        self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0f, 15.0f );
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

        self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 6.0f, 8.0f );
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
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + ( 9.0f / 16.0f );
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
    }
}

class ammo_bts_glock17f : ScriptBasePlayerAmmoEntity
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

string GetName()
{
    return "weapon_bts_glock17f";
}

string GetAmmoName()
{
    return "ammo_bts_glock17f";
}

void Register()
{
    #if SERVER
        weapons.insertLast( GetName() );
    #endif

    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_GLOCK17F::weapon_bts_glock17f", GetName() );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_GLOCK17F::ammo_bts_glock17f", GetAmmoName() );
    ID = g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", AMMO_TYPE, AMMO_TYPE2, GetAmmoName(), "" );
}

}
