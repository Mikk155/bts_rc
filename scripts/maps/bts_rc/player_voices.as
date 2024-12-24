class CVoice
{
    private float time = 0;
    private float __cooldown__;

    private array<string> __voices__ = { String::EMPTY_STRING };

    const string& voice
    {
        get const
        {
            return this.__voices__[ Math.RandomLong( 0, this.__voices__.length() - 1 ) ];
        }
    }

    void opIndex( const string&in sound )
    {
        precache::sound( sound );
        __voices__.insertLast( sound );
        g_VoiceResponse.m_Logger.info( "Push sound \"{}\"", { sound } );
    }

    CVoice( float cooldown )
    {
        this.__cooldown__ = cooldown;
    }

    bool PlaySound( CBaseEntity@ target, float volume = 1.0, int pitch = PITCH_NORM, int flags = 0 )
    {
        if( target is null || time > g_Engine.time )
            return false;

        const string& sound = this.voice;

        g_VoiceResponse.m_Logger.info( "PlaySound \"{}\" for {}", { sound, target.pev.netname } );

        g_SoundSystem.PlaySound( target.edict(), CHAN_VOICE, sound, volume, ATTN_NORM, flags, pitch, 0, true, target.GetOrigin() );

        time = g_Engine.time + __cooldown__;

        return true;
    }
}

class CVoices
{
    private string __name__;
    const string& name { get const { return this.__name__; } }

    CVoice@ takedamage = CVoice(4.0f);

    CVoices( const string&in name )
    {
        __name__ = name;
    }
}

class CVoiceResponse
{
    CLogger@ m_Logger = CLogger( "Voice Responses" );

    CVoices@ barney = CVoices( "barney" );
    CVoices@ construction = CVoices( "construction" );
    CVoices@ scientist = CVoices( "scientist" );
    CVoices@ helmet = CVoices( "helmet" );

    CVoices@ opIndex( const string&in player_model )
    {
        if( player_model == "bts_otis"
        or player_model.StartsWith( "bts_barney" ) )
        {
            return this.barney;
        }

        if( player_model == "bts_construction" )
        {
            return this.construction;
        }

        if( player_model == "bts_helmet" )
        {
            return this.helmet;
        }

        return this.scientist;
    }

    void init()
    {
        this.barney.takedamage[ "player/hud_nightvision.wav" ];
        this.barney.takedamage[ "items/flashlight2.wav" ];
    }
}

CVoiceResponse g_VoiceResponse;
