//Weapons
#include "weapons/weapon_bts_axe"
#include "weapons/weapon_bts_beretta"
#include "weapons/weapon_bts_crowbar"
#if DISCARDED
#include "weapons/weapon_bts_dartgun"
#endif
#include "weapons/weapon_bts_eagle"
#include "weapons/weapon_bts_flare"
#include "weapons/weapon_bts_flaregun"
#include "weapons/weapon_bts_flashlight"
#include "weapons/weapon_bts_glock"
#include "weapons/weapon_bts_glock17f"
#include "weapons/weapon_bts_glock18"
#include "weapons/weapon_bts_glocksd"
#include "weapons/weapon_bts_handgrenade"
#include "weapons/weapon_bts_knife"
#include "weapons/weapon_bts_m4"
#include "weapons/weapon_bts_m4sd"
#include "weapons/weapon_bts_m16"
#include "weapons/weapon_bts_m79"
#include "weapons/weapon_bts_medkit"
#include "weapons/weapon_bts_mp5"
#include "weapons/weapon_bts_mp5gl"
#include "weapons/weapon_bts_pipe"
#include "weapons/weapon_bts_poolstick"
#include "weapons/weapon_bts_python"
#include "weapons/weapon_bts_saw"
#include "weapons/weapon_bts_sbshotgun"
#include "weapons/weapon_bts_screwdriver"
#include "weapons/weapon_bts_shotgun"
#include "weapons/weapon_bts_uzi"

//Item( s )
#include "items/item_bts_sprayaid"
#include "items/item_bts_hevbattery"
#include "items/item_bts_helmet"

array<ItemMapping@> g_AmmoReplacement =
{
    ItemMapping( "weapon_9mmhandgun", HL_GLOCKSD::GetDAmmoName() ),
    ItemMapping( "weapon_glock", HL_GLOCKSD::GetDAmmoName() ),
    ItemMapping( "weapon_357", "ammo_357" ),
    ItemMapping( "weapon_eagle", BTS_DEAGLE::GetDAmmoName() ),
    ItemMapping( "weapon_9mmAR", HL_MP5::GetDAmmoName() ),
    ItemMapping( "weapon_mp5", HL_MP5::GetDAmmoName() ),
    ItemMapping( "weapon_shotgun", HL_SHOTGUN::GetDAmmoName() ),
    ItemMapping( "weapon_m16", "info_null" ),
    ItemMapping( "weapon_saw", CM249::GetDAmmoName() ),
    ItemMapping( "weapon_m249", CM249::GetDAmmoName() ),
    ItemMapping( "weapon_minigun", CM249::GetDAmmoName() ),
    ItemMapping( "weapon_medkit", BTS_MEDKIT::GetName() )
};

void RegisterBTSRCWeapons()
{
    //Register Weapons
    HL_CROWBAR::Register(); //HL Crowbar Register
    HL_GLOCK::Register(); //HL Glock Register
    HL_BERETTA::Register(); //HL Beretta M9 Register
    BTS_M16A3::Register(); //M16A3 w/ M203 ( 556 Caliber ) Register
    HL_MP5GL::Register(); //HL MP5 With GL Register
    HL_MP5::Register(); //HL MP5 w/o GL Register
    CPython::Register(); //HL 357 Python Register
    HL_SHOTGUN::Register(); //HL SPAS-12 Shotgun Register
    BTS_DEAGLE::Register(); //Desert Eagle w/ Torchlight attached
    HL_PIPE::Register(); //Visitor Pipe Register
    HL_SCREWDRIVER::Register(); //Screwdriver Register
    HL_POOLSTICK::Register(); //Azure Sheep Poolstick Register
    HL_SBSHOTGUN::Register(); //Mossberg 500 w/ Torchlight attached Register
    HL_AXE::Register(); //Brave Brain Fire Axe Register
    HL_M79::Register(); //KernCore's M79 Grenade Launcher Register
    BTS_MEDKIT::Register();
    CM249::Register(); //OP4 M249 SAW LMG Register
    BTS_KNIFE::Register(); //OP4 Combat Knife Register
    BTS_M4::Register(); //M4A1 Register
    BTS_M4SD::Register(); //Suppressed M4A1 Register
    BTS_FLARE::Register(); //Black Mesa Emergency Flare Register
    BTS_FLASHLIGHT::Register(); //Black Mesa Staff Flashlight
    HL_GLOCKSD::Register(); //HL Suppressed/Silenced Glock Register
    BTS_FLAREGUN::Register(); //Emergency Flare Gun
#if DISCARDED
    BTS_DARTGUN::Register(); //Dartgun ( Secret Weapon )
#endif
    BTS_GLOCK18::Register(); //Glock 18 ( Toggleable Mode )
    BTS_HANDGRENADE::Register(); //Custom Hand Grenade
    BTS_UZI::Register(); //Custom Single Uzi
    BTS_GLOCK17F::Register(); //Glock 17 w/ Torchlight variant
}
