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

#include "base/BTS_FireWeapon"

const int gpDefaultWeaponFlags = ( ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_NOAUTORELOAD );

class CGlobalWeaponConfig : IConfigContext
{
    CGlobalWeaponConfig()
    {
        ConfigContext::Register( this );
    }

    string GetName()
    {
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
