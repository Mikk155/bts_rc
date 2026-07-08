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

final class ASWeaponPythonConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_python";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_357.mdl";
    }

    const string& get_world_model() override
    {
        return "models/hlclassic/w_357.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_357.mdl";
    }

    const string& get_animation_extension() override
    {
        return "python";
    }

    const string& get_primary_ammo() override
    {
        return "357";
    }

    const string& get_primary_ammoentity() override
    {
        return "ammo_357";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponPythonAnim::Draw;
    }

    const uint8 get_hands_group() override
    {
        return 3;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_shot1.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_shot2.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        ASWeaponConfig::Precache();
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapon configuration",
            "description": "Control python configuration",
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
        this.slot = 1;
        this.position = 8;
        this.weight = 10;
        this.deploy_time = 1.0;
        this.primary_maxammo = 18;
        this.primary_dropammo = 6;
        this.max_clip = 6;
        this.primary_damage = 66;
        this.primary_cooldown = 0.75;
        this.primary_trained_cooldown = 0.75;

        return ASWeaponConfig::Register( json );
    }
}

ASWeaponPythonConfig gpWeaponPythonConfig;

enum WeaponPythonAnim
{
    Idle1 = 0,
    Fidget,
    Shoot,
    Reload,
    Holster,
    Draw,
    Idle2,
    Idle3
};

class weapon_bts_python : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponPythonConfig;
    }

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 3, gpWeaponPythonConfig.max_clip );
        BTS_FireWeapon::Spawn();
    }

    float Idle() override
    {
        self.ResetEmptySound();

        if( self.m_iClip <= 0 )
        {
            return 2.0f;
        }

        const float flRand = Math.RandomFloat( 0.0f, 1.0f );
        if( flRand <= 0.5f )
        {
            PlayAnim( WeaponPythonAnim::Idle1 );
            return 2.33f;
        }
        else if( flRand <= 0.7f )
        {
            PlayAnim( WeaponPythonAnim::Idle2 );
            return 2.0f;
        }
        else if( flRand <= 0.9f )
        {
            PlayAnim( WeaponPythonAnim::Idle3 );
            return 2.93f;
        }
        else
        {
            PlayAnim( WeaponPythonAnim::Fidget );
            return 5.66f;
        }
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        switch( type )
        {
            case AttackType::Tertiary:
            case AttackType::Secondary:
                return;
        }

        if( self.m_iClip <= 0 )
        {
            this.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
            return;
        }

        float cone = Accuracy( 0.01f, 0.1f, 0.01f, 0.05f );
        string szSound = ( Math.RandomLong( 0, 1 ) == 0 ) ? "hlclassic/weapons/357_shot1.wav" : "hlclassic/weapons/357_shot2.wav";

        FireBullet( 1, cone, gpWeaponPythonConfig.primary_damage, szSound, WeaponPythonAnim::Shoot, -1, TE_BOUNCE_SHELL, Math.RandomFloat( 0.8f, 0.9f ), 98 + Math.RandomLong( 0, 3 ), true, LOUD_GUN_VOLUME, BRIGHT_GUN_FLASH );

        player.pev.punchangle.x = util::IsTrainedPersonal( player ) ? -10.0f : -16.0f;

        if( self.m_iClip <= 0 && player.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && util::IsHEV( player ) )
        {
            player.SetSuitUpdate( "!HEV_AMO0", false, 0 );
        }

        self.m_flNextPrimaryAttack = g_Engine.time + 0.75f;
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
    }

    void Reload()
    {
        if( self.m_iClip == gpWeaponPythonConfig.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
        {
            return;
        }

        self.DefaultReload( gpWeaponPythonConfig.max_clip, WeaponPythonAnim::Reload, 2.0f, pev.body );
        self.m_flTimeWeaponIdle = g_Engine.time + 3.0f;
        BaseClass.Reload();
    }
}
