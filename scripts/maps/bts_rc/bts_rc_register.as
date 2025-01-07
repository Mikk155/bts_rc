/*
    Author: Mikk
*/

#include "utils/main"
#include "entities/main"
#include "gamemodes/main"
#include "Hooks/main"

#include "list_weapons"
#include "mappings"
#include "monsters/npc_ammo"

void MapStart()
{
    #if SERVER
        g_Logger.info( "Map entities {}/{}", { g_EngineFuncs.NumberOfEntities(), g_Engine.maxEntities } );
    #endif
}

void MapActivate()
{
    BTS_RC::MapActivate(); //Objective code debug
}

void MapInit()
{
    #if SERVER
        LoggerLevel = ( Warning | Debug | Info | Critical | Error );
    #endif

    g_VoiceResponse.init();
    g_sentry_laser.turn_on();

    RegisterPointCheckPointEntity();

    RegisterBTSRCWeapons(); //Custom weapons registered

    BTS_RC::ObjectiveInit(); //Objective indicator registered

    g_ClassicMode.ForceItemRemap( true );
    g_ClassicMode.SetItemMappings( @g_AmmoReplacement );

    /*==========================================================================
    *   - Start of precaching
    ==========================================================================*/
    precache::sound( CONST_HEV_NIGHTVISION_ON );
    precache::sound( CONST_HEV_NIGHTVISION_OFF );
    precache::sound( CONST_HEV_NIGHTVISION_NO_POWER );

    precache::sounds( CONST_BLOODPUDDLE_SND );

    precache::model( CONST_BLOODPUDDLE );
    precache::model( CONST_SENTRY_LASER_MODEL );
    precache::model( CONST_SENTRY_LASER_MODEL2 );
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
    /*==========================================================================
    *   - End
    ==========================================================================*/
}
