/**   MIT License
*   
*   Copyright (c) 2025 Mikk155 https://github.com/Mikk155/bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies or substantial portions of the Software.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*   SOFTWARE.
*/

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
    gpGameStarted = true;
    g_SurvivalMode.Activate();
    randomizer::Initialize();
    item_tracker::Initialize();

#if METAMOD_DEBUG
    if( true ) { return; }
#endif

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

        uint length = gpEntityOverriden.length();

        for( uint ui = 0; ui < length; ui++ )
        {
            EntityOverriden@ overrider = gpEntityOverriden[ui];

            if( overrider !is null )
                overrider.AddEntity( entityIndex, entity, ckv, monster );
        }
    }

    MapLoadedChrono.Stop();
    g_Game.AlertMessage( at_console, "The map has been loaded in %1:%2 seconds\n", MapLoadedChrono.Seconds, MapLoadedChrono.Miliseconds );
    @MapLoadedChrono = null;

    meta_api::NoticeInstallation();

    Hooks::Register();

#if METAMOD_DEBUG
MapBegin(null, null, USE_TOGGLE, 0 );
#endif
}

void MapInit()
{
    Server::chrono@ chrono = Server::chrono();

    meta_api::json::v2::json@ json;
    if( !meta_api::json::v2::Deserialize( "bts_rc/config.json", json ) )
    {
        g_EngineFuncs.ServerPrint( "[ERROR] Could not parse \"scripts/maps/bts_rc/config.json\"\n" );
        @json = meta_api::json::v2::json();
    }

    g_Logger.Register( json.FirstOrDefault( "log" ) );
    json_v2_tests::RegisterJsonV2TestCommand();

    if( g_Logger.info.active )
    {
        chrono.Stop();
        g_Logger.info.print( snprintf( glog, "Parsed \"scripts/maps/bts_rc/config.json\" in %1:%2 seconds.", chrono.Seconds, chrono.Miliseconds ) );
    }

    ConfigContext::Registry( json, chrono );

    RegisterAllCharacters( json.First( "characters" ), chrono );

    models::Precache();

    Precache();

    items::Register( json );

    btscm::CustomMonsterMapInit(); // Nero ADDED 2026-01-07 Custom Monsters

    g_WeaponsConfig.MapInit();

    if( g_Logger.info.active )
    {
        chrono.Stop();
        g_Logger.info.print( snprintf( glog, "Done with MapInit. total time elapsed: %1:%2 seconds.", chrono.Seconds, chrono.Miliseconds ) );
    }

    oldweapons::init();
}
