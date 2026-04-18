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

void RegisterPlayerClass( dictionary@ data )
{
    RegisterCharacter( "bts_cleansuit", Hands::Cleansuit, Classification::Hazard );
    RegisterCharacter( "bts_helmet", Hands::Hevsuit, Classification::HEV );

    RegisterCharacter( "bts_barney", Hands::Blue, Classification::Security );
    RegisterCharacter( "bts_barney2", Hands::Blue, Classification::Security );
    RegisterCharacter( "bts_barney3", Hands::Blue, Classification::Security );
    RegisterCharacter( "bts_otis", Hands::Blue, Classification::Security );
    RegisterCharacter( "bts_otis2", Hands::Blue, Classification::Security );
    RegisterCharacter( "bts_otis_blk", Hands::BlueBlackHands, Classification::Security );

    RegisterCharacter( "bts_scientist", Hands::White, Classification::Scientist );
    RegisterCharacter( "bts_scientist2", Hands::White, Classification::Scientist );
    RegisterCharacter( "bts_scientist3", Hands::WhiteBlackHands, Classification::Scientist );
    RegisterCharacter( "bts_scientist4", Hands::White, Classification::Scientist );
    RegisterCharacter( "bts_scientist5", Hands::White, Classification::Scientist );
    RegisterCharacter( "bts_scientist6", Hands::White, Classification::Scientist );
    
    RegisterCharacter( "bts_construction", Hands::Orange, Classification::Maintenance );
    RegisterCharacter( "bts_construction2", Hands::Green, Classification::Maintenance );
    RegisterCharacter( "bts_construction3", Hands::Orange, Classification::Maintenance );

    RegisterCharacter( "bts_op", Hands::Gray, Classification::Operative );
    RegisterCharacter( "bts_op2", Hands::Gray, Classification::Operative );
    RegisterCharacter( "bts_op3", Hands::Gray, Classification::Operative );
    RegisterCharacter( "bts_op4", Hands::Gray, Classification::Operative );
    RegisterCharacter( "bts_op6", Hands::Gray, Classification::Operative );
    RegisterCharacter( "bts_op_band", Hands::Gray, Classification::Operative );
    RegisterCharacter( "bts_op_free", Hands::Gray, Classification::Operative );
    RegisterCharacter( "bts_op_hurt", Hands::Gray, Classification::Operative );
    RegisterCharacter( "bts_op_back", Hands::Gray, Classification::Operative );
    RegisterCharacter( "bts_op_demo", Hands::GrayGloves, Classification::Operative );
    RegisterCharacter( "bts_op_dual", Hands::Gray, Classification::Operative );
    RegisterCharacter( "bts_op_medic", Hands::Gray, Classification::Operative );
    RegisterCharacter( "bts_op_otis", Hands::Gray, Classification::Operative );
    RegisterCharacter( "bts_op_pissed", Hands::Gray, Classification::Operative );
    RegisterCharacter( "bts_op_signal", Hands::Gray, Classification::Operative );
    RegisterCharacter( "bts_op_vet", Hands::Gray, Classification::Operative );
}

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

    UpdateArmor( player, classify );
}

void SetRandomClass( CBasePlayer@ player, array<Classification>@ range )
{
    SetClass( player, range[ Math.RandomLong( 0, range.length() - 1 ) ] );;
}

float gpMaxArmorHEV; // -TODO To json?
float gpMaxArmorHazard;
float gpMaxArmorDefault;

void UpdateArmor( CBasePlayer@ player, const Classification&in classify )
{
    switch( classify )
    {
        case Classification::HEV:
        {
            player.pev.armortype = 100;
            player.pev.armorvalue = Math.min( player.pev.armortype, player.pev.armorvalue );
            break;
        }
        case Classification::Hazard:
        {
            player.pev.armortype = 75;
            player.pev.armorvalue = Math.min( player.pev.armortype, player.pev.armorvalue );
            break;
        }
        default:
        {
            player.pev.armortype = 50;
            player.pev.armorvalue = Math.min( player.pev.armortype, player.pev.armorvalue );
            break;
        }
    }
}

void UpdateArmor( CBasePlayer@ player )
{
    UpdateArmor( player, util::GetClass( player ) );
}
