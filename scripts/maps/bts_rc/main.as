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

// Has the game started in the map?
bool gpGameStarted;

const uint32 gpGameVersion = g_Game.GetGameVersion();
const uint32 DMG_BTS_WEAPON = DMG_DROWN;

Server::chrono@ MapLoadedChrono = Server::chrono();

/// Called by the map through trigger_script the moment that the map gameplay has started
void MapBegin( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
{
    if( activator.GetClassname() == "trigger_script" )
        activator.pev.flags |= FL_KILLME; // Free the trigger_script entity slot.

    gpGameStarted = true;
    g_SurvivalMode.Activate();
    randomizer::Initialize();
    item_tracker::Initialize();
    lasers::MapActivate();
    
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

    Hooks::StartFrame();
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

    btscm::CustomMonsterMapInit(); // Nero ADDED 2026-01-07 Custom Monsters

    g_WeaponsConfig.MapInit();

    if( g_Logger.info )
    {
        chronoMapInit.Stop();
        g_Logger.info = snprintf( glog, "Done with MapInit. total time elapsed: %1:%2 seconds.", chrono.Seconds, chrono.Miliseconds );
    }

    oldweapons::init();
}
