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

// Shared functions
#include "base/shared/Deploy"
#include "base/shared/Hit"
#include "base/shared/SetCooldown"
#include "base/shared/TraceEffects"

// Base
#include "config/ASWeaponConfig"
#include "config/Flashlight"
#include "base/BTS_Weapon"
#include "base/BTS_MeleeWeapon"
#include "base/BTS_MeleeCharge"

// Melee
#include "Melee/weapon_bts_axe"
#include "Melee/weapon_bts_knife"
#include "Melee/weapon_bts_pipe"
#include "Melee/weapon_bts_poolstick"
#include "Melee/weapon_bts_screwdriver"
#include "Melee/weapon_crowbar"
#include "Melee/weapon_bts_pipewrench"
#include "Melee/weapon_bts_broom"
#include "Melee/weapon_bts_spanner"

// Special
#include "Special/weapon_medkit"
#include "Special/weapon_bts_flashlight"

#include "base/BTS_FireWeapon"
#include "Firearms/weapon_bts_beretta"
#include "Firearms/weapon_bts_eagle"
#include "Firearms/weapon_bts_glock"
#include "Firearms/weapon_bts_glock17f"
#include "Firearms/weapon_bts_glock18"
#include "Firearms/weapon_bts_glocksd"
#include "Firearms/weapon_bts_sw637"
#include "Firearms/weapon_bts_python"
#include "Firearms/weapon_bts_mp5"
#include "Firearms/weapon_bts_mp5gl"
#include "Firearms/weapon_bts_uzi"
#include "Firearms/weapon_bts_uzisd"
#include "Firearms/weapon_bts_m4"
#include "Firearms/weapon_bts_m4sd"
#include "Firearms/weapon_bts_m16"
#include "Firearms/weapon_bts_m16sd"
#include "Firearms/weapon_bts_sniperrifle"
#include "Firearms/weapon_bts_shotgun"
#include "Firearms/weapon_bts_sbshotgun"
#include "Firearms/weapon_bts_saw"
#include "Firearms/weapon_bts_sawsd"
#include "Firearms/weapon_bts_m79"
#include "Firearms/weapon_bts_xbow"
#include "Firearms/weapon_bts_handgrenade"
#include "Firearms/weapon_bts_flamethrower"
#include "Firearms/weapon_bts_flare"
#include "Firearms/weapon_bts_flaregun"

const int gpDefaultWeaponFlags = ( ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_NOAUTORELOAD );

final class ASGlobalWeaponConfig : IConfigurable
{
    bool melee_weapons_pull;
    float melee_weapons_pull_force;
    bool melee_weapons_push;
    float melee_weapons_push_force;
    bool blood_splash;
    bool sparks_splash;
    bool m249_knockback;

    const string& GetName() const override
    {
        return "weapons";
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapons config",
            "description": "Global weapon-related gameplay modifiers.",
            "properties":
            {
                "melee_weapons_pull":
                {
                    "type": "boolean",
                    "default": true,
                    "description": "Allow melee weapons to pull allied players."
                },
                "melee_weapons_pull_force":
                {
                    "type": "integer",
                    "minimum": 1,
                    "default": 300,
                    "description": "Force of push if melee_weapons_pull is true"
                },
                "melee_weapons_push":
                {
                    "type": "boolean",
                    "default": true,
                    "description": "Allow melee weapons to push enemies."
                },
                "melee_weapons_push_force":
                {
                    "type": "integer",
                    "minimum": 1,
                    "default": 200,
                    "description": "Force of push if melee_weapons_push is true"
                },
                "blood_splash":
                {
                    "type": "boolean",
                    "default": true,
                    "description": "Enable extra blood effects on hit."
                },
                "sparks_splash":
                {
                    "type": "boolean",
                    "default": true,
                    "description": "Enable spark effects when hitting armored enemies."
                },
                "m249_knockback":
                {
                    "type": "boolean",
                    "default": true,
                    "description": "Enable M249 SAW knockback recoil pushing the player backward."
                },
                "flashlight_drain":
                {
                    "type": "number",
                    "default": 0.8,
                    "minimum": 0.1,
                    "description": "flashlight drain time"
                },
                "flashlight_capacity":
                {
                    "type": "integer",
                    "default": 10,
                    "minimum": 0,
                    "description": "Quantity of ammo carry for flashlight weapons"
                },
                "flashlight_ammount":
                {
                    "type": "integer",
                    "default": 100,
                    "minimum": 10,
                    "description": "Quantity of ammo carry for flashlight weapons"
                }
            }
        }""";
    }

    dictionary Interfaces;

    ASWeaponConfig@ GetContext( const string&in name )
    {
        return cast<ASWeaponConfig@>( this.Interfaces[ name ] );
    }

    const array<string>@ WeaponNames()
    {
        return @this.Interfaces.getKeys();
    }

    array<ItemMapping@> ItemMappingList(0);

    bool Register( meta_api::json::v2::json@ config ) override
    {
        this.melee_weapons_pull = bool( config[ "melee_weapons_pull" ] );
        this.melee_weapons_pull_force = int( config[ "melee_weapons_pull_force" ] );
        this.melee_weapons_push = bool( config[ "melee_weapons_push" ] );
        this.melee_weapons_push_force = int( config[ "melee_weapons_push_force" ] );
        this.sparks_splash = bool( config[ "sparks_splash" ] );
        this.blood_splash = bool( config[ "blood_splash" ] );
        this.m249_knockback = bool( config[ "m249_knockback" ] );

        Flashlight::Precache();

        Flashlight::flashlight_drain = float( config[ "flashlight_drain" ] );
        Flashlight::flashlight_capacity = int( config[ "flashlight_capacity" ] );
        Flashlight::flashlight_ammount = int( config[ "flashlight_ammount" ] );

        g_ClassicMode.ForceItemRemap( true );
        g_ClassicMode.SetItemMappings( this.ItemMappingList );

        this.ItemMappingList.resize(0);

        gpWeaponFlashlight.secondary_maxammo = Flashlight::flashlight_capacity;
        return true;
    }
}

ASGlobalWeaponConfig g_WeaponsConfig;
