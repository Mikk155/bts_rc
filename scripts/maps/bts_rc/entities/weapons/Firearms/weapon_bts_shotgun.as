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

final class ASWeaponShotgunConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_shotgun";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_shotgun.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_shotgun.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_shotgun.mdl";
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
        return "ammo_bts_shotgun";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponShotgunAnim::DRAW;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/sbarrel1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/spas12_dbarrel1.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/reload1.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/reload3.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/scock1.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        ASWeaponConfig::Precache();
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        this.slot = 2;
        this.position = 7;
        this.weight = 15;
        this.deploy_time = 1.0;
        this.primary_maxammo = 30;
        this.primary_dropammo = 3;
        this.max_clip = 8;
        this.primary_damage = 16;
        this.primary_cooldown = 0.85;
        this.primary_trained_cooldown = 0.85;

        return ASWeaponConfig::Register( json );
    }
}

ASWeaponShotgunConfig gpWeaponShotgunConfig;

enum WeaponShotgunAnim
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

class weapon_bts_shotgun : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponShotgunConfig;
    }

    private float m_flTimeWeaponReload = 0.0f;
    private int m_fInReloadState = 0;

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 2, gpWeaponShotgunConfig.max_clip );
        BTS_FireWeapon::Spawn();
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

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        if( player.pev.waterlevel == WATERLEVEL_HEAD )
        {
            this.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
            return;
        }

        if( type == AttackType::Secondary )
        {
            if( self.m_iClip <= 1 )
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

            self.m_iClip -= 2;

            player.pev.effects |= EF_MUZZLEFLASH;
            pev.effects |= EF_MUZZLEFLASH;


            Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );
            Vector vecSrc = player.GetGunPosition();
            Vector vecAiming = player.GetAutoaimVector( AUTOAIM_5DEGREES );

            float x, y;
            Vector vecDir, vecEnd;
            TraceResult tr;
            CBaseEntity@ pHit;
            int pellets = 16;
            float damage = gpWeaponShotgunConfig.primary_damage;
            Vector cone = Vector( 0.17365f, 0.04362f, 0.0f ); // DOUBLE_CONE

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

            PlayAnim( WeaponShotgunAnim::SHOOT2 );
            PlaySound( "bts_rc/weapons/spas12_dbarrel1.wav", Math.RandomFloat( 0.98f, 1.0f ), 85 + Math.RandomLong( 0, 0x1f ) );
            player.pev.punchangle.x = isTrainedPersonal ? -10.0f : -24.0f;

            Vector vecForward, vecRight, vecUp;
            g_EngineFuncs.AngleVectors( player.pev.v_angle, vecForward, vecRight, vecUp );
            Vector vecOrigin = player.GetGunPosition() + vecForward * 14.0f + vecRight * 6.0f - vecUp * 34.0f;
            Vector vecVelocity1 = player.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
            Vector vecVelocity2 = player.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
            g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity1, player.pev.v_angle.y, models::shotgunshell, TE_BOUNCE_SHOTSHELL );
            g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity2, player.pev.v_angle.y, models::shotgunshell, TE_BOUNCE_SHOTSHELL );

            if( self.m_iClip <= 0 && player.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && util::IsHEV( player ) )
                player.SetSuitUpdate( "!HEV_AMO0", false, 0 );

            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.5f;
            self.m_flTimeWeaponIdle = g_Engine.time + 6.0f;

            if( !isTrainedPersonal )
            {
                const float flZVel = player.pev.velocity.z;
                player.pev.velocity = player.pev.velocity + g_Engine.v_forward * -128.0f;
                player.pev.velocity.z = flZVel;
            }

            if( self.m_iClip != 0 )
            {
                SetThink( ThinkFunction( PumpWeapon ) );
                pev.nextthink = g_Engine.time + 0.95f;
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
        float damage = gpWeaponShotgunConfig.primary_damage;
        Vector cone = Vector( 0.08716f, 0.04362f, 0.0f ); // SINGLE_CONE

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

        PlayAnim( WeaponShotgunAnim::SHOOT );
        PlaySound( "hlclassic/weapons/sbarrel1.wav", Math.RandomFloat( 0.95f, 1.0f ), 93 + Math.RandomLong( 0, 0x1f ) );
        player.pev.punchangle.x = isTrainedPersonal ? -5.0f : -11.0f;

        Vector vecForward, vecRight, vecUp;
        g_EngineFuncs.AngleVectors( player.pev.v_angle, vecForward, vecRight, vecUp );
        Vector vecOrigin = player.GetGunPosition() + vecForward * 14.0f + vecRight * 6.0f - vecUp * 34.0f;
        Vector vecVelocity = player.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
        g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, player.pev.v_angle.y, models::shotgunshell, TE_BOUNCE_SHOTSHELL );

        if( self.m_iClip <= 0 && player.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && util::IsHEV( player ) )
            player.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        if( !isTrainedPersonal )
        {
            const float flZVel = player.pev.velocity.z;
            player.pev.velocity = player.pev.velocity + g_Engine.v_forward * -64.0f;
            player.pev.velocity.z = flZVel;
        }

        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.85f;
        self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;

        if( self.m_iClip != 0 )
        {
            SetThink( ThinkFunction( PumpWeapon ) );
            pev.nextthink = g_Engine.time + 0.5f;
        }
    }

    void Reload()
    {
        if( self.m_iClip == gpWeaponShotgunConfig.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        if( self.m_flNextPrimaryAttack > g_Engine.time )
            return;

        if( m_flTimeWeaponReload > g_Engine.time )
            return;

        switch( m_fInReloadState )
        {
            case 0:
                PlayAnim( WeaponShotgunAnim::START_RELOAD );
                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.0f;
                m_flTimeWeaponReload = g_Engine.time + 0.6f;
                m_fInReloadState = 1;
                break;
            case 1:
                PlayAnim( WeaponShotgunAnim::RELOAD );
                if( Math.RandomLong( 0, 1 ) == 0 )
                    PlaySound( "hlclassic/weapons/reload1.wav", 1.0f, 85 + Math.RandomLong( 0, 0x1f ) );
                else
                    PlaySound( "hlclassic/weapons/reload3.wav", 1.0f, 85 + Math.RandomLong( 0, 0x1f ) );
                m_flTimeWeaponReload = g_Engine.time + 0.5f;
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
        FinishReload( self.m_iClip == gpWeaponShotgunConfig.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 );
    }

    private void PumpWeapon()
    {
        SetThink( null );
        PlaySound( "hlclassic/weapons/scock1.wav", 1.0f, 95 + Math.RandomLong( 0, 0x1f ) );
    }

    private bool FinishReload( bool fCondition )
    {
        if( self.m_fInReload )
        {
            if( m_fInReloadState != 0 )
            {
                if( fCondition )
                {
                    m_fInReloadState = 0;
                    self.m_fInReload = false;
                    PlayAnim( WeaponShotgunAnim::PUMP );
                    PlaySound( "hlclassic/weapons/scock1.wav", 1.0f, 95 + Math.RandomLong( 0, 0x1f ) );
                    self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.85f;
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
                PlayAnim( WeaponShotgunAnim::IDLE_DEEP );
                return 5.0f;
            case 1:
                PlayAnim( WeaponShotgunAnim::IDLE );
                return 2.22f;
            case 2:
            default:
                PlayAnim( WeaponShotgunAnim::IDLE4 );
                return 2.22f;
        }
    }
}
