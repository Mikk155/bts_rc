/**   MIT License
*   
*   Copyright (c) 2025 Mikk155 https://github.com/Mikk155/bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies or substantial portions of the Software.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*   SOFTWARE.
*/

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
    Blue = 0,
    White,
    Orange,
    WhiteBlackHands,
    Hevsuit,
    Cleansuit,
    Gray,
    BlueBlackHands,
    Green,
    GrayGloves
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

void RegisterAllCharacters( meta_api::json::v2::json@ json, Server::chrono@ chrono )
{
    if( json is null || !json.is_array() )
    {
        g_Logger.critical.print( "Could not parse \"characters\" from json! things will break!" );
        return;
    }

    int jsonLength = json.Length();

    if( jsonLength <= 0 )
    {
        g_Logger.critical.print( "No playable characters were found in json! things will break!" );
        return;
    }

    uint length = uint( jsonLength );

    for( uint ui = 0; ui < length; ui++ )
    {
        auto character_data = json[ui];

        if( character_data is null || !character_data.is_array() || character_data.Length() < 3 )
        {
            g_Logger.warning.print( snprintf( glog, "Skipping invalid character entry at index %1", ui ) );
            continue;
        }

        string character_name = string( character_data[0] );
        Classification character_classify = Classification( int( character_data[1] ) );
        Hands character_hands = Hands( int( character_data[2] ) );

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
