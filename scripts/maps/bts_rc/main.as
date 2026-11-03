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

#include "framerate"

#include "util/utils"
#include "entities/main"
#include "gamemodes/main"
#include "Hooks/main"

Server::chrono@ MapLoadedChrono = Server::chrono();

#if METAMOD_PLUGIN_ASCURL
#include "util/UpdateChecker"
#endif

/// Called by the map through trigger_script the moment that the map gameplay has started
void MapBegin( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value ) // disable-line W118
{
    if( gCheckModuleError(true) )
    {
        if( g_Logger.get() !is null && g_Logger.get().critical.active )
            g_Logger.get().critical( "MapBegin skipped because the module reported an earlier error." );
        return;
    }

    if( g_Logger.get() !is null && g_Logger.get().info.active )
        g_Logger.get().info( "Starting map gameplay. main map={} debug={}", { String::from_bool( g_IsMainMap ), String::from_bool( g_Debug ) } );

#if METAMOD_PLUGIN_ASCURL
    // Dont request every time while developing
    if( !g_Debug )
    {
        // Notice of new github releases if we're running a old version.
        if( g_Logger.get() !is null && g_Logger.get().debug.active )
            g_Logger.get().debug( "Checking for available updates." );
        UpdateChecker();
    }
#endif

    gpGameStarted = true;
    g_SurvivalMode.Activate();

    if( g_Logger.get() !is null && g_Logger.get().debug.active )
        g_Logger.get().debug( "Survival mode activated." );

    Hooks::Register();

    if( g_Logger.get() !is null && g_Logger.get().debug.active )
        g_Logger.get().debug( "Gameplay hooks registered." );

    if( g_IsMainMap )
    {
        randomizer::Initialize();

        if( g_Logger.get() !is null && g_Logger.get().debug.active )
            g_Logger.get().debug( "Main-map randomizer initialized." );
    }

    auto ckv = activator.GetCustomKeyvalues();

    Difficulty::UpdateDifficulty( ckv.GetKeyvalue( "$i_difficulty" ).GetInteger(), ckv.GetKeyvalue( "$i_hellbound" ).GetInteger() );

    if( Difficulty::HellBound() )
    {
        uint updatedPlayers = 0;
        for( int i = 0; i <= g_Engine.maxClients; i++ )
        {
            auto player = g_PlayerFuncs.FindPlayerByIndex(i);

            if( player !is null )
            {
                UpdatePlayerData( player, util::GetClass( player ) );
                updatedPlayers++;
            }
        }

        if( g_Logger.get() !is null && g_Logger.get().debug.active )
            g_Logger.get().debug( "Applied Hellbound player data to {} players.", { updatedPlayers } );
    }

    activator.pev.flags |= FL_KILLME; // Free the trigger_script entity slot.

    gCheckModuleError(false);

    if( g_Logger.get() !is null && g_Logger.get().info.active )
        g_Logger.get().info( "Map gameplay started successfully." );
}

void MapActivate()
{
    if( gCheckModuleError(true) )
    {
        if( g_Logger.get() !is null && g_Logger.get().critical.active )
            g_Logger.get().critical( "MapActivate skipped because the module reported an earlier error." );
        return;
    }

    if( g_Logger.get() !is null && g_Logger.get().info.active )
        g_Logger.get().info( "Activating map entities." );

    if( gpItemsConfig.item_tracking )
    {
        item_tracker::Reset();
    }

    uint numents = g_EngineFuncs.NumberOfEntities();
    uint overriddenEntities = 0;
    uint trackedItems = 0;

    for( uint entityIndex = 1; entityIndex < numents; entityIndex++ )
    {
        auto entity = g_EntityFuncs.Instance( entityIndex );

        if( entity is null )
            continue;

        if( EntityOverriden::Register( entity, cast<CBaseMonster@>(entity) ) )
        {
            overriddenEntities++;
        }

        // item tracker data
        if( gpItemsConfig.item_tracking && entity.GetClassname() == "item_inventory" )
        {
            CItemInventory@ item = cast<CItemInventory@>(entity);

            if( item !is null && item_tracker::ValidItemNames.find( item.m_szItemName ) >= 0 )
            {
                item_tracker::RegisterItem( item );
                trackedItems++;
            }
        }
    }

    if( g_Logger.get() !is null && g_Logger.get().debug.active )
        g_Logger.get().debug( "Processed {} entities: {} overrides and {} tracked items.", { numents - 1, overriddenEntities, trackedItems } );

    meta_api::NoticeInstallation();

    if( !g_IsMainMap )
    {
        test_chamber::MapActivate();

        if( g_Logger.get() !is null && g_Logger.get().debug.active )
            g_Logger.get().debug( "Test chamber activation completed." );
    }

    if( g_Logger.get() !is null && g_Logger.get().info.active )
        g_Logger.get().info( "Map entities activated successfully in {}:{} seconds.", { MapLoadedChrono.Seconds, MapLoadedChrono.Miliseconds } );

    MapLoadedChrono.Stop();
    if( g_Logger.get() !is null && g_Logger.get().info.active )
        g_Logger.get().info( "The map has been loaded in {}:{} seconds.", { MapLoadedChrono.Seconds, MapLoadedChrono.Miliseconds } );
    @MapLoadedChrono = null;

    gCheckModuleError(false);
}

void MapInit()
{
    if( gCheckModuleError(true) )
    {
        if( g_Logger.get() !is null && g_Logger.get().critical.active )
            g_Logger.get().critical( "MapInit skipped because the module reported an earlier error." );
        return;
    }

    Server::chrono@ chrono = Server::chrono();

    if( g_Logger.get() !is null && g_Logger.get().info.active )
        g_Logger.get().info( "Initializing map systems" );

    Precache::Precache();

    g_MapConfig.__MapInitialize__();

    if( g_Logger.get() !is null && g_Logger.get().debug.active )
        g_Logger.get().debug( "Map configuration initialized." );

    btscm::CustomMonsterMapInit(); // Nero ADDED 2026-01-07 Custom Monsters

    if( !g_IsMainMap )
    {
        test_chamber::MapInit();

        if( g_Logger.get() !is null && g_Logger.get().debug.active )
            g_Logger.get().debug( "Test chamber systems initialized." );
    }

    chrono.Stop();
    if( g_Logger.get() !is null && g_Logger.get().info.active )
        g_Logger.get().info( "Map initialization completed in {}:{} seconds.", { chrono.Seconds, chrono.Miliseconds } );

    gCheckModuleError(false);
}
