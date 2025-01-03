class CVoice
{
    private float __time__ = 0;
    private string __owner__;

    private array<string> voices;

    float cooldown = 0.5f;

    void push_back( const string& in sound )
    {
        precache::sound( sound );
        this.voices.insertLast( sound );
        g_VoiceResponse.m_Logger.info( "Push sound \"{}\" for \"{}\"", { sound, this.__owner__ } );
    }

    CVoice( const string owner )
    {
        this.__owner__ = owner;
    }

    bool PlaySound( CBaseEntity@ target, const float volume = 1.0, const int pitch = PITCH_NORM, const int flags = 0 )
    {
        if( target is null || this.__time__ > g_Engine.time )
            return false;

        if( this.voices.length() <= 0 )
        {
            g_VoiceResponse.m_Logger.warn( "Tried to PlaySound on a empty CVoice list for \"{}\"", { __owner__ } );
            return false;
        }

        const string sound = this.voices[ Math.RandomLong( 0, this.voices.length() - 1 ) ];

        g_VoiceResponse.m_Logger.info( "PlaySound \"{}\" for {} as \"{}\"", { sound, target.pev.netname, __owner__ } );

        g_SoundSystem.PlaySound( target.edict(), CHAN_VOICE, sound, volume, ATTN_NORM, flags, pitch, 0, true, target.GetOrigin() );

        this.__time__ = g_Engine.time + this.cooldown;

        return true;
    }
}

class CVoices
{
    private string __name__;

    const string& name() const
    {
        return this.__name__;
    }

    CVoice@ takedamage;

    CVoices( const string&in name )
    {
        __name__ = name;
        @takedamage = CVoice(this.__name__);
    }
}

class CVoiceResponse
{
    CLogger@ m_Logger = CLogger( "Voice Responses" );

    private array<CVoices@> voices = {};

    CVoices@ opIndex( const string&in player_model ) const
    {
        // scientist is used as a fallback anyway so if there is no match it'll be used regardless, so skip it. -Sam
        for (uint i = 1; i < this.voices.length(); ++i)
        {
            if ( player_model.StartsWith( this.voices[i].name() ) )
            {
                return this.voices[i];
            }
        }
        
        return this.voices[0];
    }

    CVoices@ get_voice( const string&in player_model ) const
    {
        return this[ player_model ];
    }

    void init()
    {
        CVoices@ scientist = CVoices( "bts_scientist" );
        CVoices@ barney = CVoices( "bts_barney" );
        CVoices@ construction = CVoices( "bts_construction" );
        CVoices@ helmet = CVoices( "bts_helmet" );

        // scientist goes first so we can get it easily as a fallback -Sam
        this.voices.insertLast( scientist );
        this.voices.insertLast( barney );
        this.voices.insertLast( construction );
        this.voices.insertLast( helmet );

        // Customize in here the Voices:
        barney.takedamage.cooldown = 4.0f;
        barney.takedamage.push_back( "player/hud_nightvision.wav" );
        barney.takedamage.push_back( "items/flashlight2.wav" );
    }
}

CVoiceResponse g_VoiceResponse;
