/**
*   Copyright (c) 2026 Mikk155 and contributors of bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software to use, copy, modify, merge, publish, distribute, sublicense,
*   and/or sell copies of the Software under the following conditions:
*   
*   A reference to the original project must be included in all copies or substantial
*   portions of the Software. This must include, at minimum, a URL to:
*   https://github.com/Mikk155/bts_rc
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies of the Software when distributed as a whole.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
**/

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

            if( gpGameVersion == 526 )
            {
                CBaseEntity@ roach = g_EntityFuncs.FindEntityInSphere( null, other.pev.origin, 512, "monster_shockroach", "classname" );

                if( roach !is null )
                {
                    auto newRoach = g_EntityFuncs.Create( "monster_shockroach", roach.pev.origin, roach.pev.angles, false, null );

                    if( newRoach !is null )
                    {
                        newRoach.Killed( other.pev, GIB_NEVER );
                    }
                }
            }

            return HOOK_CONTINUE;
        }
        return HOOK_CONTINUE;
    }
}
