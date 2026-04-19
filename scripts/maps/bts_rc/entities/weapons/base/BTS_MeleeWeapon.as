/**   MIT License
*   
*   Copyright (c) 2025 Mikk155 https://github.com/Mikk155/bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies or substantial portions of the Software.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*   SOFTWARE.
*/

abstract class BTS_MeleeWeapon : BTS_Weapon
{
    ASMeleeWeaponConfig@ get_configMelee() {
        return cast<ASMeleeWeaponConfig@>( this.config );
    }

    // Amount of swings in a raw
    int m_iSwing = 0;

    bool m_IsSecondary = false;

    // Set weapon cooldown
    void SetCooldown( bool is_trained_personal, bool miss, AttackType type ) {
        weapons::SetCooldown( self, configMelee.GetCooldown( is_trained_personal, type, miss ) );
    }

    // Hit ahead. return whatever it was a hit or a miss. automatically damages the target with config data
    bool Hit( TraceResult&out tr, AttackType type, CBaseEntity@&out hit )
    {
        auto player = this.owner;
        Math.MakeVectors( player.pev.v_angle );
        Vector vecSrc = player.GetGunPosition();
        Vector vecDirection = g_Engine.v_forward;

        switch( type )
        {
            case AttackType::Tertriary:
                vecDirection = vecDirection * this.configMelee.tertriary_distance;
            break;
            case AttackType::Secondary:
                vecDirection = vecDirection * this.configMelee.secondary_distance;
            break;
            case AttackType::Primary:
            default:
                vecDirection = vecDirection * this.configMelee.primary_distance;
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
            if( g_WeaponsConfig.melee_weapons_pull && hit.IsPlayer() )
            {
                hit.pev.velocity = hit.pev.velocity + ( owner.pev.origin - hit.pev.origin ).Normalize() * 120.0f;
            }

            if( g_WeaponsConfig.melee_weapons_push && ( hit.pev.flags & FL_ONGROUND ) == 0 && "monster_headcrab" == hit.GetClassname() )
            {
                hit.pev.velocity = ( hit.pev.origin - player.pev.origin ).Normalize() * 300.0f;
                hit.pev.velocity.z = 200.0f;
                hit.pev.nextthink = g_Engine.time + 0.2f;
            }

            g_WeaponFuncs.ClearMultiDamage();

            auto localconfigMelee = this.configMelee;

            // subsequent swings do % less damage
            float subsequent = ( self.m_flNextPrimaryAttack + 1.0f < g_Engine.time ) ? 1.0 : localconfigMelee.subsequent_hits_deduction;

            switch( type )
            {
                case AttackType::Primary:
                    hit.TraceAttack( player.pev, localconfigMelee.primary_damage * subsequent, g_Engine.v_forward, tr, DMG_SLASH | DMG_CLUB );
                break;
                case AttackType::Secondary:
                    hit.TraceAttack( player.pev, localconfigMelee.secondary_damage * subsequent, g_Engine.v_forward, tr, DMG_SLASH | DMG_CLUB );
                break;
            }

            g_WeaponFuncs.ApplyMultiDamage( player.pev, player.pev );
        }

        return ( tr.flFraction >= 1.0f );
    }
}
