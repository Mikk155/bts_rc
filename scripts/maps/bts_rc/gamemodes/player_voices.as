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

    bool PlaySound( CBaseEntity@ target, const float volume = 1.0, const int pitchOverride = -1, const int flags = 0 )
    {
        if( target is null )
            return false;

        dictionary@ data = target.GetUserData();

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

    CVoice@ takedamage;
    CVoice@ killed;

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

    dictionary@ voices = {
        { "barney", null },
        { "veteran", null },
        { "scientist", null },
        { "construction", null },
        { "helmet", null },
        { "otis", null },
        { "bscientist", null } };

    CVoices@ opIndex( CBasePlayer@ player ) const
    {
        if( player is null )
            return null;

        const PM player_class = player_models::GetClass( player, true );

        switch( player_class )
        {
            case PM::OPERATIVE:
            case PM::BARNEY:
                return cast<CVoices@>( this.voices["barney"] );

            case PM::BOTIS:
                return cast<CVoices@>( this.voices["otis"] );

            case PM::VETERAN:
                return cast<CVoices@>( this.voices["veteran"] );

            case PM::GCONSTRUCTION:
            case PM::CONSTRUCTION:
                return cast<CVoices@>( this.voices["construction"] );

            case PM::HELMET:
                return cast<CVoices@>( this.voices["helmet"] );

            case PM::CLSUIT:
                return cast<CVoices@>( this.voices["cleansuit"] );

            case PM::BSCIENTIST:
                return cast<CVoices@>( this.voices["bscientist"] );

            case PM::SCIENTIST:
            default:
                return cast<CVoices@>( this.voices["scientist"] );
        }
    }

    void Register( dictionary@ config )
    {
        if( !config.get( "voice_responses", this.Active ) || !this.Active )
            return;

        g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, PlayerTakeDamageHook( function( DamageInfo@ info )
        {
            if( !g_VoiceResponse.Active || info.flDamage <= 0 || info.pVictim is null )
                return HOOK_CONTINUE;

            CBasePlayer@ player = cast<CBasePlayer@>( info.pVictim );

            if( player is null || ( info.pAttacker is null || info.pAttacker.IRelationship( player ) == R_AL ) )
                return HOOK_CONTINUE;

            // Hooks call ordering is reversed from the registering orden so we have to do this check anyways from gamemodes/radioactivity
            // https://discord.com/channels/818989352411463731/819002186574594118/1489052351435378770
            if( ( ( info.bitsDamageType & DMG_RADIATION ) != 0 && player_models::GetClass( player, true ) == PM::HELMET ) )
                return HOOK_CONTINUE;

            CVoices@ voices = g_VoiceResponse[player];

            if( voices !is null && voices.takedamage !is null )
            {
                voices.takedamage.PlaySound( player );
            }

            return HOOK_CONTINUE;
        } ) );

        g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, PlayerKilledHook( function( CBasePlayer@ player, CBaseEntity@ attacker, int gib )
        {
            if( !g_VoiceResponse.Active || player is null )
                return HOOK_CONTINUE;

            CVoices@ voices = g_VoiceResponse[player];

            if( voices !is null && voices.killed !is null )
            {
                voices.killed.PlaySound( player );
            }

            return HOOK_CONTINUE;
        } ) );

        RegisterCommand( "player_voices", "", "toggle player voices state", 
            CommandCallback( function( CBasePlayer@ player, array<string>@ arguments )
            {
                g_VoiceResponse.Active = !g_VoiceResponse.Active;
                if( g_VoiceResponse.Active )
                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Enabled player voices\n" );
                else
                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Disabled player voices\n" );
            }
        ), true );

        // Initialize handlers for specific classes
        CVoices@ scientist = @CVoices( "scientist" );
        CVoices@ barney = @CVoices( "barney" );
        CVoices@ construction = @CVoices( "construction" );
        CVoices@ helmet = @CVoices( "helmet" );
        CVoices@ cleansuit = @CVoices( "cleansuit" );
        CVoices@ veteran = @CVoices( "veteran" );
        CVoices@ otis = @CVoices( "otis" );
        CVoices@ bscientist = @CVoices( "bscientist" );

        // Save them in the voice responses class
        this.voices["scientist"] = @scientist;
        this.voices["barney"] = @barney;
        this.voices["construction"] = @construction;
        this.voices["helmet"] = @helmet;
        this.voices["cleansuit"] = @cleansuit;
        this.voices["veteran"] = @veteran;
        this.voices["otis"] = @otis;
        this.voices["bscientist"] = @bscientist;

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
