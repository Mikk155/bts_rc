/*
    Author: Mikk
*/

/*==========================================================================
*   - Start of includes
==========================================================================*/

#include "../../mikk155/meta_api"
#include "../../mikk155/meta_api/json"
#if METAMOD_DEBUG
#include "../../mikk155/Server/chrono"
#endif

#include "util/ConfigContext"

// Contain models/sprites ID
#include "misc/Precache"
#include "misc/models"


#include "callbacks/Hellbound"
#include "callbacks/survival"

#include "entities/ammo"
#include "entities/env_bloodpuddle"
#include "entities/func_bts_recharger"
#include "entities/items"
#include "entities/point_checkpoint"
#include "entities/randomizer"
#include "entities/trigger_update_class"
#include "monsters/custommonsters" //Nero ADDED 2026-01-07 Custom Monsters


#include "gamemodes/lasers"
#include "gamemodes/player_voices"

#include "Hooks/monster_killed"
#include "Hooks/monster_takedamage"
#include "Hooks/player_connect" /* -TODO Remove this line in 5.27 */
#include "Hooks/player_takedamage"
#include "Hooks/player_think"

#include "weapons/main"

/*==========================================================================
*   - Start of variables for server operators. Modify these in config.json
==========================================================================*/
bool gpBloodPuddles;
bool gpForcepModels;
bool gpLaserSentries;
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
#if METAMOD_DEBUG
    auto chrono = Server::chrono();
#endif

    dictionary g_Config;

    if( !meta_api::json::Deserialize( "bts_rc/config.json", g_Config ) )
    {
        g_Game.AlertMessage( at_console, "[ERROR] Can not open \"scripts/maps/bts_rc/config.json\"\n" );
    }

    ConfigContext::MapInit( g_Config );

    if( g_Config.get( "voice_responses", g_VoiceResponse.Active ) && g_VoiceResponse.Active )
    {
        g_VoiceResponse.Register();
    }

    if( g_Config.get( "blood_puddles", gpBloodPuddles ) && gpBloodPuddles )
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "env_bloodpuddle::env_bloodpuddle", "env_bloodpuddle" );
        g_Game.PrecacheModel( "models/mikk/misc/bloodpuddle.mdl" );
    }

    if( g_Config.get( "turret_lasers", gpLaserSentries ) && gpLaserSentries )
    {
        g_Scheduler.SetInterval( "lasers_think", 0.01f, g_Scheduler.REPEAT_INFINITE_TIMES );
        g_Game.PrecacheModel( "sprites/glow01.spr" );
    }

    if( g_Config.get( "force_playermodels", gpForcepModels ) && gpForcepModels )
    {
        g_Game.PrecacheModel( "models/player/bts_barney/bts_barney.mdl" );
        g_Game.PrecacheModel( "models/player/bts_barney3/bts_barney3.mdl" );
        g_Game.PrecacheModel( "models/player/bts_cleansuit/bts_cleansuit.mdl" );
        g_Game.PrecacheModel( "models/player/bts_construction2/bts_construction2.mdl" );
        g_Game.PrecacheModel( "models/player/bts_construction3/bts_construction3.mdl" );
        g_Game.PrecacheModel( "models/player/bts_op/bts_op.mdl" );
        g_Game.PrecacheModel( "models/player/bts_op2/bts_op2.mdl" );
        g_Game.PrecacheModel( "models/player/bts_op3/bts_op3.mdl" );
        g_Game.PrecacheModel( "models/player/bts_op4/bts_op4.mdl" );
        g_Game.PrecacheModel( "models/player/bts_op5/bts_op5.mdl" );
        g_Game.PrecacheModel( "models/player/bts_op6/bts_op6.mdl" );
        g_Game.PrecacheModel( "models/player/bts_op_band/bts_op_band.mdl" );
        g_Game.PrecacheModel( "models/player/bts_op_free/bts_op_free.mdl" );
        g_Game.PrecacheModel( "models/player/bts_op_hurt/bts_op_hurt.mdl" );
        g_Game.PrecacheModel( "models/player/bts_otis/bts_otis.mdl" );
        g_Game.PrecacheModel( "models/player/bts_otis2/bts_otis2.mdl" );
        g_Game.PrecacheModel( "models/player/bts_otis_blk/bts_otis_blk.mdl" );
        g_Game.PrecacheModel( "models/player/bts_scientist2/bts_scientist2.mdl" );
        g_Game.PrecacheModel( "models/player/bts_scientist3/bts_scientist3.mdl" );
        g_Game.PrecacheModel( "models/player/bts_scientist4/bts_scientist4.mdl" );
        g_Game.PrecacheModel( "models/player/bts_scientist5/bts_scientist5.mdl" );
        g_Game.PrecacheModel( "models/player/bts_scientist6/bts_scientist6.mdl" );
    }

    g_Config.get( "blood_splash", gpTraceBlood );
    g_Config.get( "sparks_splash", gpTraceSparks );
    g_Config.get( "melee_weapons_pull", gpAllowMeleePull );

#if METAMOD_DEBUG
    chrono.Stop();
    g_Log.PrintF( "[BTS_RC] Done configurating json. time elapsed: %1.%2 seconds.\n", chrono.Seconds, chrono.Miliseconds );
    chrono.Restart();
#endif

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
    g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @player_takedamage );
    g_Hooks.RegisterHook( Hooks::Monster::MonsterKilled, @monster_killed );
    g_Hooks.RegisterHook( Hooks::Monster::MonsterTakeDamage, @monster_takedamage );
    /* -TODO Remove this line in 5.27 */ if( g_Game.GetGameVersion() == 526 )
    {
        g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @notice_assets::player_connect );
    }

#if METAMOD_DEBUG
    chrono.Stop();
    g_Log.PrintF( "[BTS_RC] Done registering entities & hooks. time elapsed: %1.%2 seconds.\n", chrono.Seconds, chrono.Miliseconds );
#endif
}

// sven only has 8192 edicts at any given time
// so assume each player carries exactly 16 weapons, and then leave 100 slots free for various temporary things. -Zode
bool freeedicts( int overhead = 1 )
{
    return ( g_EngineFuncs.NumberOfEntities() < g_Engine.maxEntities - ( 16 * g_Engine.maxClients ) - 100 - overhead );
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
    private uint mdl_scientist_last = Math.RandomLong( 0, 4 );
    private array<string> mdl_scientist = {
        "bts_scientist",
        "bts_scientist3",
        "bts_scientist4",
        "bts_scientist5",
        "bts_scientist6" };
    private uint mdl_barney_last = Math.RandomLong( 0, 2 );
    private array<string> mdl_barney = {
        "bts_barney",
        "bts_barney2",
        "bts_barney3" };
    private uint mdl_con_last = Math.RandomLong( 0, 3 );
    private array<string> mdl_con = {
        "bts_construction",
        "bts_construction2",
        "bts_construction3" };
    private uint mdl_operative_last = Math.RandomLong( 0, 5 );
    private array<string> mdl_operative = {
        "bts_op",
        "bts_op2",
        "bts_op3",
        "bts_op4",
        "bts_op5",
        "bts_op6" };

    const PM opIndex( CBasePlayer@ player, bool DontSet = false )
    {
        if( player !is null )
        {
            dictionary@ data = player.GetUserData();

            if( !data.exists( "class" ) )
            {
                if( DontSet )
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

            return PM( data["class"] );
        }

        return PM::SCIENTIST;
    }

    bool is_trained_personal( CBasePlayer@ player )
    {
        PM pm = g_PlayerClass[player];

        switch( pm )
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

    void set_class( CBasePlayer@ player, PM player_class )
    {
        const string model = this.model( player_class );

        // Update class for bodygroups of view models n
        if( model == "bts_scientist3" )
        {
            player_class = PM::BSCIENTIST;
        }
        if( model == "bts_construction2" )
        {
            player_class = PM::GCONSTRUCTION;
        }
        if( model == "bts_otis_blk" )
        {
            player_class = PM::OTIS;
        }

        player.GetUserData()["pm"] = model;
        player.GetUserData()["class"] = player_class;

        // Hide flashlight icon.
        player.m_iHideHUD |= HIDEHUD_FLASHLIGHT;

        player.pev.armortype = ( player_class == PM::HELMET ? 100 : 50 );

        // Re-Deploy weapon to update view model hands
        if( player.m_hActiveItem.IsValid() )
        {
            CBaseEntity@ active_item = player.m_hActiveItem.GetEntity();

            if( active_item !is null )
            {
                CBasePlayerItem@ weapon = cast<CBasePlayerItem@>( active_item );

                if( weapon !is null )
                {
                    weapon.Deploy();
                }
            }
        }
    }

    // Return a player model for the given class
    const string& model( const PM player_class )
    {
        switch( player_class )
        {
            case PM::SCIENTIST:
            {
                mdl_scientist_last = ( mdl_scientist_last >= mdl_scientist.length() - 1 ) ? 0 : mdl_scientist_last + 1;
                return mdl_scientist[mdl_scientist_last];
            }
            case PM::CONSTRUCTION:
            {
                mdl_con_last = ( mdl_con_last >= mdl_con.length() - 1 ) ? 0 : mdl_con_last + 1;
                return mdl_con[mdl_con_last];
            }
            case PM::BARNEY:
            {
                mdl_barney_last = ( mdl_barney_last >= mdl_barney.length() - 1 ) ? 0 : mdl_barney_last + 1;
                return mdl_barney[mdl_barney_last];
            }
            case PM::OPERATIVE:
            {
                mdl_operative_last = ( mdl_operative_last >= mdl_operative.length() - 1 ) ? 0 : mdl_operative_last + 1;
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
