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
#include "base/shared/Accuracy"
#include "base/shared/bullet"
#include "base/shared/Deploy"
#include "base/shared/Hit"
#include "base/shared/Kickback"
#include "base/shared/SetCooldown"
#include "base/shared/TraceEffects"

// Base
#include "config/ASWeaponConfig"
#include "config/ASWeaponLaserConfig"
#include "config/ASWeaponLightConfig"

#include "base/BTS_FireWeapon"
#include "base/BTS_MeleeCharge"
#include "base/BTS_MeleeWeapon"
#include "base/BTS_Weapon"

// Melee
#include "Melee/axe"
#include "Melee/knife"
#include "Melee/pipe"
#include "Melee/poolstick"
#include "Melee/screwdriver"
#include "Melee/crowbar"
#include "Melee/pipewrench"
#include "Melee/broom"
#include "Melee/spanner"

// Special
#include "Special/medkit"
#include "Special/flashlight"

#include "Firearms/beretta"
#include "Firearms/eagle"
#include "Firearms/glock"
#include "Firearms/glock17f"
#include "Firearms/glock18"
#include "Firearms/glocksd"
#include "Firearms/sw637"
#include "Firearms/python"
#include "Firearms/mp5"
#include "Firearms/mp5gl"
#include "Firearms/uzi"
#include "Firearms/uzisd"
#include "Firearms/m4"
#include "Firearms/m4sd"
#include "Firearms/m16"
#include "Firearms/m16sd"
#include "Firearms/sniperrifle"
#include "Firearms/shotgun"
#include "Firearms/sbshotgun"
#include "Firearms/saw"
#include "Firearms/sawsd"
#include "Firearms/m79"
#include "Firearms/xbow"
#include "Firearms/handgrenade"
#include "Firearms/flamethrower"
#include "Firearms/flare"
#include "Firearms/flaregun"

const int gpDefaultWeaponFlags = ( ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_NOAUTORELOAD );

final class ASGlobalWeaponConfig : IConfigurable
{
    bool melee_weapons_pull;
    float melee_weapons_pull_force;
    bool infinite_ammo;
    bool melee_weapons_push;
    float melee_weapons_push_force;
    bool blood_splash;
    bool sparks_splash;
    bool m249_knockback;
    int flashlight_maxcarry;

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
                    "description": "Allow melee weapons to pull allied players."
                },
                "infinite_ammo":
                {
                    "type": "boolean",
                    "description": "Weapons has infinite ammo. made for testing firing."
                },
                "melee_weapons_pull_force":
                {
                    "type": "integer",
                    "minimum": 1,
                    "description": "Force of push if melee_weapons_pull is true"
                },
                "melee_weapons_push":
                {
                    "type": "boolean",
                    "description": "Allow melee weapons to push enemies."
                },
                "melee_weapons_push_force":
                {
                    "type": "integer",
                    "minimum": 1,
                    "description": "Force of push if melee_weapons_push is true"
                },
                "blood_splash":
                {
                    "type": "boolean",
                    "description": "Enable extra blood effects on hit."
                },
                "sparks_splash":
                {
                    "type": "boolean",
                    "description": "Enable spark effects when hitting armored enemies."
                },
                "m249_knockback":
                {
                    "type": "boolean",
                    "description": "Enable M249 SAW knockback recoil pushing the player backward."
                },
                "flashlight_maxcarry":
                {
                    "type": "integer",
                    "minimum": 0,
                    "description": "Quantity of ammo carry for flashlight weapons"
                },
                "item_remap":
                {
                    "type": "object",
                    "description": "Modify how items are replaced in the map",
                    "additionalProperties":
                    {
                        "type": "string",
                        "description": "Key names are item classnames to replace to the value names"
                    }
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
        this.flashlight_maxcarry = int( config[ "flashlight_maxcarry" ] );
        this.infinite_ammo = bool( config[ "infinite_ammo" ] );

        // ItemMapping stuff
        if( g_MapConfig.MapLoading )
        {
            auto@ remaps = config.ValueOrDefault( "item_remap" );
            const auto@ remaps_from = remaps.Keys;
            uint length = remaps.Length();

            for( uint ui = 0; ui < length; ui++ )
            {
                string classFrom = remaps_from[ui];
                string classTo = string( remaps[ classFrom ] );

                auto remap = ItemMapping( classFrom, classTo );
                g_WeaponsConfig.ItemMappingList.insertLast( @remap );

                if( g_Logger.info.active )
                {
                    g_Logger.info.print( "Adding ItemMapping \"{}\" -> \"{}\"", { classFrom, classTo } );
                }
            }

            g_ClassicMode.ForceItemRemap( true );
            g_ClassicMode.SetItemMappings( this.ItemMappingList );

            // Free object
            this.ItemMappingList.resize(0);

            RegisterCommand( "infinite_ammo", "<int 0/1 (optional)>", "Toggle infinite ammunition mode",
                @CommandCallback( function( CBasePlayer@ player, array<string>@ arguments )
                {
                    if( arguments !is null && arguments.length() > 0 )
                        g_WeaponsConfig.infinite_ammo = ( atoi( arguments[0] ) != 0 );
                    else
                        g_WeaponsConfig.infinite_ammo = !g_WeaponsConfig.infinite_ammo;
                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Infinite ammo has been " + ( g_WeaponsConfig.infinite_ammo ? "activated\n" : "deactivated\n" ) );
                } ), true, "weapon" );
        }

        return true;
    }
}

ASGlobalWeaponConfig g_WeaponsConfig;
