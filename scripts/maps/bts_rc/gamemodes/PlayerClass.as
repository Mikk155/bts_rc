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
        // Radiation inmunity/deduction for HEV/Hazard
        if( info.flDamage > 0 && ( info.bitsDamageType & DMG_RADIATION ) != 0 )
        {
            switch( Classify )
            {
                case Classification::Hazard:
                {
                    float dmg = info.flDamage * 0.3;

                    if( dmg > 1.0 )
                        info.flDamage = dmg;

                    break;
                }
                case Classification::HEV:
                {
                    info.flDamage = 0;
                    break;
                }
            }
        }
    }
}

array<array<CCharacter@>> g_Characters(Classification::__Size__);
array<uint> g_LastSelectedCharacter(Classification::__Size__);

CCharacter@ RegisterCharacter( const string&in modelName, Hands hands, const Classification&in classify )
{
    array<CCharacter@>@ list = g_Characters[classify];

    auto character = CCharacter( modelName, hands, classify );

    list.insertLast( @character );

    // For randomization
    g_LastSelectedCharacter[classify] = Math.RandomLong( 0, list.length() - 1 );

    return @character;
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
    player.pev.armortype = armor;
    player.pev.armorvalue = Math.min( player.pev.armortype, player.pev.armorvalue );
    player.pev.max_health = health;
    player.pev.health = Math.min( player.pev.health, player.pev.max_health );
}

void UpdatePlayerData( CBasePlayer@ player, const Classification&in classify )
{
    switch( classify )
    {
        case Classification::HEV: SerPlayerDurability( player, 100, 100 ); break;
        case Classification::Hazard: SerPlayerDurability( player, 75, 75 ); break;
        default: SerPlayerDurability( player, 50, 50 ); break;
    }
}

void UpdatePlayerData( CBasePlayer@ player )
{
    UpdatePlayerData( player, util::GetClass( player ) );
}
