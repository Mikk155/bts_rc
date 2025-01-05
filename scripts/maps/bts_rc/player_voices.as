class CVoice
{
    private string __owner__;
    private string __type__;

    private array<string> voices;

    float cooldown = 0.5f;

    void push_back( const string& in sound )
    {
        precache::sound( sound );
        this.voices.insertLast( sound );
#if SERVER
        g_VoiceResponse.m_Logger.info( "Push sound \"{}\" for \"{}\"", { sound, this.__owner__ } );
#endif
    }

    CVoice( const string owner, const string type )
    {
        this.__type__ = type;
        this.__owner__ = owner;
    }

    bool PlaySound( CBaseEntity@ target, const float volume = 1.0, const int pitch = PITCH_NORM, const int flags = 0 )
    {
        if( target is null )
            return false;

        dictionary@ data = target.GetUserData();

        if( g_Engine.time < float( data[ this.__type__] ) )
            return false;

        if( this.voices.length() <= 0 )
        {
#if SERVER
            g_VoiceResponse.m_Logger.warn( "Tried to PlaySound on a empty CVoice list for \"{}\"", { __owner__ } );
#endif
            return false;
        }

        const string sound = this.voices[ Math.RandomLong( 0, this.voices.length() - 1 ) ];

#if SERVER
        g_VoiceResponse.m_Logger.info( "PlaySound \"{}\" for {} as \"{}\"", { sound, target.pev.netname, __owner__ } );
#endif

        g_SoundSystem.PlaySound( target.edict(), CHAN_VOICE, sound, volume, ATTN_NORM, flags, pitch, 0, true, target.GetOrigin() );

        data[ this.__type__] = g_Engine.time + this.cooldown;

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
        @takedamage = CVoice(this.__name__, "takedamage" );
    }
}

class CVoiceResponse
{
#if SERVER
    CLogger@ m_Logger = CLogger( "Voice Responses" );
#endif

    private dictionary@ voices = {
        { "barney", null },
        { "scientist", null },
        { "construction", null },
        { "helmet", null }
    };

    CVoices@ opIndex( CBasePlayer@ player ) const
    {
        if( player is null )
            return null;

        const PM player_class = g_PlayerClass[ player, true ];

        switch( player_class )
        {
            case PM::BARNEY:
                return cast<CVoices@>( this.voices[ "barney" ] );

            case PM::CONSTRUCTION:
                return cast<CVoices@>( this.voices[ "construction" ] );

            case PM::HELMET:
                return cast<CVoices@>( this.voices[ "helmet" ] );

            case PM::SCIENTIST:
            case PM::BSCIENTIST:
            default:
                return cast<CVoices@>( this.voices[ "scientist" ] );
        }
    }

    void init()
    {
        CVoices@ scientist = CVoices( "scientist" );
        CVoices@ barney = @CVoices( "barney" );
        CVoices@ construction = @CVoices( "construction" );
        CVoices@ helmet = @CVoices( "helmet" );

        this.voices[ "scientist" ] = @scientist;
        this.voices[ "barney" ] = @barney;
        this.voices[ "construction" ] = @construction;
        this.voices[ "helmet" ] = @helmet;
    }
}

CVoiceResponse g_VoiceResponse;
