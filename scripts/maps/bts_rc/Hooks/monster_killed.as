/*
    Author: Mikk
*/

#if SERVER
    namespace monster_killed
    {
        CLogger@ m_Logger = CLogger( "MonsterKilledHook" );
    }
#endif

HookReturnCode monster_killed( CBaseMonster@ monster, CBaseEntity@ attacker, int iGib )
{
    if( monster !is null )
    {
        dictionary@ user_data = monster.GetUserData();

        if( freeedicts( 1 ) )
        {
            bool is_zombie = false;

            string drop_item = String::EMPTY_STRING;

            if( "monster_zombie" == monster.pev.classname )
            {
                is_zombie = true;

                switch( Math.RandomLong( 1, 7 ) )
                {
                    case 1:
                        drop_item = BTS_FLASHLIGHT::GetAmmoName();
                    break;
                    case 2:
                        drop_item = BTS_FLARE::GetName();
                    break;
                    case 3:
                        drop_item = HL_GLOCKSD::GetDAmmoName();
                    break;
                    case 4:
                        drop_item = "item_bts_sprayaid";
                    break;
                }
            }
            else if( monster.pev.classname == "monster_zombie_barney" )
            {
                is_zombie = true;

                switch( Math.RandomLong( 1, 7 ) )
                {
                    case 1:
                        drop_item = HL_GLOCKSD::GetDAmmoName();
                    break;
                    case 2:
                        drop_item = BTS_DEAGLE::GetDAmmoName();
                    break;
                    case 3:
                        drop_item = HL_SHOTGUN::GetDAmmoName();
                    break;
                    case 4:
                        drop_item = HL_BERETTA::GetAmmoName();
                    break;
                }
            }
            else if( monster.pev.classname == "monster_zombie_soldier" || monster.pev.classname == "monster_gonome" )
            {
                is_zombie = true;

                switch( Math.RandomLong( 1, 15 ) )
                {
                    case 1:
                    case 2:
                        drop_item = HL_SHOTGUN::GetDAmmoName();
                    break;
                    case 3:
                        drop_item = HL_MP5::GetDAmmoName();
                    break;
                    case 4:
                        drop_item = BTS_M16A3::GetDAmmoName();
                    break;
                    case 5:
                        drop_item = CPython::GetDAmmoName();
                    break;
                    case 6:
                        drop_item = BTS_DEAGLE::GetDAmmoName();
                    break;
                    case 7:
                        drop_item = HL_GLOCKSD::GetDAmmoName();
                    break;
                    case 8:
                        drop_item = BTS_M4::GetDAmmoName();
                    break;
                    case 9:
                        drop_item = "item_bts_hevbattery";
                    break;
                    case 10:
                    case 11:
                    case 12:
                    case 13:
                    case 14:
                    case 15:
                        g_EntityFuncs.ShootTimed( monster.pev, monster.Center(), Vector( 0, 0, -90 ), Math.RandomFloat( 1.5, 5.5 ) );
                    break;
                }
            }
            else if( monster.pev.classname == "monster_sentry" )
            {
                if( Math.RandomLong( 1, 2 ) == 1 )
                {
                    drop_item = HL_MP5GL::GetDAmmoName();
                }
            }

            if( is_zombie )
            {
                const float headcrab_health = g_EngineFuncs.CVarGetFloat( "sk_headcrab_health" );
                const float headcrab_damage = int(user_data[ "headcrab_damage" ]);

                // Check if the stored received damage is less than a headcrab's HP
                if( headcrab_damage < headcrab_health )
                {
                    monster.SetBodygroup( 1, 1 );

                    // This model does have an extra bodygroup for the headcrab or was gibbed
                    if( monster.GetBodygroup( 1 ) == 1 || iGib == GIB_ALWAYS )
                    {
                        // -TODO Should models have an attachment instead of +72 offset?
                        CBaseEntity@ headcrab = g_EntityFuncs.Create( "monster_headcrab", monster.pev.origin + Vector( 0, 0, 72 ), monster.pev.angles, false, monster.edict() );

                        if( headcrab !is null )
                        {
                            headcrab.pev.health = headcrab_health - headcrab_damage;

#if SERVER
                            monster_killed::m_Logger.info( "Created Headcrab for \"{}\" at \"{}\" with \"{}\" HP", { monster.pev.classname, headcrab.pev.origin.ToString(), headcrab.pev.health } );
#endif
                        }
                    }
#if SERVER
                    else
                    {
                        monster_killed::m_Logger.info( "Monster \"{}\" doesn't have a headcrab hitgroup for model \"{}\"", { monster.pev.classname, monster.pev.model } );
                    }
#endif
                }
            }

            if( drop_item != String::EMPTY_STRING )
            {
                CBaseEntity@ item = g_EntityFuncs.Create( drop_item, monster.Center(), g_vecZero, false, monster.edict() );

                if( item !is null )
                {
#if SERVER
                    monster_killed::m_Logger.info( "Created item \"{}\" for monster \"{}\" at \"{}\"", { drop_item, monster.pev.classname, monster.Center().ToString() } );
#endif
                    item.pev.spawnflags |= 1024; // no more respawn
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
