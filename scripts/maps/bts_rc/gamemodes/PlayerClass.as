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

namespace Classification
{
    const string& ToString( Classification classification )
    {
        switch( classification )
        {
            case Classification::Security:
                return "Security";
            case Classification::Scientist:
                return "Scientist";
            case Classification::Maintenance:
                return "Maintenance";
            case Classification::HEV:
                return "HEV";
            case Classification::Hazard:
                return "Hazard";
            case Classification::Operative:
                return "Operative";
            case Classification::Unset:
            default:
                return String::EMPTY_STRING;
        }
    }

    const string ToString( CBasePlayer@ player )
    {
        return ToString( util::GetClass(player) );
    }

    const Classification FromString( string className )
    {
        if( className.IsEmpty() )
            return Classification::Unset;

        className.ToLowercase();

        if( className == "security" )
            return Classification::Security;

        if( className == "scientist" )
            return Classification::Scientist;

        if( className == "scientist" )
            return Classification::Scientist;

        if( className == "maintenance" )
            return Classification::Maintenance;

        if( className == "hev" )
            return Classification::HEV;

        if( className == "hazard" )
            return Classification::Hazard;

        if( className == "operative" )
            return Classification::Operative;

        return Classification::Unset;
    }
}

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

final class CCharacter
{
    private CVoices@ m_Voices;
    CVoices@ get_Voices() const property
    {
        return @this.m_Voices;
    }

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

    CCharacter( const string&in modelName, Hands hands, const Classification&in classify, const string&in voiceProfile = String::EMPTY_STRING )
    {
        this.m_Name = modelName;
        this.m_Hands = hands;
        this.m_Classify = classify;
        @this.m_Voices = g_VoiceResponse[voiceProfile];

        if( this.m_Voices is null )
            @this.m_Voices = g_VoiceResponse.ForClass( classify );

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

final class ASPlayerCharactersConfig : IConfigurable
{
    private
        void __RegisterCharacter__( string character_name, Classification character_classify, Hands character_hands, const string&in voice_profile = String::EMPTY_STRING )
        {
            array<CCharacter@>@ list = g_Characters[character_classify];

            CCharacter@ character = CCharacter( character_name, character_hands, character_classify, voice_profile );

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

    const string& GetName() const override
    {
        return "characters";
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Characters",
            "description": "Control player characters and their voice profiles.",
            "properties":
            {
                "voice_profiles":
                {
                    "type": "object",
                    "description": "Named voice profiles referenced by playable characters.",
                    "additionalProperties":
                    {
                        "type": "object",
                        "unevaluatedProperties": false,
                        "properties":
                        {
                            "takedamage":
                            {
                                "type": "object",
                                "unevaluatedProperties": false,
                                "properties":
                                {
                                    "sounds": { "type": "array", "items": { "type": "string" } },
                                    "cooldown": { "type": "number", "minimum": 0 },
                                    "pitch": { "type": "number", "minimum": 1, "maximum": 255 }
                                }
                            },
                            "killed":
                            {
                                "type": "object",
                                "unevaluatedProperties": false,
                                "properties":
                                {
                                    "sounds": { "type": "array", "items": { "type": "string" } },
                                    "cooldown": { "type": "number", "minimum": 0 },
                                    "pitch": { "type": "number", "minimum": 1, "maximum": 255 }
                                }
                            }
                        }
                    }
                },
                "models":
                {
                    "type": "object",
                    "description": "Playable character models.",
                    "additionalProperties":
                    {
                        "type": "object",
                        "unevaluatedProperties": false,
                        "description": "Playable character definition",
                        "properties":
                        {
                            "classify":
                            {
                                "type": "number",
                                "description": "Classification used for the character, See: https://github.com/Mikk155/bts_rc/wiki/characters#playable-characters",
                                "minimum": 0,
                                "maximum": 6
                            },
                            "hands":
                            {
                                "type": "number",
                                "description": "View model hands used for the character, See: https://github.com/Mikk155/bts_rc/wiki/characters#player-view-hands",
                                "minimum": 0,
                                "maximum": 9
                            },
                            "voice":
                            {
                                "type": "string",
                                "description": "Name of a voice_profiles entry used by this character."
                            }
                        }
                    }
                }
            }
        }""";
    }

    uint RegisterCharacters( meta_api::json::v2::json@ config )
    {
        uint registered = 0;

        if( config is null )
            return registered;

        uint length = config.Length();

        for( uint ui = 0; ui < length; ui++ )
        {
            auto@ character_data = config[ui];

            meta_api::json::v2::json@ jClassify = character_data[ "classify" ];
            meta_api::json::v2::json@ jHands = character_data[ "hands" ];

            int iClassify;
            if( !jClassify.is_number_unsigned() || !jClassify.Get( iClassify ) || Math.clamp( Classification::Unset + 1, Classification::__Size__ - 1, iClassify ) != iClassify )
            {
                if( g_Logger.warning.active )
                    g_Logger.warning.print( snprintf( glog, "Skipping invalid character entry at index %1 classification is not a valid number!", ui ) );
                continue;
            }

            int iHands;
            if( !jHands.is_number_unsigned() || !jHands.Get( iHands ) || Math.clamp( Hands::Unset + 1, Hands::__Size__ - 1, iHands ) != iHands )
            {
                if( g_Logger.warning.active )
                    g_Logger.warning.print( snprintf( glog, "Skipping invalid character entry at index %1 hands is not a valid number!", ui ) );
                continue;
            }

            registered++;
            string voiceProfile;
            voiceProfile = character_data.ValueOrDefault( "voice", voiceProfile, false );
            this.__RegisterCharacter__( character_data.Name, Classification( iClassify ), Hands( iHands ), voiceProfile );
        }

        return registered;
    }

    bool Register( meta_api::json::v2::json@ config ) override
    {
        g_VoiceResponse.Register( config[ "voice_profiles" ] );
        this.RegisterCharacters( config[ "models" ] );

        // Have at least one of each if undefined
        if( g_Characters[Classification::Hazard].length() <= 0 ) {
            this.__RegisterCharacter__("bts_cleansuit", Classification::Hazard, Hands::Cleansuit );
        }
        if( g_Characters[Classification::HEV].length() <= 0 ) {
            this.__RegisterCharacter__("bts_helmet", Classification::HEV, Hands::Hevsuit );
        }
        if( g_Characters[Classification::Security].length() <= 0 ) {
            this.__RegisterCharacter__("bts_barney", Classification::Security, Hands::Blue );
        }
        if( g_Characters[Classification::Scientist].length() <= 0 ) {
            this.__RegisterCharacter__("bts_scientist", Classification::Scientist, Hands::White );
        }
        if( g_Characters[Classification::Maintenance].length() <= 0 ) {
            this.__RegisterCharacter__("bts_construction", Classification::Maintenance, Hands::Orange );
        }
        if( g_Characters[Classification::Operative].length() <= 0 ) {
            this.__RegisterCharacter__("bts_op", Classification::Operative, Hands::Gray );
        }

        return true;
    }
}

ASPlayerCharactersConfig gpCharactersConfig;

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

/// Set the player class
void SetClass( CBasePlayer@ player, const Classification&in classify )
{
    if( player is null )
        return;

    dictionary@ data = player.GetUserData();

    if( data is null )
        return;

    if( classify <= Classification::Unset || classify >= Classification::__Size__ )
    {
        data.delete( "character" );
        data.delete( "security" );
        return;
    }

    auto character = SetRandomCharacter( player, classify );

    if( character is null )
        return;

    SetCharacter( player, character );
}

void SetCharacter( CBasePlayer@ player, CCharacter@ character )
{
    if( player is null || character is null )
        return;

    dictionary@ data = player.GetUserData();
    @data[ "character" ] = character;
    UpdatePlayerData( player, character.Classify );
    Hooks::PlayerSetClass( player, character );
}

void PlayerSetClass( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
{
    CBasePlayer@ player = null;

    if( activator is null || caller is null || !activator.IsPlayer() || ( @player = cast<CBasePlayer@>( activator ) ) is null )
        return;

    const Classification classification = Classification( int( caller.pev.health ) );

    SetClass( player, classification );
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

#if SERVER
ASCommand ASEquipmentTestCommand(
"set",
"[class index]",
"Set your class to the given index, use w/o arguments to see indexes",
function( CBasePlayer@ player, array<string>@ arguments )
{
    if( arguments is null || arguments.length() <= 0 )
    {
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Possible class values are either these numerical indexes or names (case unsensitive)\n" );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, " " + int(Classification::Unset) + " | \"" + Classification::ToString(Classification::Unset) + "\"\n" );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, " " + int(Classification::Security) + " | \"" + Classification::ToString(Classification::Security) + "\"\n" );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, " " + int(Classification::Scientist) + " | \"" + Classification::ToString(Classification::Scientist) + "\"\n" );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, " " + int(Classification::Maintenance) + " | \"" + Classification::ToString(Classification::Maintenance) + "\"\n" );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, " " + int(Classification::HEV) + " | \"" + Classification::ToString(Classification::HEV) + "\"\n" );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, " " + int(Classification::Hazard) + " | \"" + Classification::ToString(Classification::Hazard) + "\"\n" );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, " " + int(Classification::Operative) + " | \"" + Classification::ToString(Classification::Operative) + "\"\n" );
        return;
    }


    string arg = arguments[0];
    Classification classify;

    if( g_Utility.IsStringInt( arg ) )
    {
        classify = Classification( int( atoi( arg ) ) );
    }
    else
    {
        classify = Classification::FromString( arg );
    }

    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Set Classification \"" + Classification::ToString(classify) + " (" + int(classify) + ")\n" );

    SetClass( player, classify );

}, true, "class" );

ASCommand ASCharacterTestCommand(
"character",
"[model name]",
"Show playable characters or select a specific character",
function( CBasePlayer@ player, array<string>@ arguments )
{
    if( arguments is null || arguments.length() == 0 )
    {
        CCharacter@ current = GetCharacter( player );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Current character: " + ( current is null ? "none" : current.Name ) + "\nPlayable characters:\n" );

        for( uint classIndex = 0; classIndex < g_Characters.length(); classIndex++ )
        {
            array<CCharacter@>@ characters = g_Characters[classIndex];

            for( uint characterIndex = 0; characterIndex < characters.length(); characterIndex++ )
                g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, " - " + characters[characterIndex].Name + " (" + Classification::ToString( characters[characterIndex].Classify ) + ")\n" );
        }
        return;
    }

    string requestedName = arguments[0];
    requestedName.ToLowercase();

    for( uint classIndex = 0; classIndex < g_Characters.length(); classIndex++ )
    {
        array<CCharacter@>@ characters = g_Characters[classIndex];

        for( uint characterIndex = 0; characterIndex < characters.length(); characterIndex++ )
        {
            string characterName = characters[characterIndex].Name;
            characterName.ToLowercase();

            if( characterName == requestedName )
            {
                SetCharacter( player, characters[characterIndex] );
                g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Selected character \"" + characters[characterIndex].Name + "\"\n" );
                return;
            }
        }
    }

    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Unknown character \"" + arguments[0] + "\". Run bts_rc class character to list valid names.\n" );
}, true, "class" );
#endif
