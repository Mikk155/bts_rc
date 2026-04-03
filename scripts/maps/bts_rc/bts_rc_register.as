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

// Contain models/sprites ID
#include "misc/Precache"
#include "misc/models"

#include "callbacks/Hellbound"
#include "callbacks/survival"

#include "entities/ammo"
#include "entities/func_bts_recharger"
#include "entities/items"
#include "entities/point_checkpoint"
#include "entities/randomizer"
#include "entities/trigger_update_class"
#include "monsters/custommonsters" //Nero ADDED 2026-01-07 Custom Monsters

#include "gamemodes/bloodpuddle"
#include "gamemodes/deathdrop"
#include "gamemodes/lasers"
#include "gamemodes/player_models"
#include "gamemodes/player_voices"
#include "gamemodes/radioactivity"

#include "Hooks/monster_killed"
#include "Hooks/monster_takedamage"
#include "Hooks/player_connect" /* -TODO Remove this line in 5.27 */
#include "Hooks/player_think"

#include "weapons/main"

/*==========================================================================
*   - Start of variables for server operators. Modify these in config.json
==========================================================================*/
bool gpTraceBlood;
bool gpTraceSparks;
bool gpAllowMeleePull;
/*==========================================================================
*   - End
==========================================================================*/

void MapActivate()
{
    meta_api::NoticeInstallation();
    lasers::MapActivate();
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

    bloodpuddle::Register( @g_Config );
    lasers::Register( @g_Config );
    player_models::Register( @g_Config );

    g_VoiceResponse.Register( @g_Config );

    g_Config.get( "blood_splash", gpTraceBlood );
    g_Config.get( "sparks_splash", gpTraceSparks );
    g_Config.get( "melee_weapons_pull", gpAllowMeleePull );

    Precache();

    weapons::MapInit();

    /*==========================================================================
    *   - Start of custom entities registry
    ==========================================================================*/
    g_CustomEntityFuncs.RegisterCustomEntity( "func_bts_recharger::func_bts_recharger", "func_bts_recharger" );
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_update_class::trigger_update_class", "trigger_update_class" );
    g_CustomEntityFuncs.RegisterCustomEntity( "point_checkpoint::point_checkpoint", "point_checkpoint" );
    btscm::CustomMonsterMapInit(); // Nero ADDED 2026-01-07 Custom Monsters

    // Randomizer
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_npc", "randomizer_npc" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_item", "randomizer_item" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_hull", "randomizer_hull" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_boss", "randomizer_boss" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_wave", "randomizer_wave" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_headcrab", "randomizer_headcrab" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_hullwave", "randomizer_hullwave" );

    // Items
    g_CustomEntityFuncs.RegisterCustomEntity( "item_bts_armorvest", "item_bts_armorvest" );
    g_CustomEntityFuncs.RegisterCustomEntity( "item_bts_helmet", "item_bts_helmet" );
    g_CustomEntityFuncs.RegisterCustomEntity( "item_bts_hevbattery", "item_bts_hevbattery" );
    g_CustomEntityFuncs.RegisterCustomEntity( "item_bts_sprayaid", "item_bts_sprayaid" );

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
