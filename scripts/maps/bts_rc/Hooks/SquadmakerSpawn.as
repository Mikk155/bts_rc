namespace Hooks
{
void SquadmakerSpawn( CBaseMonster@ squad, CBaseEntity@ entity )
{
    if( entity is null )
        return;

    string classname = entity.GetClassname();

    // Add sentries to the lasers list
//    if( lasers::turrets.find( classname ) >= 0 )
    if( classname == "monster_sentry")
    {
        lasers::handles.insertLast( EHandle( entity ) );

        if( g_Logger.trace )
            g_Logger.trace = snprintf( glog, "Added %1 to lasers list at index %2.\n", classname, lasers::handles.length() );
    }

    auto ckv = entity.GetCustomKeyvalues();

    // Swap a specific squadmaker to a random location.
    if( ckv.GetKeyvalue( "$i_randomize_squad" ).GetInteger() == 1 )
    {
        if( squad !is null || !g_EntityFuncs.IsValidEntity( squad.pev.owner ) )
        {
            if( g_Logger.error )
                g_Logger.error = snprintf( glog, "Failed to swap squad at %1 Null squadmaker", entity.pev.origin.ToString() );
            return;
        }

        CBaseEntity@ owner_spot = g_EntityFuncs.Instance( squad.pev.owner );

        if( owner_spot is null )
        {
            if( g_Logger.error )
                g_Logger.error = snprintf( glog, "Failed to swap squad at %1 Null squadmaker's owner (randomizer entity)", entity.pev.origin.ToString() );
            return;
        }

        owner_spot.Use( null, null, USE_TOGGLE ); // Do not change USE_TYPE input.
    }
}
}