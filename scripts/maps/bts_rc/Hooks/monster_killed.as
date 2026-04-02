HookReturnCode monster_killed( CBaseMonster@ monster, CBaseEntity@ attacker, int gib )
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
                        drop_item = "ammo_bts_battery";
                        break;
                    case 2:
                        drop_item = "weapon_bts_flare";
                        break;
                    case 3:
                        drop_item = "ammo_bts_dglocksd";
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
                        drop_item = "ammo_bts_dglocksd";
                        break;
                    case 2:
                        drop_item = "ammo_bts_dreagle";
                        break;
                    case 3:
                        drop_item = "ammo_bts_shotshell";
                        break;
                    case 4:
                        drop_item = "ammo_bts_beretta";
                        break;
                }
            }
            else if( monster.pev.classname == "monster_human_grunt" && monster.pev.weapons == 5 )
            {
                drop_item = "ammo_bts_556round";
            }
            else if( monster.pev.classname == "monster_male_assassin" && monster.pev.weapons == 5 )
            {
                drop_item = "ammo_bts_556round";
            }
            else if( monster.pev.model == "models/bts_rc/monsters/zombie_medic.mdl" )
            {
                is_zombie = true;
                switch( Math.RandomLong( 1, 2 ) )
                {
                    case 1:
                        drop_item = "item_bts_sprayaid";
                        break;
                    case 2:
                        drop_item = "item_healthkit";
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
                        drop_item = "ammo_bts_shotshell";
                        break;
                    case 3:
                        drop_item = "ammo_bts_9mmbox";
                        break;
                    case 4:
                        drop_item = "ammo_bts_556round";
                        break;
                    case 5:
                        drop_item = "ammo_bts_357cyl";
                        break;
                    case 6:
                        drop_item = "ammo_bts_dreagle";
                        break;
                    case 7:
                        drop_item = "ammo_bts_dglocksd";
                        break;
                    case 8:
                        drop_item = "item_bts_hevbattery";
                        break;
                    default:
                        g_EntityFuncs.ShootTimed( monster.pev, monster.Center(), Vector( 0, 0, -90 ), Math.RandomFloat( 1.5, 5.5 ) );
                        break;
                }
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

            if( drop_item != String::EMPTY_STRING )
            {
                CBaseEntity@ item = g_EntityFuncs.Create( drop_item, monster.Center(), g_vecZero, false, monster.edict() );

                if( item !is null )
                {
                    item.pev.spawnflags |= 1024; // no more respawn
                }
            }
        }
    }

    return HOOK_CONTINUE;
}
