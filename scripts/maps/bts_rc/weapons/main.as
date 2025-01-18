#include "proj/dart"
#include "proj/flare"
#include "proj/m79_rocket"

#include "weapon_bts_axe"
#include "weapon_bts_beretta"
#include "weapon_bts_crowbar"
#include "weapon_bts_eagle"
#include "weapon_bts_flare"
#include "weapon_bts_flaregun"
#include "weapon_bts_flashlight"
#include "weapon_bts_glock"
#include "weapon_bts_glock17f"
#include "weapon_bts_glock18"
#include "weapon_bts_glocksd"
#include "weapon_bts_handgrenade"
#include "weapon_bts_knife"
#include "weapon_bts_m4"
#include "weapon_bts_m4sd"
#include "weapon_bts_m16"
#include "weapon_bts_m79"
#include "weapon_bts_medkit"
#include "weapon_bts_mp5"
#include "weapon_bts_mp5gl"
#include "weapon_bts_pipe"
#include "weapon_bts_poolstick"
#include "weapon_bts_python"
#include "weapon_bts_saw"
#include "weapon_bts_sbshotgun"
#include "weapon_bts_screwdriver"
#include "weapon_bts_shotgun"
#include "weapon_bts_uzi"

array<ItemMapping@> g_AmmoReplacement =
{
    ItemMapping( "weapon_9mmhandgun", "ammo_bts_dglocksd" ),
    ItemMapping( "weapon_glock", "ammo_bts_dglocksd" ),
    ItemMapping( "weapon_357", "ammo_bts_357cyl" ),
    ItemMapping( "weapon_eagle", "ammo_bts_dreagle" ),
    ItemMapping( "weapon_9mmAR", "ammo_bts_9mmbox" ),
    ItemMapping( "weapon_mp5", "ammo_bts_9mmbox" ),
    ItemMapping( "weapon_shotgun", "ammo_bts_shotshell" ),
    ItemMapping( "weapon_m16", "ammo_bts_9mmbox" ),
    ItemMapping( "weapon_saw", "ammo_bts_dsaw" ),
    ItemMapping( "weapon_m249", "ammo_bts_dsaw" ),
    ItemMapping( "weapon_minigun", "ammo_bts_dsaw" ),
    ItemMapping( "weapon_medkit", "weapon_bts_medkit" )
};

const int WEAPON_DEFAULT_FLAGS = ( ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_NOAUTORELOAD );