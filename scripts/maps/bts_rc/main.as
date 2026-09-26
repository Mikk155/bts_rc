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

#include "util/utils"
#include "entities/main"
#include "gamemodes/main"
#include "Hooks/main"

#include "../bts_rc_weapons/main"

Server::chrono@ MapLoadedChrono = Server::chrono();

#if METAMOD_PLUGIN_ASCURL
#include "util/UpdateChecker"
#endif

/// Called by the map through trigger_script the moment that the map gameplay has started
void MapBegin( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
{
    if( gCheckModuleError(true) )
        return;

#if METAMOD_PLUGIN_ASCURL
    UpdateChecker(); // Notice of new github releases if we're running a old version.
#endif

    gpGameStarted = true;
    g_SurvivalMode.Activate();

    Hooks::Register();

    if( g_IsMainMap )
    {
        randomizer::Initialize();
    }

    activator.pev.flags |= FL_KILLME; // Free the trigger_script entity slot.

    gCheckModuleError(false);
}

void MapActivate()
{
    if( gCheckModuleError(true) )
        return;

    if( g_WeaponsConfig.item_tracking )
        item_tracker::Reset();
    uint numents = g_EngineFuncs.NumberOfEntities();

    for( uint entityIndex = 1; entityIndex < numents; entityIndex++ )
    {
        auto entity = g_EntityFuncs.Instance( entityIndex );

        if( entity is null )
            continue;

        CBaseMonster@ monster = null;

        if( entity.IsMonster() )
            @monster = cast<CBaseMonster@>(entity);

        auto ckv = entity.GetCustomKeyvalues();

        EntityOverriden::Register( entityIndex, entity, ckv, monster );

        // item tracker data
        if( g_WeaponsConfig.item_tracking && entity.GetClassname() == "item_inventory" )
        {
            CItemInventory@ item = cast<CItemInventory@>(entity);

            if( item !is null && item_tracker::ValidItemNames.find( item.m_szItemName ) >= 0 )
            {
                item_tracker::RegisterItem( item );
            }
        }
    }

    MapLoadedChrono.Stop();
    g_Game.AlertMessage( at_console, "The map has been loaded in %1:%2 seconds\n", MapLoadedChrono.Seconds, MapLoadedChrono.Miliseconds );
    @MapLoadedChrono = null;

    meta_api::NoticeInstallation();

    gCheckModuleError(false);
}

void MapInit()
{
    if( gCheckModuleError(true) )
        return;

    Server::chrono@ chrono = null;

    if( g_Logger.info.active )
    {
        @chrono = Server::chrono();
    }

    models::Precache();

    Precache();

    g_MapConfig.__MapInitialize__();

    btscm::CustomMonsterMapInit(); // Nero ADDED 2026-01-07 Custom Monsters

    if( g_Logger.info.active )
    {
        chrono.Stop();
        g_Logger.info.print( snprintf( glog, "Done with MapInit. total time elapsed: %1:%2 seconds.", chrono.Seconds, chrono.Miliseconds ) );
    }

#if SERVER
    if( !g_IsMainMap )
    {
        CustomEntity( "trigger_logger", true, "test_chamber::trigger_logger" );
        CustomEntity( "info_section", true, "test_chamber::info_section" );
        CustomEntity( "entitymaker", true, "test_chamber::entitymaker" );
    }
#endif

    gCheckModuleError(false);
}
