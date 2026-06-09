namespace Hooks
{
    HookReturnCode PlayerCanCollect( CBaseEntity@ pickup, CBaseEntity@ other, bool &out result )
    {
        if( pickup is null || other is null )
            return HOOK_CONTINUE;

        string classname = pickup.GetClassname();

        if( classname == "weapon_shockrifle" )
        {
            result = false;

            CBaseEntity@ roach = g_EntityFuncs.FindEntityInSphere( null, other.pev.origin, 512, "monster_shockroach", "classname" );

            if( roach !is null )
            {
                auto newRoach = g_EntityFuncs.Create( "monster_shockroach", roach.pev.origin, roach.pev.angles, false, null );

                if( newRoach !is null )
                {
                    newRoach.Killed( other.pev, GIB_NEVER );
                }
            }

            return HOOK_CONTINUE;
        }
        return HOOK_CONTINUE;
    }
}
