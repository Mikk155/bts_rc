namespace survival
{
    void activate( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
    {
        g_SurvivalMode.Activate();
    }

    void deactivate( CBaseEntity@ pActivator, CBaseEntity@ pCaller,  USE_TYPE useType, float flValue )
    {
        g_SurvivalMode.Disable();
    }

    void toggle( CBaseEntity@ pActivator, CBaseEntity@ pCaller,  USE_TYPE useType, float flValue )
    {
        if( g_SurvivalMode.IsActive() )
            deactivate( null, null, USE_SET, 0 );
        else
            activate( null, null, USE_SET, 0 );
    }
}
