/*
    Author: Mikk
    Help Support: SoloKiller
    Idea: AraseFiq
*/

class CVoice
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

    bool PlaySound( CBaseEntity @target, const float volume = 1.0, const int pitchOverride = -1, const int flags = 0 )
    {
        if( target is null )
            return false;

        dictionary @data = target.GetUserData();

        if( g_Engine.time < float( data[this.__type__] ) )
            return false;

        if( this.voices.length() <= 0 )
        {
            return false;
        }

        const string sound = this.voices[Math.RandomLong( 0, this.voices.length() - 1 )];

        // If pitchOverride == -1 → use class pitch
        const int finalPitch = ( pitchOverride == -1 ? int( this.pitch ) : pitchOverride );

        g_SoundSystem.PlaySound( target.edict(), CHAN_VOICE, sound, volume, ATTN_NORM, flags, finalPitch, 0, true, target.GetOrigin() );

        data[this.__type__] = g_Engine.time + this.cooldown;

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

    CVoice @takedamage;
    CVoice @killed;

    CVoices( const string&in name )
    {
        __name__ = name;
        @takedamage = CVoice( this.__name__, "takedamage" );
        @killed = CVoice( this.__name__, "killed" );
    }
}

class CVoiceResponse
{
    bool Active = false;

    dictionary @voices = {
        { "barney", null },
        { "veteran", null },
        { "scientist", null },
        { "construction", null },
        { "helmet", null },
        { "otis", null },
        { "bscientist", null } };

    CVoices @opIndex( CBasePlayer @player ) const
    {
        if( player is null )
            return null;

        const PM player_class = g_PlayerClass[player, true];

        switch( player_class )
        {
            case PM::OPERATIVE:
            case PM::BARNEY:
                return cast<CVoices @>( this.voices["barney"] );

            case PM::OTIS:
                return cast<CVoices @>( this.voices["otis"] );

            case PM::VETERAN:
                return cast<CVoices @>( this.voices["veteran"] );

            case PM::GCONSTRUCTION:
            case PM::CONSTRUCTION:
                return cast<CVoices @>( this.voices["construction"] );

            case PM::HELMET:
                return cast<CVoices @>( this.voices["helmet"] );

            case PM::CLSUIT:
                return cast<CVoices @>( this.voices["cleansuit"] );

            case PM::BSCIENTIST:
                return cast<CVoices @>( this.voices["bscientist"] );

            case PM::SCIENTIST:
            default:
                return cast<CVoices @>( this.voices["scientist"] );
        }
    }

    void Register()
    {
        // Initialize handlers for specific classes
        CVoices @scientist = @CVoices( "scientist" );
        CVoices @barney = @CVoices( "barney" );
        CVoices @construction = @CVoices( "construction" );
        CVoices @helmet = @CVoices( "helmet" );
        CVoices @cleansuit = @CVoices( "cleansuit" );
        CVoices @veteran = @CVoices( "veteran" );
        CVoices @otis = @CVoices( "otis" );
        CVoices @bscientist = @CVoices( "bscientist" );

        // Save them in the voice responses class
        g_VoiceResponse.voices["scientist"] = @scientist;
        g_VoiceResponse.voices["barney"] = @barney;
        g_VoiceResponse.voices["construction"] = @construction;
        g_VoiceResponse.voices["helmet"] = @helmet;
        g_VoiceResponse.voices["cleansuit"] = @cleansuit;
        g_VoiceResponse.voices["veteran"] = @veteran;
        g_VoiceResponse.voices["otis"] = @otis;
        g_VoiceResponse.voices["bscientist"] = @bscientist;

        // Constructor
        construction.takedamage.cooldown = 1.0;
        construction.takedamage.push_back( "bts_rc/player/construction/co_pain1.wav" );
        construction.takedamage.push_back( "bts_rc/player/construction/co_pain2.wav" );
        construction.takedamage.push_back( "bts_rc/player/construction/co_pain3.wav" );
        construction.takedamage.push_back( "bts_rc/player/construction/co_pain4.wav" );
        construction.killed.push_back( "bts_rc/player/construction/co_die1.wav" );
        construction.killed.push_back( "bts_rc/player/construction/co_die2.wav" );
        construction.killed.push_back( "bts_rc/player/construction/co_die3.wav" );
        construction.killed.push_back( "bts_rc/player/construction/co_die4.wav" );

        // Barney
        barney.takedamage.cooldown = 1.0;
        barney.takedamage.push_back( "barney/ba_pain1.wav" );
        barney.takedamage.push_back( "barney/ba_pain2.wav" );
        barney.takedamage.push_back( "barney/ba_pain3.wav" );
        barney.killed.push_back( "barney/ba_die1.wav" );
        barney.killed.push_back( "barney/ba_die2.wav" );
        barney.killed.push_back( "barney/ba_die3.wav" );

        // Otis
        otis.takedamage.cooldown = 1.0;
        otis.takedamage.pitch = 94.0f;
        otis.killed.pitch = 94.0f;
        otis.takedamage.push_back( "otis/scar.wav" );
        otis.takedamage.push_back( "barney/ba_pain1.wav" );
        otis.takedamage.push_back( "barney/ba_pain2.wav" );
        otis.takedamage.push_back( "barney/ba_pain3.wav" );
        otis.takedamage.push_back( "barney/aghh.wav" );
        otis.takedamage.push_back( "barney/ba_die3.wav" );
        otis.takedamage.push_back( "barney/ba_pain3.wav" );
        otis.killed.push_back( "barney/ba_die1.wav" );
        otis.killed.push_back( "barney/ba_die2.wav" );
        otis.killed.push_back( "barney/ba_die3.wav" );

        // Veteran
        veteran.takedamage.cooldown = 1.0;
        veteran.takedamage.pitch = 103.0f;
        veteran.killed.pitch = 103.0f;
        veteran.takedamage.push_back( "fgrunt/gr_pain1.wav" );
        veteran.takedamage.push_back( "fgrunt/gr_pain2.wav" );
        veteran.takedamage.push_back( "fgrunt/gr_pain3.wav" );
        veteran.takedamage.push_back( "fgrunt/gr_pain4.wav" );
        veteran.takedamage.push_back( "fgrunt/gr_pain5.wav" );
        veteran.takedamage.push_back( "fgrunt/gr_pain6.wav" );
        veteran.killed.push_back( "fgrunt/death1.wav" );
        veteran.killed.push_back( "fgrunt/death2.wav" );
        veteran.killed.push_back( "fgrunt/death3.wav" );
        veteran.killed.push_back( "fgrunt/death4.wav" );
        veteran.killed.push_back( "fgrunt/death5.wav" );
        veteran.killed.push_back( "fgrunt/death6.wav" );

        // H.E.V
        helmet.takedamage.cooldown = 1.0;
        helmet.takedamage.push_back( "bts_rc/player/helmet/hm_pain1.wav" );
        helmet.takedamage.push_back( "bts_rc/player/helmet/hm_pain2.wav" );
        helmet.takedamage.push_back( "bts_rc/player/helmet/hm_pain3.wav" );
        helmet.takedamage.push_back( "bts_rc/player/helmet/hm_pain4.wav" );
        helmet.takedamage.push_back( "bts_rc/player/helmet/hm_pain5.wav" );
        helmet.killed.push_back( "bts_rc/player/helmet/hm_death1.wav" );
        helmet.killed.push_back( "bts_rc/player/helmet/hm_death2.wav" );
        helmet.killed.push_back( "bts_rc/player/helmet/hm_death3.wav" );
        helmet.killed.push_back( "bts_rc/player/helmet/hm_death4.wav" );

        // Cleansuit
        cleansuit.takedamage.cooldown = 1.0;
        cleansuit.takedamage.push_back( "bts_rc/player/cleansuit/cl_pain1.wav" );
        cleansuit.takedamage.push_back( "bts_rc/player/cleansuit/cl_pain2.wav" );
        cleansuit.takedamage.push_back( "bts_rc/player/cleansuit/cl_pain3.wav" );
        cleansuit.takedamage.push_back( "bts_rc/player/cleansuit/cl_pain4.wav" );
        cleansuit.takedamage.push_back( "bts_rc/player/cleansuit/cl_pain5.wav" );
        cleansuit.killed.push_back( "bts_rc/player/cleansuit/cl_death1.wav" );
        cleansuit.killed.push_back( "bts_rc/player/cleansuit/cl_death2.wav" );
        cleansuit.killed.push_back( "bts_rc/player/cleansuit/cl_death3.wav" );
        cleansuit.killed.push_back( "bts_rc/player/cleansuit/cl_death4.wav" );

        // Black Scientist
        bscientist.takedamage.cooldown = 1.0;
        bscientist.takedamage.pitch = 94.0f;
        bscientist.killed.pitch = 94.0f;
        bscientist.takedamage.push_back( "scientist/sci_pain1.wav" );
        bscientist.takedamage.push_back( "scientist/sci_pain2.wav" );
        bscientist.takedamage.push_back( "scientist/sci_pain3.wav" );
        bscientist.takedamage.push_back( "scientist/sci_pain4.wav" );
        bscientist.takedamage.push_back( "scientist/sci_pain5.wav" );
        bscientist.takedamage.push_back( "scientist/sci_pain6.wav" );
        bscientist.takedamage.push_back( "scientist/sci_pain7.wav" );
        bscientist.takedamage.push_back( "scientist/sci_pain8.wav" );
        bscientist.takedamage.push_back( "scientist/sci_pain9.wav" );
        bscientist.takedamage.push_back( "scientist/sci_pain10.wav" );
        bscientist.takedamage.push_back( "scientist/sci_fear11.wav" );
        bscientist.takedamage.push_back( "scientist/sci_fear15.wav" );
        bscientist.killed.push_back( "scientist/sci_die1.wav" );
        bscientist.killed.push_back( "scientist/sci_die2.wav" );
        bscientist.killed.push_back( "scientist/sci_die3.wav" );
        bscientist.killed.push_back( "scientist/scream21.wav" );
        bscientist.killed.push_back( "scientist/scream23.wav" );

        // Scientist
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
        scientist.takedamage.push_back( "scientist/sci_fear11.wav" );
        scientist.takedamage.push_back( "scientist/sci_fear15.wav" );
        scientist.killed.push_back( "scientist/sci_die1.wav" );
        scientist.killed.push_back( "scientist/sci_die2.wav" );
        scientist.killed.push_back( "scientist/sci_die3.wav" );
        scientist.killed.push_back( "scientist/scream21.wav" );
        scientist.killed.push_back( "scientist/scream23.wav" );
    }
}

CVoiceResponse g_VoiceResponse;
