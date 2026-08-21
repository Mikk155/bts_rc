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

final class ASWeaponM16SDConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_m16sd";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_m16sd.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_m16sd.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_m16a2sd.mdl";
    }

    const string& get_animation_extension() override
    {
        return "m16";
    }

    const string& get_primary_ammo() override
    {
        return "556";
    }

    const string& get_primary_ammoentity() override
    {
        return "ammo_bts_m16sd";
    }

    const string& get_secondary_ammo() override
    {
        return "ARgrenades";
    }

    const string& get_secondary_ammoentity() override
    {
        return "ammo_bts_m16sd_grenade";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponM16Anim::DRAW;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "weapons/glauncher.wav" );
        g_SoundSystem.PrecacheSound( "weapons/glauncher2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/gl_reload.wav" );
        ASWeaponConfig::Precache();
    }

    const uint8 get_hands_group() override
    {
        return 2;
    }
}

ASWeaponM16SDConfig gpWeaponM16SDConfig;

class weapon_bts_m16sd : weapon_bts_m16_base
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponM16SDConfig;
    }

    bool IsSilenced() override
    {
        return true;
    }
}
