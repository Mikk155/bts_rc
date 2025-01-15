/*
    Author: Mikk
    Help Support: SoloKiller
    Idea: AraseFiq
*/

CCVar@ cvar_player_voices = CCVar( "bts_rc_disable_player_voices", 0 );

class CVoice
{
    private string __owner__;
    private string __type__;

    private array<string> voices;

    float cooldown = 0.0f;

    void push_back( const string& in sound )
    {
        g_SoundSystem.PrecacheSound( sound );

        this.voices.insertLast( sound );

#if SERVER
        g_VoiceResponse.m_Logger.info( "Push sound \"{}\" for \"{}\" as \"{}\"", { sound, this.__owner__, this.__type__ } );
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

        if( g_Engine.time < float( data[ this.__type__ ] ) )
            return false;

        if( this.voices.length() <= 0 )
        {
#if SERVER
            g_VoiceResponse.m_Logger.warn( "Tried to PlaySound on a empty CVoice list for \"{}\" at \"{}\"", { this.__type__, this.__owner__ } );
#endif

            return false;
        }

        const string sound = this.voices[ Math.RandomLong( 0, this.voices.length() - 1 ) ];

#if SERVER
        g_VoiceResponse.m_Logger.info( "PlaySound \"{}\" for {} as \"{}\" from \"{}\"", { sound, target.pev.netname, this.__type__, this.__owner__ } );
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
//    CVoice@ drowndamage;
    CVoice@ killed;

    CVoices( const string&in name )
    {
        __name__ = name;
        @takedamage = CVoice(this.__name__, "takedamage" );
//        @drowndamage = CVoice(this.__name__, "drowndamage" );
        @killed = CVoice(this.__name__, "killed" );
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

            case PM::CLSUIT:
                return cast<CVoices@>( this.voices[ "cleansuit" ] );

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
        CVoices@ cleansuit = @CVoices( "cleansuit" );

        this.voices[ "scientist" ] = @scientist;
        this.voices[ "barney" ] = @barney;
        this.voices[ "construction" ] = @construction;
        this.voices[ "helmet" ] = @helmet;
        this.voices[ "cleansuit" ] = @cleansuit;

        // Customize in here the Voices:
        construction.takedamage.cooldown = 1.0;
        construction.takedamage.push_back( "bts_rc/player/construction/co_pain1.wav" );
        construction.takedamage.push_back( "bts_rc/player/construction/co_pain2.wav" );
        construction.takedamage.push_back( "bts_rc/player/construction/co_pain3.wav" );
        construction.takedamage.push_back( "bts_rc/player/construction/co_pain4.wav" );

        barney.takedamage.cooldown = 1.0;
        barney.takedamage.push_back( "barney/ba_pain1.wav" );
        barney.takedamage.push_back( "barney/ba_pain2.wav" );
        barney.takedamage.push_back( "barney/ba_pain3.wav" );

        helmet.takedamage.cooldown = 1.0;
        helmet.takedamage.push_back( "bts_rc/player/helmet/hm_pain1.wav" );
        helmet.takedamage.push_back( "bts_rc/player/helmet/hm_pain2.wav" );
        helmet.takedamage.push_back( "bts_rc/player/helmet/hm_pain3.wav" );
        helmet.takedamage.push_back( "bts_rc/player/helmet/hm_pain4.wav" );
        helmet.takedamage.push_back( "bts_rc/player/helmet/hm_pain5.wav" );

        @cleansuit.takedamage = helmet.takedamage;
        @cleansuit.killed = helmet.takedamage;

        scientist.takedamage.cooldown = 1.0;
        scientist.takedamage.push_back( "scientist/sci_pain1.wav" );
        scientist.takedamage.push_back( "scientist/sci_pain2.wav" );
        scientist.takedamage.push_back( "scientist/sci_pain3.wav" );
        scientist.takedamage.push_back( "scientist/sci_pain4.wav" );
        scientist.takedamage.push_back( "scientist/sci_pain5.wav" );
        scientist.takedamage.push_back( "scientist/sci_pain6.wav" );
        scientist.takedamage.push_back( "scientist/sci_pain7.wav" );
        scientist.takedamage.push_back( "scientist/sci_pain8.wav" );
        scientist.takedamage.push_back( "scientist/sci_pain9.wav" );
        scientist.takedamage.push_back( "scientist/sci_pain10.wav" );
/*
        scientist.takedamage.cooldown = CONST_VOICE_COOLDOWN_DROWNDAMAGE;
        scientist.drowndamage.push_back( "bts_rc/player/pl_drown1.wav" );
        // Same sounds so use the same pointer
        @barney.drowndamage = scientist.drowndamage;
        @construction.drowndamage = scientist.drowndamage;
        @helmet.drowndamage = scientist.drowndamage;
*/
        scientist.killed.push_back( "scientist/sci_die1.wav" );
        scientist.killed.push_back( "scientist/sci_die2.wav" );
        scientist.killed.push_back( "scientist/sci_die3.wav" );

        barney.killed.push_back( "barney/ba_die1.wav" );
        barney.killed.push_back( "barney/ba_die2.wav" );
        barney.killed.push_back( "barney/ba_die3.wav" );

        construction.killed.push_back( "bts_rc/player/construction/co_die1.wav" );
        construction.killed.push_back( "bts_rc/player/construction/co_die2.wav" );
        construction.killed.push_back( "bts_rc/player/construction/co_die3.wav" );
        construction.killed.push_back( "bts_rc/player/construction/co_die4.wav" );

        helmet.killed.push_back( "bts_rc/player/helmet/hm_death1.wav" );
        helmet.killed.push_back( "bts_rc/player/helmet/hm_death2.wav" );
        helmet.killed.push_back( "bts_rc/player/helmet/hm_death3.wav" );
        helmet.killed.push_back( "bts_rc/player/helmet/hm_death4.wav" );
    }
}

CVoiceResponse g_VoiceResponse;
