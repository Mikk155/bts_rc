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

final class ASWeaponFlamethrowerConfig : ASWeaponConfig
{
    int m_iFlameSprite;

    const string& GetName() const override
    {
        return "weapon_bts_flamethrower";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_flame.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_flame.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_flame.mdl";
    }

    const string& get_animation_extension() override
    {
        return "egon";
    }

    const string& get_primary_ammo() override
    {
        return "uranium";
    }

    const string& get_primary_ammoentity() override
    {
        return "ammo_gaussclip";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponFlamethrowerAnim::Draw;
    }

    void Precache() override
    {
        this.m_iFlameSprite = g_ModelFuncs.ModelIndex( "sprites/bts_rc/fthrow.spr" );

        ASWeaponConfig::Precache();
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        if( g_MapConfig.MapLoading )
        {
            g_CustomEntityFuncs.RegisterCustomEntity( "env_flame", "env_flame" );
        }

        return ASWeaponConfig::Register( json );
    }
}

ASWeaponFlamethrowerConfig gpWeaponFlamethrowerConfig;

enum WeaponFlamethrowerAnim
{
    Idle1 = 0,
    Fidget,
    FireOn,
    FireCycle,
    FireOff,
    Fire1,
    Fire2,
    Fire3,
    Fire4,
    Draw,
    Holster
};

const float FLAME_SPEED = 600.0f;
const Vector FLAME_OFFSET = Vector( 34.333031f, 12.009664f, -5.616758f );

class weapon_bts_flamethrower : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponFlamethrowerConfig;
    }

    void PrimaryAttack()
    {
        CBasePlayer@ player = this.owner;

        bool is_trained_personal = util::IsTrainedPersonal( player );
        this.SetCooldown( is_trained_personal, AttackType::Primary );

        if( player.pev.waterlevel == 3 )
        {
            self.PlayEmptySound();
            return;
        }

        int ammo1 = player.m_rgAmmo( self.m_iPrimaryAmmoType );

        if( ammo1 <= 0 )
        {
            self.PlayEmptySound();
            return;
        }

        --ammo1;
        player.m_rgAmmo( self.m_iPrimaryAmmoType, ammo1 );

        PlaySound( "bts_rc/weapons/flmfire2.wav", 1.0f, PITCH_NORM, CHAN_WEAPON );

        player.m_iWeaponVolume = LOUD_GUN_VOLUME;

        PlayAnim( WeaponFlamethrowerAnim::Fire1 + RandomUint(3), PLAYER_ANIM::PLAYER_ATTACK1 );

        weapons::Kickback( player, this.config.primary_kickback, is_trained_personal );

        Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );
        Vector vecSrc = player.GetGunPosition() + g_Engine.v_forward * FLAME_OFFSET.x
            + g_Engine.v_right * FLAME_OFFSET.y + g_Engine.v_up * FLAME_OFFSET.z;

        auto flame = env_flame::Factory( player );
        vecSrc.z -= 8;
        g_EntityFuncs.SetOrigin( flame.self, vecSrc );
        flame.self.pev.dmg = gpWeaponFlamethrowerConfig.primary_damage;
        flame.SetDuration( g_WeaponsConfig.fire_duration );
        flame.self.pev.velocity = g_Engine.v_forward * FLAME_SPEED;

        self.m_flTimeWeaponIdle = g_Engine.time + 0.5;
    }

    float Idle() override
    {
        self.ResetEmptySound();

        float flRand = Math.RandomFloat( 0.0f, 1.0f );

        if( flRand <= 0.5f )
        {
            PlayAnim( WeaponFlamethrowerAnim::Idle1 );
            return 4.2f;
        }

        PlayAnim( WeaponFlamethrowerAnim::Fidget );
        return 3.6f;
    }
}
