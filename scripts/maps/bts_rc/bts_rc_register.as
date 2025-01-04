/*
    Black Mesa Training Simulation - Resonance Cascade

    - AraseFiq
        - Script general and initial idea for these features
    - Mikk155
        - Various
    - Rizulix
        - Weapons, Item tracker
    - Gaftherman
        - Item tracker
    - KernCore
        - Various code references
    - Nero0
        - Ditto
    - Solokiller
        - Help Support
    - H²
        - Ditto
    - Adambean
        - Objetive indicator
    - Hezus
        - Ditto
    - GeckoN
        - Ditto

    MIT License Copyright (c)

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
*/

/*
#define LOGGERS
This doesn't work so to enable loggers find all "#if LOGGERS" and replace to "#if SERVER"
*/

#include "utils/main"

// Entities
#include "entities/randomizer"
#include "entities/trigger_script"
#include "entities/trigger_update_class"

#include "player_voices"

#include "game_item_tracker"
#include "list_weapons"
#include "mappings"
#include "monsters/npc_ammo"
#include "point_checkpoint"
#include "objective_indicator"

void MapStart()
{
#if SERVER
    g_Logger.info( "Map entities {}/{}", { g_EngineFuncs.NumberOfEntities(), g_Engine.maxEntities } );
#endif
}

void MapActivate()
{
    SetupItemTracker();
    BTS_RC::MapActivate(); //Objective code debug
}

void MapInit()
{
#if SERVER
    LoggerLevel = ( Warning | Debug | Info | Critical | Error );
#endif

    g_VoiceResponse.init();

    RegisterItemTracker();

    RegisterPointCheckPointEntity();

    RegisterBTSRCWeapons(); //Custom weapons registered

    BTS_RC::ObjectiveInit(); //Objective indicator registered

    g_ClassicMode.ForceItemRemap( true );
    g_ClassicMode.SetItemMappings( @g_AmmoReplacement );

    /*==========================================================================
    *   - Start of precaching
    ==========================================================================*/
    precache::sound( "items/flashlight2.wav" );
    precache::sound( "player/hud_nightvision.wav" );
    /*==========================================================================
    *   - End
    ==========================================================================*/

    // Size the array to the number of slots
    for( int i = 0; i < g_Engine.maxClients; i++ )
    {
        players_origin.insertLast( g_vecZero );
    }

    /*==========================================================================
    *   - Start of hooks
    ==========================================================================*/
    g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @PlayerThink );
    /*==========================================================================
    *   - End
    ==========================================================================*/
}

/*==========================================================================
*   - Start of Voice Responses
==========================================================================*/

array<Vector> players_origin;

/*==========================================================================
*   - End
==========================================================================*/

HookReturnCode PlayerThink( CBasePlayer@ player )
{
    if( player !is null && player.IsConnected() )
    {
        // Save last origin for interpreting if there's a player nearby
        players_origin[ player.entindex() -1 ] = player.pev.origin;

        /*==========================================================================
        *   - Start of Night Vision
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
        *   - End
        ==========================================================================*/
    }

    return HOOK_CONTINUE;
}
