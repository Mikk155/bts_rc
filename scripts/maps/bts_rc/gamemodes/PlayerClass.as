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

/*
Author: Mikk
*/

// Players classification
enum Classification
{
    // Player not currently set to any class
    Unset = -1,
    // Security officer
    Security,
    // Science team
    Scientist,
    // Maintenance
    Maintenance,
    // HEV suit
    HEV = 4,
    // Hazard suit
    Hazard,
    // Operative security officer
    Operative,
    // Just a end of enum for size reference.
    __Size__
};

// View model hands bodygroups
enum Hands
{
    Unset = -1,
    Blue = 0,
    White,
    Orange,
    WhiteBlackHands,
    Hevsuit,
    Cleansuit,
    Gray,
    BlueBlackHands,
    Green,
    GrayGloves,
    // Just a end of enum for size reference.
    __Size__
};

array<CCharacter@> g_ScienceTeam;
array<CCharacter@> g_MaintenanceTeam;
array<CCharacter@> g_SecurityTeam;
array<CCharacter@> g_OperativeTeam;

class CCharacter
{
    private Hands m_Hands;
    const Hands& HandsGroup {
        get const {
            return this.m_Hands;
        }
    }

    private string m_Name;
    const string& Name {
        get const {
            return this.m_Name;
        }
    }

    private Classification m_Classify;

    const Classification& Classify {
        get const {
            return this.m_Classify;
        }
    }

    // dictionary constructor
    CCharacter() {}

    CCharacter( const string&in modelName, Hands hands, const Classification&in classify )
    {
        this.m_Name = modelName;
        this.m_Hands = hands;
        this.m_Classify = classify;

        string model;
        snprintf( model, "models/player/%1/%1.mdl", modelName, modelName );
        g_Game.PrecacheModel( model );

        string thumbnail;
        snprintf( thumbnail, "models/player/%1/%1.bmp", modelName, modelName );
        g_Game.PrecacheGeneric( thumbnail );
    }

    /// Is the player wearing a HEV suit?
    bool IsHEV {
        get { return this.Classify == Classification::HEV; }
    }

    /// Is the player wearing a Hazard suit?
    bool IsHazard {
        get { return this.Classify == Classification::Hazard; }
    }

    void TakeDamage( CBasePlayer@ player, DamageInfo@ info )
    {
        if( info.flDamage > 0 )
        {
            switch( Classify )
            {
                case Classification::Hazard:
                {
                    // Radiation deduction for Hazard
                    if( ( info.bitsDamageType & DMG_RADIATION ) != 0 )
                    {
                        float dmg = info.flDamage * 0.3;

                        if( dmg > 1.0 )
                            info.flDamage = dmg;
                    }
                    // Generic damage does deduct 3 of armor no matter the real damage
                    else if( player.pev.armorvalue > 0 )
                    {
                        player.pev.armorvalue = Math.max( 0, player.pev.armorvalue - 3 );
                    }

                    break;
                }
                case Classification::HEV:
                {
                    // Radiation inmunity for HEV
                    if( ( info.bitsDamageType & DMG_RADIATION ) != 0 )
                        info.flDamage = 0;
                    break;
                }
                default:
                {
                    // Armor perforation
                    info.bitsDamageType |= DMG_SNIPER;
                    break;
                }
            }
        }
    }
}

array<array<CCharacter@>> g_Characters(Classification::__Size__);
array<uint> g_LastSelectedCharacter(Classification::__Size__);

void __RegisterCharacter__( string character_name, Classification character_classify, Hands character_hands )
{
    array<CCharacter@>@ list = g_Characters[character_classify];

    CCharacter@ character = CCharacter( character_name, character_hands, character_classify );

    list.insertLast( @character );

    // For randomization
    g_LastSelectedCharacter[character_classify] = Math.RandomLong( 0, list.length() - 1 );

    if( g_Logger.debug.active )
    {
        string strlog;
        snprintf( strlog, "Registered character \"%1\" at classify %2 ", character_name, int( character_classify ));
        switch( character_classify )
        {
            case Classification::Security: snprintf( strlog, "%1\"%2\"", strlog, "Security" ); break;
            case Classification::Scientist: snprintf( strlog, "%1\"%2\"", strlog, "Scientist" ); break;
            case Classification::Maintenance: snprintf( strlog, "%1\"%2\"", strlog, "Maintenance" ); break;
            case Classification::HEV: snprintf( strlog, "%1\"%2\"", strlog, "HEV" ); break;
            case Classification::Hazard: snprintf( strlog, "%1\"%2\"", strlog, "Hazard" ); break;
            case Classification::Operative: snprintf( strlog, "%1\"%2\"", strlog, "Operative" ); break;
        }
        snprintf( strlog, "%1 using hands %2 ", strlog, int( character_hands ) );
        switch( character_hands )
        {
            case Hands::Blue: snprintf( strlog, "%1\"%2\"", strlog, "Blue" ); break;
            case Hands::White: snprintf( strlog, "%1\"%2\"", strlog, "White" ); break;
            case Hands::Orange: snprintf( strlog, "%1\"%2\"", strlog, "Orange" ); break;
            case Hands::WhiteBlackHands: snprintf( strlog, "%1\"%2\"", strlog, "WhiteBlackHands" ); break;
            case Hands::Hevsuit: snprintf( strlog, "%1\"%2\"", strlog, "Hevsuit" ); break;
            case Hands::Cleansuit: snprintf( strlog, "%1\"%2\"", strlog, "Cleansuit" ); break;
            case Hands::Gray: snprintf( strlog, "%1\"%2\"", strlog, "Gray" ); break;
            case Hands::BlueBlackHands: snprintf( strlog, "%1\"%2\"", strlog, "BlueBlackHands" ); break;
            case Hands::Green: snprintf( strlog, "%1\"%2\"", strlog, "Green" ); break;
            case Hands::GrayGloves: snprintf( strlog, "%1\"%2\"", strlog, "GrayGloves" ); break;
        }
        g_Logger.debug.print( strlog );
    }
}

void RegisterAllCharacters( meta_api::json::v2::json@ json, Server::chrono@ chrono )
{
    if( json is null )
    {
        g_Logger.warning.print( "Could not parse \"characters\" missing from json!" );
        @json = meta_api::json::v2::json();
    }
    else if( !json.is_array() )
    {
        g_Logger.warning.print( "\"characters\" from json is not an array!" );
        json.Clear();
    }
    else if( json.Length() <= 0 )
    {
        g_Logger.warning.print( "\"characters\" from json was empty!" );
    }

    uint length = uint( json.Length() );

    for( uint ui = 0; ui < length; ui++ )
    {
        auto character_data = json[ui];

        if( character_data is null  )
        {
            g_Logger.warning.print( snprintf( glog, "Skipping null character entry at index %1", ui ) );
            continue;
        }

        if( !character_data.is_array() )
        {
            g_Logger.warning.print( snprintf( glog, "Skipping non-array character entry at index %1", ui ) );
            continue;
        }

        if( character_data.Length() < 3 )
        {
            g_Logger.warning.print( snprintf( glog, "Skipping invalid character entry at index %1", ui ) );
            continue;
        }

        meta_api::json::v2::json@ jName = character_data[0];
        meta_api::json::v2::json@ jClassify = character_data[1];
        meta_api::json::v2::json@ jHands = character_data[2];

        if( !jName.is_string() )
        {
            g_Logger.warning.print( snprintf( glog, "Skipping invalid character entry at index %1 first argument is not string!", ui ) );
            continue;
        }

        int iClassify;
        if( !jClassify.is_number_unsigned() || !jClassify.Get( iClassify ) || Math.clamp( Classification::Unset + 1, Classification::__Size__ - 1, iClassify ) != iClassify )
        {
            g_Logger.warning.print( snprintf( glog, "Skipping invalid character entry at index %1 second argument is not valid number!", ui ) );
            continue;
        }

        int iHands;
        if( !jHands.is_number_unsigned() || !jHands.Get( iHands ) || Math.clamp( Hands::Unset + 1, Hands::__Size__ - 1, iHands ) != iHands )
        {
            g_Logger.warning.print( snprintf( glog, "Skipping invalid character entry at index %1 second argument is not valid number!", ui ) );
            continue;
        }

        __RegisterCharacter__( string( jName ), Classification( iClassify ), Hands( iHands ) );
    }

    if( g_Characters[Classification::Hazard].length() <= 0 ) {
        __RegisterCharacter__("bts_cleansuit", Classification::Hazard, Hands::Cleansuit );
    }
    if( g_Characters[Classification::HEV].length() <= 0 ) {
        __RegisterCharacter__("bts_helmet", Classification::HEV, Hands::Hevsuit );
    }
    if( g_Characters[Classification::Security].length() <= 0 ) {
        __RegisterCharacter__("bts_barney", Classification::Security, Hands::Blue );
    }
    if( g_Characters[Classification::Scientist].length() <= 0 ) {
        __RegisterCharacter__("bts_scientist", Classification::Scientist, Hands::White );
    }
    if( g_Characters[Classification::Maintenance].length() <= 0 ) {
        __RegisterCharacter__("bts_construction", Classification::Maintenance, Hands::Orange );
    }
    if( g_Characters[Classification::Operative].length() <= 0 ) {
        __RegisterCharacter__("bts_op", Classification::Operative, Hands::Gray );
    }

    if( g_Logger.info.active )
    {
        chrono.Stop();
        g_Logger.info.print( snprintf( glog, "Finish initializing player characters. %1:%2 seconds elapsed since the map started.", chrono.Seconds, chrono.Miliseconds ) );
    }
}

CCharacter@ SetRandomCharacter( CBasePlayer@ player, const Classification&in classify )
{
    array<CCharacter@>@ list = g_Characters[classify];

    uint size = list.length();

    if( size == 1 ) // HEV/Hazard
        return list[0];

    uint last = g_LastSelectedCharacter[classify] + 1;

    if( last >= size )
        last = 0;

    g_LastSelectedCharacter[classify] = last;

    return list[last];
}


/// Get the player class
CCharacter@ GetCharacter( CBasePlayer@ player )
{
    if( player !is null )
    {
        dictionary@ data = player.GetUserData();

        if( data !is null )
            return cast<CCharacter@>( data[ "character" ] );
    }

    return null;
}

CCharacter@ GetCharacter( CBaseEntity@ player )
{
    return GetCharacter( cast<CBasePlayer@>(player) );
}

dictionary __JoinedPlayers__;

/// Set the player class
void SetClass( CBasePlayer@ player, const Classification&in classify )
{
    if( player is null )
        return;

    dictionary@ data = player.GetUserData();

    if( data is null )
        return;

    auto character = SetRandomCharacter( player, classify );

    if( character is null )
        return;

    switch( classify )
    {
        case Classification::Security:
        case Classification::Operative:
            data[ "security" ] = true;
        break;
    }

    @data[ "character" ] = character;

    if( player.IsAlive() )
    {
        // Re-Deploy weapon to update view model hands
        if( player.m_hActiveItem.IsValid() )
        {
            CBaseEntity@ active_item = player.m_hActiveItem.GetEntity();

            if( active_item !is null )
            {
                CBasePlayerItem@ weapon = cast<CBasePlayerItem@>( active_item );

                if( weapon !is null )
                {
                    weapon.Deploy();
                }
            }
        }
    }
    else if( !__JoinedPlayers__.exists( g_EngineFuncs.GetPlayerAuthId( player.edict() ) ) )
    {
        g_PlayerFuncs.RespawnPlayer( player, false, true );
    }

    __JoinedPlayers__[ g_EngineFuncs.GetPlayerAuthId( player.edict() ) ] = true;

    UpdatePlayerData( player, classify );
}

void SetRandomClass( CBasePlayer@ player, array<Classification>@ range )
{
    SetClass( player, range[ Math.RandomLong( 0, range.length() - 1 ) ] );;
}

void SerPlayerDurability( CBasePlayer@ player, float health, float armor )
{
    if( player is null )
        return;

    player.pev.armortype = armor;
    player.pev.armorvalue = Math.min( player.pev.armortype, player.pev.armorvalue );
    player.pev.max_health = health;
    player.pev.health = Math.min( player.pev.health, player.pev.max_health );
}

void UpdatePlayerData( CBasePlayer@ player, const Classification&in classify )
{
    if( player is null )
        return;

    if( gpHellHound )
    {
        player.pev.health = player.pev.max_health = 1;
        player.pev.armortype = player.pev.armorvalue = 0;
        return;
    }

    switch( classify )
    {
        case Classification::HEV: SerPlayerDurability( player, 100, 100 ); break;
        case Classification::Hazard: SerPlayerDurability( player, 75, 75 ); break;
        default: SerPlayerDurability( player, 50, 50 ); break;
    }
}

void UpdatePlayerData( CBasePlayer@ player )
{
    if( player is null )
        return;

    UpdatePlayerData( player, util::GetClass( player ) );
}
