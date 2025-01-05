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

            if( cvar_bloodpuddles.GetInt() == 0 )
            {
                env_bloodpuddle::create(monster, user_data, iGib);
            }
        }
    }

    return HOOK_CONTINUE;
}
