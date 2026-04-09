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
#include "gamemodes/deathdrop"
#include "gamemodes/lasers"
#include "gamemodes/player_voices"
#include "gamemodes/PlayerClass"
#include "gamemodes/randomizer"

#include "Hooks/PlayerRevive"
#include "Hooks/PlayerSpawn"
#include "Hooks/PlayerTakeDamage"
#include "Hooks/PlayerThink"

#include "Hooks/monster_killed"
#include "Hooks/monster_takedamage"
#include "Hooks/player_connect" /* -TODO Remove this line in 5.27 */
#include "Hooks/player_think"

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
}

void MapInit()
{
#if METAMOD_DEBUG
    gpGameStarted = true;
#endif

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

    bloodpuddle::Register( @g_Config );
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

    g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @player_think );
    g_Hooks.RegisterHook( Hooks::Monster::MonsterKilled, @monster_killed );
    g_Hooks.RegisterHook( Hooks::Monster::MonsterTakeDamage, @monster_takedamage );
    /* -TODO Remove this line in 5.27 */ if( g_Game.GetGameVersion() == 526 )
    {
        g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @notice_assets::player_connect );
    }

    if( g_Logger.info )
    {
        chronoMapInit.Stop();
        g_Logger.info = snprintf( glog, "Done with MapInit. total time elapsed: %1:%2 seconds.", chrono.Seconds, chrono.Miliseconds );
    }
}

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
    void open( CBasePlayer@ player, const string&in buffer )
    {
        if( player !is null && player.IsConnected() )
        {
            uint iChars = 0;

            string szSplitMsg = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

            for( uint uChars = 0; uChars < item_tracker::buffer.Length(); uChars++ )
            {
                szSplitMsg.SetCharAt( iChars, char( item_tracker::buffer[uChars] ) );
                iChars++;

                if( iChars == 32 )
                {
                    NetworkMessage motd_append( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict() );
                    motd_append.WriteByte( 0 );
                    motd_append.WriteString( szSplitMsg );
                    motd_append.End();

                    iChars = 0;
                }
            }

            // If we reached the end, send the last letters of the message
            if( iChars > 0 )
            {
                szSplitMsg.Truncate( iChars );

                NetworkMessage motd_fix( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict() );
                motd_fix.WriteByte( 0 );
                motd_fix.WriteString( szSplitMsg );
                motd_fix.End();
            }

            NetworkMessage motd_open( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict() );
            motd_open.WriteByte( 1 );
            motd_open.WriteString( "\n" );
            motd_open.End();
        }
    }
}
