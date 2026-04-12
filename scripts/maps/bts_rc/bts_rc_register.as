/*
    Author: Mikk
*/

/*==========================================================================
*   - Start of includes
==========================================================================*/

#include "../../mikk155/meta_api"
#include "../../mikk155/meta_api/json"
#include "../../mikk155/Server/chrono"

#include "util/CommandContext"
#include "util/ConfigContext"
#include "util/freeedicts"
#include "util/Logger"
#include "util/PlayerClass"
#include "util/PlayerData"

// Contain models/sprites ID
#include "misc/Precache"
#include "misc/models"

#include "callbacks/Hellbound"
#include "callbacks/survival"

#include "entities/ammo"
#include "entities/func_bts_recharger"
#include "entities/point_checkpoint"
#include "entities/trigger_update_class"
#include "monsters/custommonsters" //Nero ADDED 2026-01-07 Custom Monsters

#include "gamemodes/bloodpuddle"
#include "gamemodes/item_tracker"
#include "gamemodes/deathdrop"
#include "gamemodes/lasers"
#include "gamemodes/player_voices"
#include "gamemodes/PlayerClass"
#include "gamemodes/randomizer"
#include "gamemodes/zombie_uncrab"

#include "Hooks/ClientInitialized"
#include "Hooks/PlayerRevive"
#include "Hooks/PlayerSpawn"
#include "Hooks/PlayerTakeDamage"
#include "Hooks/PlayerThink"
#include "Hooks/SquadmakerSpawn"

#include "items/main"

#include "weapons/main"

// Has the game started in the map?
bool gpGameStarted;

Server::chrono@ MapLoadedChrono = Server::chrono();

void MapActivate()
{
    meta_api::NoticeInstallation();
    lasers::MapActivate();

    MapLoadedChrono.Stop();
    g_Game.AlertMessage( at_console, "The map has been loaded in %1:%2 seconds\n", MapLoadedChrono.Seconds, MapLoadedChrono.Miliseconds );
    @MapLoadedChrono = null;

#if METAMOD_DEBUG
    survival::activate(null, null, USE_TOGGLE, 0);
#endif
}

void MapInit()
{
    Server::chrono@ chrono = Server::chrono();
    Server::chrono@ chronoMapInit = Server::chrono();

    dictionary g_Config;

    if( !meta_api::json::Deserialize( "bts_rc/config.json", g_Config ) )
    {
        g_Logger.critical = snprintf( glog, "Could not parse \"scripts/maps/bts_rc/config.json\"" );
    }

    g_Logger.__Register__( cast<dictionary@>( g_Config[ "log" ] ) );

    if( g_Logger.info )
    {
        chrono.Stop();
        g_Logger.info = snprintf( glog, "Parsed \"scripts/maps/bts_rc/config.json\" in %1:%2 seconds.", chrono.Seconds, chrono.Miliseconds );
        chrono.Restart();
    }

    ConfigContext::MapInit( g_Config );

    if( g_Logger.info )
    {
        chrono.Stop();
        g_Logger.info = snprintf( glog, "Configured all config contexts in %1:%2 seconds.", chrono.Seconds, chrono.Miliseconds );
    }

    lasers::Register( @g_Config );
    RegisterPlayerClass( @g_Config );

    g_VoiceResponse.Register( @g_Config );

    Precache();

    items::Register( g_Config );
    weapons::Register( g_Config );

    /*==========================================================================
    *   - Start of custom entities registry
    ==========================================================================*/
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_update_class::trigger_update_class", "trigger_update_class" );
    g_CustomEntityFuncs.RegisterCustomEntity( "point_checkpoint::point_checkpoint", "point_checkpoint" );
    btscm::CustomMonsterMapInit(); // Nero ADDED 2026-01-07 Custom Monsters

    if( g_Logger.info )
    {
        chronoMapInit.Stop();
        g_Logger.info = snprintf( glog, "Done with MapInit. total time elapsed: %1:%2 seconds.", chrono.Seconds, chrono.Miliseconds );
    }
}
