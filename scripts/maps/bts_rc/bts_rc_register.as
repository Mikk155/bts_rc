//Black Mesa Training Simulation - Resonance Cascade
//Credits:-
//Map Design: RaptorSKA
//Models: Valve, Gearbox Software, MTB, KernCore, ZikShadow, MiroSklenar, HAPE B, Ixnay, Organic700, DAVLevels, Sven Co-op Teams
//Scripts: KernCore, Nero0, Solokiller, H², Rizulix, Mikk155, Gaftherman, RaptorSKA, Valve, Gearbox Software
//Sound: Valve, Gearbox Software, MTB, LIL-PIF, KernCore, ZikShadow, TurtleRock Studios, Sven Co-op Teams
//Sprites: Valve, Gearbox Software, KernCore, KEZÆIV, ZikShadow, MiroSklenar, Ixnay, Organic700, DAVLevels, Sven Co-op Teams
//Hands Sleeve Difference based on Playermodels code: KernCore & Mikk155
//Bullet Wallpuff Code: KernCore, Rizulix

#include "entities/randomizer"

#include "trigger_script/survival"

#include "game_item_tracker"
#include "list_weapons"
#include "mappings"
#include "player_voices/player_voices"
#include "monsters/npc_ammo"
#include "point_checkpoint"
//#include "selective_nvg" < Broken -Sniper's fan
#include "objective_indicator"

void MapStart()
{
	g_Log.PrintF( "Max entities: %1\nNumber of entities in bsp: %2", g_Engine.maxEntities, g_EngineFuncs.NumberOfEntities() );
}

void MapActivate()
{
	randomizer::unregister();

	SetupItemTracker();
	BTS_RC::MapActivate(); //Objective code debug
}

void MapInit()
{
	randomizer::register();

	RegisterItemTracker();

	RegisterPointCheckPointEntity();

	RegisterBTSRCWeapons(); //Custom weapons registered

	BTS_RC::ObjectiveInit(); //Objective indicator registered

	g_ClassicMode.ForceItemRemap( true );
	g_ClassicMode.SetItemMappings( @g_AmmoReplacement );

	//Hooks
	g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PLAYER_VOICES::BTSRC_PlayerSpawn );
	g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @PLAYER_VOICES::BTSRC_PlayerKilled );
	g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @PLAYER_VOICES::BTSRC_PlayerPostThink );
	g_Hooks.RegisterHook( Hooks::Monster::MonsterKilled, @NPC_DROPAMMO::BTSRC_MonsterKilled );

	//Sound Precache
	PLAYER_VOICES::BTSRC_PrecachePlayerSounds();
}