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

final class ASWeaponFlareGunConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_flaregun";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_flaregun.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_flaregun.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_flaregun.mdl";
    }

    const string& get_animation_extension() override
    {
        return "python";
    }

    const string& get_primary_ammo() override
    {
        return "Emergency Flare";
    }

    const string& get_primary_ammoentity() override
    {
        return "weapon_bts_flare";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponFlareGunAnim::DRAW;
    }

    void Precache() override
    {
        g_Game.PrecacheModel( "models/bts_rc/weapons/v_flaregun.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/p_flaregun.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/w_flaregun.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/w_flaregun_clip.mdl" );

        g_SoundSystem.PrecacheSound( "bts_rc/weapons/flaregun_shot1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/flaregun_reload1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/flaregun_reload2.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );

        ASWeaponConfig::Precache();
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapon configuration",
            "description": "Control flaregun configuration",
            "allOf":
            [
                "ASWeaponConfig"
            ],
            "properties":
            {
            }
        }""";
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        this.slot = 4;
        this.position = 13;
        this.weight = 15;
        this.deploy_time = 1.0;
        this.primary_maxammo = 6;
        this.primary_dropammo = 1;
        this.max_clip = 1;
        this.primary_damage = 35;

        return ASWeaponConfig::Register( json );
    }
}

ASWeaponFlareGunConfig gpWeaponFlareGunConfig;

enum WeaponFlareGunAnim
{
    IDLE1 = 0,
    FIDGET,
    SHOOT,
    RELOAD,
    HOLSTER,
    DRAW,
    IDLE2,
    IDLE3
};

class weapon_bts_flaregun : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponFlareGunConfig;
    }

    void Spawn() override
    {
        self.m_iDefaultAmmo = 3;
        BTS_FireWeapon::Spawn();
    }


    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        switch( type )
        {
            case AttackType::Tertiary:
            case AttackType::Secondary:
                return;
        }

        if( player.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;
            return;
        }

        player.m_iWeaponVolume = NORMAL_GUN_VOLUME;
        player.m_iWeaponFlash = BRIGHT_GUN_FLASH;

        player.m_iExtraSoundTypes = bits_SOUND_DANGER;
        player.m_flStopExtraSoundTime = g_Engine.time + 0.2f;

        --self.m_iClip;

        player.pev.effects |= EF_MUZZLEFLASH;
        pev.effects |= EF_MUZZLEFLASH;

        player.SetAnimation( PLAYER_ATTACK1 );

        Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );
        Vector offset = Vector( 8.0f, 4.0f, -2.0f );
        Vector vecSrc = player.GetGunPosition() + g_Engine.v_forward * offset.x + g_Engine.v_right * offset.y + g_Engine.v_up * offset.z;
        Vector vecVelocity = g_Engine.v_forward * 1500.0f;

        auto flare = FLARE::Shoot( player.pev, vecSrc, vecVelocity, 35.0f, 180.0f );
        if( flare !is null )
        {
            flare.pev.scale = 1.0f;
        }

        PlayAnim( WeaponFlareGunAnim::SHOOT );
        PlaySound( "bts_rc/weapons/flaregun_shot1.wav", Math.RandomFloat( 0.95f, 1.0f ), 93 + Math.RandomLong( 0, 0xf ), CHAN_WEAPON );

        player.pev.punchangle.x = Math.RandomFloat( -2.0f, -3.0f );

        if( self.m_iClip <= 0 && player.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && util::IsHEV( player ) )
            player.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;
        self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;
    }

    void Reload()
    {
        if( self.m_iClip == gpWeaponFlareGunConfig.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        if( self.m_flNextPrimaryAttack > g_Engine.time )
            return;

        BaseClass.Reload();
        self.DefaultReload( gpWeaponFlareGunConfig.max_clip, WeaponFlareGunAnim::RELOAD, 3.5f, pev.body );
        self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 3.5f;
        SetThink( ThinkFunction( this.FinishAnim ) );
        pev.nextthink = g_Engine.time + 3.5f;
    }

    float Idle() override
    {
        self.ResetEmptySound();
        this.owner.GetAutoaimVector( AUTOAIM_10DEGREES );

        float flRand = Math.RandomFloat( 0.0f, 1.0f );
        if( flRand <= 0.5f )
        {
            PlayAnim( WeaponFlareGunAnim::IDLE1 );
            return 2.33f;
        }
        else if( flRand <= 0.7f )
        {
            PlayAnim( WeaponFlareGunAnim::IDLE2 );
            return 2.0f;
        }
        else if( flRand <= 0.9f )
        {
            PlayAnim( WeaponFlareGunAnim::IDLE3 );
            return 2.93f;
        }
        else
        {
            PlayAnim( WeaponFlareGunAnim::FIDGET );
            return 5.66f;
        }
    }

    private void FinishAnim()
    {
        SetThink( null );

        if( Math.RandomLong( 0, 1 ) == 0 )
            PlaySound( "bts_rc/weapons/flaregun_reload1.wav", 1.0f, 85 + Math.RandomLong( 0, 0x1f ), CHAN_ITEM );
        else
            PlaySound( "bts_rc/weapons/flaregun_reload2.wav", 1.0f, 85 + Math.RandomLong( 0, 0x1f ), CHAN_ITEM );
    }
}
