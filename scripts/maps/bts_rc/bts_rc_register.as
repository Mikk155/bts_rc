//Black Mesa Training Simulation - Resonance Cascade
//Credits:-
//Map Design: RaptorSKA
//Models: Valve, Gearbox Software, MTB, KernCore, ZikShadow, MiroSklenar, HAPE B, Ixnay, Organic700, DAVLevels, Sven Co-op Teams
//Scripts: KernCore, Nero0, Solokiller, H², Rizulix, Mikk155, Gaftherman, RaptorSKA, Valve, Gearbox Software
//Sound: Valve, Gearbox Software, MTB, LIL-PIF, KernCore, ZikShadow, TurtleRock Studios, Sven Co-op Teams
//Sprites: Valve, Gearbox Software, KernCore, KEZÆIV, ZikShadow, MiroSklenar, Ixnay, Organic700, DAVLevels, Sven Co-op Teams
//Hands Sleeve Difference based on Playermodels code: KernCore & Mikk155
//Bullet Wallpuff Code: KernCore, Rizulix

#include "utils/main"

#include "entities/randomizer"

#include "trigger_script/survival"

#include "game_item_tracker"
#include "list_weapons"
#include "mappings"
#include "monsters/npc_ammo"
#include "point_checkpoint"
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
    LoggerLevel = ( Warning | Debug | Info | Critical | Error );

    randomizer::register();

    RegisterItemTracker();

    RegisterPointCheckPointEntity();

    RegisterBTSRCWeapons(); //Custom weapons registered

    BTS_RC::ObjectiveInit(); //Objective indicator registered

    g_ClassicMode.ForceItemRemap( true );
    g_ClassicMode.SetItemMappings( @g_AmmoReplacement );

    /*==========================================================================
    *
    *   - START OF PRECACHE
    *
    ==========================================================================*/

    precache::sound( "items/flashlight2.wav" );
    precache::sound( "player/hud_nightvision.wav" );

    /*==========================================================================
    *
    *   - END OF PRECACHE
    *
    ==========================================================================*/

    /*==========================================================================
    *
    *   - START OF HOOKS
    *
    ==========================================================================*/

    g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @PlayerThink );

    /*==========================================================================
    *
    *   - END OF HOOKS
    *
    ==========================================================================*/
}

HookReturnCode PlayerThink( CBasePlayer@ player )
{
    if( player !is null && player.IsConnected() )
    {
        /*==========================================================================
        *
        *   - START OF NIGHT VISION
        *
        ==========================================================================*/

        CustomKeyvalues@ kvd = player.GetCustomKeyvalues();

        int state = kvd.GetKeyvalue( "$i_nightvision_state" ).GetInteger();

        if( g_EngineFuncs.GetInfoKeyBuffer( player.edict() ).GetValue( "model" ) == "bts_helmet" )
        {
            // Catch impulse commands and toggle night vision state
            if( player.pev.impulse == 100 )
            {
                g_EntityFuncs.DispatchKeyValue( player.edict(), "$i_nightvision_state", ( state == 1 ? 0 : 1 ) );

                g_PlayerFuncs.ScreenFade( player, Vector( 250, 200, 20 ), 1.0f, 0.5f, 255.0f, state == 0 ? 6 : 2 );

                g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, ( state == 1 ? "items/flashlight2.wav" : "player/hud_nightvision.wav" ), 1.0, ATTN_NORM, 0, PITCH_NORM );
            }

            // Night vision ON, drain and light
            if( state == 1 )
            {
                // Show even when dead lying.
                if( !player.GetObserver().IsObserver() )
                {
                    NetworkMessage m( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, player.edict() );
                        m.WriteByte( TE_DLIGHT );
                        m.WriteCoord(player.pev.origin.x);
                        m.WriteCoord(player.pev.origin.y);
                        m.WriteCoord(player.pev.origin.z);
                        m.WriteByte(40);
                        m.WriteByte(255);
                        m.WriteByte(255);
                        m.WriteByte(255);
                        m.WriteByte(2);
                        m.WriteByte(1);
                    m.End();
                }
                else
                {
                    g_PlayerFuncs.ScreenFade( player, g_vecZero, 0.0f, 0.0f, 0.0f, ( FFADE_OUT | FFADE_STAYOUT ) );
                    g_EntityFuncs.DispatchKeyValue( player.edict(), "$i_nightvision_state", 0 );
                }
            }
        }
        // Player changed his model. Turn off night vision.
        else if( state == 1 )
        {
            g_PlayerFuncs.ScreenFade( player, g_vecZero, 0.0f, 0.0f, 0.0f, ( FFADE_OUT | FFADE_STAYOUT ) );
            g_EntityFuncs.DispatchKeyValue( player.edict(), "$i_nightvision_state", 0 );
        }
        /*==========================================================================
        *
        *   - END OF NIGHT VISION
        *
        ==========================================================================*/
    }

    return HOOK_CONTINUE;
}
