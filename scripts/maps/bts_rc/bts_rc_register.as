/*
    Author: Mikk
*/

/*==========================================================================
*   - Start of includes
==========================================================================*/

#include "../../mikk155/meta_api"
#include "../../mikk155/meta_api/json"

// Contain models/sprites ID
#include "misc/models"
#include "misc/Precache"

#include "callbacks/Hellbound"
#include "callbacks/survival"

#include "entities/ammo"
#include "monsters/custommonsters" //Nero ADDED 2026-01-07 Custom Monsters
#include "entities/env_bloodpuddle"
#include "entities/func_bts_recharger"
#include "entities/items"
#include "entities/point_checkpoint"
#include "entities/randomizer"
#include "entities/trigger_update_class"

#include "gamemodes/lasers"
#include "gamemodes/player_voices"

#include "Hooks/monster_killed"
#include "Hooks/monster_takedamage"
#include "Hooks/player_connect" /* -TODO Remove this line in 5.27 */
#include "Hooks/player_takedamage"
#include "Hooks/player_think"

#include "weapons/main"

/*==========================================================================
*   - Start of Cvars for server operators. Modify these in maps/bts_rc.cfg
==========================================================================*/
bool gpBloodPuddles;
bool gpForcepModels;
bool gpLaserSentries;
bool gpTraceBlood;
bool gpTraceSparks;
/*==========================================================================
*   - End
==========================================================================*/

void MapActivate()
{
    meta_api::NoticeInstallation();
    lasers::MapActivate();
}

dictionary g_Config;

void MapInit()
{
    if( !meta_api::json::Deserialize( "bts_rc/config.json", g_Config ) )
    {
        g_Game.AlertMessage( at_console, "[ERROR] Can not open \"scripts/maps/bts_rc/config.json\"\n" );
    }

    if( g_Config.get( "voice_responses", g_VoiceResponse.Active ) && g_VoiceResponse.Active )
    {
        g_VoiceResponse.Register();
    }

    if( g_Config.get( "blood_puddles", gpBloodPuddles ) && gpBloodPuddles )
    {
        g_CustomEntityFuncs.RegisterCustomEntity("env_bloodpuddle::env_bloodpuddle", "env_bloodpuddle");
        g_Game.PrecacheModel( "models/mikk/misc/bloodpuddle.mdl" );
    }

    if( g_Config.get( "turret_lasers", gpLaserSentries ) && gpLaserSentries )
    {
        g_Scheduler.SetInterval( "lasers_think", 0.01f, g_Scheduler.REPEAT_INFINITE_TIMES );
        g_Game.PrecacheModel( "sprites/glow01.spr" );
    }

    g_Config.get( "force_playermodels", gpForcepModels );
    g_Config.get( "blood_splash", gpTraceBlood );
    g_Config.get( "sparks_splash", gpTraceSparks );

    Precache();

    /*==========================================================================
    *   - Start of custom entities registry
    ==========================================================================*/
    g_CustomEntityFuncs.RegisterCustomEntity("func_bts_recharger::func_bts_recharger", "func_bts_recharger");
    g_CustomEntityFuncs.RegisterCustomEntity("trigger_update_class::trigger_update_class", "trigger_update_class");
    g_CustomEntityFuncs.RegisterCustomEntity("point_checkpoint::point_checkpoint", "point_checkpoint");
    btscm::CustomMonsterMapInit(); //Nero ADDED 2026-01-07 Custom Monsters

    // Randomizer
    g_CustomEntityFuncs.RegisterCustomEntity("randomizer::randomizer_npc", "randomizer_npc");
    g_CustomEntityFuncs.RegisterCustomEntity("randomizer::randomizer_item", "randomizer_item");
    g_CustomEntityFuncs.RegisterCustomEntity("randomizer::randomizer_hull", "randomizer_hull");
    g_CustomEntityFuncs.RegisterCustomEntity("randomizer::randomizer_boss", "randomizer_boss");
    g_CustomEntityFuncs.RegisterCustomEntity("randomizer::randomizer_wave", "randomizer_wave");
    g_CustomEntityFuncs.RegisterCustomEntity("randomizer::randomizer_headcrab", "randomizer_headcrab");
    g_CustomEntityFuncs.RegisterCustomEntity("randomizer::randomizer_hullwave", "randomizer_hullwave");

    // Items
    g_CustomEntityFuncs.RegisterCustomEntity("item_bts_armorvest", "item_bts_armorvest");
    g_CustomEntityFuncs.RegisterCustomEntity("item_bts_helmet", "item_bts_helmet");
    g_CustomEntityFuncs.RegisterCustomEntity("item_bts_hevbattery", "item_bts_hevbattery");
    g_CustomEntityFuncs.RegisterCustomEntity("item_bts_sprayaid", "item_bts_sprayaid");

    // Projectiles
    g_CustomEntityFuncs.RegisterCustomEntity("M79_ROCKET::CM79Rocket", "m79_rocket");
    g_CustomEntityFuncs.RegisterCustomEntity("FLARE::CFlare", "flare");
    g_CustomEntityFuncs.RegisterCustomEntity("BTS_FLAMETHROWER::flame_proj", "flame_proj");

    // Weapon Entities
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_axe::weapon_bts_axe", "weapon_bts_axe");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_pipewrench::weapon_bts_pipewrench", "weapon_bts_pipewrench");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_beretta::weapon_bts_beretta", "weapon_bts_beretta");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_crowbar::weapon_bts_crowbar", "weapon_bts_crowbar");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_eagle::weapon_bts_eagle", "weapon_bts_eagle");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_flare::weapon_bts_flare", "weapon_bts_flare");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_flaregun::weapon_bts_flaregun", "weapon_bts_flaregun");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_flashlight::weapon_bts_flashlight", "weapon_bts_flashlight");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_sw637::weapon_bts_sw637", "weapon_bts_sw637");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_glock::weapon_bts_glock", "weapon_bts_glock");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_glock17f::weapon_bts_glock17f", "weapon_bts_glock17f");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_glock18::weapon_bts_glock18", "weapon_bts_glock18");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_glocksd::weapon_bts_glocksd", "weapon_bts_glocksd");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_knife::weapon_bts_knife", "weapon_bts_knife");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_handgrenade::weapon_bts_handgrenade", "weapon_bts_handgrenade");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_m4::weapon_bts_m4", "weapon_bts_m4");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_m4sd::weapon_bts_m4sd", "weapon_bts_m4sd");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_m16::weapon_bts_m16", "weapon_bts_m16");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_m16sd::weapon_bts_m16sd", "weapon_bts_m16sd");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_m79::weapon_bts_m79", "weapon_bts_m79");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_medkit::weapon_bts_medkit", "weapon_bts_medkit");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_mp5gl::weapon_bts_mp5gl", "weapon_bts_mp5gl");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_mp5::weapon_bts_mp5", "weapon_bts_mp5");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_pipe::weapon_bts_pipe", "weapon_bts_pipe");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_poolstick::weapon_bts_poolstick", "weapon_bts_poolstick");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_python::weapon_bts_python", "weapon_bts_python");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_shotgun::weapon_bts_shotgun", "weapon_bts_shotgun");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_uzi::weapon_bts_uzi", "weapon_bts_uzi");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_uzisd::weapon_bts_uzisd", "weapon_bts_uzisd");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_saw::weapon_bts_saw", "weapon_bts_saw");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_sawsd::weapon_bts_sawsd", "weapon_bts_sawsd");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_sbshotgun::weapon_bts_sbshotgun", "weapon_bts_sbshotgun");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_screwdriver::weapon_bts_screwdriver", "weapon_bts_screwdriver");

    // Ammo
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_beretta", "ammo_bts_beretta");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_beretta_battery", "ammo_bts_beretta_battery");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_eagle", "ammo_bts_eagle");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_eagle_battery", "ammo_bts_eagle_battery");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_eagle", "ammo_bts_dreagle");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_flarebox", "ammo_bts_flarebox");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_battery", "ammo_bts_battery");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_sw637", "ammo_bts_sw637");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_glock", "ammo_bts_glock");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_glock17f", "ammo_bts_glock17f");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_glock17f_battery", "ammo_bts_glock17f_battery");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_glock18", "ammo_bts_glock18");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_glocksd", "ammo_bts_glocksd");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_glocksd_battery", "ammo_bts_glocksd_battery");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_glocksd", "ammo_bts_dglocksd");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m4", "ammo_bts_m4");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_dummy", "ammo_bts_dummy");
//  g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m4", "ammo_bts_556mag"); // uncomment this to have infinite 556 ammo
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m4sd", "ammo_bts_m4sd");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m16", "ammo_bts_m16");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m16sd", "ammo_bts_m16sd");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m16", "ammo_bts_556round");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m16_grenade", "ammo_bts_m16_grenade");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m16sd_grenade", "ammo_bts_m16sd_grenade");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m79", "ammo_bts_m79");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_mp5", "ammo_bts_mp5");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_mp5", "ammo_bts_dmp5");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_mp5gl", "ammo_bts_mp5gl");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_mp5gl", "ammo_bts_9mmbox");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_mp5gl_grenade", "ammo_bts_mp5gl_grenade");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_python", "ammo_bts_python");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_python", "ammo_bts_357cyl");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_saw", "ammo_bts_saw");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_sawsd", "ammo_bts_sawsd");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_saw", "ammo_bts_dsaw");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_sbshotgun", "ammo_bts_sbshotgun");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_sbshotgun_battery", "ammo_bts_sbshotgun_battery");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_shotgun", "ammo_bts_shotgun");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_shotgun", "ammo_bts_shotshell");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_uzi", "ammo_bts_uzi");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_uzisd", "ammo_bts_uzisd");

    // Weapons
    g_ItemRegistry.RegisterWeapon("weapon_bts_axe", "bts_rc/weapons");
    g_ItemRegistry.RegisterWeapon("weapon_bts_pipewrench", "bts_rc/weapons");
    g_ItemRegistry.RegisterWeapon("weapon_bts_beretta", "bts_rc/weapons", "9mm", "bts:battery", "ammo_bts_beretta", "ammo_bts_beretta_battery");
    g_ItemRegistry.RegisterWeapon("weapon_bts_crowbar", "bts_rc/weapons");
    g_ItemRegistry.RegisterWeapon("weapon_bts_eagle", "bts_rc/weapons", "357", "bts:battery", "ammo_bts_eagle", "ammo_bts_eagle_battery");
    g_ItemRegistry.RegisterWeapon("weapon_bts_flare", "bts_rc/weapons", "weapon_bts_flare", "", "weapon_bts_flare", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_flaregun", "bts_rc/weapons", "bts:flare", "", "ammo_bts_flarebox", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_flashlight", "bts_rc/weapons", "bts:battery", "", "ammo_bts_battery", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_sw637", "bts_rc/weapons", "38", "", "ammo_bts_sw637", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_glock", "bts_rc/weapons", "9mm", "", "ammo_bts_glock", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_glock17f", "bts_rc/weapons", "9mm", "bts:battery", "ammo_bts_glock17f", "ammo_bts_glock17f_battery");
    g_ItemRegistry.RegisterWeapon("weapon_bts_glock18", "bts_rc/weapons", "9mm", "", "ammo_bts_glock18", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_glocksd", "bts_rc/weapons", "9mm", "bts:battery", "ammo_bts_glocksd", "ammo_bts_glocksd_battery");
    g_ItemRegistry.RegisterWeapon("weapon_bts_knife", "bts_rc/weapons");
    g_ItemRegistry.RegisterWeapon("weapon_bts_handgrenade", "bts_rc/weapons", "Hand Grenade", "", "weapon_bts_handgrenade", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_m4", "bts_rc/weapons", "556", "", "ammo_bts_m4", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_m4sd", "bts_rc/weapons", "556", "", "ammo_bts_m4sd", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_m16", "bts_rc/weapons", "556", "ARgrenades", "ammo_bts_m16", "ammo_bts_m16_grenade");
    g_ItemRegistry.RegisterWeapon("weapon_bts_m16sd", "bts_rc/weapons", "556", "ARgrenades", "ammo_bts_m16sd", "ammo_bts_m16sd_grenade");
    g_ItemRegistry.RegisterWeapon("weapon_bts_m79", "bts_rc/weapons", "ARgrenades", "", "ammo_bts_m79", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_medkit", "bts_rc/weapons", "health", "", "ammo_medkit");
    g_ItemRegistry.RegisterWeapon("weapon_bts_mp5gl", "bts_rc/weapons", "9mm", "ARgrenades", "ammo_bts_mp5gl", "ammo_bts_mp5gl_grenade");
    g_ItemRegistry.RegisterWeapon("weapon_bts_mp5", "bts_rc/weapons", "9mm", "", "ammo_bts_mp5", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_pipe", "bts_rc/weapons");
    g_ItemRegistry.RegisterWeapon("weapon_bts_poolstick", "bts_rc/weapons");
    g_ItemRegistry.RegisterWeapon("weapon_bts_python", "bts_rc/weapons", "357", "", "ammo_bts_python", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_shotgun", "bts_rc/weapons", "buckshot", "", "ammo_bts_shotgun", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_uzi", "bts_rc/weapons", "9mm", "", "ammo_bts_uzi", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_uzisd", "bts_rc/weapons", "9mm", "", "ammo_bts_uzisd", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_saw", "bts_rc/weapons", "556", "", "ammo_bts_saw", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_sawsd", "bts_rc/weapons", "556", "", "ammo_bts_sawsd", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_sbshotgun", "bts_rc/weapons", "buckshot", "bts:battery", "ammo_bts_sbshotgun", "ammo_bts_sbshotgun_battery");
    g_ItemRegistry.RegisterWeapon("weapon_bts_screwdriver", "bts_rc/weapons");
    BTS_XBOW::Register();
    weapon_bts_sniperrifle::Register();
    BTS_FLAMETHROWER::Register();
    weapon_bts_sw637::Register();
    /*==========================================================================
    *   - End
    ==========================================================================*/

    /*==========================================================================
    *   - Start of Item Mapping
    ==========================================================================*/
    g_ClassicMode.ForceItemRemap(true);
    g_ClassicMode.SetItemMappings(
        {ItemMapping("weapon_9mmhandgun", "ammo_bts_dglocksd"),
         ItemMapping("weapon_glock", "ammo_bts_dglocksd"),
         ItemMapping("weapon_357", "ammo_bts_357cyl"),
         ItemMapping("weapon_eagle", "ammo_bts_dreagle"),
         ItemMapping("weapon_uzi", "ammo_bts_9mmbox"),
         ItemMapping("weapon_uziakimbo", "ammo_bts_9mmbox"),
         ItemMapping("weapon_9mmAR", "ammo_bts_9mmbox"),
         ItemMapping("weapon_mp5", "ammo_bts_9mmbox"),
         ItemMapping("weapon_shotgun", "ammo_bts_shotshell"),
         ItemMapping("weapon_m16", "ammo_bts_dummy"), //please consult yourself with line 183 of ammo.as line
         ItemMapping("weapon_sniperrifle", "weapon_bts_sniperrifle"),
         ItemMapping("weapon_saw", "ammo_bts_dsaw"),
         ItemMapping("weapon_m249", "ammo_bts_dsaw"),
         ItemMapping("weapon_minigun", "ammo_bts_dsaw"),
         ItemMapping("weapon_rpg", "weapon_bts_m79"),
         ItemMapping("weapon_medkit", "weapon_bts_medkit")});

    /*==========================================================================
    *   - Start of hooks
    ==========================================================================*/
    g_Hooks.RegisterHook(Hooks::Player::PlayerPostThink, @player_think);
    g_Hooks.RegisterHook(Hooks::Player::PlayerTakeDamage, @player_takedamage);
    g_Hooks.RegisterHook(Hooks::Monster::MonsterKilled, @monster_killed);
    g_Hooks.RegisterHook(Hooks::Monster::MonsterTakeDamage, @monster_takedamage);
    /* -TODO Remove this line in 5.27 */ if (g_Game.GetGameVersion() == 526)
    {
        g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @notice_assets::player_connect);
    }
    /*==========================================================================
    *   - End
    ==========================================================================*/
}

// sven only has 8192 edicts at any given time
// so assume each player carries exactly 16 weapons, and then leave 100 slots free for various temporary things. -Zode
bool freeedicts(int overhead = 1)
{
    return (g_EngineFuncs.NumberOfEntities() < g_Engine.maxEntities - (16 * g_Engine.maxClients) - 100 - overhead);
}

// Barney > Scientist > Construction > Black Scientist    > Helmet > Cleansuit      > Operative > Black Otis      > Green Construction > Veterans
// Blue   > White     > Yellow       > White (Blk hand)   > Orange > White (Yellow) > Gray      > Blue (Blk Hand) > Green              > Gray (Speical)

enum PM
{
    UNSET = -1,
    BARNEY = 0,
    SCIENTIST = 1,
    CONSTRUCTION = 2,
    BSCIENTIST = 3,
    HELMET = 4,
    CLSUIT = 5,
    OPERATIVE = 6,
    OTIS = 7,
    GCONSTRUCTION = 8,
    VETERAN = 9
};

final class PlayerClass
{
    // Index of the last used model so we give each player a different one instead of a random one.
    private uint mdl_scientist_last = Math.RandomLong(0, 4);
    private array<string> mdl_scientist = {
        "bts_scientist",
        "bts_scientist3",
        "bts_scientist4",
        "bts_scientist5",
        "bts_scientist6"};
    private uint mdl_barney_last = Math.RandomLong(0, 2);
    private array<string> mdl_barney = {
        "bts_barney",
        "bts_barney2",
        "bts_barney3"};
    private uint mdl_con_last = Math.RandomLong(0, 3);
    private array<string> mdl_con = {
        "bts_construction",
        "bts_construction2",
        "bts_construction3"};
    private uint mdl_operative_last = Math.RandomLong(0, 5);
    private array<string> mdl_operative = {
        "bts_op",
        "bts_op2",
        "bts_op3",
        "bts_op4",
        "bts_op5",
        "bts_op6"};

    const PM opIndex(CBasePlayer @player, bool DontSet = false)
    {
        if (player !is null)
        {
            dictionary @data = player.GetUserData();

            if (!data.exists("class"))
            {
                if (DontSet)
                {
                    return PM::UNSET;
                }

                switch( Math.RandomLong( 1, 3 ) )
                {
                    case 1:
                        g_PlayerClass.set_class( player, PM::BARNEY );
                    break;
                    case 2:
                        g_PlayerClass.set_class( player, PM::CONSTRUCTION );
                    break;
                    case 3:
                        g_PlayerClass.set_class( player, PM::OPERATIVE );
                    break;
                }
            }

            return PM(data["class"]);
        }

        return PM::SCIENTIST;
    }

    bool is_trained_personal(CBasePlayer @player)
    {
        PM pm = g_PlayerClass[player];

        switch (pm)
        {
            case PM::BARNEY:
            case PM::OTIS:
            case PM::VETERAN:
            case PM::OPERATIVE:
            case PM::HELMET:
            case PM::CLSUIT:
                return true;
        }
        return false;
    }

    void set_class(CBasePlayer @player, PM player_class)
    {
        const string model = this.model(player_class);

        // Update class for bodygroups of view models n
        if (model == "bts_scientist3")
        {
            player_class = PM::BSCIENTIST;
        }
        if (model == "bts_construction2")
        {
            player_class = PM::GCONSTRUCTION;
        }
        if (model == "bts_otis_blk")
        {
            player_class = PM::OTIS;
        }

        player.GetUserData()["pm"] = model;
        player.GetUserData()["class"] = player_class;

        // Hide flashlight icon.
        player.m_iHideHUD |= HIDEHUD_FLASHLIGHT;

        player.pev.armortype = (player_class == PM::HELMET ? 100 : 50);

        // Re-Deploy weapon to update view model hands
        if (player.m_hActiveItem.IsValid())
        {
            CBaseEntity @active_item = player.m_hActiveItem.GetEntity();

            if (active_item !is null)
            {
                CBasePlayerItem @weapon = cast<CBasePlayerItem @>(active_item);

                if (weapon !is null)
                {
                    weapon.Deploy();
                }
            }
        }
    }

    // Return a player model for the given class
    const string& model(const PM player_class)
    {
        switch (player_class)
        {
            case PM::SCIENTIST:
            {
                mdl_scientist_last = (mdl_scientist_last >= mdl_scientist.length() - 1) ? 0 : mdl_scientist_last + 1;
                return mdl_scientist[mdl_scientist_last];
            }
            case PM::CONSTRUCTION:
            {
                mdl_con_last = (mdl_con_last >= mdl_con.length() - 1) ? 0 : mdl_con_last + 1;
                return mdl_con[mdl_con_last];
            }
            case PM::BARNEY:
            {
                mdl_barney_last = (mdl_barney_last >= mdl_barney.length() - 1) ? 0 : mdl_barney_last + 1;
                return mdl_barney[mdl_barney_last];
            }
            case PM::OPERATIVE:
            {
                mdl_operative_last = (mdl_operative_last >= mdl_operative.length() - 1) ? 0 : mdl_operative_last + 1;
                return mdl_operative[mdl_operative_last];
            }
            case PM::CLSUIT:
            {
                return "bts_cleansuit";
            }
            case PM::HELMET:
            {
                return "bts_helmet";
            }
        }
        return "bts_op3";
    }
}

PlayerClass g_PlayerClass;

namespace item_tracker
{
    // Last frame we did an operation.
    float time;
    // String containing all the information.
    string buffer;
}

//================================================================================================
//  Shows a MOTD message to the player
//  Code by Giegue. Taken from: https://github.com/JulianR0/TPvP/blob/master/src/plugins/TPvP.as#L7375
//================================================================================================
namespace motd
{
    void open(CBasePlayer @player, const string&in buffer)
    {
        if (player !is null && player.IsConnected())
        {
            uint iChars = 0;

            string szSplitMsg = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

            for (uint uChars = 0; uChars < item_tracker::buffer.Length(); uChars++)
            {
                szSplitMsg.SetCharAt(iChars, char(item_tracker::buffer[uChars]));
                iChars++;

                if (iChars == 32)
                {
                    NetworkMessage motd_append(MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict());
                    motd_append.WriteByte(0);
                    motd_append.WriteString(szSplitMsg);
                    motd_append.End();

                    iChars = 0;
                }
            }

            // If we reached the end, send the last letters of the message
            if (iChars > 0)
            {
                szSplitMsg.Truncate(iChars);

                NetworkMessage motd_fix(MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict());
                motd_fix.WriteByte(0);
                motd_fix.WriteString(szSplitMsg);
                motd_fix.End();
            }

            NetworkMessage motd_open(MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict());
            motd_open.WriteByte(1);
            motd_open.WriteString("\n");
            motd_open.End();
        }
    }
}
