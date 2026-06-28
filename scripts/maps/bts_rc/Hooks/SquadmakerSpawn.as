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
    void SquadmakerSpawn( CBaseMonster@ squad, CBaseEntity@ entity )
    {
        if( entity is null )
            return;

        auto ckv = squad.GetCustomKeyvalues();

        // Get squadmaker custom keyvalues and pass them to childs
        {
            auto ckv_ent = entity.GetCustomKeyvalues();

            CustomKeyvalue deathdrop = ckv.GetKeyvalue( "$s_deathdrop" );
            if( deathdrop.Exists() )
                ckv_ent.SetKeyvalue( "$s_deathdrop", deathdrop.GetString() );
        }

        string classname = entity.GetClassname();

        CBaseMonster@ monster = null;

        if( entity.IsMonster() )
            @monster = cast<CBaseMonster@>(entity);

        EntityOverriden::Register(  entity.entindex(), entity, ckv, monster );

        // Swap a specific squadmaker to a random location.
        if( ckv.GetKeyvalue( "$i_randomize_squad" ).GetInteger() == 1 )
        {
            if( squad !is null || !g_EntityFuncs.IsValidEntity( squad.pev.owner ) )
            {
                if( g_Logger.error.active )
                    g_Logger.error.print( snprintf( glog, "Failed to swap squad at %1 Null squadmaker", entity.pev.origin.ToString() ) );
                return;
            }

            CBaseEntity@ owner_spot = g_EntityFuncs.Instance( squad.pev.owner );

            if( owner_spot is null )
            {
                if( g_Logger.error.active )
                    g_Logger.error.print( snprintf( glog, "Failed to swap squad at %1 Null squadmaker's owner (randomizer entity)", entity.pev.origin.ToString() ) );
                return;
            }

            owner_spot.Use( null, null, USE_TOGGLE ); // Do not change USE_TYPE input.
        }
    }
}
