#include "shared/deploy"
#include "shared/pull_target"
#include "shared/trace_effect"

#include "base/CBaseMelee"
#include "base/CBaseWeapon"

#include "proj/flare"
#include "proj/m79_rocket"

#include "weapon_bts_beretta"
#include "weapon_bts_crowbar"
#include "weapon_bts_eagle"
#include "weapon_bts_flamethrower"
#include "weapon_bts_flare"
#include "weapon_bts_flaregun"
#include "weapon_bts_flashlight"
#include "weapon_bts_glock"
#include "weapon_bts_glock17f"
#include "weapon_bts_glock18"
#include "weapon_bts_glocksd"
#include "weapon_bts_handgrenade"
#include "weapon_bts_knife"
#include "weapon_bts_m16"
#include "weapon_bts_m16sd"
#include "weapon_bts_m4"
#include "weapon_bts_m4sd"
#include "weapon_bts_m79"
#include "weapon_bts_medkit"
#include "weapon_bts_mp5"
#include "weapon_bts_mp5gl"
#include "weapon_bts_pipe"
#include "weapon_bts_pipewrench"
#include "weapon_bts_python"
#include "weapon_bts_saw"
#include "weapon_bts_sawsd"
#include "weapon_bts_sbshotgun"
#include "weapon_bts_shotgun"
#include "weapon_bts_sniperrifle"
#include "weapon_bts_sw637"
#include "weapon_bts_uzi"
#include "weapon_bts_uzisd"
#include "weapon_bts_xbow"


namespace weapons
{
    const int gpDefaultFlags = ( ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_NOAUTORELOAD );

    void RegisterWeapon(
        const string &in entityName,
        const string &in primaryName = String::EMPTY_STRING,
        const string &in secondaryName = String::EMPTY_STRING,
        const string &in primaryObject = String::EMPTY_STRING,
        const string &in secondaryObject = String::EMPTY_STRING,
        const string &in remapEntity = String::EMPTY_STRING
    )
    {
        if( !remapEntity.IsEmpty() )
        {
            auto remap = ItemMapping( remapEntity, entityName );
            gpItemMapping.insertLast( @remap );
        }

        string objectName;
        snprintf( objectName, "weapons::%1::%1", entityName, entityName );
        g_CustomEntityFuncs.RegisterCustomEntity( objectName, entityName );

        if( secondaryObject != String::EMPTY_STRING && !g_CustomEntityFuncs.IsCustomEntity( secondaryObject ) )
        {
            string secondaryAmmoClass;
            snprintf( secondaryAmmoClass, "weapons::%1::%1", entityName, secondaryObject );
            g_CustomEntityFuncs.RegisterCustomEntity( secondaryAmmoClass, secondaryObject );
        }

        if( secondaryObject != String::EMPTY_STRING && !g_CustomEntityFuncs.IsCustomEntity( primaryObject ) )
        {
            string secondaryAmmoClass;
            snprintf( secondaryAmmoClass, "weapons::%1::%1", entityName, primaryObject );
            g_CustomEntityFuncs.RegisterCustomEntity( secondaryAmmoClass, primaryObject );
        }

        g_ItemRegistry.RegisterWeapon( entityName, "bts_rc/weapons", primaryObject, secondaryObject, primaryName, secondaryName );

        gpWeaponNames.insertLast( entityName );
    }

    void Registerfake( dictionary@ data )
    {
        RegisterWeapon( "weapon_bts_beretta", "9mm", "bts:battery", "ammo_bts_beretta", "ammo_bts_beretta_battery" );

        // Projectiles
        g_CustomEntityFuncs.RegisterCustomEntity( "M79_ROCKET::CM79Rocket", "m79_rocket" );
        g_CustomEntityFuncs.RegisterCustomEntity( "FLARE::CFlare", "flare" );
        g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLAMETHROWER::flame_proj", "flame_proj" );
        // Weapon Entities
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_pipewrench::weapon_bts_pipewrench", "weapon_bts_pipewrench" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_crowbar::weapon_bts_crowbar", "weapon_bts_crowbar" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_eagle::weapon_bts_eagle", "weapon_bts_eagle" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_flare::weapon_bts_flare", "weapon_bts_flare" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_flaregun::weapon_bts_flaregun", "weapon_bts_flaregun" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_flashlight::weapon_bts_flashlight", "weapon_bts_flashlight" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_sw637::weapon_bts_sw637", "weapon_bts_sw637" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_glock::weapon_bts_glock", "weapon_bts_glock" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_glock17f::weapon_bts_glock17f", "weapon_bts_glock17f" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_glock18::weapon_bts_glock18", "weapon_bts_glock18" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_glocksd::weapon_bts_glocksd", "weapon_bts_glocksd" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_knife::weapon_bts_knife", "weapon_bts_knife" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_handgrenade::weapon_bts_handgrenade", "weapon_bts_handgrenade" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_m4::weapon_bts_m4", "weapon_bts_m4" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_m4sd::weapon_bts_m4sd", "weapon_bts_m4sd" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_m16::weapon_bts_m16", "weapon_bts_m16" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_m16sd::weapon_bts_m16sd", "weapon_bts_m16sd" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_m79::weapon_bts_m79", "weapon_bts_m79" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_medkit::weapon_bts_medkit", "weapon_bts_medkit" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_mp5gl::weapon_bts_mp5gl", "weapon_bts_mp5gl" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_mp5::weapon_bts_mp5", "weapon_bts_mp5" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_pipe::weapon_bts_pipe", "weapon_bts_pipe" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_python::weapon_bts_python", "weapon_bts_python" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_shotgun::weapon_bts_shotgun", "weapon_bts_shotgun" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_uzi::weapon_bts_uzi", "weapon_bts_uzi" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_uzisd::weapon_bts_uzisd", "weapon_bts_uzisd" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_saw::weapon_bts_saw", "weapon_bts_saw" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_sawsd::weapon_bts_sawsd", "weapon_bts_sawsd" );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_sbshotgun::weapon_bts_sbshotgun", "weapon_bts_sbshotgun" );
        // Ammo
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_eagle", "ammo_bts_eagle" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_eagle_battery", "ammo_bts_eagle_battery" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_eagle", "ammo_bts_dreagle" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_flarebox", "ammo_bts_flarebox" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_battery", "ammo_bts_battery" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_sw637", "ammo_bts_sw637" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_glock", "ammo_bts_glock" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_glock17f", "ammo_bts_glock17f" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_glock17f_battery", "ammo_bts_glock17f_battery" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_glock18", "ammo_bts_glock18" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_glocksd", "ammo_bts_glocksd" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_glocksd_battery", "ammo_bts_glocksd_battery" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_glocksd", "ammo_bts_dglocksd" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_m4", "ammo_bts_m4" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_dummy", "ammo_bts_dummy" );
        //  g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m4", "ammo_bts_556mag"); // uncomment this to have infinite 556 ammo
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_m4sd", "ammo_bts_m4sd" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_m16", "ammo_bts_m16" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_m16sd", "ammo_bts_m16sd" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_m16", "ammo_bts_556round" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_m16_grenade", "ammo_bts_m16_grenade" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_m16sd_grenade", "ammo_bts_m16sd_grenade" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_m79", "ammo_bts_m79" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_mp5", "ammo_bts_mp5" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_mp5", "ammo_bts_dmp5" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_mp5gl", "ammo_bts_mp5gl" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_mp5gl", "ammo_bts_9mmbox" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_mp5gl_grenade", "ammo_bts_mp5gl_grenade" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_python", "ammo_bts_python" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_python", "ammo_bts_357cyl" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_saw", "ammo_bts_saw" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_sawsd", "ammo_bts_sawsd" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_saw", "ammo_bts_dsaw" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_sbshotgun", "ammo_bts_sbshotgun" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_sbshotgun_battery", "ammo_bts_sbshotgun_battery" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_shotgun", "ammo_bts_shotgun" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_shotgun", "ammo_bts_shotshell" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_uzi", "ammo_bts_uzi" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_uzisd", "ammo_bts_uzisd" );

        g_ItemRegistry.RegisterWeapon( "weapon_bts_pipewrench", "bts_rc/weapons" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_crowbar", "bts_rc/weapons" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_eagle", "bts_rc/weapons", "357", "bts:battery", "ammo_bts_eagle", "ammo_bts_eagle_battery" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_flare", "bts_rc/weapons", "weapon_bts_flare", "", "weapon_bts_flare", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_flaregun", "bts_rc/weapons", "bts:flare", "", "ammo_bts_flarebox", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_flashlight", "bts_rc/weapons", "bts:battery", "", "ammo_bts_battery", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_sw637", "bts_rc/weapons", "38", "", "ammo_bts_sw637", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_glock", "bts_rc/weapons", "9mm", "", "ammo_bts_glock", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_glock17f", "bts_rc/weapons", "9mm", "bts:battery", "ammo_bts_glock17f", "ammo_bts_glock17f_battery" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_glock18", "bts_rc/weapons", "9mm", "", "ammo_bts_glock18", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_glocksd", "bts_rc/weapons", "9mm", "bts:battery", "ammo_bts_glocksd", "ammo_bts_glocksd_battery" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_knife", "bts_rc/weapons" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_handgrenade", "bts_rc/weapons", "Hand Grenade", "", "weapon_bts_handgrenade", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_m4", "bts_rc/weapons", "556", "", "ammo_bts_m4", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_m4sd", "bts_rc/weapons", "556", "", "ammo_bts_m4sd", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_m16", "bts_rc/weapons", "556", "ARgrenades", "ammo_bts_m16", "ammo_bts_m16_grenade" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_m16sd", "bts_rc/weapons", "556", "ARgrenades", "ammo_bts_m16sd", "ammo_bts_m16sd_grenade" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_m79", "bts_rc/weapons", "ARgrenades", "", "ammo_bts_m79", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_medkit", "bts_rc/weapons", "health", "", "ammo_medkit" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_mp5gl", "bts_rc/weapons", "9mm", "ARgrenades", "ammo_bts_mp5gl", "ammo_bts_mp5gl_grenade" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_mp5", "bts_rc/weapons", "9mm", "", "ammo_bts_mp5", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_pipe", "bts_rc/weapons" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_python", "bts_rc/weapons", "357", "", "ammo_bts_python", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_shotgun", "bts_rc/weapons", "buckshot", "", "ammo_bts_shotgun", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_uzi", "bts_rc/weapons", "9mm", "", "ammo_bts_uzi", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_uzisd", "bts_rc/weapons", "9mm", "", "ammo_bts_uzisd", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_saw", "bts_rc/weapons", "556", "", "ammo_bts_saw", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_sawsd", "bts_rc/weapons", "556", "", "ammo_bts_sawsd", "" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_sbshotgun", "bts_rc/weapons", "buckshot", "bts:battery", "ammo_bts_sbshotgun", "ammo_bts_sbshotgun_battery" );
        BTS_XBOW::Register();
        weapon_bts_sniperrifle::Register();
        BTS_FLAMETHROWER::Register();
        weapon_bts_sw637::Register();
    }
}
