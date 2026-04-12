namespace survival
{
    void activate( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
    {
        gpGameStarted = true;
        g_SurvivalMode.Activate();
        item_tracker::Initialize();
    }
}
