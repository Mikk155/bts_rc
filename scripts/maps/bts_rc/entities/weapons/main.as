/**   MIT License
*   
*   Copyright (c) 2025 Mikk155 https://github.com/Mikk155/bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies or substantial portions of the Software.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*   SOFTWARE.
*/

// Vanilla weapons override interface
#include "base/WeaponOverrider"

// Base
#include "config/ASWeaponConfig"
#include "base/BTS_Weapon"

// Melee
#include "config/ASMeleeWeaponConfig"
#include "base/BTS_MeleeWeapon"
#include "base/BTS_MeleeCharge"
#include "Melee/weapon_bts_axe"
#include "Melee/weapon_bts_knife"
#include "Melee/weapon_bts_pipe"
#include "Melee/weapon_bts_poolstick"
#include "Melee/weapon_bts_screwdriver"
#include "Melee/weapon_crowbar"

#include "base/BTS_FireWeapon"

const int gpDefaultWeaponFlags = ( ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_NOAUTORELOAD );

class CGlobalWeaponConfig : IConfigContext
{
    CGlobalWeaponConfig()
    {
        ConfigContext::Register( this );
    }

    const string& get_Name() override {
        return "weapons";
    }

    bool melee_weapons_pull;
    bool melee_weapons_push;
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
        g_ClassicMode.ForceItemRemap( true );
        g_ClassicMode.SetItemMappings( this.ItemMappingList );
        this.ItemMappingList.resize(0);
    }

    void Parse( dictionary@ json )
    {
        json.get( "melee_weapons_pull", melee_weapons_pull );
        json.get( "melee_weapons_push", melee_weapons_push );
        json.get( "blood_splash", blood_splash );
        json.get( "sparks_splash", sparks_splash );
    }
}

CGlobalWeaponConfig g_WeaponsConfig;
