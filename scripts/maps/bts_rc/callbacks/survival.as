namespace survival
{
    void activate( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
    {
        g_SurvivalMode.Activate();
    }
}
