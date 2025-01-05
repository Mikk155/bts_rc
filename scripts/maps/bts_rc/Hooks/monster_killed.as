/*
    Author: Mikk
*/

HookReturnCode monster_killed( CBaseMonster@ monster, CBaseEntity@ attacker, int iGib )
{
    if( monster !is null )
    {
        dictionary@ user_data = monster.GetUserData();

        if( freeedicts( 1 ) )
        {
            if( monster.pev.classname == "monster_zombie" )
            {
                const float headcrab_health = g_EngineFuncs.CVarGetFloat( "sk_headcrab_health" );
                const float headcrab_damage = int(user_data[ "headcrab_damage" ]);

                // Check if the stored received damage is less than a headcrab's HP
                if( headcrab_damage < headcrab_health )
                {
                    monster.SetBodygroup( 1, 1 );
                }

                // This model does have an extra bodygroup for the headcrab or was gibbed
                if( monster.GetBodygroup( 1 ) == 1 || iGib == GIB_ALWAYS )
                {
                    CBaseEntity@ headcrab = g_EntityFuncs.Create( "monster_headcrab", monster.pev.origin + Vector( 0, 0, 72 ), monster.pev.angles, false, monster.edict() );

                    if( headcrab !is null )
                    {
                        headcrab.pev.health = headcrab_health - headcrab_damage;
                    }
                }
            }
        }

        // Create a blood puddle if possible.
        /* Do not create for non-bleedable npcs */
        if( monster.m_bloodColor != DONT_BLEED
        /* Check for Server operator's choices */
        && cvar_bloodpuddles.GetInt() == 0
        /* I'm sure Kern fixed this but just in case of a future update, we wouldn't want a bunch of puddles x[ */
        && !user_data.exists( "bloodpuddle" )
        /* Do not create if there's not at least 20 free slot */
        && freeedicts( 20 ) )
        {
            CBaseEntity@ bloodpuddle = g_EntityFuncs.Create(
                "env_bloodpuddle",
                /* About +6 units should be enough i think */
                monster.Center() + Vector( 0, 0, 6 ),
                g_vecZero,
                false,
                monster.edict()
            );

            if( bloodpuddle !is null && monster.m_bloodColor == ( BLOOD_COLOR_GREEN | BLOOD_COLOR_YELLOW ) )
            {
                bloodpuddle.pev.skin = 1;
            }

            user_data[ "bloodpuddle" ] = true;
        }
    }

    return HOOK_CONTINUE;
}
