HookReturnCode monster_killed( CBaseMonster@ monster, CBaseEntity@ attacker, int gib )
{
    if( monster !is null )
    {
        dictionary@ user_data = monster.GetUserData();

        if( freeedicts( 1 ) )
        {
            bool is_zombie = false;

            if( "monster_zombie" == monster.pev.classname )
            {
                is_zombie = true;
            }
            else if( monster.pev.classname == "monster_zombie_barney" )
            {
                is_zombie = true;
            }
            else if( monster.pev.classname == "monster_zombie_soldier" || monster.pev.classname == "monster_gonome" )
            {
                is_zombie = true;
            }

            if( is_zombie )
            {
                const float headcrab_health = g_EngineFuncs.CVarGetFloat( "sk_headcrab_health" );
                const float headcrab_damage = int( user_data["headcrab_damage"] );

                // Check if the stored received damage is less than a headcrab's HP
                if( headcrab_damage < headcrab_health )
                {
                    monster.SetBodygroup( 1, 1 );

                    // This model does have an extra bodygroup for the headcrab or was gibbed
                    if( monster.GetBodygroup( 1 ) == 1 || gib == GIB_ALWAYS )
                    {
                        // -TODO Should models have an attachment instead of +72 offset?
                        CBaseEntity@ headcrab = g_EntityFuncs.Create( "monster_headcrab", monster.pev.origin + Vector( 0, 0, 72 ), monster.pev.angles, false, monster.edict() );

                        if( headcrab !is null )
                        {
                            headcrab.pev.health = headcrab_health - headcrab_damage;
                        }
                    }
                }
            }
        }
    }

    return HOOK_CONTINUE;
}
