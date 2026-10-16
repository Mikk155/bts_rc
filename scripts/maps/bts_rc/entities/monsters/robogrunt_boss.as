/**
*   Copyright (c) 2026 Mikk155 and contributors of bts_rc
*
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software to use, copy, modify, merge, publish, distribute, sublicense,
*   and/or sell copies of the Software under the following conditions:
*
*   A reference to the original project must be included in all copies or substantial
*   portions of the Software. This must include, at minimum, a URL to:
*   https://github.com/Mikk155/bts_rc
*
*   The above copyright notice and this permission notice shall be included in all
*   copies of the Software when distributed as a whole.
*
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
**/

const int SHIELD_AOE_RADIUS = 240;
const float SHIELD_AOE_DAMAGE = 15.0;
const float SHIELD_AOE_KNOCKBACK = 1337.0;
const float SURROUND_RADIUS = 220.0;                        // the number of players within this range will change the color and damage of the aoe
const float SURROUND_BONUS = 1.1;                           // damage multiplied by this for every player in range (~ish) set to 0.0 for no bonus (unless my math is flawed :owo:)
const RGBA SONIC_BEAM_COLOR_1 = RGBA( 188, 220, 255, 255 ); // based on number of nearby players
const RGBA SONIC_BEAM_COLOR_2 = RGBA( 101, 133, 221, 255 );
const RGBA SONIC_BEAM_COLOR_3 = RGBA( 67, 85, 255, 255 );
const RGBA SONIC_BEAM_COLOR_4 = RGBA( 62, 33, 211, 255 );

const float ANTIFLARE_RANGE = 200.0;

final class ASRoboGruntBoss : ASRoboGrunt
{
    const string& GetName() const override {
        return "robo_grunt_boss";
    }

    private int m_iShockwave;
    private int m_iAnimAttack = -1;
    private int m_iAnimSpindown = -1;
    private int m_iAnimShieldStomp = -1;

    bool Register( btson@ config ) override
    {
        if( g_MapConfig.MapLoading )
        {
            g_SoundSystem.PrecacheSound( "garg/gar_stomp1.wav" );
            this.m_iShockwave = g_Game.PrecacheModel( "sprites/shockwave.spr" );
        }

        return ASRoboGrunt::Register( config );
    }

    bool AddEntity( CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( monster is null || string( entity.pev.model ) != "models/bts_rc/monsters/robothwgrunt.mdl" )
            return false;

        if( !g_IsMainMap )
            SetDebugName( entity, "Robo grunt boss" );

        if( this.m_iAnimAttack < 0 )
            this.m_iAnimAttack = monster.LookupSequence( "attack" );

        if( this.m_iAnimSpindown < 0 )
            this.m_iAnimSpindown = monster.LookupSequence( "spindown" );

        if( this.m_iAnimShieldStomp < 0 )
            this.m_iAnimShieldStomp = monster.LookupSequence( "shield_stomp" );

        BurningMonster::SetInmune( entity );

        return EntityOverriden::AddEntity( entity, monster );
    }

    uint TakeDamage( uint index, CBaseMonster@ monster, DamageInfo@ info ) override
    {
        if( info.flDamage <= 0.0 or monster.pev.takedamage == DAMAGE_NO )
            return ASRoboGrunt::TakeDamage( index, monster, info );

        if( ( info.bitsDamageType & DMG_BLAST ) != 0 && monster.pev.health > 10.0 )
        {
            info.bitsDamageType &= ~DMG_BLAST | DMG_LAUNCH;
            info.flDamage *= this.m_fDmgMultiplierBlast;
        }

        dictionary@ data = monster.GetUserData();
        int hitgroup = monster.MyMonsterPointer().m_LastHitGroup;

        switch( hitgroup )
        {
            case 15:
            {
                TraceResult tr = g_Utility.GetGlobalTrace();

                if( info.pAttacker !is null and info.pAttacker.IsPlayer() )
                {
                    NetworkMessage m( MSG_ONE, NetworkMessages::ShieldRic, info.pAttacker.edict() );
                        m.WriteCoord( tr.vecEndPos.x );
                        m.WriteCoord( tr.vecEndPos.y );
                        m.WriteCoord( tr.vecEndPos.z );
                    m.End();
                }

//                info.flDamage *= DAMAGE_MULT_SHIELD; this was at 0.0

                break;
            }
            case HITGROUP_HEAD:
            {
                data[ "smokepuff" ] = int( 3 + ( info.flDamage / 5.0 ) );
                break;
            }
        }

        return ASRoboGrunt::TakeDamage( index, monster, info );
    }

    CBaseEntity@ CheckTraceHullAttack( CBaseEntity@ attacker, float dist )
    {
        TraceResult tr;
        Math.MakeAimVectors( attacker.pev.angles );

        Vector vecStart = attacker.pev.origin;
        vecStart.z += attacker.pev.size.z * 0.5;
        Vector vecEnd = vecStart + ( g_Engine.v_forward * dist );

        g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, attacker.edict(), tr );

        return g_EntityFuncs.Instance( tr.pHit );
    }

    int Nearby( CBaseMonster@ monster )
    {
        int iNearby = 0;

        CBaseEntity@ entity = null;
        while( ( @entity = g_EntityFuncs.FindEntityInSphere( entity, monster.pev.origin, SURROUND_RADIUS, "*", "classname" ) ) !is null )
        {
            if( entity.pev.FlagBitSet( FL_MONSTER | FL_CLIENT ) and entity.pev.takedamage != DAMAGE_NO and entity.edict() !is monster.edict() )
            {
                if( !monster.FVisible( entity, true ) )
                    continue;

                if( monster.IRelationship( entity ) <= R_NO )
                    continue;

                iNearby++;
            }
        }

        return iNearby;
    }

    void MeleeAttack( CBaseMonster@ monster, bool bKick )
    {
        float flRange = bKick ? 80 : 70;
        float flDamage = bKick ? 15 : 30;

        CBaseEntity@ victim = CheckTraceHullAttack( monster, flRange );

        if( victim !is null )
        {
            victim.TakeDamage( monster.pev, monster.pev, flDamage, DMG_CRUSH );

            if( victim.IsMonster() || victim.IsPlayer() )
            {
                victim.pev.punchangle.z = -18;
                victim.pev.punchangle.x = 5;

                if( bKick )
                    victim.pev.velocity = victim.pev.velocity + g_Engine.v_forward * 400 + g_Engine.v_up * 400;
                else
                    victim.pev.velocity = victim.pev.velocity - g_Engine.v_right * 200;
            }

            switch( RandomUint( 2, monster ) )
            {
                case 0: g_SoundSystem.EmitSoundDyn( monster.edict(), CHAN_WEAPON, "zombie/claw_strike1.wav", VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) ); break;
                case 1: g_SoundSystem.EmitSoundDyn( monster.edict(), CHAN_WEAPON, "zombie/claw_strike2.wav", VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) ); break;
                case 2: g_SoundSystem.EmitSoundDyn( monster.edict(), CHAN_WEAPON, "zombie/claw_strike3.wav", VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) ); break;
            }
        }
        else
        {
            switch( RandomUint( 1, monster ) )
            {
                case 0: g_SoundSystem.EmitSoundDyn( monster.edict(), CHAN_WEAPON, "zombie/claw_miss1.wav", VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) ); break;
                case 1: g_SoundSystem.EmitSoundDyn( monster.edict(), CHAN_WEAPON, "zombie/claw_miss2.wav", VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) ); break;
            }
        }
    }

    RGBA GetBeamColor( CBaseMonster@ monster, bool bRandom = false )
    {
        if( monster is null )
            return RGBA( 255, 255, 255, 255 );

        uint8 bRed, bGreen, bBlue;

        if( bRandom || Nearby( monster ) >= 1 )
        {
            int iNumToCheck = Nearby( monster );
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

    uint EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( !entity.IsAlive() )
            return ASRoboGrunt::EntityThink( index, entity, monster );

        dictionary@ data = monster.GetUserData();

        float attackTime;

        if( data.get( "nextkick", attackTime ) && attackTime <= g_Engine.time )
        {
            MeleeAttack( monster, true );
            data.delete( "nextkick" );
        }
        else if( data.get( "nextslam", attackTime ) && attackTime <= g_Engine.time )
        {
            MeleeAttack( monster, false );
            data.delete( "nextslam" );
        }
        else if( data.get( "nextstompcheck", attackTime ) && attackTime <= g_Engine.time
        && monster.pev.sequence != this.m_iAnimShieldStomp
        && Nearby( monster ) >= 1 )
        {
            if( monster.pev.sequence == this.m_iAnimAttack
            ||   monster.pev.sequence == this.m_iAnimSpindown )
            {
                switch( RandomUint( 1, monster ) )
                {
                    case 0:
                    {
                        monster.ChangeSchedule( monster.GetScheduleOfType( SCHED_RELOAD ) );
                        data[ "nextslam" ] = g_Engine.time + 0.1;
                        data[ "nextstomp" ] = g_Engine.time + 0.3;
                        break;
                    }
                    case 1:
                    {
                        monster.ChangeSchedule( monster.GetScheduleOfType( SCHED_ARM_WEAPON ) );
                        data[ "nextkick" ] = g_Engine.time + 0.1;
                        data[ "nextstomp" ] = g_Engine.time + 0.3;
                        break;
                    }
                }
            }
        }
        else if( data.get( "nextstomp", attackTime ) && attackTime <= g_Engine.time)
        {
            if( monster.pev.sequence == this.m_iAnimShieldStomp )
            {
                float flAdjustedDamage;
                float flDist;
                RGBA beamColor = GetBeamColor( monster );

                // Houndeye rings
                {
                    NetworkMessage m( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, monster.pev.origin );
                        m.WriteByte( TE_BEAMCYLINDER );
                        m.WriteCoord( monster.pev.origin.x );
                        m.WriteCoord( monster.pev.origin.y );
                        m.WriteCoord( monster.pev.origin.z + 16 );
                        m.WriteCoord( monster.pev.origin.x );
                        m.WriteCoord( monster.pev.origin.y );
                        m.WriteCoord( monster.pev.origin.z + 16 + SHIELD_AOE_RADIUS / 0.2 ); // reach damage radius over .3 seconds
                        m.WriteShort( this.m_iShockwave );
                        m.WriteByte( 0 ); // startframe
                        m.WriteByte( 0 ); // framerate
                        m.WriteByte( 2 ); // life
                        m.WriteByte( 16 ); // width
                        m.WriteByte( 0 ); // noise
                        m.WriteByte( beamColor.r ); // r, g, b
                        m.WriteByte( beamColor.g ); // r, g, b
                        m.WriteByte( beamColor.b ); // r, g, b
                        m.WriteByte( beamColor.a ); // brightness
                        m.WriteByte( 0 ); // speed
                    m.End();
                }

                {
                    NetworkMessage m( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, monster.pev.origin );
                        m.WriteByte( TE_BEAMCYLINDER );
                        m.WriteCoord( monster.pev.origin.x );
                        m.WriteCoord( monster.pev.origin.y );
                        m.WriteCoord( monster.pev.origin.z + 16 );
                        m.WriteCoord( monster.pev.origin.x );
                        m.WriteCoord( monster.pev.origin.y );
                        m.WriteCoord( monster.pev.origin.z + 16 + ( SHIELD_AOE_RADIUS / 2 ) / 0.2 ); // reach damage radius over .3 seconds
                        m.WriteShort( this.m_iShockwave );
                        m.WriteByte( 0 ); // startframe
                        m.WriteByte( 0 ); // framerate
                        m.WriteByte( 2 ); // life
                        m.WriteByte( 16 ); // width
                        m.WriteByte( 0 ); // noise
                        m.WriteByte( beamColor.r ); // r, g, b
                        m.WriteByte( beamColor.g ); // r, g, b
                        m.WriteByte( beamColor.b ); // r, g, b
                        m.WriteByte( beamColor.a ); // brightness
                        m.WriteByte( 0 ); // speed
                    m.End();
                }

                CBaseEntity@ pEntity = null;
                while( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, monster.pev.origin, SHIELD_AOE_RADIUS, "*", "classname" ) ) !is null )
                {
                    if( pEntity.pev.takedamage != DAMAGE_NO and pEntity.edict() !is monster.edict() )
                    {
                        if( !pEntity.pev.ClassNameIs( "monster_hwgrunt" ) )
                        {
                            if( Nearby( monster ) > 1 )
                                flAdjustedDamage = SHIELD_AOE_DAMAGE + SHIELD_AOE_DAMAGE * ( SURROUND_BONUS * ( Nearby( monster ) - 1 ) );
                            else
                                flAdjustedDamage = SHIELD_AOE_DAMAGE;

                            flDist = ( pEntity.Center() - monster.pev.origin ).Length();

                            flAdjustedDamage -= ( flDist / SHIELD_AOE_RADIUS ) * flAdjustedDamage;

                            if( !monster.FVisible( pEntity, true ) )
                            {
                                if( pEntity.pev.FlagBitSet( FL_CLIENT ) )
                                    flAdjustedDamage *= 0.5;
                                else if( !pEntity.pev.ClassNameIs( "func_breakable" ) and !pEntity.pev.ClassNameIs( "func_pushable" ) )
                                    flAdjustedDamage = 0;
                            }

                            // ONLY allow players and monsters
                            if( !pEntity.pev.FlagBitSet( FL_CLIENT | FL_MONSTER ) )
                                continue;

                            // Extra safety: don't push non-damageable or dead things
                            if( pEntity.pev.takedamage == DAMAGE_NO )
                                continue;

                            Vector vecAttacker = monster.pev.origin;
                            Vector vecVictim = pEntity.pev.origin;
                            Vector vecVicCurVel;

                            vecAttacker.z = vecVictim.z = 0.0;
                            vecVictim = vecVictim - vecAttacker;

                            float flDistance = vecVictim.Length();
                            if( flDistance <= 0.0f )
                                continue;

                            vecVictim = vecVictim * ( 1.0f / flDistance );

                            vecVicCurVel = pEntity.pev.velocity;
                            vecVictim = vecVictim * SHIELD_AOE_KNOCKBACK;
                            vecVictim.z = vecVictim.Length() * 0.15f;

                            if( !monster.pev.FlagBitSet( FL_ONGROUND ) )
                            {
                                vecVictim = vecVictim * 1.2f;
                                vecVictim.z *= 0.4f;
                            }

                            if( vecVictim.Length() > vecVicCurVel.Length() )
                                pEntity.pev.velocity = vecVictim;
                            if( flAdjustedDamage > 0 )
                                pEntity.TakeDamage( monster.pev, monster.pev, flAdjustedDamage, DMG_SONIC | DMG_ALWAYSGIB );
                        }
                    }
                }
                data.delete( "nextstomp" );
            }
            else
            {
                monster.ChangeSchedule( monster.GetScheduleOfType( SCHED_COWER ) );
                data[ "nextstomp" ] = g_Engine.time + 0.57;
            }
        }

        array<ASFlare@>@ livingFlares = util::GetLivingFlares();

        uint length = livingFlares.length();

        for( uint ui = 0; ui < length; ui++ )
        {
            ASFlare@ flare = livingFlares[ui];

            if( monster.FVisible( flare.self, true ) )
            {
                flare.pev.flags |= FL_KILLME;

                if( FreeEdicts( 1 ) )
                {
                    CBeam@ pBeam = g_EntityFuncs.CreateBeam( "sprites/laserbeam.spr", 50 );
                    if( pBeam !is null )
                    {
                        pBeam.PointsInit( monster.Center(), flare.self.Center() );
                        RGBA col;// = GetBeamColor( monster, true );
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
                    NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, flare.pev.origin );
                    m.WriteByte( TE_SMOKE );
                    m.WriteCoord( flare.pev.origin.x );
                    m.WriteCoord( flare.pev.origin.y );
                    m.WriteCoord( flare.pev.origin.z - 32.0 );
                    m.WriteShort( models::steam1 );
                    m.WriteByte( Math.RandomLong( 1, 6 ) ); // scale * 10
                    m.WriteByte( 24 );                      // framerate
                    m.End();
                }

                g_SoundSystem.EmitSoundDyn( monster.edict(), CHAN_STATIC, "debris/beamstart14.wav", 0.8, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong( -10, 10 ) );
            }
        }

        return ASRoboGrunt::EntityThink( index, entity, monster );
    }
}
