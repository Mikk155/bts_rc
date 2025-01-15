namespace randomizer
{
    // Swap a specific squad to a random location.
    void randomize_squad( CBaseMonster@ squad, CBaseEntity@ entity )
    {
        if( squad !is null && g_EntityFuncs.IsValidEntity( squad.pev.owner ) )
        {
            CBaseEntity@ owner_spot = g_EntityFuncs.Instance( squad.pev.owner );

            if( owner_spot !is null )
            {
                owner_spot.Use( null, null, USE_TOGGLE ); // Do not change USE_TYPE input.
            }
#if SERVER
            else
            {
                randomizer::m_Logger.warn( "Failed to swap a squad. null owner for squad" );
            }
#endif
        }
#if SERVER
        else
        {
            randomizer::m_Logger.warn( "Failed to swap a squad: {}", { ( squad is null ? "null squad" : "null owner for squad" ) } );
        }
#endif
    }

    // Swap all squads to a random and unique location.
    void randomize( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
    {
        g_RandomizerHeadcrab.init();
        g_RandomizerNpc.init();
        g_RandomizerBoss.init();
        g_RandomizerHull.init();
        g_RandomizerWave.init();
        g_RandomizerItem.init();

        // Free the entity slot.
        if( pActivator !is null )
            pActivator.pev.flags |= FL_KILLME;
    }
}

namespace lasers
{
    void add_sentry( CBaseMonster@ squad, CBaseEntity@ entity )
    {
        // Sentries are spawned via squadmaker so g_sentry_laser can't find them.
        if( entity !is null )
        {
            g_sentry_laser.handles.insertLast( EHandle( entity ) );
        }
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
