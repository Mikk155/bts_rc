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

#if SERVER
// All the weapons used in the map.
array<string> weapons = {
    "weapon_medkit"
};
#endif

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

    /*==========================================================================
    *   - Start of hooks
    ==========================================================================*/
    g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @PlayerThink );
    /*==========================================================================
    *   - End
    ==========================================================================*/
}

HookReturnCode PlayerThink( CBasePlayer@ player )
{
    if( player !is null && player.IsConnected() )
    {
        dictionary@ user_data = player.GetUserData();

#if SERVER
        if( player.pev.impulse == 101 && g_EngineFuncs.CVarGetFloat( "sv_cheats" ) > 0 && g_PlayerFuncs.AdminLevel( player ) >= ADMIN_YES )
        {
            for( uint ui = 0; ui < weapons.length(); ui++ )
            {
                player.GiveNamedItem( weapons[ui] );
            }
            player.pev.impulse = 0;
        }
#endif

#if FALSE // -TODO Idk how the fuck do this xd @rizulix
        /*==========================================================================
        *   - Start of custom arms on vanilla weapons
        ==========================================================================*/
        EHandle hActiveItem = player.m_hActiveItem;

        if( hActiveItem.IsValid() )
        {
            CBaseEntity@ active_item = hActiveItem.GetEntity();

            if( active_item !is null )
            {
                CBasePlayerWeapon@ weapon = cast<CBasePlayerWeapon@>( active_item );

                if( weapon !is null )
                {
                    if( weapon.pev.classname == "weapon_medkit" )
                    {
                        weapon.pev.body = weapon.SetBodygroup( 1, 3 );
                        g_Logger.warn( "Active valid? {}", { weapon.pev.body } );
                    }
                }
            }
        }
        /*==========================================================================
        *   - End
        ==========================================================================*/
#endif

        switch( g_PlayerClass[ player, true ] )
        {
            /*==========================================================================
            *   - Start of Helmet night vision
            ==========================================================================*/
            case PM::HELMET:
            {
                if( !user_data.exists( "helmet_nv_state" ) )
                    break;

                int state = int( user_data[ "helmet_nv_state" ] );

                // Catch impulse commands and toggle night vision state
                if( player.pev.impulse == 100 )
                {
                    user_data[ "helmet_nv_state" ] = ( state == 1 ? 0 : 1 );

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
                        user_data[ "helmet_nv_state" ] = 0;
                    }
                }
                break;
            }
            /*==========================================================================
            *   - End
            ==========================================================================*/
        }
    }

    return HOOK_CONTINUE;
}
