/*
    Author: Mikk
*/
enum PM
{
    UNSET = -1,
    BARNEY,
    SCIENTIST,
    CONSTRUCTION,
    BSCIENTIST,
    HELMET,
    CLSUIT,
    OPERATIVE,
    BOTIS,
    GCONSTRUCTION,
    VETERAN
};

namespace player_models
{
    uint scientistLast;
    array<string> scientist(0);
    uint barneyLast;
    array<string> barney(0);
    uint operativeLast;
    array<string> operative(0);
    uint constructorLast;
    array<string> constructor(0);

    void Register( const string&in name, array<string>@ list )
    {
        string model;
        snprintf( model, "models/player/%1/%1.mdl", name, name );
        g_Game.PrecacheModel( model );

        string thumbnail;
        snprintf( thumbnail, "models/player/%1/%1.bmp", name, name );
        g_Game.PrecacheGeneric( thumbnail );

        if( list !is null )
        {
            list.insertLast( name );
        }
    }

    // Return a player model for the given class
    string GetModel( const PM player_class )
    {
        switch( player_class )
        {
            case PM::SCIENTIST:
            {
                scientistLast = ( scientistLast >= scientist.length() - 1 ) ? 0 : scientistLast + 1;
                return scientist[scientistLast];
            }
            case PM::CONSTRUCTION:
            {
                constructorLast = ( constructorLast >= constructor.length() - 1 ) ? 0 : constructorLast + 1;
                return constructor[constructorLast];
            }
            case PM::BARNEY:
            {
                barneyLast = ( barneyLast >= barney.length() - 1 ) ? 0 : barneyLast + 1;
                return barney[barneyLast];
            }
            case PM::OPERATIVE:
            {
                operativeLast = ( operativeLast >= operative.length() - 1 ) ? 0 : operativeLast + 1;
                return operative[operativeLast];
            }
            case PM::CLSUIT:
            {
                return "bts_cleansuit";
            }
            case PM::HELMET:
            {
                return "bts_helmet";
            }
        }
        return "bts_op3";
    }

    bool IsTrainedPersonal( CBasePlayer@ player )
    {
        PM pm = GetClass( player );

        switch( pm )
        {
            case PM::BARNEY:
            case PM::BOTIS:
            case PM::VETERAN:
            case PM::OPERATIVE:
            case PM::HELMET:
            case PM::CLSUIT:
                return true;
        }
        return false;
    }

    void SetClass( CBasePlayer@ player, PM player_class )
    {
        const string model = GetModel( player_class );

        // Update class for view model bodygroups
        if( model == "bts_scientist3" )
        {
            player_class = PM::BSCIENTIST;
        }
        else if( model == "bts_construction2" )
        {
            player_class = PM::GCONSTRUCTION;
        }
        else if( model == "bts_otis_blk" )
        {
            player_class = PM::BOTIS;
        }

        dictionary@ data = player.GetUserData();

        data["pm"] = model;

        // Set appropiate class for hev/cleansuit
        auto oldClass = GetClass( player, true );

        if( oldClass != PM::UNSET )
        {
        }

        data["class"] = player_class;

        // Hide flashlight icon.
        player.m_iHideHUD |= HIDEHUD_FLASHLIGHT;

        switch( player_class )
        {
            case PM::HELMET:
                player.pev.armortype = 100;
            break;
            case PM::CLSUIT:
                player.pev.armortype = 75;
            break;
            default:
                player.pev.armortype = 50;
            break;
        }

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

    const PM GetClass( CBasePlayer@ player, bool DontSet = false )
    {
        if( player !is null )
        {
            dictionary@ data = player.GetUserData();

            if( !data.exists( "class" ) )
            {
                if( DontSet )
                {
                    return PM::UNSET;
                }

                switch( Math.RandomLong( 0, 3 ) )
                {
                    case 0:
                    {
                        SetClass( player, PM::SCIENTIST );
                        return PM::SCIENTIST;
                    }
                    case 1:
                    {
                        SetClass( player, PM::BARNEY );
                        return PM::BARNEY;
                    }
                    case 2:
                    {
                        SetClass( player, PM::CONSTRUCTION );
                        return PM::CONSTRUCTION;
                    }
                    case 3:
                    {
                        SetClass( player, PM::OPERATIVE );
                        return PM::OPERATIVE;
                    }
                }
            }

            return PM( data["class"] );
        }

        return PM::SCIENTIST;
    }

    void Register( dictionary@ config )
    {
        if( bool( config[ "force_playermodels" ] ) )
        {
            g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink,
                PlayerPostThinkHook( function( CBasePlayer@ player )
                {
                    if( player !is null && player.IsConnected() )
                    {
                        string model;
                        dictionary@ data = player.GetUserData();

                        if( data.get( "pm", model ) )
                        {
                            player.SetOverriddenPlayerModel( model );
                        }
                    }

                    return HOOK_CONTINUE;
                }
            ) );
        }

        Register( "bts_barney", barney );
        Register( "bts_barney2", barney );
        Register( "bts_barney3", barney );

        Register( "bts_cleansuit", null );
        Register( "bts_helmet", null );

        Register( "bts_scientist", scientist );
        Register( "bts_scientist2", scientist );
        Register( "bts_scientist3", scientist );
        Register( "bts_scientist4", scientist );
        Register( "bts_scientist5", scientist );
        Register( "bts_scientist6", scientist );

        Register( "bts_construction", constructor );
        Register( "bts_construction2", constructor );
        Register( "bts_construction3", constructor );

        Register( "bts_op", operative );
        Register( "bts_op2", operative );
        Register( "bts_op3", operative );
        Register( "bts_op4", operative );
        Register( "bts_op6", operative );
        Register( "bts_op_band", operative );
        Register( "bts_op_free", operative );
        Register( "bts_op_hurt", operative );
        Register( "bts_otis", operative );
        Register( "bts_otis2", operative );
        Register( "bts_otis_blk", operative );
        Register( "bts_op_back", operative );
        Register( "bts_op_demo", operative );
        Register( "bts_op_dual", operative );
        Register( "bts_op_medic", operative );
        Register( "bts_op_otis", operative );
        Register( "bts_op_pissed", operative );
        Register( "bts_op_signal", operative );
        Register( "bts_op_vet", operative );

        scientistLast = Math.RandomLong( 0, scientist.length() - 1 );
        barneyLast = Math.RandomLong( 0, barney.length() - 1 );
        operativeLast = Math.RandomLong( 0, operative.length() - 1 );
        constructorLast = Math.RandomLong( 0, constructor.length() - 1 );
    }
}
