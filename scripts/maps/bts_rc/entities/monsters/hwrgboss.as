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

/*
    Author: Nero
*/

namespace btscm
{

    HookReturnCode HWRGTakeDamage( DamageInfo@ pDamageInfo )
    {
        if( IsRobotBoss( pDamageInfo.pVictim ) )
        {
            if( pDamageInfo.flDamage <= 0.0 or pDamageInfo.pVictim.pev.takedamage == DAMAGE_NO )
                return HOOK_CONTINUE;

            int iHitGroup = pDamageInfo.pVictim.MyMonsterPointer().m_LastHitGroup;

            if( iHitGroup == HITGROUP_SHIELD )
            {
                TraceResult tr = g_Utility.GetGlobalTrace();

                if( pDamageInfo.pAttacker !is null and pDamageInfo.pAttacker.pev.FlagBitSet( FL_CLIENT ) )
                {
                    NetworkMessage m1( MSG_ONE, NetworkMessages::ShieldRic, pDamageInfo.pAttacker.edict() );
                    m1.WriteCoord( tr.vecEndPos.x );
                    m1.WriteCoord( tr.vecEndPos.y );
                    m1.WriteCoord( tr.vecEndPos.z );
                    m1.End();
                }

                pDamageInfo.flDamage *= DAMAGE_MULT_SHIELD;

                return HOOK_CONTINUE;
            }
            else if( iHitGroup == HITGROUP_HEAD and ( HasFlags( pDamageInfo.bitsDamageType, DMG_SNIPER ) or IsUsingSniperRifle( pDamageInfo.pAttacker ) ) )
            {
                CustomKeyvalues@ pCustom = pDamageInfo.pVictim.GetCustomKeyvalues();
                pCustom.SetKeyvalue( KVN_DOSMOKEPUFF, int( 3 + ( pDamageInfo.flDamage / 5.0 ) ) );

                pDamageInfo.flDamage *= DAMAGE_MULT_HEAD;

                return HOOK_CONTINUE;
            }

            HandleRobotDamage( pDamageInfo, true );
        }

        return HOOK_CONTINUE;
    }

    bool IsUsingSniperRifle( CBaseEntity@ pEntity )
    {
        if( HasFlags( pEntity.pev.flags, FL_CLIENT ) )
        {
            CBasePlayer@ pPlayer = cast<CBasePlayer@>( pEntity );

            if( pPlayer.m_hActiveItem.GetEntity() !is null and pPlayer.m_hActiveItem.GetEntity().GetClassname() == "weapon_bts_sniperrifle" )
                return true;
        }

        return false;
    }

    void HWRGThink()
    {
        CBaseEntity@ pEntity = null;
        while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_hwgrunt" ) ) !is null )
        {
            if( pEntity.pev.model != "models/bts_rc/monsters/robothwgrunt.mdl" )
                continue;

            // add a check for when they're not active (still hiding in a box away from the map) ??
            // in-game origins:
            //"192 4032 -245"
            //"304 4032 -245"
            //"306.898987 3901.97998 -245"
            //"-2040 -5960 -2079.96875"

            //.map origins:
            //"192 4032 -246"
            //"304 4032 -246"
            //"306.899 3901.98 -246"
            //"194.899 3901.98 -246"

            CustomKeyvalues@ pCustom = pEntity.GetCustomKeyvalues();
            float flNextThink = pCustom.GetKeyvalue( KVN_MONSTERTHINK ).GetFloat();
            float flNextShieldStompCheck = pCustom.GetKeyvalue( KVN_SHIELDCHECK ).GetFloat();

            if( flNextThink <= g_Engine.time )
            {
                if( pEntity.pev.deadflag == DEAD_NO )
                {
                    ShowDamage( EHandle( pEntity ) );
                    LowHealth( EHandle( pEntity ) );
                    DoShockTouch( EHandle( pEntity ) );
                    DoKick( EHandle( pEntity ) );
                    DoShieldSlam( EHandle( pEntity ) );
                    DoShieldStomp( EHandle( pEntity ) );
                    DealWithFlares( EHandle( pEntity ) );
                }

                DieThink( EHandle( pEntity ) );

                pCustom.SetKeyvalue( KVN_MONSTERTHINK, g_Engine.time + THINKRATE_OTHER );
            }

            if( flNextShieldStompCheck <= g_Engine.time )
            {
                CheckForShieldStomp( EHandle( pEntity ) );

                pCustom.SetKeyvalue( KVN_SHIELDCHECK, g_Engine.time + THINKRATE_AOE_CHECK );
            }
        }
    }

    void CheckForShieldStomp( EHandle hMonster )
    {
        CBaseMonster@ pMonster = hMonster.GetEntity().MyMonsterPointer();
        if( pMonster is null )
            return;

        CustomKeyvalues@ pCustom = pMonster.GetCustomKeyvalues();
        float flShieldStomp = pCustom.GetKeyvalue( KVN_SHIELDSTOMP ).GetFloat();
        if( flShieldStomp > 0 or pMonster.pev.sequence == pMonster.LookupSequence( "shield_stomp" ) )
            return;

        if( IsSurrounded( hMonster ) )
        {
            if( pMonster.pev.sequence == pMonster.LookupSequence( "attack" ) or pMonster.pev.sequence == pMonster.LookupSequence( "spindown" ) )
            {
                if( Math.RandomLong( 0, 1 ) == 1 )
                {
                    pMonster.ChangeSchedule( pMonster.GetScheduleOfType( SCHED_RELOAD ) );
                    pCustom.SetKeyvalue( KVN_SHIELDSLAM, g_Engine.time + 0.1 );
                    pCustom.SetKeyvalue( KVN_SHIELDSTOMP, g_Engine.time + 0.3 );
                }
                else
                {
                    pMonster.ChangeSchedule( pMonster.GetScheduleOfType( SCHED_ARM_WEAPON ) );
                    pCustom.SetKeyvalue( KVN_KICK, g_Engine.time + 0.1 );
                    pCustom.SetKeyvalue( KVN_SHIELDSTOMP, g_Engine.time + 0.3 );
                }
            }
            else
                pCustom.SetKeyvalue( KVN_SHIELDSTOMP, g_Engine.time );
        }
    }

    void DoShieldStomp( EHandle hMonster )
    {
        CBaseMonster@ pMonster = hMonster.GetEntity().MyMonsterPointer();
        if( pMonster is null )
            return;

        CustomKeyvalues@ pCustom = pMonster.GetCustomKeyvalues();
        float flShieldStomp = pCustom.GetKeyvalue( KVN_SHIELDSTOMP ).GetFloat();

        if( flShieldStomp > 0 and flShieldStomp <= g_Engine.time )
        {
            if( pMonster.pev.sequence == pMonster.LookupSequence( "shield_stomp" ) )
            {
                ShieldBlast( hMonster );
                pCustom.SetKeyvalue( KVN_SHIELDSTOMP, 0 );
            }
            else
            {
                pMonster.ChangeSchedule( pMonster.GetScheduleOfType( SCHED_COWER ) );
                pCustom.SetKeyvalue( KVN_SHIELDSTOMP, g_Engine.time + 0.57 );
            }
        }
    }

    void ShieldBlast( EHandle hMonster )
    {
        CBaseMonster@ pMonster = hMonster.GetEntity().MyMonsterPointer();
        if( pMonster is null )
            return;

        float flAdjustedDamage;
        float flDist;

        // Houndeye rings
        NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, pMonster.pev.origin );
        m1.WriteByte( TE_BEAMCYLINDER );
        m1.WriteCoord( pMonster.pev.origin.x );
        m1.WriteCoord( pMonster.pev.origin.y );
        m1.WriteCoord( pMonster.pev.origin.z + 16 );
        m1.WriteCoord( pMonster.pev.origin.x );
        m1.WriteCoord( pMonster.pev.origin.y );
        m1.WriteCoord( pMonster.pev.origin.z + 16 + SHIELD_AOE_RADIUS / 0.2 ); // reach damage radius over .3 seconds
        m1.WriteShort( g_Game.PrecacheModel( SPRITE_SHIELD_AOE ) );
        m1.WriteByte( 0 );                                                     // startframe
        m1.WriteByte( 0 );                                                     // framerate
        m1.WriteByte( 2 );                                                     // life
        m1.WriteByte( 16 );                                                    // width
        m1.WriteByte( 0 );                                                     // noise
        m1.WriteByte( GetBeamColor( hMonster ).r );                            // r, g, b
        m1.WriteByte( GetBeamColor( hMonster ).g );                            // r, g, b
        m1.WriteByte( GetBeamColor( hMonster ).b );                            // r, g, b
        m1.WriteByte( GetBeamColor( hMonster ).a );                            // brightness
        m1.WriteByte( 0 );                                                     // speed
        m1.End();

        NetworkMessage m2( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, pMonster.pev.origin );
        m2.WriteByte( TE_BEAMCYLINDER );
        m2.WriteCoord( pMonster.pev.origin.x );
        m2.WriteCoord( pMonster.pev.origin.y );
        m2.WriteCoord( pMonster.pev.origin.z + 16 );
        m2.WriteCoord( pMonster.pev.origin.x );
        m2.WriteCoord( pMonster.pev.origin.y );
        m2.WriteCoord( pMonster.pev.origin.z + 16 + ( SHIELD_AOE_RADIUS / 2 ) / 0.2 ); // reach damage radius over .3 seconds
        m2.WriteShort( g_Game.PrecacheModel( SPRITE_SHIELD_AOE ) );
        m2.WriteByte( 0 );                                                             // startframe
        m2.WriteByte( 0 );                                                             // framerate
        m2.WriteByte( 2 );                                                             // life
        m2.WriteByte( 16 );                                                            // width
        m2.WriteByte( 0 );                                                             // noise
        m2.WriteByte( GetBeamColor( hMonster ).r );                                    // r, g, b
        m2.WriteByte( GetBeamColor( hMonster ).g );                                    // r, g, b
        m2.WriteByte( GetBeamColor( hMonster ).b );                                    // r, g, b
        m2.WriteByte( GetBeamColor( hMonster ).a );                                    // brightness
        m2.WriteByte( 0 );                                                             // speed
        m2.End();

        CBaseEntity@ pEntity = null;
        while( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, pMonster.pev.origin, SHIELD_AOE_RADIUS, "*", "classname" ) ) !is null )
        {
            if( pEntity.pev.takedamage != DAMAGE_NO and pEntity.edict() !is pMonster.edict() )
            {
                if( !pEntity.pev.ClassNameIs( "monster_hwgrunt" ) )
                {
                    if( SurroundedBy( hMonster ) > 1 )
                        flAdjustedDamage = SHIELD_AOE_DAMAGE + SHIELD_AOE_DAMAGE * ( SURROUND_BONUS * ( SurroundedBy( hMonster ) - 1 ) );
                    else
                        flAdjustedDamage = SHIELD_AOE_DAMAGE;

                    flDist = ( pEntity.Center() - pMonster.pev.origin ).Length();

                    flAdjustedDamage -= ( flDist / SHIELD_AOE_RADIUS ) * flAdjustedDamage;

                    if( !pMonster.FVisible( pEntity, true ) )
                    {
                        if( pEntity.pev.FlagBitSet( FL_CLIENT ) )
                            flAdjustedDamage *= 0.5;
                        else if( !pEntity.pev.ClassNameIs( "func_breakable" ) and !pEntity.pev.ClassNameIs( "func_pushable" ) )
                            flAdjustedDamage = 0;
                    }

                    Knockback( hMonster, pEntity );

                    if( flAdjustedDamage > 0 )
                        pEntity.TakeDamage( pMonster.pev, pMonster.pev, flAdjustedDamage, DMG_SONIC | DMG_ALWAYSGIB );
                }
            }
        }
    }

    void Knockback( EHandle hMonster, CBaseEntity@ pTarget )
    {
        if( pTarget is null )
            return;

        // ONLY allow players and monsters
        if( !pTarget.pev.FlagBitSet( FL_CLIENT | FL_MONSTER ) )
            return;

        // Extra safety: don't push non-damageable or dead things
        if( pTarget.pev.takedamage == DAMAGE_NO )
            return;

        CBaseEntity@ pMonster = hMonster.GetEntity();
        if( pMonster is null )
            return;

        Vector vecAttacker = pMonster.pev.origin;
        Vector vecVictim = pTarget.pev.origin;
        Vector vecVicCurVel;

        vecAttacker.z = vecVictim.z = 0.0;
        vecVictim = vecVictim - vecAttacker;

        float flDistance = vecVictim.Length();
        if( flDistance <= 0.0f )
            return;

        vecVictim = vecVictim * ( 1.0f / flDistance );

        vecVicCurVel = pTarget.pev.velocity;
        vecVictim = vecVictim * SHIELD_AOE_KNOCKBACK;
        vecVictim.z = vecVictim.Length() * 0.15f;

        if( !pMonster.pev.FlagBitSet( FL_ONGROUND ) )
        {
            vecVictim = vecVictim * 1.2f;
            vecVictim.z *= 0.4f;
        }

        if( vecVictim.Length() > vecVicCurVel.Length() )
            pTarget.pev.velocity = vecVictim;
    }

    bool IsSurrounded( EHandle hMonster )
    {
        CBaseEntity@ pMonster = hMonster.GetEntity();
        if( pMonster is null )
            return false;

        return SurroundedBy( hMonster ) >= SHIELD_AOE_TRIGGER;
    }

    int SurroundedBy( EHandle hMonster )
    {
        CBaseEntity@ pMonster = hMonster.GetEntity();
        if( pMonster is null )
            return 0;

        int iSurroundedBy = 0;

        CBaseEntity@ pEntity = null;
        while( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, pMonster.pev.origin, SURROUND_RADIUS, "*", "classname" ) ) !is null )
        {
            if( pEntity.pev.FlagBitSet( FL_MONSTER | FL_CLIENT ) and pEntity.pev.takedamage != DAMAGE_NO and pEntity.edict() !is pMonster.edict() )
            {
                if( !pMonster.FVisible( pEntity, true ) )
                    continue;

                if( pMonster.IRelationship( pEntity ) <= R_NO )
                    continue;

                iSurroundedBy++;
            }
        }

        return iSurroundedBy;
    }

    RGBA GetBeamColor( EHandle hMonster, bool bRandom = false )
    {
        CBaseEntity@ pMonster = hMonster.GetEntity();
        if( pMonster is null )
            return RGBA( 255, 255, 255, 255 );

        uint8 bRed, bGreen, bBlue;

        if( IsSurrounded( hMonster ) or bRandom )
        {
            int iNumToCheck = SurroundedBy( hMonster );
            if( bRandom )
                iNumToCheck = Math.RandomLong( 0, 4 );

            switch( iNumToCheck )
            {
                case 2:
                    bRed = SONIC_BEAM_COLOR_2.r;
                    bGreen = SONIC_BEAM_COLOR_2.g;
                    bBlue = SONIC_BEAM_COLOR_2.b;
                    break;
                case 3:
                    bRed = SONIC_BEAM_COLOR_3.r;
                    bGreen = SONIC_BEAM_COLOR_3.g;
                    bBlue = SONIC_BEAM_COLOR_3.b;
                    break;
                case 4:
                    bRed = SONIC_BEAM_COLOR_4.r;
                    bGreen = SONIC_BEAM_COLOR_4.g;
                    bBlue = SONIC_BEAM_COLOR_4.b;
                    break;
                default:
                    bRed = SONIC_BEAM_COLOR_4.r;
                    bGreen = SONIC_BEAM_COLOR_4.g;
                    bBlue = SONIC_BEAM_COLOR_4.b;
                    break;
            }
        }
        else
        {
            bRed = SONIC_BEAM_COLOR_1.r;
            bGreen = SONIC_BEAM_COLOR_1.g;
            bBlue = SONIC_BEAM_COLOR_1.b;
        }

        return RGBA( bRed, bGreen, bBlue, 255 );
    }

    void DoKick( EHandle hMonster )
    {
        CBaseEntity@ pMonster = hMonster.GetEntity();
        if( pMonster is null )
            return;

        CustomKeyvalues@ pCustom = pMonster.GetCustomKeyvalues();
        float flKick = pCustom.GetKeyvalue( KVN_KICK ).GetFloat();

        if( flKick > 0 and flKick <= g_Engine.time )
        {
            MeleeAttack( hMonster, true );
            pCustom.SetKeyvalue( KVN_KICK, 0 );
        }
    }

    void DoShieldSlam( EHandle hMonster )
    {
        CBaseEntity@ pMonster = hMonster.GetEntity();
        if( pMonster is null )
            return;

        CustomKeyvalues@ pCustom = pMonster.GetCustomKeyvalues();
        float flShieldSlam = pCustom.GetKeyvalue( KVN_SHIELDSLAM ).GetFloat();

        if( flShieldSlam > 0 and flShieldSlam <= g_Engine.time )
        {
            MeleeAttack( hMonster, false );
            pCustom.SetKeyvalue( KVN_SHIELDSLAM, 0 );
        }
    }

    void MeleeAttack( EHandle hMonster, bool bKick )
    {
        CBaseEntity@ pMonster = hMonster.GetEntity();
        if( pMonster is null )
            return;

        float flRange = bKick ? KICK_RANGE : SHIELD_SLAM_RANGE;
        float flDamage = bKick ? KICK_DAMAGE : SHIELD_SLAM_DAMAGE;

        CBaseEntity@ pHurt = CheckTraceHullAttack( pMonster, flRange, flDamage, DMG_CRUSH );
        if( pHurt !is null )
        {
            if( HasFlags( pHurt.pev.flags, ( FL_MONSTER | FL_CLIENT ) ) )
            {
                pHurt.pev.punchangle.z = -18;
                pHurt.pev.punchangle.x = 5;

                if( bKick )
                    pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * KICK_FORCE + g_Engine.v_up * KICK_FORCE;
                else
                    pHurt.pev.velocity = pHurt.pev.velocity - g_Engine.v_right * SHIELD_SLAM_FORCE;
            }

            int iRandom = Math.RandomLong( 1, 3 );
            if( iRandom == 1 )
                g_SoundSystem.EmitSoundDyn( pMonster.edict(), CHAN_WEAPON, "zombie/claw_strike1.wav", VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) );
            else if( iRandom == 2 )
                g_SoundSystem.EmitSoundDyn( pMonster.edict(), CHAN_WEAPON, "zombie/claw_strike2.wav", VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) );
            else
                g_SoundSystem.EmitSoundDyn( pMonster.edict(), CHAN_WEAPON, "zombie/claw_strike3.wav", VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) );
        }
        else
        {
            if( Math.RandomLong( 1, 2 ) == 1 )
                g_SoundSystem.EmitSoundDyn( pMonster.edict(), CHAN_WEAPON, "zombie/claw_miss1.wav", VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) );
            else
                g_SoundSystem.EmitSoundDyn( pMonster.edict(), CHAN_WEAPON, "zombie/claw_miss2.wav", VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) );
        }

        // AttackSound();
    }

    CBaseEntity@ CheckTraceHullAttack( CBaseEntity@ pThis, float flDist, float flDamage, int iDmgType )
    {
        TraceResult tr;

        if( pThis.pev.FlagBitSet( FL_CLIENT ) )
            Math.MakeVectors( pThis.pev.angles );
        else
            Math.MakeAimVectors( pThis.pev.angles );

        Vector vecStart = pThis.pev.origin;
        vecStart.z += pThis.pev.size.z * 0.5;
        Vector vecEnd = vecStart + ( g_Engine.v_forward * flDist );

        g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, pThis.edict(), tr );

        if( tr.pHit !is null )
        {
            CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

            if( flDamage > 0 )
                pEntity.TakeDamage( pThis.pev, pThis.pev, flDamage, iDmgType );

            return pEntity;
        }

        return null;
    }

    void DealWithFlares( EHandle hMonster )
    {
        CBaseEntity@ pMonster = hMonster.GetEntity();
        if( pMonster is null )
            return;

        CBaseEntity@ pEntity = null;
        while( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, pMonster.pev.origin, ANTIFLARE_RANGE, "*", "classname" ) ) !is null )
        {
            if( pEntity.GetClassname() != "flare" )
                continue;

            if( pMonster.FVisible( pEntity, true ) )
                break;
        }

        if( pEntity !is null )
        {
            Vector vecCenter = pMonster.Center();

            if( pEntity.pev.solid != SOLID_NOT ) // just in case
                pEntity.Killed( null, GIB_NEVER );

            if( FreeEdicts( 1 ) )
            {
                CBeam@ pBeam = g_EntityFuncs.CreateBeam( SPRITE_ANTIFLARE, 50 );
                if( pBeam !is null )
                {
                    pBeam.PointsInit( pMonster.Center(), pEntity.Center() );
                    RGBA col = GetBeamColor( hMonster, true );
                    pBeam.SetColor( col.r, col.g, col.b );
                    pBeam.SetBrightness( col.a );
                    pBeam.SetFlags( 130 );
                    pBeam.SetNoise( 50 );
                    pBeam.SetScrollRate( 50.0 );
                    pBeam.LiveForTime( 0.2 );
                }
            }

            if( FreeEdicts( 1 ) )
            {
                NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pEntity.pev.origin );
                m1.WriteByte( TE_SMOKE );
                m1.WriteCoord( pEntity.pev.origin.x );
                m1.WriteCoord( pEntity.pev.origin.y );
                m1.WriteCoord( pEntity.pev.origin.z - 32.0 );
                m1.WriteShort( g_Game.PrecacheModel( SPRITE_RGRUNT_SMOKE ) );
                m1.WriteByte( Math.RandomLong( 1, 6 ) ); // scale * 10
                m1.WriteByte( 24 );                      // framerate
                m1.End();
            }

            g_SoundSystem.EmitSoundDyn( pMonster.edict(), CHAN_STATIC, "debris/beamstart14.wav", 0.8, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong( -10, 10 ) );
        }
    }

    void HWRGMapInit() // HWRGMapInit
    {
        g_Game.PrecacheModel( SPRITE_ANTIFLARE );

        // shield aoe
        g_SoundSystem.PrecacheSound( "garg/gar_stomp1.wav" );
        g_Game.PrecacheModel( SPRITE_SHIELD_AOE );

        // melee attacks
        g_SoundSystem.PrecacheSound( "zombie/claw_strike1.wav" );
        g_SoundSystem.PrecacheSound( "zombie/claw_strike2.wav" );
        g_SoundSystem.PrecacheSound( "zombie/claw_strike3.wav" );
        g_SoundSystem.PrecacheSound( "zombie/claw_miss1.wav" );
        g_SoundSystem.PrecacheSound( "zombie/claw_miss2.wav" );

        // handles different hitgroups (head, shield), ricochets, and damage reduction for various damage types, probably needs tweaking :eheh:
        g_Hooks.RegisterHook( Hooks::Monster::MonsterTakeDamage, @HWRGTakeDamage );
    }

} // namespace btscm END
