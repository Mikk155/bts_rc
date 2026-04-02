namespace deathdrop
{
    class CDeathDropConfig : IConfigContext
    {
        dictionary m_Monsters;

        CDeathDropConfig()
        {
            ConfigContext::Register( this );
        }

        string GetName()
        {
            return "deathdrop";
        }

        void Parse( dictionary@ json )
        {
            array<string>@ monsters = json.getKeys();
            uint size = monsters.length();

            for( uint ui = 0; ui < size; ui++ )
            {
                string monster = monsters[ui];
                dictionary values = cast<dictionary@>( json[ monster ] );

                uint valuesSize = values.getSize();

                array<string> itemNames( valuesSize );

                for( uint ui2 = 0; ui2 < valuesSize; ui2++ )
                {
                    itemNames[ui2] = string( values[ui2] );
                }

                m_Monsters[ monster ] = itemNames;
            }

            g_Hooks.RegisterHook( Hooks::Monster::MonsterKilled, @deathdrop::monster_killed );
        }
    }

    CDeathDropConfig gpConfig;

    HookReturnCode monster_killed( CBaseMonster@ monster, CBaseEntity@ attacker, int gib )
    {
        if( monster is null || !freeedicts( 1 ) )
            return HOOK_CONTINUE;

        array<string>@ drops;

        if( !gpConfig.m_Monsters.get( string( monster.pev.model ), @drops ) )
            gpConfig.m_Monsters.get( monster.GetClassname(), @drops );

        if( drops is null || drops.length() <= 0 )
            return HOOK_CONTINUE;

        string drop = drops[ Math.RandomLong( 0, drops.length() - 1 ) ];

        if( drop.IsEmpty() )
            return HOOK_CONTINUE;

        if( drop == "grenade" )
        {
            g_EntityFuncs.ShootTimed( monster.pev, monster.Center(), Vector( 0, 0, -90 ), Math.RandomFloat( 1.5, 5.5 ) );
            return HOOK_CONTINUE;
        }

        CBaseEntity@ item = g_EntityFuncs.Create( drop, monster.Center(), g_vecZero, false, monster.edict() );

        if( item !is null )
            item.pev.spawnflags |= 1024; // no more respawn

        return HOOK_CONTINUE;
    }
}
