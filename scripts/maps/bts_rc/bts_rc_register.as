/*
    Author: Mikk
*/

#include "utils/main"
#include "entities/main"
#include "gamemodes/main"
#include "Hooks/main"
#include "weapons/main"

void MapActivate()
{
#if SERVER
    g_Logger.info( "Map entities {}/{}", { g_EngineFuncs.NumberOfEntities(), g_Engine.maxEntities } );
#endif

    g_sentry_laser.map_activate();
    BTS_RC_ERTY::MapActivate();
}

void MapInit()
{
#if SERVER
    LoggerLevel = ( Warning | Debug | Info | Critical | Error );
#endif

    g_VoiceResponse.init();

    RegisterPointCheckPointEntity();

    RegisterBTSRCWeapons(); //Custom weapons registered

    /*==========================================================================
    *   - Start of custom entities
    ==========================================================================*/
    g_CustomEntityFuncs.RegisterCustomEntity( "env_bloodpuddle::env_bloodpuddle", "env_bloodpuddle" );
    g_CustomEntityFuncs.RegisterCustomEntity( "func_bts_recharger::func_bts_recharger", "func_bts_recharger" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_npc", "randomizer_npc" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_item", "randomizer_item" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_hull", "randomizer_hull" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_boss", "randomizer_boss" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_wave", "randomizer_wave" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_headcrab", "randomizer_headcrab" );
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_update_class::trigger_update_class", "trigger_update_class" );
    g_CustomEntityFuncs.RegisterCustomEntity( "bts_items::item_bts_armorvest", "item_bts_armorvest" );
    g_CustomEntityFuncs.RegisterCustomEntity( "bts_items::item_bts_helmet", "item_bts_helmet" );
    g_CustomEntityFuncs.RegisterCustomEntity( "bts_items::item_bts_hevbattery", "item_bts_hevbattery" );
    g_CustomEntityFuncs.RegisterCustomEntity( "bts_items::item_bts_sprayaid", "item_bts_sprayaid" );
#if SERVER
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_logger::trigger_logger", "trigger_logger" );
#endif
    g_CustomEntityFuncs.RegisterCustomEntity( "M79_ROCKET::CM79Rocket", "m79_rocket" );
    g_CustomEntityFuncs.RegisterCustomEntity( "FLARE::CFlare", "flare" );
    g_CustomEntityFuncs.RegisterCustomEntity( "DART::CDart", "gun_dart" );
    /*==========================================================================
    *   - End
    ==========================================================================*/

    g_ClassicMode.ForceItemRemap( true );
    g_ClassicMode.SetItemMappings( @g_AmmoReplacement );

    /*==========================================================================
    *   - Start of precaching
    ==========================================================================*/
    g_SoundSystem.PrecacheSound( "bts_rc/items/nvg_on.wav" );
    g_SoundSystem.PrecacheSound( "bts_rc/items/nvg_off.wav" );
    g_SoundSystem.PrecacheSound( "items/suitchargeno1.wav" );
    g_SoundSystem.PrecacheSound( "vox/user.wav" );
    g_SoundSystem.PrecacheSound( "vox/security.wav" );
    g_SoundSystem.PrecacheSound( "vox/research.wav" );
    g_SoundSystem.PrecacheSound( "vox/maintenance.wav" );
    g_SoundSystem.PrecacheSound( "vox/authorized.wav" );

    g_Game.PrecacheModel( "models/w_security.mdl" );
    g_Game.PrecacheModel( "models/tool_box.mdl" );
    g_Game.PrecacheModel( "sprites/bts_rc/inv_card_security.spr" );
    g_Game.PrecacheModel( "sprites/bts_rc/inv_card_research.spr" );
    g_Game.PrecacheModel( "sprites/bts_rc/inv_card_maint.spr" );

#if DISCARDED
    for( uint ui = 0; ui < CONST_BLOODPUDDLE_SND.length(); ui++ )
        g_SoundSystem.PrecacheSound( CONST_BLOODPUDDLE_SND[ui] );
#endif

    for( uint ui = 0; ui < BloodSplash::Red.length(); ui++ )
        g_Game.PrecacheModel( BloodSplash::Red[ui] );

    for( uint ui = 0; ui < BloodSplash::Yellow.length(); ui++ )
        g_Game.PrecacheModel( BloodSplash::Yellow[ui] );

    g_Game.PrecacheOther( "item_bts_hevbattery" );
    g_Game.PrecacheOther( "item_bts_sprayaid" );
    g_Game.PrecacheOther( "m79_rocket" );
    g_Game.PrecacheOther( "flare" );
    g_Game.PrecacheOther( "gun_dart" );

#if SERVER
    g_Game.PrecacheOther( "monster_headcrab" );
    g_Game.PrecacheOther( "item_bts_armorvest" );
    g_Game.PrecacheOther( "item_bts_helmet" );
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
