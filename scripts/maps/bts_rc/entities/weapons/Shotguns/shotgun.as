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

    const uint8 get_hands_group() override
    {
        return 2;
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
        BTS_FireWeapon::Spawn();
    }

    void Holster( int skiplocal = 0 )
    {
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
                this.PlayEmptySound( AttackType::Secondary );
                self.m_flNextPrimaryAttack = g_Engine.time + 0.75f;
                return;
            }

            if( FinishReload( true ) )
                return;

            bullet.Weapon( this )
                .Shots( 16 )
                .AmmoCost( 2 )
                .Spread( gpWeaponShotgunConfig.secondary_spread )
                .Range( 2048.0f )
                .Sound( "bts_rc/weapons/spas12_dbarrel1.wav", Math.RandomFloat( 0.98f, 1.0f ), 85 + Math.RandomLong( 0, 31 ), LOUD_GUN_VOLUME )
                .Shell( -1 )
                .Animation( WeaponShotgunAnim::SHOOT2 )
            .Fire();

            bool isTrainedPersonal = util::IsTrainedPersonal( player );

            player.pev.punchangle.x = isTrainedPersonal ? -10.0f : -24.0f;

            Vector vecForward, vecRight, vecUp;
            g_EngineFuncs.AngleVectors( player.pev.v_angle, vecForward, vecRight, vecUp );
            Vector vecOrigin = player.GetGunPosition() + vecForward * 14.0f + vecRight * 6.0f - vecUp * 34.0f;
            Vector vecVelocity1 = player.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
            Vector vecVelocity2 = player.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
            g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity1, player.pev.v_angle.y, models::shotgunshell, TE_BOUNCE_SHOTSHELL );
            g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity2, player.pev.v_angle.y, models::shotgunshell, TE_BOUNCE_SHOTSHELL );

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
                StartSchedule( g_Scheduler.SetTimeout( @this, "PumpWeapon", 0.95f ) );
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

        bullet.Weapon( this )
            .Shots( 8 )
            .Range( 2048.0f )
            .Sound( "hlclassic/weapons/sbarrel1.wav", Math.RandomFloat( 0.95f, 1.0f ), 93 + Math.RandomLong( 0, 31 ), LOUD_GUN_VOLUME )
            .Shell( -1 )
            .Animation( WeaponShotgunAnim::SHOOT )
        .Fire();

        bool isTrainedPersonal = util::IsTrainedPersonal( player );

        player.pev.punchangle.x = isTrainedPersonal ? -5.0f : -11.0f;

        Vector vecForward, vecRight, vecUp;
        g_EngineFuncs.AngleVectors( player.pev.v_angle, vecForward, vecRight, vecUp );
        Vector vecOrigin = player.GetGunPosition() + vecForward * 14.0f + vecRight * 6.0f - vecUp * 34.0f;
        Vector vecVelocity = player.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
        g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, player.pev.v_angle.y, models::shotgunshell, TE_BOUNCE_SHOTSHELL );

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
            StartSchedule( g_Scheduler.SetTimeout( @this, "PumpWeapon", 0.5f ) );
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
                    PlaySound( "hlclassic/weapons/reload1.wav", 1.0f, 85 + Math.RandomLong( 0, 31 ) );
                else
                    PlaySound( "hlclassic/weapons/reload3.wav", 1.0f, 85 + Math.RandomLong( 0, 31 ) );
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

    void PumpWeapon()
    {
        PlaySound( "hlclassic/weapons/scock1.wav", 1.0f, 95 + Math.RandomLong( 0, 31 ) );
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
                    PlaySound( "hlclassic/weapons/scock1.wav", 1.0f, 95 + Math.RandomLong( 0, 31 ) );
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
