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
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_update_class::trigger_update_class", "trigger_update_class" );
#if SERVER
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_logger::trigger_logger", "trigger_logger" );
#endif

    // Randomizer
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_npc", "randomizer_npc" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_item", "randomizer_item" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_hull", "randomizer_hull" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_boss", "randomizer_boss" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_wave", "randomizer_wave" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_headcrab", "randomizer_headcrab" );

    // Items
    g_CustomEntityFuncs.RegisterCustomEntity( "bts_items::item_bts_armorvest", "item_bts_armorvest" );
    g_CustomEntityFuncs.RegisterCustomEntity( "bts_items::item_bts_helmet", "item_bts_helmet" );
    g_CustomEntityFuncs.RegisterCustomEntity( "bts_items::item_bts_hevbattery", "item_bts_hevbattery" );
    g_CustomEntityFuncs.RegisterCustomEntity( "bts_items::item_bts_sprayaid", "item_bts_sprayaid" );

    // Projectiles
    g_CustomEntityFuncs.RegisterCustomEntity( "M79_ROCKET::CM79Rocket", "m79_rocket" );
    g_CustomEntityFuncs.RegisterCustomEntity( "FLARE::CFlare", "flare" );
    g_CustomEntityFuncs.RegisterCustomEntity( "DART::CDart", "gun_dart" );


    // Weapons
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_AXE::weapon_bts_axe", "weapon_bts_axe" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_axe", "bts_rc/weapons" );

    g_CustomEntityFuncs.RegisterCustomEntity( "HL_BERETTA::weapon_bts_beretta", "weapon_bts_beretta" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_BERETTA::ammo_bts_beretta", "ammo_bts_beretta" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_BERETTA::ammo_bts_beretta_battery", "ammo_bts_beretta_battery" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_beretta", "bts_rc/weapons", "9mm", "bts:battery", "ammo_bts_beretta", "ammo_bts_beretta_battery" );

    g_CustomEntityFuncs.RegisterCustomEntity( "HL_CROWBAR::weapon_bts_crowbar", "weapon_bts_crowbar" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_crowbar", "bts_rc/weapons" );

    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_DEAGLE::weapon_bts_eagle", "weapon_bts_eagle" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_DEAGLE::ammo_bts_eagle", "ammo_bts_eagle" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_DEAGLE::ammo_bts_eagle_battery", "ammo_bts_eagle_battery" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_DEAGLE::ammo_bts_eagle", "ammo_bts_dreagle" ); 
    g_ItemRegistry.RegisterWeapon( "weapon_bts_eagle", "bts_rc/weapons", "357", "bts:battery", "ammo_bts_eagle", "ammo_bts_eagle_battery" );

    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLARE::weapon_bts_flare", "weapon_bts_flare" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_flare", "bts_rc/weapons", "weapon_bts_flare", "", "weapon_bts_flare", "" );

    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLAREGUN::weapon_bts_flaregun", "weapon_bts_flaregun" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLAREGUN::ammo_bts_flarebox", "ammo_bts_flarebox" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_flaregun", "bts_rc/weapons", "bts:flare", "", "ammo_bts_flarebox", "" );

    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLASHLIGHT::weapon_bts_flashlight", "weapon_bts_flashlight" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLASHLIGHT::ammo_bts_battery", "ammo_bts_battery" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_flashlight", "bts_rc/weapons", "bts:battery", "", "ammo_bts_battery", "" );

    g_CustomEntityFuncs.RegisterCustomEntity( "HL_GLOCK::weapon_bts_glock", "weapon_bts_glock" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_GLOCK::ammo_bts_glock", "ammo_bts_glock" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_glock", "bts_rc/weapons", "9mm", "", "ammo_bts_glock", "" );

    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_GLOCK17F::weapon_bts_glock17f", "weapon_bts_glock17f" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_GLOCK17F::ammo_bts_glock17f", "ammo_bts_glock17f" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_GLOCK17F::ammo_bts_glock17f_battery", "ammo_bts_glock17f_battery" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_glock17f", "bts_rc/weapons", "9mm", "bts:battery", "ammo_bts_glock17f", "ammo_bts_glock17f_battery" );

    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_GLOCK18::weapon_bts_glock18", "weapon_bts_glock18" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_GLOCK18::ammo_bts_glock18", "ammo_bts_glock18" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_glock18", "bts_rc/weapons", "9mm", "", "ammo_bts_glock18", "" );

    g_CustomEntityFuncs.RegisterCustomEntity( "HL_GLOCKSD::weapon_bts_glocksd", "weapon_bts_glocksd" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_GLOCKSD::ammo_bts_glocksd", "ammo_bts_glocksd" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_GLOCKSD::ammo_bts_glocksd", "ammo_bts_dglocksd" ); // ammo drop case
    g_ItemRegistry.RegisterWeapon( "weapon_bts_glocksd", "bts_rc/weapons", "9mm", "", "ammo_bts_glocksd", "" );

    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_KNIFE::weapon_bts_knife", "weapon_bts_knife" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_knife", "bts_rc/weapons" );

    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_HANDGRENADE::weapon_bts_handgrenade", "weapon_bts_handgrenade" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_handgrenade", "bts_rc/weapons", "Hand Grenade", "", "weapon_bts_handgrenade", "" );

    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M4::weapon_bts_m4", "weapon_bts_m4" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M4::ammo_bts_m4", "ammo_bts_m4" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M4::ammo_bts_m4", "ammo_bts_556mag" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_m4", "bts_rc/weapons", "556", "", "ammo_bts_m4", "" );

    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M4SD::weapon_bts_m4sd", "weapon_bts_m4sd" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M4SD::ammo_bts_m4sd", "ammo_bts_m4sd" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_m4sd", "bts_rc/weapons", "556", "", "ammo_bts_m4sd", "" );

    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M16A3::weapon_bts_m16", "weapon_bts_m16" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M16A3::ammo_bts_m16", "ammo_bts_m16" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M16A3::ammo_bts_m16", "ammo_bts_556round" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M16A3::ammo_bts_m16_grenade", "ammo_bts_m16_grenade" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_m16", "bts_rc/weapons", "556", "ARgrenades", "ammo_bts_m16", "ammo_bts_m16_grenade" );

    g_CustomEntityFuncs.RegisterCustomEntity( "HL_M79::weapon_bts_m79", "weapon_bts_m79" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_M79::ammo_bts_m79", "ammo_bts_m79" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_m79", "bts_rc/weapons", "ARgrenades", "", "ammo_bts_m79", "" );

    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_MEDKIT::weapon_bts_medkit", "weapon_bts_medkit" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_medkit", "bts_rc/weapons", "health", "", "ammo_medkit" );

    g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5GL::weapon_bts_mp5gl", "weapon_bts_mp5gl" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5GL::ammo_bts_mp5gl", "ammo_bts_mp5gl" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5GL::ammo_bts_mp5gl", "ammo_bts_9mmbox" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5GL::ammo_bts_mp5gl_grenade", "ammo_bts_mp5gl_grenade" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_mp5gl", "bts_rc/weapons", "9mm", "ARgrenades", "ammo_bts_mp5gl", "ammo_bts_mp5gl_grenade" );

    g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5::weapon_bts_mp5", "weapon_bts_mp5" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5::ammo_bts_mp5", "ammo_bts_mp5" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5::ammo_bts_mp5", "ammo_bts_dmp5" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_mp5", "bts_rc/weapons", "9mm", "", "ammo_bts_mp5", "" );

    g_CustomEntityFuncs.RegisterCustomEntity( "HL_PIPE::weapon_bts_pipe", "weapon_bts_pipe" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_pipe", "bts_rc/weapons" );

    g_CustomEntityFuncs.RegisterCustomEntity( "HL_POOLSTICK::weapon_bts_poolstick", "weapon_bts_poolstick" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_poolstick", "bts_rc/weapons" );

    g_CustomEntityFuncs.RegisterCustomEntity( "CPython::weapon_bts_python", "weapon_bts_python" ); // 357 Colt Python Revolver
    g_CustomEntityFuncs.RegisterCustomEntity( "CPython::ammo_bts_python", "ammo_bts_python" ); // 357 Ammo Rounds
    g_CustomEntityFuncs.RegisterCustomEntity( "CPython::ammo_bts_python", "ammo_bts_357cyl" ); // 357 Ammo Drop by NPCs
    g_ItemRegistry.RegisterWeapon( "weapon_bts_python", "bts_rc/weapons", "357", "", "ammo_bts_python", "" ); // Register all of them here

    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SHOTGUN::weapon_bts_shotgun", "weapon_bts_shotgun" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SHOTGUN::ammo_bts_shotgun", "ammo_bts_shotgun" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SHOTGUN::ammo_bts_shotgun", "ammo_bts_shotshell" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_shotgun", "bts_rc/weapons", "buckshot", "", "ammo_bts_shotgun", "" );

    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_UZI::weapon_bts_uzi", "weapon_bts_uzi" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_UZI::ammo_bts_uzi", "ammo_bts_uzi" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_uzi", "bts_rc/weapons", "9mm", "", "ammo_bts_uzi", "" );

    g_CustomEntityFuncs.RegisterCustomEntity( "CM249::weapon_bts_saw", "weapon_bts_saw" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CM249::ammo_bts_saw", "ammo_bts_saw" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CM249::ammo_bts_saw", "ammo_bts_dsaw" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_saw", "bts_rc/weapons", "556", "", "ammo_bts_saw", "" );

    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SBSHOTGUN::weapon_bts_sbshotgun", "weapon_bts_sbshotgun" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SBSHOTGUN::ammo_bts_sbshotgun", "ammo_bts_sbshotgun" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SBSHOTGUN::ammo_bts_sbshotgun_battery", "ammo_bts_sbshotgun_battery" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_sbshotgun", "bts_rc/weapons", "buckshot", "bts:battery", "ammo_bts_sbshotgun", "ammo_bts_sbshotgun_battery" );

    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SCREWDRIVER::weapon_bts_screwdriver", "weapon_bts_screwdriver" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_screwdriver", "bts_rc/weapons" );

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
