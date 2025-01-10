/*
    Author: Mikk
*/

#if DEVELOP
    namespace monster_killed
    {
        CLogger@ m_Logger = CLogger( "MonsterKilledHook" );
    }
#endif

// Stupid language without Lambdas x[
void npcdrop( const string &in name, CBaseMonster@ monster )
{
    if( monster !is null )
    {
        CBaseEntity@ item = g_EntityFuncs.Create( name, monster.Center(), g_vecZero, false, monster.edict() );

        if( item !is null )
        {
#if DEVELOP
            monster_killed::m_Logger.info( "Created item \"{}\" for monster \"{}\" at \"{}\"", { name, monster.pev.classname, monster.Center().ToString() } );
#endif
            item.pev.spawnflags |= 1024; // no more respawn
        }
    }
}

// Stupid language without goto x[
void zombie_crab( CBaseMonster@ monster, int iGib, dictionary@ user_data )
{
    if( monster !is null )
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
                CBaseEntity@ headcrab = g_EntityFuncs.Create( "monster_headcrab", monster.pev.origin + Vector( 0, 0, 72 ), monster.pev.angles, false, monster.edict() );

                if( headcrab !is null )
                {
                    headcrab.pev.health = headcrab_health - headcrab_damage;

#if DEVELOP
                    monster_killed::m_Logger.info( "Created Headcrab for \"{}\" at \"{}\" with \"{}\" HP", { monster.pev.classname, headcrab.pev.origin.ToString(), headcrab.pev.health } );
#endif
                }
            }
#if DEVELOP
            else
            {
                monster_killed::m_Logger.info( "Monster \"{}\" doesn't have a headcrab hitgroup for model \"{}\"", { monster.pev.classname, monster.pev.model } );
            }
#endif
        }
    }
}

HookReturnCode monster_killed( CBaseMonster@ monster, CBaseEntity@ attacker, int iGib )
{
    if( monster !is null )
    {
        dictionary@ user_data = monster.GetUserData();

        if( freeedicts( 1 ) )
        {
            // Monsters drop items
            if( monster.pev.classname == "monster_zombie" )
            {
                zombie_crab(monster, iGib, user_data);

                switch( Math.RandomLong( 1, 7 ) )
                {
                    case 1:
                        npcdrop( BTS_FLASHLIGHT::GetAmmoName(), monster );
                    break;
                    case 2:
                        npcdrop( BTS_FLARE::GetName(), monster );
                    break;
                    case 3:
                        npcdrop( HL_GLOCKSD::GetDAmmoName(), monster );
                    break;
                    case 4:
                        npcdrop( "item_bts_sprayaid", monster );
                    break;
                }
            }
            else if( monster.pev.classname == "monster_zombie_barney" )
            {
                zombie_crab(monster, iGib, user_data);

                switch( Math.RandomLong( 1, 7 ) )
                {
                    case 1:
                        npcdrop( HL_GLOCKSD::GetDAmmoName(), monster );
                    break;
                    case 2:
                        npcdrop( BTS_DEAGLE::GetDAmmoName(), monster );
                    break;
                    case 3:
                        npcdrop( HL_SHOTGUN::GetDAmmoName(), monster );
                    break;
                    case 4:
                        npcdrop( HL_BERETTA::GetAmmoName(), monster );
                    break;
                }
            }
            else if( monster.pev.classname == "monster_zombie_soldier" || monster.pev.classname == "monster_gonome" )
            {
                switch( Math.RandomLong( 1, 15 ) )
                {
                    case 1:
                    case 2:
                        npcdrop( HL_SHOTGUN::GetDAmmoName(), monster );
                    break;
                    case 3:
                        npcdrop( HL_MP5::GetDAmmoName(), monster );
                    break;
                    case 4:
                        npcdrop( BTS_M16A3::GetDAmmoName(), monster );
                    break;
                    case 5:
                        npcdrop( CPython::GetDAmmoName(), monster );
                    break;
                    case 6:
                        npcdrop( BTS_DEAGLE::GetDAmmoName(), monster );
                    break;
                    case 7:
                        npcdrop( HL_GLOCKSD::GetDAmmoName(), monster );
                    break;
                    case 8:
                        npcdrop( BTS_M4::GetDAmmoName(), monster );
                    break;
                    case 9:
                        npcdrop( "item_bts_hevbattery", monster );
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
                    npcdrop( HL_MP5GL::GetDAmmoName(), monster );
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
