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

final class ASWeaponM79Config : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_m79";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_m79.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_m79.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_m79.mdl";
    }

    const string& get_animation_extension() override
    {
        return "bow";
    }

    const string& get_primary_ammo() override
    {
        return "ARgrenades";
    }

    const string& get_primary_ammoentity() override
    {
        return "ammo_ARgrenades";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponM79Anim::Draw;
    }
}

ASWeaponM79Config gpWeaponM79Config;

enum WeaponM79Anim
{
    Idle = 0,
    Shoot,
    Reload,
    Draw,
    Holster
};

class weapon_bts_m79 : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponM79Config;
    }

    void PrimaryAttack()
    {
        CBasePlayer@ player = this.owner;

        this.SetCooldown( util::IsTrainedPersonal( this.owner ), AttackType::Primary );

        if( player.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
        {
            self.PlayEmptySound();
            return;
        }

        player.m_iWeaponVolume = NORMAL_GUN_VOLUME;
        player.m_iWeaponFlash = BRIGHT_GUN_FLASH;

        player.m_iExtraSoundTypes = bits_SOUND_DANGER;
        player.m_flStopExtraSoundTime = g_Engine.time + 0.2f;

        --self.m_iClip;

        player.pev.effects |= EF_MUZZLEFLASH;
        pev.effects |= EF_MUZZLEFLASH;

        Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );
        Vector offset = Vector( 8.0f, 4.0f, -2.0f );
        Vector vecSrc = player.GetGunPosition() + g_Engine.v_forward * offset.x + g_Engine.v_right * offset.y + g_Engine.v_up * offset.z;
        Vector vecVelocity = g_Engine.v_forward * 1200.0f;

        CGrenade@ pGrenade = g_EntityFuncs.ShootContact( player.pev, vecSrc, vecVelocity );

        if( pGrenade !is null )
        {
            g_EntityFuncs.SetModel( pGrenade, "models/hlclassic/grenade.mdl" );
            pGrenade.pev.dmg = gpWeaponM79Config.primary_damage;
        }

        PlayAnim( WeaponM79Anim::Shoot, PLAYER_ANIM::PLAYER_ATTACK1 );
        PlaySound( "bts_rc/weapons/m79_fire.wav", Math.RandomFloat( 0.95f, 1.0f ), 93 + Math.RandomLong( 0, 15 ) );

        CheckDepletedAmmo( self.m_iPrimaryAmmoType );

        self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;
    }

    float Idle() override
    {
        self.ResetEmptySound();
        PlayAnim( WeaponM79Anim::Idle );
        return Math.RandomFloat( 5.0f, 6.0f );
    }
}
