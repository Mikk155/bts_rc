/*
    Author: Mikk
*/

/*==========================================================================
*   - Start of includes
==========================================================================*/

#include "util/utils"
#include "misc/Precache"
#include "entities/main"
#include "gamemodes/main"
#include "Hooks/main"
#include "weapons/main"

// Has the game started in the map?
bool gpGameStarted;

Server::chrono@ MapLoadedChrono = Server::chrono();

/// Called by the map through trigger_script the moment that the map gameplay has started
void MapBegin( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
{
    gpGameStarted = true;
    g_SurvivalMode.Activate();
    item_tracker::Initialize();
}

void MapActivate()
{
    lasers::MapActivate();

    MapLoadedChrono.Stop();
    g_Game.AlertMessage( at_console, "The map has been loaded in %1:%2 seconds\n", MapLoadedChrono.Seconds, MapLoadedChrono.Miliseconds );
    @MapLoadedChrono = null;

#if METAMOD_DEBUG
    MapBegin(null, null, USE_TOGGLE, 0);
#endif

    meta_api::NoticeInstallation();
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
    g_CustomEntityFuncs.RegisterCustomEntity( "point_checkpoint::point_checkpoint", "point_checkpoint" );
    btscm::CustomMonsterMapInit(); // Nero ADDED 2026-01-07 Custom Monsters

    if( g_Logger.info )
    {
        chronoMapInit.Stop();
        g_Logger.info = snprintf( glog, "Done with MapInit. total time elapsed: %1:%2 seconds.", chrono.Seconds, chrono.Miliseconds );
    }
}
