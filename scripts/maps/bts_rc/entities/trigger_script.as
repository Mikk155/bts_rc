namespace randomizer
{
    // Swap a specific squad to a random location.
    void randomize_squad( CBaseMonster@ psquad, CBaseEntity@ pentity )
    {
        swap_squadmakers(psquad, pentity);
    }

    // Swap all squads to a random and unique location.
    void randomize( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
    {
        init_squadmakers();
    }
}

// Do we really need a script to do this?
namespace survival
{
    // This is stupid.
    void activate( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
    {
        g_SurvivalMode.Activate();
    }

    // Still stupid.
    void deactivate( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
    {
        g_SurvivalMode.Disable();
    }

    // Even more stupid.
    void toggle( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
    {
        if( g_SurvivalMode.IsActive() )
        {
            deactivate( null, null, USE_SET, 0 );
        }
        else
        {
            activate( null, null, USE_SET, 0 );
        }
    }
}
