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

final class ASWeaponSBShotgunConfig : ASWeaponLightConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_sbshotgun";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_sbshotgun.mdl";
    }

    const string& get_player_model_flashlight() override
    {
        return "models/bts_rc/weapons/p_sbshotgun_cone.mdl";
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

    const uint8 get_animation_draw() override
    {
        return WeaponSBShotgunAnim::DRAW;
    }

    const int get_animation_holster() override
    {
        return WeaponSBShotgunAnim::HOLSTER;
    }

    const uint8 get_animation_toggle() override
    {
        return WeaponSBShotgunAnim::FLASH;
    }

    const uint8 get_hands_group() override
    {
        return 2;
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

    private float m_flTimeWeaponReload = 0.0f;
    private float m_flRestoreAfter = 0.0f;
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

        m_fInReloadState = 0;
        m_flRestoreAfter = 0.0f;
        self.m_fInReload = false;
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
            self.m_flNextPrimaryAttack = g_Engine.time + 0.12f;
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
                    PlaySound( "bts_rc/weapons/reload1.wav", 1.0f, 85 + Math.RandomLong( 0, 31 ) );
                else
                    PlaySound( "bts_rc/weapons/reload3.wav", 1.0f, 85 + Math.RandomLong( 0, 31 ) );
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
        PlaySound( "bts_rc/weapons/sbscock1.wav", 1.0f, 95 + Math.RandomLong( 0, 31 ) );
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
                    PlaySound( "bts_rc/weapons/sbscock1.wav", 1.0f, 95 + Math.RandomLong( 0, 31 ) );
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
