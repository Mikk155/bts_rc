/*
    Author: Mikk
*/

#include "utils/main"
#include "entities/main"
#include "gamemodes/main"
#include "Hooks/main"
#include "items/main"

#include "list_weapons"
#include "mappings"

void MapStart()
{
#if TEST
    BTS_MEDKIT::MapStart();
#endif
}

void MapActivate()
{
#if DEVELOP
    g_Logger.info( "Map entities {}/{}", { g_EngineFuncs.NumberOfEntities(), g_Engine.maxEntities } );
#endif

    g_sentry_laser.map_activate();
}

void MapInit()
{
#if DEVELOP
    LoggerLevel = ( Warning | Debug | Info | Critical | Error );
#endif

    g_VoiceResponse.init();

    bts_items::register();

    RegisterPointCheckPointEntity();

    RegisterBTSRCWeapons(); //Custom weapons registered

    g_ClassicMode.ForceItemRemap( true );
    g_ClassicMode.SetItemMappings( @g_AmmoReplacement );

    /*==========================================================================
    *   - Start of precaching
    ==========================================================================*/
    g_SoundSystem.PrecacheSound( CONST_HEV_NIGHTVISION_ON );
    g_SoundSystem.PrecacheSound( CONST_HEV_NIGHTVISION_OFF );
    g_SoundSystem.PrecacheSound( CONST_HEV_NIGHTVISION_NO_POWER );

#if DISCARDED
    for( uint ui = 0; ui < CONST_BLOODPUDDLE_SND.length(); ui++ )
        g_SoundSystem.PrecacheSound( CONST_BLOODPUDDLE_SND[ui] );
#endif

    for( uint ui = 0; ui < BloodSplash::Red.length(); ui++ )
        g_Game.PrecacheModel( BloodSplash::Red[ui] );

    for( uint ui = 0; ui < BloodSplash::Yellow.length(); ui++ )
        g_Game.PrecacheModel( BloodSplash::Yellow[ui] );

#if DEVELOP
    g_Game.PrecacheOther( "monster_headcrab" );
    g_Game.PrecacheOther( "item_bts_armorvest" );
#endif

    /*==========================================================================
    *   - End
    ==========================================================================*/

    /*==========================================================================
    *   - Start of hooks
    ==========================================================================*/
    g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @player_think );
    g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @player_takedamage );
    g_Hooks.RegisterHook( Hooks::Monster::MonsterKilled, @monster_killed );
    g_Hooks.RegisterHook( Hooks::Monster::MonsterTakeDamage, @monster_takedamage );

    // Remove this shit in 5.27.
    if( g_Game.GetGameVersion() == 526 )
    {
        g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @notice_assets::player_connect );
    }

    /*==========================================================================
    *   - End
    ==========================================================================*/
}
