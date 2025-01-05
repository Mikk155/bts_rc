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
#define DEVELOP
This doesn't work so to enable loggers and other features find all "#if SERVER" and replace to "#if SERVER"
*/

#include "utils/main"

// Entities
#include "entities/env_bloodpuddle"
#include "entities/game_item_tracker"
#include "entities/point_checkpoint"
#include "entities/randomizer"
#include "entities/trigger_script"
#include "entities/trigger_update_class"

#include "player_voices"

#include "list_weapons"
#include "mappings"
#include "monsters/npc_ammo"
#include "objective_indicator"

void MapStart()
{
#if SERVER
    g_Logger.info( "Map entities {}/{}", { g_EngineFuncs.NumberOfEntities(), g_Engine.maxEntities } );
#endif
}

void MapActivate()
{
    game_item_tracker::SetupItemTracker();
    BTS_RC::MapActivate(); //Objective code debug
}

void MapInit()
{
#if SERVER
    LoggerLevel = ( Warning | Debug | Info | Critical | Error );
#endif

    g_VoiceResponse.init();

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

    precache::model( CONST_BLOODPUDDLE );
    /*==========================================================================
    *   - End
    ==========================================================================*/

    /*==========================================================================
    *   - Start of hooks
    ==========================================================================*/
    g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @PlayerThink );
    g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage );
    g_Hooks.RegisterHook( Hooks::Monster::MonsterKilled, @MonsterKilled );
    g_Hooks.RegisterHook( Hooks::Monster::MonsterTakeDamage, @MonsterTakeDamage );
    /*==========================================================================
    *   - End
    ==========================================================================*/
}

HookReturnCode PlayerThink( CBasePlayer@ player )
{
    if( player !is null && player.IsConnected() )
    {

#if SERVER
        // Change impulse 101 command with our own weapons.
        check_impulse_101(player);
#endif

        // Do not update the class here, Only weapons should do that so we assume the game hasn't started yet.
        const PM player_class = g_PlayerClass[ player, true ];

        // Clases not yet set? Then there's nothing to do here.
        if( player_class == PM::UNSET )
        {
            return HOOK_CONTINUE;
        }

        dictionary@ user_data = player.GetUserData();

        switch( player_class )
        {
            /*==========================================================================
            *   - Start of Helmet night vision
            ==========================================================================*/
            case PM::HELMET:
            {
                int state = int( user_data[ "helmet_nv_state" ] );

                // Not enough power, Shut down
                if( player.pev.armorvalue <= 0 )
                {
                    if( state == 1 )
                    {
                        g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, CONST_HEV_NIGHTVISION_OFF, 1.0, ATTN_NORM, 0, PITCH_NORM );
                        g_PlayerFuncs.ScreenFade( player, Vector( 250, 200, 20 ), 1.0f, 0.5f, 255.0f, 2 );
                    }
                    else if( player.pev.impulse == 100 )
                    {
                        g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, CONST_HEV_NIGHTVISION_NO_POWER, 1.0, ATTN_NORM, 0, PITCH_NORM );
                    }

                    user_data[ "helmet_nv_state" ] = state = 0;
                }
                // Catch impulse command and toggle night vision state
                else if( player.pev.impulse == 100 )
                {
                    user_data[ "helmet_nv_state" ] = ( state == 1 ? 0 : 1 );

                    g_PlayerFuncs.ScreenFade( player, Vector( 250, 200, 20 ), 1.0f, 0.5f, 255.0f, state == 0 ? 6 : 2 );

                    g_SoundSystem.EmitSoundDyn(
                        player.edict(),
                        CHAN_WEAPON,
                        ( state == 1 ? CONST_HEV_NIGHTVISION_OFF : CONST_HEV_NIGHTVISION_ON ),
                        1.0,
                        ATTN_NORM,
                        0,
                        PITCH_NORM
                    );
                }

                // Night vision ON, drain and light.
                if( state == 1 )
                {
                    // Show even when dead lying.
                    if( !player.GetObserver().IsObserver() )
                    {
                        if( float( user_data[ "helmet_nv_drain" ] ) <= g_Engine.time )
                        {
                            player.pev.armorvalue--;
                            // -TODO Find a nice drain time
                            user_data[ "helmet_nv_drain" ] = 4.5 + g_Engine.time;
#if SERVER
                            g_Logger.debug( "HEV Battery of {} at {}", { player.pev.netname, player.pev.armorvalue } );
#endif
                        }

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

                player.m_iFlashBattery = int(Math.max( 1, player.pev.armorvalue ));

                // Update HUD
                NetworkMessage m( MSG_ONE, NetworkMessages::Flashlight, player.edict() );
                    m.WriteByte( state );
                    m.WriteByte(player.m_iFlashBattery);
                m.End();

                break;
            }
            /*==========================================================================
            *   - End
            ==========================================================================*/
        }

        // Deny flashlight as we use our own.
        if( player.pev.impulse == 100 )
        {
            player.pev.impulse = 0;
        }
    }

    return HOOK_CONTINUE;
}

HookReturnCode PlayerTakeDamage( DamageInfo@ pDamageInfo )
{
    CBaseEntity@ victim = pDamageInfo.pVictim;

    if( victim !is null )
    {
        CBasePlayer@ player = cast<CBasePlayer@>( victim );

        if( player !is null )
        {
            if( cvar_player_voices.GetInt() == 0 )
            {
                CVoices@ voices = g_VoiceResponse[ player ];

                if( voices !is null )
                {
                    if( player.pev.waterlevel == WATERLEVEL_HEAD )
                    {
                        if( voices.drowndamage !is null )
                        {
                            voices.drowndamage.PlaySound( player );
                        }
                    }
                    else
                    {
                        if( voices.takedamage !is null )
                        {
                            voices.takedamage.PlaySound( player );
                        }
                    }
                }
            }
        }
    }
    return HOOK_CONTINUE;
}

HookReturnCode MonsterKilled( CBaseMonster@ monster, CBaseEntity@ attacker, int iGib )
{
    if( monster !is null )
    {
        dictionary@ user_data = monster.GetUserData();

        // Spawn stuff if there are enough free edicts
        if( freeedicts( 1 ) )
        {
            if( monster.pev.classname == "monster_zombie" )
            {
                // Check if the stored received damage is less than a headcrab's HP

                const float headcrab_health = g_EngineFuncs.CVarGetFloat( "sk_headcrab_health" );
                const float headcrab_damage = int(user_data[ "headcrab_damage" ]);

                if( headcrab_damage < headcrab_health )
                {
                    monster.SetBodygroup( 1, 1 );
                }

                // This model does have an extra bodygroup for the headcrab or was gibbed
                if( monster.GetBodygroup( 1 ) == 1 || iGib == GIB_ALWAYS )
                {
                    CBaseEntity@ headcrab = g_EntityFuncs.Create( "monster_headcrab", monster.pev.origin + Vector( 0, 0, 72 ), monster.pev.angles, false, monster.edict() );

                    if( headcrab !is null )
                    {
                        headcrab.pev.health = headcrab_health - headcrab_damage;
                    }
                }
            }

            // Create a blood puddle if possible.
            /* Do not create for non-bleedable npcs */
            if( monster.m_bloodColor != DONT_BLEED
            /* Check for Server operator's choices */
            && cvar_bloodpuddles.GetInt() == 0
            /* I'm sure Kern fixed this but just in case of a future update, we wouldn't want a bunch of puddles x[ */
            && !user_data.exists( "bloodpuddle" ) )
            /* Do not create if there's not a "free" slot */
            {
                CBaseEntity@ bloodpuddle = g_EntityFuncs.Create(
                    "env_bloodpuddle",
                    /* About +6 units should be enough i think */
                    monster.Center() + Vector( 0, 0, 6 ),
                    g_vecZero,
                    false,
                    monster.edict()
                );

                if( bloodpuddle !is null && monster.m_bloodColor == ( BLOOD_COLOR_GREEN | BLOOD_COLOR_YELLOW ) )
                {
                    bloodpuddle.pev.skin = 1;
                }

                user_data[ "bloodpuddle" ] = true;
            }
        }
    }

    return HOOK_CONTINUE;
}

HookReturnCode MonsterTakeDamage( DamageInfo@ pDamageInfo )
{
    if( pDamageInfo.flDamage <= 0 )
        return HOOK_CONTINUE;

    if( pDamageInfo.pVictim !is null )
    {
        CBaseMonster@ monster = cast<CBaseMonster@>( pDamageInfo.pVictim );

        if( monster !is null )
        {
            dictionary@ user_data = monster.GetUserData();

            if( monster.pev.classname == "monster_zombie" )
            {
                // Got hit on the headcrab. store damage
                if( monster.m_LastHitGroup == 1 )
                {
                    user_data[ "headcrab_damage" ] = int(user_data[ "headcrab_damage" ]) + pDamageInfo.flDamage;
                }
            }
        }
    }

    return HOOK_CONTINUE;
}
