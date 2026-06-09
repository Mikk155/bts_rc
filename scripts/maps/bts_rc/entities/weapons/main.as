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
#include "config/ASMeleeWeaponConfig"
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

// Special
#include "Special/weapon_medkit"
#include "Special/weapon_bts_flashlight"

#include "base/BTS_FireWeapon"

const int gpDefaultWeaponFlags = ( ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_NOAUTORELOAD );

class CGlobalWeaponConfig : IConfigurable
{
    const string& get_Name() override {
        return "weapons";
    }

    bool melee_weapons_pull;
    float melee_weapons_pull_force;
    bool melee_weapons_push;
    float melee_weapons_push_force;
    bool blood_splash;
    bool sparks_splash;

    dictionary Interfaces;

    ASWeaponConfig@ GetContext( const string&in name )
    {
        return cast<ASWeaponConfig@>( this.Interfaces[ name ] );
    }

    const array<string>@ WeaponNames() {
        return @this.Interfaces.getKeys();
    }

    array<ItemMapping@> ItemMappingList(0);

    void MapInit()
    {
        Flashlight::Precache();

        g_ClassicMode.ForceItemRemap( true );
        g_ClassicMode.SetItemMappings( this.ItemMappingList );
        this.ItemMappingList.resize(0);
    }

    void Register( meta_api::json::v2::json@ json ) override
    {
        this.melee_weapons_pull = json.ValueOrDefault( "melee_weapons_pull", true );
        this.melee_weapons_pull_force = Math.max( 1, json.ValueOrDefault( "melee_weapons_pull_force", 300 ) );

        this.melee_weapons_push = json.ValueOrDefault( "melee_weapons_push", true );
        this.melee_weapons_push_force = Math.max( 1, json.ValueOrDefault( "melee_weapons_push_force", 200 ) );

        this.blood_splash = json.ValueOrDefault( "blood_splash", true );
        this.sparks_splash = json.ValueOrDefault( "sparks_splash", true );

        Flashlight::Register( json );
        gpWeaponFlashlight.secondary_maxammo = Flashlight::flashlight_capacity;
    }
}

CGlobalWeaponConfig g_WeaponsConfig;
