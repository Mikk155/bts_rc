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

class CWeaponSniperRifleConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_sniperrifle";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_m40a1.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_m40a1.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_m40a1.mdl";
    }

    const string& get_animation_extension() override
    {
        return "sniper";
    }

    const string& get_primary_ammo() override
    {
        return "m40a1"; // wait, the original registered with "m40a1", ammo_762 is primary ammo entity
    }

    const string& get_primary_ammoentity() override
    {
        return "ammo_762";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponSniperRifleAnim::DRAW;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "ambience/rifle2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/sniper_zoom.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        ASWeaponConfig::Precache();
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        this.slot = 5;
        this.position = 5;
        this.weight = 10;
        this.deploy_time = 1.0;
        this.primary_maxammo = 10;
        this.primary_dropammo = 5;
        this.max_clip = 5;
        this.primary_damage = 120;
        this.primary_cooldown = 2.0;
        this.primary_trained_cooldown = 2.0;

        return ASWeaponConfig::Register( json );
    }
}

CWeaponSniperRifleConfig gpWeaponSniperRifleConfig;

enum WeaponSniperRifleAnim
{
    DRAW = 0,
    SLOWIDLE,
    FIRE,
    FIRELASTROUND,
    RELOAD1,
    RELOAD2,
    RELOAD3,
    SLOWIDLE2,
    HOLSTER
};

class weapon_bts_sniperrifle : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponSniperRifleConfig;
    }

    private float m_flReloadStart = 0;
    private bool m_bReloading = false;

    void Spawn() override
    {
        self.m_iDefaultAmmo = gpWeaponSniperRifleConfig.max_clip;
        BTS_FireWeapon::Spawn();
    }

    void Holster( int skiplocal = 0 )
    {
        self.m_fInReload = false;
        if( this.owner.m_iFOV != 0 )
        {
            ToggleZoom();
        }
        BaseClass.Holster( skiplocal );
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        switch( type )
        {
            case AttackType::Tertiary:
                return;
            case AttackType::Secondary:
            {
                PlaySound( "weapons/sniper_zoom.wav", 1.0f );
                ToggleZoom();
                self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
                return;
            }
        }

        if( self.m_iClip <= 0 )
        {
            this.PlayEmptySound();
            return;
        }

        bool isTrainedPersonal = util::IsTrainedPersonal( player );
        float cone = 0.01f;

        uint8 anim = ( self.m_iClip <= 1 ) ? WeaponSniperRifleAnim::FIRELASTROUND : WeaponSniperRifleAnim::FIRE;

        FireBullet( 1, cone, gpWeaponSniperRifleConfig.primary_damage, "ambience/rifle2.wav", anim, -1, TE_BOUNCE_SHELL, Math.RandomFloat( 0.9f, 1.0f ), 98 + Math.RandomLong( 0, 3 ), true, QUIET_GUN_VOLUME );

        player.pev.punchangle.x = isTrainedPersonal ? -2.0f : -18.0f;

        if( self.m_iClip <= 0 && player.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            player.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        self.m_flNextPrimaryAttack = g_Engine.time + 2.0f;
        self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;
    }

    void Reload()
    {
        if( self.m_iClip == gpWeaponSniperRifleConfig.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
        {
            return;
        }

        if( this.owner.m_iFOV != 0 )
        {
            ToggleZoom();
        }

        if( self.m_iClip > 0 )
        {
            if( self.DefaultReload( gpWeaponSniperRifleConfig.max_clip, WeaponSniperRifleAnim::RELOAD3, 2.324f, pev.body ) )
            {
                self.m_flNextPrimaryAttack = g_Engine.time + 2.324f;
            }
        }
        else if( self.DefaultReload( gpWeaponSniperRifleConfig.max_clip, WeaponSniperRifleAnim::RELOAD1, 2.324f, pev.body ) )
        {
            self.m_flNextPrimaryAttack = g_Engine.time + 4.102f;
            m_flReloadStart = g_Engine.time;
            m_bReloading = true;
        }
        else
        {
            m_bReloading = false;
        }

        self.m_flTimeWeaponIdle = g_Engine.time + 4.102f;
        BaseClass.Reload();
    }

    void ToggleZoom()
    {
        if( this.owner.m_iFOV == 0 )
        {
            this.owner.m_iFOV = 18;
        }
        else
        {
            this.owner.m_iFOV = 0;
        }
    }

    float Idle() override
    {
        self.ResetEmptySound();

        if( m_bReloading && g_Engine.time >= m_flReloadStart + 2.324f )
        {
            PlayAnim( WeaponSniperRifleAnim::RELOAD2 );
            m_bReloading = false;
        }

        if( self.m_iClip > 0 )
        {
            PlayAnim( WeaponSniperRifleAnim::SLOWIDLE );
        }
        else
        {
            PlayAnim( WeaponSniperRifleAnim::SLOWIDLE2 );
        }

        return 4.348f;
    }
}
