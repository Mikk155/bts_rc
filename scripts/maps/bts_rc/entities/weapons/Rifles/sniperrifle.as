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

final class ASWeaponSniperRifleConfig : ASWeaponScopeLightConfig
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

    const string& get_zoom_view_model() override
    {
        return "models/mikk155/misc/v_scope_ch1.mdl";
    }

    const string& get_animation_extension() override
    {
        return "sniper";
    }

    const string& get_zoom_animation_extension() override
    {
        return "sniperscope";
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
        return WeaponSniperRifleAnim::Draw;
    }

    const uint8 get_animation_zoom() override
    {
        return WeaponSniperRifleAnim::IronIn;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "ambience/rifle2.wav" );
        ASWeaponScopeLightConfig::Precache();
    }
}

ASWeaponSniperRifleConfig gpWeaponSniperRifleConfig;

enum WeaponSniperRifleAnim
{
    Draw = 0,
    SlowIdle,
    Fire,
    FireLastRound,
    Reload1,
    Reload2,
    Reload3,
    SlowIdle2,
    Holster,
    IronIn,
    IronOut,
    IronOutEmpty,
    IronOutReload,
    IronOutReloadEmpty
};

class weapon_bts_sniperrifle : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponSniperRifleConfig;
    }

    private float m_flReloadStart = 0;
    private bool m_bReloading = false;

    void Holster( int skiplocal = 0 )
    {
        self.m_fInReload = false;
        gpWeaponSniperRifleConfig.DisableZoom( this.owner, self );
        BaseClass.Holster( skiplocal );
    }

    void PrimaryAttack() override
    {
        if( self.m_iClip <= 0 )
        {
            this.PlayEmptySound();
            return;
        }

        CBasePlayer@ player = this.owner;

        gpWeaponSniperRifleConfig.DisableZoom( player, self );

        bullet.Weapon( this )
            .Sound( "ambience/rifle2.wav", Math.RandomFloat( 0.9f, 1.0f ), 98 + Math.RandomLong( 0, 3 ), QUIET_GUN_VOLUME )
            .Shell( -1 )
            .Animation( ( self.m_iClip <= 1 ) ? WeaponSniperRifleAnim::FireLastRound : WeaponSniperRifleAnim::Fire )
        .Fire();
    }

    void Reload()
    {
        if( self.m_iClip == gpWeaponSniperRifleConfig.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
        {
            return;
        }

        if( self.m_iClip > 0 )
        {
            if( self.DefaultReload( gpWeaponSniperRifleConfig.max_clip, WeaponSniperRifleAnim::Reload3, 2.324f, this.body ) )
            {
                if( gpWeaponSniperRifleConfig.DisableZoom( this.owner, self ) )
                {
                    PlayAnim( WeaponSniperRifleAnim::IronOutReload, PLAYER_ANIM::PLAYER_RELOAD );
                }
                self.m_flNextPrimaryAttack = g_Engine.time + 2.324f;
            }
        }
        else if( self.DefaultReload( gpWeaponSniperRifleConfig.max_clip, WeaponSniperRifleAnim::Reload1, 2.324f, this.body ) )
        {
            if( gpWeaponSniperRifleConfig.DisableZoom( this.owner, self ) )
            {
                PlayAnim( WeaponSniperRifleAnim::IronOutReloadEmpty, PLAYER_ANIM::PLAYER_RELOAD );
            }
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

    float Idle() override
    {
        if( this.owner.m_iFOV != 0 )
            return 0.1f;

        self.ResetEmptySound();

        if( m_bReloading && g_Engine.time >= m_flReloadStart + 2.324f )
        {
            PlayAnim( WeaponSniperRifleAnim::Reload2, PLAYER_ANIM::PLAYER_RELOAD );
            m_bReloading = false;
        }

        if( self.m_iClip > 0 )
        {
            PlayAnim( WeaponSniperRifleAnim::SlowIdle );
        }
        else
        {
            PlayAnim( WeaponSniperRifleAnim::SlowIdle2 );
        }

        return 4.348f;
    }
}
