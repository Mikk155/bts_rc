class BTS_MeleeWeapon : BTS_Weapon
{
    // Amount of swings in a raw
    int m_iSwing = 0;

    bool m_IsSecondary = false;

    float GetCooldown( bool is_trained_personal, bool miss, AttackType type )
    {
        switch( type )
        {
            case AttackType::Primary:
            {
                if( is_trained_personal )
                    return ( miss ? this.DefaultConfig.PrimaryMissTrainedCooldown : this.DefaultConfig.PrimaryCooldown );
                return ( miss ? this.DefaultConfig.PrimaryMissCooldown : this.DefaultConfig.PrimaryCooldown );
            }
            case AttackType::Secondary:
            {
                if( is_trained_personal )
                    return ( miss ? this.DefaultConfig.SecondaryMissTrainedCooldown : this.DefaultConfig.SecondaryTrainedCooldown );
                return ( miss ? this.DefaultConfig.SecondaryMissCooldown : this.DefaultConfig.SecondaryCooldown );
            }
            case AttackType::Tertriary:
            default:
            {
                return GetCooldown( is_trained_personal, type );
            }
        }
    }

    // Set weapon cooldown
    void SetCooldown( bool is_trained_personal, bool miss, AttackType type )
    {
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack =
            g_Engine.time + this.GetCooldown( is_trained_personal, miss, type );

        if( self.m_flTimeWeaponIdle < self.m_flNextPrimaryAttack )
            self.m_flTimeWeaponIdle= self.m_flNextPrimaryAttack;
    }

    // Hit ahead. return whatever it was a hit or a miss. automatically damages the target with DefaultConfig data
    bool Hit( TraceResult&out tr, AttackType type, CBaseEntity@&out hit )
    {
        auto player = this.owner;
        Math.MakeVectors( player.pev.v_angle );
        Vector vecSrc = player.GetGunPosition();
        Vector vecDirection = g_Engine.v_forward;

        switch( type )
        {
            case AttackType::Tertriary:
                vecDirection = vecDirection * this.DefaultConfig.TertriaryDistance;
            break;
            case AttackType::Secondary:
                vecDirection = vecDirection * this.DefaultConfig.SecondaryDistance;
            break;
            case AttackType::Primary:
            default:
                vecDirection = vecDirection * this.DefaultConfig.PrimaryDistance;
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
            if( weapons::gpAllowMeleePull && hit.IsPlayer() )
            {
                hit.pev.velocity = hit.pev.velocity + ( owner.pev.origin - hit.pev.origin ).Normalize() * 120.0f;
            }

            if( weapons::gpAllowMeleePush && ( hit.pev.flags & FL_ONGROUND ) == 0 && "monster_headcrab" == hit.GetClassname() )
            {
                hit.pev.velocity = ( hit.pev.origin - player.pev.origin ).Normalize() * 300.0f;
                hit.pev.velocity.z = 200.0f;
                hit.pev.nextthink = g_Engine.time + 0.2f;
            }

            g_WeaponFuncs.ClearMultiDamage();

            // subsequent swings do % less damage
            float subsequent = ( self.m_flNextPrimaryAttack + 1.0f < g_Engine.time ) ? 1.0 : this.DefaultConfig.SubsequentDeduction;

            switch( type )
            {
                case AttackType::Primary:
                    hit.TraceAttack( player.pev, this.DefaultConfig.PrimaryDamage * subsequent, g_Engine.v_forward, tr, DMG_SLASH | DMG_CLUB );
                break;
                case AttackType::Secondary:
                    hit.TraceAttack( player.pev, this.DefaultConfig.SecondaryDamage * subsequent, g_Engine.v_forward, tr, DMG_SLASH | DMG_CLUB );
                break;
            }

            g_WeaponFuncs.ApplyMultiDamage( player.pev, player.pev );
        }

        return ( tr.flFraction >= 1.0f );
    }
}
