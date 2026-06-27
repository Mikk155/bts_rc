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
#include "misc/Precache"
#include "entities/main"
#include "gamemodes/main"
#include "Hooks/main"

#include "../bts_rc_weapons/main"

Server::chrono@ MapLoadedChrono = Server::chrono();

/// Called by the map through trigger_script the moment that the map gameplay has started
void MapBegin( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
{
#if METAMOD_PLUGIN_ASCURL
    // Tell server ops there's a new update
    int requestID = g_EngineFuncs.CreateHTTPRequest( "https://api.github.com/repos/Mikk155/bts_rc/releases/latest", true, 0, 5000, 10000 );
    g_EngineFuncs.AppendHTTPRequestHeader(requestID, "User-Agent: sven-coop" );
    g_EngineFuncs.AppendHTTPRequestHeader(requestID, "Accept: application/vnd.github+json" );
    g_EngineFuncs.SetHTTPRequestCallback( requestID, function( int reqid )
    {
        int response_code = 0;
        string response_json;
        g_EngineFuncs.GetHTTPResponse( reqid, response_code, void, response_json );

        if( response_code >= 200 )
        {
            meta_api::json::v2::json@ response;
            if( meta_api::json::v2::Deserialize( response_json, response ) )
            {
                string tagName;

                if( response.Get( "tag_name", tagName ) )
                {
                    const SemanticVersion@ latestVersion = SemVer( tagName, true );

                    if( latestVersion > g_ScriptsVersion )
                    {
                        g_EngineFuncs.ServerPrint( "Map scripts got a newer version released!\n" );
                        g_EngineFuncs.ServerPrint( "https://github.com/Mikk155/bts_rc/releases/tag/" + latestVersion.ToString() + "\n" );
                    }
                }
            }
            g_EngineFuncs.DestroyHTTPRequest(reqid);
        }
    } );
    g_EngineFuncs.SendHTTPRequest( requestID );
#endif

    gpGameStarted = true;
    g_SurvivalMode.Activate();

    Hooks::Register();

    if( !g_IsMainMap )
        return;

    randomizer::Initialize();

    auto ckv = activator.GetCustomKeyvalues();

    // Remove developer commentary
    if( ckv.GetKeyvalue( "$i_devcommentary" ).GetInteger() == 0 )
    {
        CBaseEntity@ devcom = null;
        while( ( @devcom = g_EntityFuncs.FindEntityByClassname( devcom, "env_commentary" ) ) !is null ) {
            devcom.pev.flags |= FL_KILLME;
        }
        g_CustomEntityFuncs.UnRegisterCustomEntity( "env_commentary" );
    }

    activator.pev.flags |= FL_KILLME; // Free the trigger_script entity slot.
}

void MapActivate()
{
    item_tracker::gpItems.resize(0);
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
        if( entity.GetClassname()  == "item_inventory" )
        {
            CItemInventory@ item = cast<CItemInventory@>(entity);

            if( item !is null && item_tracker::ValidItemNames.find( item.m_szItemName ) >= 0 )
            {
                item_tracker::gpItems.insertLast( EHandle( item ) );
                array<string> list = { item.m_szDisplayName, item.m_szDescription };
                item_tracker::Items[ item.m_szItemName ] = list;
            }
        }
    }

    MapLoadedChrono.Stop();
    g_Game.AlertMessage( at_console, "The map has been loaded in %1:%2 seconds\n", MapLoadedChrono.Seconds, MapLoadedChrono.Miliseconds );
    @MapLoadedChrono = null;

    meta_api::NoticeInstallation();

    if( !g_IsMainMap )
        MapBegin(null, null, USE_TOGGLE, 0 );
}

void MapInit()
{
    Server::chrono@ chrono = null;

    if( g_Logger.info.active )
    {
        @chrono = Server::chrono();
    }

    g_MapConfig.__LoadMapConfiguration__();

    // Logger first
    g_MapConfig.Register( g_Logger );

    // No ordering required:
    g_MapConfig.Register( g_WeaponsConfig ); // Always active
    g_MapConfig.Register( ASBloodPuddleConfig() );
    g_MapConfig.Register( ASDynamicAmmoConfig() );
    g_MapConfig.Register( ASZombieUncrabConfig() );
    g_MapConfig.Register( ASDeathDropConfig() );
    g_MapConfig.Register( ASAimingLasersConfig() );
    g_MapConfig.Register( ASBlackOpsFlashbang() );
    g_MapConfig.Register( ASGruntEngineer() );
    g_MapConfig.Register( ASWallRechargerConfig() ); // Always active

    g_MapConfig.Register( gpRoboGrunt ); // Always active
    g_MapConfig.Register( gpRoboGruntBoss ); // Always active
    g_MapConfig.Register( gpZombieEngineer ); // Always active

    // Items
    g_MapConfig.Register( gpItemsConfig ); // Always active

    // Weapons
    g_MapConfig.Register( gpWeaponCrowbarConfig ); // Always active
    g_MapConfig.Register( gpWeaponScrewDriverConfig ); // Always active
    g_MapConfig.Register( gpWeaponPoolstickConfig ); // Always active
    g_MapConfig.Register( gpWeaponPipeWrenchConfig ); // Always active
    g_MapConfig.Register( gpWeaponPipeConfig ); // Always active
    g_MapConfig.Register( gpWeaponKnifeConfig ); // Always active
    g_MapConfig.Register( gpWeaponAxeConfig ); // Always active
    g_MapConfig.Register( gpWeaponMedkitConfig ); // Always active
    g_MapConfig.Register( gpWeaponFlashlight ); // Always active

    // Player characters
    g_MapConfig.Register( gpCharactersConfig ); // Always active

    g_MapConfig.__ValidateMapConfiguration__();

    g_VoiceResponse.Register();

    models::Precache();

    Precache();

    btscm::CustomMonsterMapInit(); // Nero ADDED 2026-01-07 Custom Monsters

    if( g_Logger.info.active )
    {
        chrono.Stop();
        g_Logger.info.print( snprintf( glog, "Done with MapInit. total time elapsed: %1:%2 seconds.", chrono.Seconds, chrono.Miliseconds ) );
    }

    oldweapons::init();

#if SERVER
    if( g_IsMainMap )
        return;

    CustomEntity( "trigger_logger", true, "test_chamber::trigger_logger" );
    CustomEntity( "func_section", true, "test_chamber::func_section" );
#endif
}

void MapStart()
{
#if SERVER
    if( g_IsMainMap )
        return;

    g_StartInventory.Remove( "weapon_medkit" );
    g_EngineFuncs.CVarSetFloat( "mp_timelimit", 0 );
    g_EngineFuncs.CVarSetFloat( "mp_timelimit_empty", 0 );
    g_EngineFuncs.CVarSetFloat( "mp_respawndelay", 0 );
#endif
}
