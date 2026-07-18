/**
*   Copyright (c) 2026 Mikk155 and contributors of bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software to use, copy, modify, merge, publish, distribute, sublicense,
*   and/or sell copies of the Software under the following conditions:
*   
*   A reference to the original project must be included in all copies or substantial
*   portions of the Software. This must include, at minimum, a URL to:
*   https://github.com/Mikk155/bts_rc
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies of the Software when distributed as a whole.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
**/

#include "MapConfig"
#include "CommandContext"
#include "EntityOverriden"
#include "Logger"
#include "models"
#include "PlayerClass"
#include "Precache"

#include "../../../mikk155/SemanticVersion"

const SemanticVersion@ g_ScriptsVersion = SemVer( 4, 2, 0 );

// Whatever the current map is bts_rc
const bool g_IsMainMap = ( string( g_Engine.mapname ) == "bts_rc" );

// Has the game started in the map?
bool gpGameStarted;

// Idk raptor
bool gpHellHound = false;

// Current game version
const uint32 gpGameVersion = g_Game.GetGameVersion();

// Alias to DMG_DROWN used to identify TakeDamage has been called by a weapon of ours
const uint32 DMG_BTS_WEAPON = DMG_DROWN; // -TODO Maybe a new unused bit? Would have to inspect the SDK to actually see DMG_DROWN does nothing

// sven only has 8192 edicts at any given time
// so assume each player carries exactly 10 weapons, and then leave 100 slots free for various temporary things. -Zode
const int __freedicts_overhead__ = g_Engine.maxEntities - ( 10 * g_Engine.maxClients ) - 100;

// Return whatever there's space in the server to spawn "overhead" amount of entities
bool FreeEdicts( int overhead = 1 )
{
    return ( g_EngineFuncs.NumberOfEntities() < __freedicts_overhead__ - overhead );
}

// Get a random number between 0 and max. if RandomUint was called before the result will be stored in target user data as "RandomUint" to avoid repeating the same number in a row
uint8 RandomUint( uint8 max, CBaseEntity@ target )
{
    if( target is null )
        return 0;

    if( max == 0 )
    {
        if( g_Logger.critical.active )
            g_Logger.critical.print( snprintf( glog, "RandomUint called with an argument of zero!" ) );
        return 0;
    }

    dictionary@ data = target.GetUserData();

    uint8 lastRand;
    data.get( "RandomUint", lastRand );
    uint8 rand;

    do{ rand = Math.RandomLong( 0, max ); }
    while( rand == lastRand );

    data[ "RandomUint" ]  = rand;

    return rand;
}

/// Register a custom entity with the given classname. if internalName is empty we asume the class is named the same as the entity classname
bool CustomEntity( const string&in className, bool precacheEntity = false, const string&in internalName = String::EMPTY_STRING )
{
    g_CustomEntityFuncs.RegisterCustomEntity( internalName.IsEmpty() ? className : internalName, className );

    if( precacheEntity )
        g_Game.PrecacheOther( className );

    return true;
}

namespace Hellbound
{
    void Startup( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
    {
        gpHellHound = true;

        for( int i = 0; i <= g_Engine.maxClients; i++ )
        {
            UpdatePlayerData( g_PlayerFuncs.FindPlayerByIndex( i ), Classification::Unset );
        }
    }
}

float __LastMultiTouchTime__;
int __LastMultiTouchIndex__ = 0;

// Return true for all valid players that are intersecting with "other"
bool MultiTouch( CBaseEntity@ other, CBasePlayer@&out player )
{
    if( other !is null )
    {
        if( __LastMultiTouchIndex__ > 0 && __LastMultiTouchTime__ < g_Engine.time )
        {
            __LastMultiTouchTime__ = g_Engine.time;
            __LastMultiTouchIndex__ = 0;
        }

        while( __LastMultiTouchIndex__ < g_Engine.maxClients )
        {
            __LastMultiTouchIndex__++;
            auto entity = g_PlayerFuncs.FindPlayerByIndex(__LastMultiTouchIndex__);

            if( entity !is null && entity.IsConnected() && entity.Intersects( other ) )
            {
                @player = entity;
                return true;
            }
        }
    }

    return false;
}

#if SERVER
// Set a display name to a entity this is shown as simple text (No HUD Message) on the center of the screen
void SetDebugName( CBaseEntity@ target, const string&in name )
{
    if( target is null )
        return;

    auto ckv = target.GetCustomKeyvalues();

    if( !ckv.HasKeyvalue( "$s_message" ) )
    {
        g_EntityFuncs.DispatchKeyValue( target.edict(), "$s_message", name );
    }
}
