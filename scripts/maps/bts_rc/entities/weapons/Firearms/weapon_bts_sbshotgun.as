/**
*   Copyright (c) 2026 Mikk155 and contributors of bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software to use, copy, modify, merge, publish, distribute, sublicense,
*   and/or sell copies of the Software under the following conditions:
*   
*   A reference to the original project must be included in all copies or substantial
*   portions of the Software. This must include, at minimum, a URL to:
*   https://github.com/Mikk155/bts_rc
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies of the Software when distributed as a whole.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
**/

final class ASWeaponSBShotgunConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_sbshotgun";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_sbshotgun.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_sbshotgun.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_sbshotgun.mdl";
    }

    const string& get_animation_extension() override
    {
        return "shotgun";
    }

    const string& get_primary_ammo() override
    {
        return "buckshot";
    }

    const string& get_primary_ammoentity() override
    {
        return "ammo_bts_sbshotgun";
    }

    const string& get_secondary_ammo() override
    {
        return "bts_battery";
    }

    const string& get_secondary_ammoentity() override
    {
        return "ammo_bts_sbshotgun_battery";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponSBShotgunAnim::DRAW;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/sbshotgun_fire1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/reload1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/reload3.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/sbscock1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/items/battery_reload.wav" );
        g_SoundSystem.PrecacheSound( "items/flashlight1.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        ASWeaponConfig::Precache();
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapon configuration",
            "description": "Control sbshotgun configuration",
            "allOf":
            [
                "ASWeaponConfig"
            ],
            "properties":
            {
            }
        }""";
    }
}

ASWeaponSBShotgunConfig gpWeaponSBShotgunConfig;

enum WeaponSBShotgunAnim
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
    IDLE_DEEP,
    IDLE_STEAMFACEPALM,
    FLASH
};

class weapon_bts_sbshotgun : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponSBShotgunConfig;
    }

    private int m_iFlashBattery
    {
        get
        {
            if( !this.owner.GetUserData().exists( pev.classname ) )
            {
                this.owner.GetUserData()[pev.classname] = Math.RandomLong( 0, 50 );
            }
            return int( this.owner.GetUserData()[pev.classname] );
        }
        set
        {
            this.owner.GetUserData()[pev.classname] = value;
        }
    }

    private float m_flTimeWeaponReload = 0.0f;
    private float m_flFlashLightTime = 0.0f;
    private float m_flRestoreAfter = 0.0f;
    private int m_iCurrentBattery = 0;
    private int m_fInReloadState = 0;

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 1, gpWeaponSBShotgunConfig.max_clip );
        self.m_iDefaultSecAmmo = Math.RandomLong( 1, 2 );
        BTS_FireWeapon::Spawn();
    }

    void Holster( int skiplocal = 0 )
    {
        SetThink( null );
        g_SoundSystem.StopSound( this.owner.edict(), CHAN_WEAPON, "bts_rc/items/battery_reload.wav" );

        if( this.owner.FlashlightIsOn() )
            FlashlightTurnOff();

        m_fInReloadState = 0;
        m_flRestoreAfter = 0.0f;
        self.m_fInReload = false;
        m_iFlashBattery = m_iCurrentBattery;
        this.owner.m_iHideHUD |= HIDEHUD_FLASHLIGHT;
        BaseClass.Holster( skiplocal );
    }

    void ItemPostFrame()
    {
        float drainTime = 0.8f;
        if( m_flFlashLightTime != 0.0f && m_flFlashLightTime <= g_Engine.time )
        {
            if( this.owner.FlashlightIsOn() )
            {
                if( m_iCurrentBattery != 0 )
                {
                    m_flFlashLightTime = g_Engine.time + drainTime;
                    --m_iCurrentBattery;

                    if( m_iCurrentBattery == 0 )
                        FlashlightTurnOff();
                }
            }
            else
            {
                m_flFlashLightTime = 0.0f;
            }

            NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::FlashBat, this.owner.edict() );
            msg.WriteByte( m_iCurrentBattery );
            msg.End();
        }

        if( m_flRestoreAfter > 0.0f && m_flRestoreAfter <= g_Engine.time )
        {
            m_flRestoreAfter = 0.0f;
            this.owner.pev.effects |= EF_DIMLIGHT;
        }

        BaseClass.ItemPostFrame();

        if( self.m_fInReload && m_fInReloadState != 0 )
            self.Reload();
    }

    bool Deploy() override
    {
        m_iCurrentBattery = m_iFlashBattery;
        this.owner.pev.effects &= ~EF_DIMLIGHT;
        this.owner.m_iHideHUD &= ~HIDEHUD_FLASHLIGHT;

        NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, this.owner.edict() );
        msg.WriteByte( 0 );
        msg.WriteByte( m_iCurrentBattery );
        msg.End();

        return BTS_FireWeapon::Deploy();
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        if( player.pev.waterlevel == WATERLEVEL_HEAD )
        {
            this.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.12f;
            return;
        }

        if( type == AttackType::Secondary )
        {
            if( self.m_fInReload )
                return;

            if( m_iCurrentBattery == 0 )
            {
                if( player.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0 || FinishReload( true ) )
                {
                    this.PlayEmptySound();
                    self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
                }
                else
                {
                    SetThink( null );
                    m_fInReloadState = 0;
                    m_flRestoreAfter = 0.0f;
                    self.m_fInReload = false;
                    m_flFlashLightTime = 0.0f;

                    SetThink( ThinkFunction( BatteryRechargeStart ) );
                    pev.nextthink = g_Engine.time + ( 10.0f / 30.0f );

                    PlayAnim( WeaponSBShotgunAnim::HOLSTER );
                    self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;
                }
            }
            else
            {
                if( player.FlashlightIsOn() )
                    FlashlightTurnOff();
                else
                    FlashlightTurnOn();

                self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 5.0f, 10.0f );
                PlayAnim( WeaponSBShotgunAnim::FLASH );
                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.5f;
            }
            return;
        }

        if( type != AttackType::Primary )
        {
            return;
        }

        if( self.m_iClip <= 0 )
        {
            self.Reload();
            this.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.75f;
            return;
        }

        if( FinishReload( true ) )
            return;

        player.m_iWeaponVolume = LOUD_GUN_VOLUME;
        player.m_iWeaponFlash = NORMAL_GUN_FLASH;

        self.m_iClip -= 1;

        player.pev.effects |= EF_MUZZLEFLASH;
        pev.effects |= EF_MUZZLEFLASH;

        Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );
        Vector vecSrc = player.GetGunPosition();
        Vector vecAiming = player.GetAutoaimVector( AUTOAIM_5DEGREES );

        float x, y;
        Vector vecDir, vecEnd;
        TraceResult tr;
        CBaseEntity@ pHit;
        int pellets = 8;
        float damage = gpWeaponSBShotgunConfig.primary_damage;
        Vector cone = Vector( 0.08716f, 0.04362f, 0.0f ); // CONE

        for( int i = 0; i < pellets; i++ )
        {
            g_Utility.GetCircularGaussianSpread( x, y );

            vecDir = vecAiming + x * cone.x * g_Engine.v_right + y * cone.y * g_Engine.v_up;
            vecEnd = vecSrc + vecDir * 2048.0f;

            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, player.edict(), tr );
            self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 2048.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, int( damage ), player.pev );
            TraceEffects( tr, Bullet::BULLET_PLAYER_CUSTOMDAMAGE );
        }

        bool isTrainedPersonal = util::IsTrainedPersonal( player );

        PlayAnim( WeaponSBShotgunAnim::SHOOT );
        PlaySound( "bts_rc/weapons/sbshotgun_fire1.wav", Math.RandomFloat( 0.92f, 1.0f ), 98 + Math.RandomLong( 0, 3 ) );
        player.pev.punchangle.x = isTrainedPersonal ? -5.0f : -11.0f;

        Vector vecForward, vecRight, vecUp;
        g_EngineFuncs.AngleVectors( player.pev.v_angle, vecForward, vecRight, vecUp );
        Vector vecOrigin = player.GetGunPosition() + vecForward * 14.0f + vecRight * 6.0f - vecUp * 34.0f;
        Vector vecVelocity = player.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
        g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, player.pev.v_angle.y, models::shotgunshell, TE_BOUNCE_SHOTSHELL );

        CheckDepletedAmmo( self.m_iPrimaryAmmoType );

        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.85f;
        self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;

        if( !isTrainedPersonal )
        {
            const float flZVel = player.pev.velocity.z;
            player.pev.velocity = player.pev.velocity + g_Engine.v_forward * -64.0f;
            player.pev.velocity.z = flZVel;
        }

        if( self.m_iClip != 0 )
        {
            SetThink( ThinkFunction( PumpWeapon ) );
            pev.nextthink = g_Engine.time + 0.5f;
        }
    }

    void Reload()
    {
        if( self.m_iClip == gpWeaponSBShotgunConfig.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        if( self.m_flNextPrimaryAttack > g_Engine.time )
            return;

        if( m_flTimeWeaponReload > g_Engine.time )
            return;

        if( this.owner.FlashlightIsOn() )
            FlashlightTurnOff();

        switch( m_fInReloadState )
        {
            case 0:
                PlayAnim( WeaponSBShotgunAnim::START_RELOAD );
                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 1.0f;
                m_flTimeWeaponReload = g_Engine.time + 0.6f;
                m_fInReloadState = 1;
                break;
            case 1:
                PlayAnim( WeaponSBShotgunAnim::RELOAD );
                if( Math.RandomLong( 0, 1 ) == 0 )
                    PlaySound( "bts_rc/weapons/reload1.wav", 1.0f, 85 + Math.RandomLong( 0, 0x1f ) );
                else
                    PlaySound( "bts_rc/weapons/reload3.wav", 1.0f, 85 + Math.RandomLong( 0, 0x1f ) );
                m_flTimeWeaponReload = g_Engine.time + 0.4f;
                m_fInReloadState = 2;
                BaseClass.Reload();
                break;
            case 2:
                self.m_iClip += 1;
                this.owner.m_rgAmmo( self.m_iPrimaryAmmoType, this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
                m_fInReloadState = 1;
                break;
        }

        self.m_fInReload = true;
        self.m_flTimeWeaponIdle = g_Engine.time + 1.5f;
    }

    void FinishReload()
    {
        FinishReload( self.m_iClip == gpWeaponSBShotgunConfig.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 );
    }

    private void PumpWeapon()
    {
        SetThink( null );
        PlaySound( "bts_rc/weapons/sbscock1.wav", 1.0f, 95 + Math.RandomLong( 0, 0x1f ) );
    }

    private void BatteryRechargeStart()
    {
        SetThink( ThinkFunction( BatteryRechargeEnd ) );
        pev.nextthink = g_Engine.time + 4.0f;
        FlashlightTurnOff();

        PlaySound( "bts_rc/items/battery_reload.wav", 1.0f, 95 + Math.RandomLong( 0, 10 ) );
    }

    private void BatteryRechargeEnd()
    {
        SetThink( null );

        PlayAnim( WeaponSBShotgunAnim::DRAW );
        m_iFlashBattery = m_iCurrentBattery = 100;

        NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::FlashBat, this.owner.edict() );
        msg.WriteByte( m_iCurrentBattery );
        msg.End();

        this.owner.m_flNextAttack = 0.5f;
        this.owner.m_rgAmmo( self.m_iSecondaryAmmoType, this.owner.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + ( 12.0f / 24.0f );
    }

    private void FlashlightTurnOn()
    {
        PlaySound( "items/flashlight1.wav", 1.0f, 95 + Math.RandomLong( 0, 10 ) );
        this.owner.pev.effects |= EF_DIMLIGHT;

        NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, this.owner.edict() );
        msg.WriteByte( 1 );
        msg.WriteByte( m_iCurrentBattery );
        msg.End();

        float drainTime = 0.8f;
        m_flFlashLightTime = g_Engine.time + drainTime;
    }

    private void FlashlightTurnOff()
    {
        PlaySound( "items/flashlight1.wav", 1.0f, 95 + Math.RandomLong( 0, 10 ) );
        this.owner.pev.effects &= ~EF_DIMLIGHT;

        NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, this.owner.edict() );
        msg.WriteByte( 0 );
        msg.WriteByte( m_iCurrentBattery );
        msg.End();

        m_flFlashLightTime = 0.0f;
    }

    private bool FinishReload( bool fCondition )
    {
        if( self.m_fInReload )
        {
            if( m_fInReloadState != 0 )
            {
                if( fCondition )
                {
                    if( m_flRestoreAfter == -1.0f )
                        m_flRestoreAfter = g_Engine.time + 1.0f;

                    m_fInReloadState = 0;
                    self.m_fInReload = false;
                    PlayAnim( WeaponSBShotgunAnim::PUMP );
                    PlaySound( "bts_rc/weapons/sbscock1.wav", 1.0f, 95 + Math.RandomLong( 0, 0x1f ) );
                    self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.85f;
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

    float Idle() override
    {
        self.ResetEmptySound();

        switch( Math.RandomLong( 0, 2 ) )
        {
            case 0:
                PlayAnim( WeaponSBShotgunAnim::IDLE_DEEP );
                return 5.0f;
            case 1:
                PlayAnim( WeaponSBShotgunAnim::IDLE );
                return 2.22f;
            case 2:
            default:
                PlayAnim( WeaponSBShotgunAnim::IDLE4 );
                return 2.22f;
        }
    }
}
