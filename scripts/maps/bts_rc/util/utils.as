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

#include "../../../mikk155/meta_api/json/v2"
#include "../../../mikk155/meta_api/json/v2/schema"

#include "MapConfig"
#include "CustomKeyValues"
#include "Difficulty"
#include "CommandContext"
#include "EntityOverriden"
#include "Logger"
#include "models"
#include "PlayerClass"
#include "Precache"
#include "test_chamber"

#include "../../../mikk155/Server/chrono/v1"
#include "../../../mikk155/SemanticVersion"
#include "../../../mikk155/TextMenu/v1"
#include "../../../mikk155/Player/ChatColor"
#include "../../../mikk155/Player/GetUniqueID"
#include "../../../mikk155/Player/GiveItem"
#include "../../../mikk155/Entity/Create"
#include "../../../mikk155/meta_api"

TextMenu::v1::Menu g_ClassSelectionMenu;

// Boolean supposed to be true on Github while development. this is set to false when a release is generated.
const bool g_Debug = true;

const SemanticVersion@ g_ScriptsVersion = SemVer( 4, 8, 1 );

// Whatever the current map is bts_rc
const bool g_IsMainMap = ( string( g_Engine.mapname ) == "bts_rc" );

// Has the game started in the map?
bool gpGameStarted;

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
    if( className.IsEmpty() || g_CustomEntityFuncs.IsCustomEntity( className ) )
        return false;

    g_CustomEntityFuncs.RegisterCustomEntity( internalName.IsEmpty() ? className : internalName, className );

    if( precacheEntity )
    {
        g_Game.PrecacheOther( className );
    }

    return g_CustomEntityFuncs.IsCustomEntity( className );
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

            if( entity !is null && entity.IsConnected() && other.Intersects( entity ) )
            {
                @player = entity;
                return true;
            }
        }
    }

    return false;
}

// Set a display name to a entity this is shown as simple text (No HUD Message) on the center of the screen
void SetDebugName( CBaseEntity@ target, string&in name )
{
    if( target is null )
        return;

    auto ckv = target.GetCustomKeyvalues();
    auto nameValue = ckv.GetKeyvalue( "$s_message" );

    if( nameValue.Exists() )
        name = nameValue.GetString() + '\n' + name;

    g_EntityFuncs.DispatchKeyValue( target.edict(), "$s_message", name );
}

bool __gmodule_error__ = false;

// Stop module since the game doesn't care if MapInit had a exception and will call apActivate/MapStart regardless.
bool gCheckModuleError( bool setTo )
{
    if( setTo ) {
        bool hadError = __gmodule_error__;
        __gmodule_error__ = setTo;
        return hadError;
    }
    __gmodule_error__ = setTo;
    return false;
}

void EquipAllWeapons( CBasePlayer@ player )
{
    if( player is null )
        return;

    const array<string>@ weaponNames = g_WeaponsConfig.WeaponNames();
    uint length = weaponNames.length();

    gpDynamicEquipment.Lock();

    for( uint ui = 0; ui < length; ui++ )
    {
        const string weapon_name = weaponNames[ui];

        Player::GiveItem( player, weapon_name );

        CBasePlayerItem@ item = player.HasNamedPlayerItem( weapon_name );

        if( item is null )
            continue;

        CBasePlayerWeapon@ weapon = cast<CBasePlayerWeapon@>( item );

        if( weapon is null )
            continue;

        if( weapon.m_iPrimaryAmmoType > 0 )
        {
            player.m_rgAmmo( weapon.m_iPrimaryAmmoType, weapon.iMaxAmmo1() );
        }

        weapon.m_iClip = weapon.iMaxClip();

        if( weapon.m_iSecondaryAmmoType > 0 )
        {
            player.m_rgAmmo( weapon.m_iSecondaryAmmoType, weapon.iMaxAmmo2() );
        }
    }

    gpDynamicEquipment.UnLock();
}

void EquipAllWeapons( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
{
    if( activator !is null && activator.IsPlayer() )
        EquipAllWeapons( cast<CBasePlayer@>( activator ) );
}

namespace util
{
    // Fix stupid double trace at CBasePlayerWeapon::FireBullets
    // Because some dumb ass though it would be cool to make a new trace line alo CS to pass through victim
    // BUT they trace line BEFORE calling the fucking Take/Trace-Damage hooks!
    namespace Trace
    {
        EHandle __EntIgnore__;
        Vector __StartPoint__;
        float __ShouldFix__;

        void Prepare( CBaseEntity@ owner, const Vector&in vecSrc )
        {
            __ShouldFix__ = g_Engine.time;
            __StartPoint__ = vecSrc;
            __EntIgnore__ = EHandle( owner );
        }

        void Fix()
        {
            if( __ShouldFix__ != g_Engine.time )
                return;

            __ShouldFix__ = 0;

            CBasePlayer@ player = null;
            CBaseEntity@ entity = null;
            edict_t@ edict = null;

            if( !__EntIgnore__.IsValid()
            || ( @entity = __EntIgnore__.GetEntity() ) is null
            || ( @edict = entity.edict() ) is null
            || ( !entity.IsPlayer() )
            || ( @player = cast<CBasePlayer@>( entity ) ) is null )
                return;

            // Get the global trace (The one traced AGAIN at FireBullets)
            TraceResult tr = g_Utility.GetGlobalTrace();

            // Alien grunt for example won't trace again if hit in armor so we shouldn't tracing again
            if( tr.pHit is null
            || tr.pHit.vars.classname == "worldspawn" )
            {
                TraceResult tr2;
                g_Utility.TraceLine(
                    __StartPoint__,
                    tr.vecEndPos,
                    IGNORE_MONSTERS::dont_ignore_monsters,
                    IGNORE_GLASS::dont_ignore_glass,
                    edict,
                    tr2
                );
            }
        }
    }

    // For some reason CBasePlayer::IsFacing is failing.
    bool IsFacing( CBasePlayer@ player, CBaseEntity@ target, float dot = 0.5f )
    {
        Vector vecSrc = player.pev.origin + player.pev.view_ofs;

        TraceResult tr;
        g_Utility.TraceLine( vecSrc, target.pev.origin, ignore_monsters, ignore_glass, player.edict(), tr );

        if( tr.flFraction < 1.0 )
            return false;

        Math.MakeVectors( player.pev.v_angle );
        Vector vecToTarget = ( target.pev.origin - vecSrc ).Normalize();
        return ( DotProduct( g_Engine.v_forward, vecToTarget ) >= dot );
    }
}
