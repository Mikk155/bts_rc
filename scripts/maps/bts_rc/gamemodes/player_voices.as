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
    Help Support: SoloKiller
    Idea: AraseFiq
*/

final class CVoice
{
    private string __owner__;
    private string __type__;

    private array<string> voices;

    float cooldown = 0.0f;
    float pitch = 100.0f;

    void push_back( const string& in sound )
    {
        g_SoundSystem.PrecacheSound( sound );

        this.voices.insertLast( sound );
    }

    CVoice( const string owner, const string type )
    {
        this.__type__ = type;
        this.__owner__ = owner;
    }

    bool PlaySound( CBaseEntity@ target, const float volume = 1.0, const int pitchOverride = -1, const int flags = 0 )
    {
        if( target is null )
            return false;

        dictionary@ data = target.GetUserData();

        float nextVoice;
        if( data.get( this.__type__, nextVoice ) && g_Engine.time < nextVoice )
            return false;

        if( this.voices.length() <= 0 )
        {
            return false;
        }

        const string sound = this.voices[Math.RandomLong( 0, this.voices.length() - 1 )];

        int finalPitch = int( this.pitch );
        
        if( pitchOverride > 0 )
        {
            finalPitch = pitchOverride;
        }
        else
        {
            CBasePlayer@ player = cast<CBasePlayer@>(target);
            CCharacter@ character = GetCharacter(player);

            if( character !is null && ( character.HandsGroup == Hands::WhiteBlackHands || character.HandsGroup == Hands::BlueBlackHands || character.Name == "bts_otis" || character.Name == "bts_otis2" ) )
            {
                finalPitch = 94;
            }
        }

        g_SoundSystem.PlaySound( target.edict(), CHAN_VOICE, sound, volume, ATTN_NORM, flags, finalPitch, 0, true, target.GetOrigin() );

        data[this.__type__] = g_Engine.time + this.cooldown;

        return true;
    }
}

final class CVoices
{
    private string __name__;

    const string& name() const
    {
        return this.__name__;
    }

    CVoice@ takedamage;
    CVoice@ killed;

    CVoices( const string&in name )
    {
        __name__ = name;
        @takedamage = CVoice( this.__name__, "takedamage" );
        @killed = CVoice( this.__name__, "killed" );
    }
}

final class CVoiceResponse
{
    dictionary voices;

    CVoices@ opIndex( const string&in name ) const
    {
        if( name.IsEmpty() || !this.voices.exists( name ) )
            return null;

        return cast<CVoices@>( this.voices[name] );
    }

    CVoices@ ForClass( Classification playerClass ) const
    {
        switch( playerClass )
        {
            case Classification::Operative:
            case Classification::Security:
                return cast<CVoices@>( this.voices["barney"] );

            case Classification::Maintenance:
                return cast<CVoices@>( this.voices["construction"] );

            case Classification::HEV:
                return cast<CVoices@>( this.voices["helmet"] );

            case Classification::Hazard:
                return cast<CVoices@>( this.voices["cleansuit"] );

            case Classification::Scientist:
            default:
                return cast<CVoices@>( this.voices["scientist"] );
        }
    }

    private void RegisterVoice( CVoice@ voice, meta_api::json::v2::json@ config )
    {
        if( voice is null || config is null )
            return;

        voice.cooldown = config.ValueOrDefault( "cooldown", voice.cooldown, false, false );
        voice.pitch = config.ValueOrDefault( "pitch", voice.pitch, false, false );

        array<string>@ sounds;
        if( meta_api::json::v2::fmt::ToArray( config[ "sounds" ], sounds, true, false ) )
        {
            uint length = sounds.length();
            for( uint ui = 0; ui < length; ui++ )
                voice.push_back( sounds[ui] );
        }
    }

    bool Register( meta_api::json::v2::json@ profiles )
    {
        this.voices.deleteAll();

        if( profiles is null )
            return false;

        uint length = profiles.Length();
        for( uint ui = 0; ui < length; ui++ )
        {
            meta_api::json::v2::json@ profile = profiles[ui];
            string name = profile.Name;
            CVoices@ voiceProfile = CVoices( name );

            RegisterVoice( voiceProfile.takedamage, profile[ "takedamage" ] );
            RegisterVoice( voiceProfile.killed, profile[ "killed" ] );
            @this.voices[name] = voiceProfile;
        }

        return true;
    }
}

CVoiceResponse g_VoiceResponse;
