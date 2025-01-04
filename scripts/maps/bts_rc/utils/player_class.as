enum PM
{
    UNSET = -1,
    BARNEY = 0,
    SCIENTIST = 1,
    CONSTRUCTION = 2,
    BSCIENTIST = 3,
    HELMET = 4,

    // Scrapped
    CLSUIT = 5
};

final class PlayerClass
{
#if SERVER
    CLogger@ m_Logger = CLogger( "Player Class System" );
#endif

    // Index of the last used model so we give each player a different one instead of a random one.
    private uint mdl_scientist_last = Math.RandomLong( 0, 3 );
    private array<string> mdl_scientist = {
        "bts_scientist",
        "bts_scientist4",
        "bts_scientist5",
        "bts_scientist6"
    };
    private uint mdl_barney_last = Math.RandomLong( 0, 3 );
    private array<string> mdl_barney = {
        "bts_barney",
        "bts_barney2",
        "bts_barney3",
        "bts_otis"
    };

    const PM opIndex( CBasePlayer@ player, bool DontSet = false )
    {
        if( player !is null )
        {
            dictionary@ data = player.GetUserData();

            if( !data.exists( "class" ) && !DontSet )
            {
#if SERVER
                m_Logger.info( "Unseted class for {}. Setting as operator", { player.pev.netname } );
#endif
                set_class( player, PM( Math.RandomLong( PM::BARNEY, PM::BSCIENTIST ) ) );
            }

            return PM( data[ "class" ] );
        }

        return PM::SCIENTIST;
    }

    void set_class( CBasePlayer@ player, const PM player_class )
    {
        player.GetUserData()[ "class" ] = player_class;

        const string model = this.model( player_class );

        player.SetOverriddenPlayerModel( model );

#if SERVER
        m_Logger.debug( "Asigned model \"{}\" to player {} at class {}", { model, player.pev.netname, player_class } );
#endif

    }

    // Return a player model for the given class
    const string& model( const PM player_class )
    {
        switch( player_class )
        {
            case PM::CONSTRUCTION:
            {
                return "bts_construction";
            }
            case PM::BSCIENTIST:
            {
                return "bts_scientist3";
            }
            case PM::HELMET:
            {
                return "bts_helmet";
            }
            case PM::BARNEY:
            {
                mdl_barney_last = ( mdl_barney_last >= mdl_barney.length() -1 ) ? 0 : mdl_barney_last + 1;
                return mdl_barney[ mdl_barney_last ];
            }
        }

        mdl_scientist_last = ( mdl_scientist_last >= mdl_scientist.length() -1 ) ? 0 : mdl_scientist_last + 1;
        return mdl_scientist[ mdl_scientist_last ];
    }
}

PlayerClass g_PlayerClass;
