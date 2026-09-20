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

final class ASWeaponSniperRifleConfig : ASWeaponConfig
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

    const string& get_zoom_view_model()
    {
        return "models/mikk155/misc/v_scope_ch1.mdl";
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
        return WeaponSniperRifleAnim::Draw;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "ambience/rifle2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/sniper_zoom.wav" );
        g_Game.PrecacheModel( this.zoom_view_model );
        ASWeaponConfig::Precache();
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
    Holster
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
        DisableZoom();
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
        uint8 anim = ( self.m_iClip <= 1 ) ? WeaponSniperRifleAnim::FireLastRound : WeaponSniperRifleAnim::Fire;

        DisableZoom();

        bullet.Weapon( this )
            .Sound( "ambience/rifle2.wav", Math.RandomFloat( 0.9f, 1.0f ), 98 + Math.RandomLong( 0, 3 ), QUIET_GUN_VOLUME )
            .Shell( -1 )
            .Animation( anim )
        .Fire();

        player.pev.punchangle.x = isTrainedPersonal ? -2.0f : -18.0f;

        self.m_flNextPrimaryAttack = g_Engine.time + 2.0f;
        self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;
    }

    void ItemPostFrame()
    {
        BaseClass.ItemPostFrame();

        auto owner = this.owner;

        if( owner.m_iFOV == 0 )
            return;

        Vector vecSrc = owner.GetGunPosition();

        Math.MakeVectors( owner.pev.v_angle + owner.pev.punchangle );

        TraceResult tr;

        Vector vecEnd = vecSrc + g_Engine.v_forward * 2048;
        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, owner.edict(), tr );

        int[] color = { 255, 60, 60 };

        g_PlayerFuncs.ScreenFade( owner, Vector( color[0], color[1], color[2] ), 0.5f, 0.0f, 255.0f, FFADE_MODULATE | FFADE_IN );

        {
            NetworkMessage m( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, owner.edict() );
                m.WriteByte( TE_DLIGHT );
                m.WriteCoord( tr.vecEndPos.x );
                m.WriteCoord( tr.vecEndPos.y );
                m.WriteCoord( tr.vecEndPos.z );
                m.WriteByte( 128 );   // radius
                m.WriteByte( color[0] );
                m.WriteByte( color[1] );
                m.WriteByte( color[2] );
                m.WriteByte( 2 );
                m.WriteByte( 1 );
            m.End();
        }

        {
            NetworkMessage m( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, owner.edict() );
                m.WriteByte( TE_DLIGHT );
                m.WriteCoord( owner.pev.origin.x );
                m.WriteCoord( owner.pev.origin.y );
                m.WriteCoord( owner.pev.origin.z );
                m.WriteByte( 64 );   // radius
                m.WriteByte( color[0] );
                m.WriteByte( color[1] );
                m.WriteByte( color[2] );
                m.WriteByte( 2 );
                m.WriteByte( 1 );
            m.End();
        }
    }

    void Reload()
    {
        if( self.m_iClip == gpWeaponSniperRifleConfig.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
        {
            return;
        }

        DisableZoom();

        if( self.m_iClip > 0 )
        {
            if( self.DefaultReload( gpWeaponSniperRifleConfig.max_clip, WeaponSniperRifleAnim::Reload3, 2.324f, this.body ) )
            {
                self.m_flNextPrimaryAttack = g_Engine.time + 2.324f;
            }
        }
        else if( self.DefaultReload( gpWeaponSniperRifleConfig.max_clip, WeaponSniperRifleAnim::Reload1, 2.324f, this.body ) )
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

    void DisableZoom()
    {
        if( this.owner.m_iFOV != 0 )
        {
            ToggleZoom();
        }
    }

    void ToggleZoom()
    {
        PlaySound( "weapons/sniper_zoom.wav", 1.0f );

        if( this.owner.m_iFOV == 0 )
        {
            this.owner.m_iFOV = 18;
            this.owner.m_szAnimExtension = "bowscope";
            this.owner.pev.viewmodel = gpWeaponSniperRifleConfig.zoom_view_model;
        }
        else
        {
            this.owner.m_iFOV = 0;
            this.owner.pev.viewmodel = gpWeaponSniperRifleConfig.animation_extension;
            this.owner.pev.viewmodel = gpWeaponSniperRifleConfig.view_model;
        }
    }

    float Idle() override
    {
        if( this.owner.m_iFOV != 0 )
            return 0.1f;

        self.ResetEmptySound();

        if( m_bReloading && g_Engine.time >= m_flReloadStart + 2.324f )
        {
            PlayAnim( WeaponSniperRifleAnim::Reload2 );
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
