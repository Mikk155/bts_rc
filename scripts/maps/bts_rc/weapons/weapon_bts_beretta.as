/*
* M9 Beretta w/ Torchlight attached
* Author: Giegue, Mikk
* Animation: MTB
*/
// Rewrited by Rizulix for bts_rc (december 2024)

namespace HL_BERETTA
{

enum hlberetta_e
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
    ADD_SILENCER // IDLE3_2
};

enum bodygroups_e
{
    STUDIO = 0,
    HANDS
}

// Sounds
array<string> SOUNDS = {
    "bts_rc/weapons/beretta_draw.wav",
    "bts_rc/items/9mmclip1.wav",
    "bts_rc/items/9mmclip2.wav",
    "bts_rc/items/9mmcock3.wav"
};
// Weapon info
int MAX_CARRY = 120;
int MAX_CARRY2 = 10;
int MAX_CLIP = 15;
int MAX_CLIP2 = WEAPON_NOCLIP;
// int DEFAULT_GIVE = Math.RandomLong( 1, 15 );
// int DEFAULT_GIVE2 = Math.RandomLong( 1, 2 );
int AMMO_GIVE = MAX_CLIP;
int AMMO_GIVE2 = 1;
int AMMO_DROP = AMMO_GIVE;
int AMMO_DROP2 = AMMO_GIVE2;
int WEIGHT = 10;
int FLAGS = ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY;
// Weapon HUD
int SLOT = 1;
int POSITION = 6;
// Vars
int DAMAGE = 14;
float DRAIN_TIME = 0.8f;
string BATTERY_KV = "$i_berettaBattery";
Vector CONE( 0.01f, 0.01f, 0.01f );
Vector SHELL( 32.0f, 6.0f, -12.0f );

class weapon_bts_beretta : ScriptBasePlayerWeaponEntity
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
        pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( "models/bts_rc/weapons/v_beretta.mdl" ), pev.body, HANDS, g_PlayerClass[m_pPlayer] );
        return pev.body;
    }

    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, self.GetW_Model( "models/bts_rc/weapons/w_beretta.mdl" ) );
        self.m_iDefaultAmmo = Math.RandomLong( 1, MAX_CLIP );
        self.m_iDefaultSecAmmo = Math.RandomLong( 1, 2 );
        self.FallInit();
    }

    void Precache()
    {
        self.PrecacheCustomModels();
        g_Game.PrecacheModel( "models/bts_rc/weapons/w_beretta.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/v_beretta.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/p_beretta.mdl" );
        g_Game.PrecacheModel( "models/hlclassic/w_9mmclip.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/furniture/w_flashlightbattery.mdl" );

        m_iShell = g_Game.PrecacheModel( "models/hlclassic/shell.mdl" );

        g_Game.PrecacheOther( "ammo_bts_beretta" );
        g_Game.PrecacheOther( "ammo_bts_beretta_battery" );

        g_SoundSystem.PrecacheSound( "bts_rc/weapons/beretta_fire1.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );

        for( uint i = 0; i < SOUNDS.length(); i++ )
            g_SoundSystem.PrecacheSound( SOUNDS[i] );

        g_SoundSystem.PrecacheSound( "bts_rc/items/flashlight1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/items/battery_reload.wav" );

        g_Game.PrecacheGeneric( "sprites/bts_rc/wepspr.spr" );
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

        self.DefaultDeploy( self.GetV_Model( "models/bts_rc/weapons/v_beretta.mdl" ), self.GetP_Model( "models/bts_rc/weapons/p_beretta.mdl" ), DRAW, "onehanded", 0, GetBodygroup() );
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
        return true;
    }

    void Holster( int skiplocal = 0 )
    {
        SetThink( null );
        g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/items/battery_reload.wav" );

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
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/357_cock1.wav", 0.8f, ATTN_NORM, 0, PITCH_NORM );
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
            Sparks::Sparks( tr.pHit, tr.iHitgroup, tr.vecEndPos );
            BloodSplash::Create( tr.pHit, tr.iHitgroup, tr.vecEndPos );

            if( tr.flFraction < 1.0f && tr.pHit !is null )
            {
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if( ( pHit is null || pHit.IsBSPModel() ) && !pHit.pev.FlagBitSet( FL_WORLDBRUSH ) )
                    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
            }
        }

        self.SendWeaponAnim( self.m_iClip != 0 ? SHOOT : SHOOT_EMPTY, 0, GetBodygroup() );
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/beretta_fire1.wav", Math.RandomFloat( 0.92f, 1.0f ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
        m_pPlayer.pev.punchangle.x = m_fHasHEV ? -2.0f : -2.5f;

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

        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/items/battery_reload.wav", 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
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
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + ( 15.0f / 21.0f );
    }

    private void FlashlightTurnOn()
    {
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/items/flashlight1.wav", 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
        m_pPlayer.pev.effects |= EF_DIMLIGHT;

        NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, m_pPlayer.edict() );
            msg.WriteByte( 1 );
            msg.WriteByte( m_iCurrentBaterry );
        msg.End();

        m_flFlashLightTime = g_Engine.time + DRAIN_TIME;
    }

    private void FlashlightTurnOff()
    {
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/items/flashlight1.wav", 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
        m_pPlayer.pev.effects &= ~EF_DIMLIGHT;

        NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, m_pPlayer.edict() );
            msg.WriteByte( 0 );
            msg.WriteByte( m_iCurrentBaterry );
        msg.End();

        m_flFlashLightTime = 0.0f;
    }
}

class ammo_bts_beretta : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, "models/hlclassic/w_9mmclip.mdl" );
        BaseClass.Spawn();
    }

    void Precache()
    {
        g_Game.PrecacheModel( "models/hlclassic/w_9mmclip.mdl" );
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

class ammo_bts_beretta_battery : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, "models/bts_rc/furniture/w_flashlightbattery.mdl" );
        BaseClass.Spawn();
    }

    void Precache()
    {
        g_Game.PrecacheModel( "models/bts_rc/furniture/w_flashlightbattery.mdl" );
        g_SoundSystem.PrecacheSound( "bts_rc/items/battery_pickup1.wav" );
    }

    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( AMMO_GIVE2, "bts:battery", MAX_CARRY2 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "bts_rc/items/battery_pickup1.wav", 1.0f, ATTN_NORM );
            return true;
        }
        return false;
    }
}
}
