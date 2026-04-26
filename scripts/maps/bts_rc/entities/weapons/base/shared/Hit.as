namespace weapons
{
    // Hit ahead. return whatever it was a hit or a miss. automatically damages the target with config data
    bool Hit( CBasePlayerWeapon@ weapon, CBasePlayer@ player, TraceResult&out tr, AttackType type, CBaseEntity@&out hit, ASMeleeWeaponConfig@ config, bool Shove = false )
    {
        Math.MakeVectors( player.pev.v_angle );
        Vector vecSrc = player.GetGunPosition();
        Vector vecDirection = g_Engine.v_forward;

        switch( type )
        {
            case AttackType::Tertiary:
                vecDirection = vecDirection * config.tertiary_distance;
            break;
            case AttackType::Secondary:
                vecDirection = vecDirection * config.secondary_distance;
            break;
            case AttackType::Primary:
            default:
                vecDirection = vecDirection * config.primary_distance;
            break;
        }

        Vector vecEnd = vecSrc + vecDirection;

        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, player.edict(), tr );

        if( tr.flFraction >= 1.0f )
        {
            g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, player.edict(), tr );

            if( tr.flFraction < 1.0f )
            {
                // Calculate the point of intersection of the line (or hull) and the object we hit
                // This is and approximation of the "best" intersection
                if( tr.pHit !is null && ( @hit = g_EntityFuncs.Instance( tr.pHit ) ) is null || hit.IsBSPModel() )
                {
                    g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, player.edict() );
                }

                vecEnd = tr.vecEndPos; // This is the point on the actual surface (the hull could have hit space)
            }
        }

        if( hit !is null || ( tr.pHit !is null && ( @hit = g_EntityFuncs.Instance( tr.pHit ) ) !is null ) )
        {
            // Pull players just like the crowbar does
            if( g_WeaponsConfig.melee_weapons_pull && !Shove && hit.IsPlayer() )
            {
                hit.pev.velocity = hit.pev.velocity + ( player.pev.origin - hit.pev.origin ).Normalize() * g_WeaponsConfig.melee_weapons_push_force;
            }

            if( g_WeaponsConfig.melee_weapons_push )
            {
                if( ( hit.pev.flags & FL_ONGROUND ) == 0 && "monster_headcrab" == hit.GetClassname() )
                {
                    hit.pev.velocity = ( hit.pev.origin - player.pev.origin ).Normalize() * g_WeaponsConfig.melee_weapons_pull_force;
                    hit.pev.velocity.z = 200.0f;
                    hit.pev.nextthink = g_Engine.time + 0.2f;
                }
                else if( Shove && ( hit.IsMonster() || hit.IsPlayer() ) )
                {
                    hit.pev.velocity = hit.pev.velocity + ( player.pev.origin - hit.pev.origin ).Normalize() * -g_WeaponsConfig.melee_weapons_pull_force;
                }
            }

            g_WeaponFuncs.ClearMultiDamage();

            // subsequent swings do % less damage
            float subsequent = config.subsequent_hits_deduction;

            switch( type )
            {
                case AttackType::Primary:
                    subsequent = Math.max( 0.1, ( g_Engine.time > weapon.m_flNextPrimaryAttack + 1.0 ? 1.0 : subsequent ) );
                    hit.TraceAttack( player.pev, config.primary_damage * subsequent, g_Engine.v_forward, tr, ( DMG_SLASH | DMG_CLUB | DMG_BTS_WEAPON ) );
                break;
                case AttackType::Secondary:
                    subsequent = Math.max( 0.1, ( g_Engine.time > weapon.m_flNextSecondaryAttack + 1.0 ? 1.0 : subsequent ) );
                    hit.TraceAttack( player.pev, config.secondary_damage * subsequent, g_Engine.v_forward, tr, ( DMG_SLASH | DMG_CLUB | DMG_BTS_WEAPON ) );
                break;
            }

            g_WeaponFuncs.ApplyMultiDamage( player.pev, player.pev );
        }

        return ( tr.flFraction >= 1.0f );
    }
}
