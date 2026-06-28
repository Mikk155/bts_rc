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

/*
    Author: Mikk
    Original code: Nero
*/

final class ASGruntEngineer : EntityOverriden, IConfigurableContext
{
    const string& GetName() const override {
        return "grunt_engineer";
    }

    const string GetSchema() const override {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "description": "Controls engineer grunt sentry spawning",
            "allOf":
            [
                "IConfigurableContext"
            ],
            "properties":
            {
                "interval":
                {
                    "title": "Think rate",
                    "type": "number",
                    "minimum": 0.0,
                    "default": 0.1,
                    "description": "Internal think rate interval. the lower the value the more cpu usage"
                },
                "capacity":
                {
                    "default": 5,
                    "type": "integer",
                    "minimum": 1,
                    "description": "Max sentry spawn capacity per engineer"
                },
                "distance":
                {
                    "default": 128,
                    "type": "number",
                    "minimum": 32,
                    "description": "Distance from the engineer to spawn"
                },
                "cooldown_start":
                {
                    "default": 6.0,
                    "type": "number",
                    "minimum": 0,
                    "description": "Time until engineer can place a sentry after spawning"
                },
                "cooldown_combat":
                {
                    "default": 6.0,
                    "type": "number",
                    "minimum": 0,
                    "description": "How often to try to drop a sentry in combat, in seconds"
                },
                "cooldown_idle":
                {
                    "default": 30.0,
                    "type": "number",
                    "minimum": 0,
                    "description": "How often to try to drop a sentry while idle/roaming, in seconds"
                },
                "cooldown_rng":
                {
                    "default": 15.0,
                    "type": "number",
                    "minimum": 0,
                    "description": "cooldown_idle plus/minus this"
                },
                "chance":
                {
                    "default": 75,
                    "type": "number",
                    "minimum": 0,
                    "maximum": 100,
                    "description": "Chance to drop a sentry while idle/roaming, in percentage 0-100"
                }
            }
        }""";
    }

    private uint m_uiMaxCapacity;
    private float m_fRadius;
    private float m_fCooldownInitial;
    private float m_fCooldownCombat;
    private float m_fCooldownIdle;
    private float m_fCooldownRNG;
    private uint m_uiRandomChance;
    private int m_iGateAnimation = -1;

    bool Register( meta_api::json::v2::json@ config ) override
    {
        if( !bool( config[ "active" ] ) )
            return false;

        config.Get( "capacity", this.m_uiMaxCapacity );
        config.Get( "distance", this.m_fRadius, false );
        config.Get( "cooldown_start", this.m_fCooldownInitial, false );
        config.Get( "cooldown_combat", this.m_fCooldownCombat, false );
        config.Get( "cooldown_idle", this.m_fCooldownIdle, false );
        config.Get( "cooldown_rng", this.m_fCooldownRNG, false );
        config.Get( "chance", this.m_uiRandomChance, false );

        EntityOverriden::SetThink( float( config[ "interval" ] ) );

#if SERVER
        g_Game.PrecacheOther( "monster_human_torch_ally" );
#endif

        return true;
    }

    bool AddEntity( uint index, CBaseEntity@ entity, CustomKeyvalues@ ckv, CBaseMonster@ monster ) override
    {
        if( entity.GetClassname() != "monster_human_torch_ally" )
            return false;

#if SERVER
        SetDebugName( entity, "Engineer sentry spawner" );
#endif

        dictionary@ data = entity.GetUserData();

        data[ "sentry_left" ] = m_uiMaxCapacity;
        data[ "sentry_cooldown" ] = g_Engine.time + m_fCooldownInitial + Math.RandomFloat( -this.m_fCooldownRNG, this.m_fCooldownRNG );

#if SERVER
        data[ "sentry_cooldown" ] = g_Engine.time + 10.2;
#endif

        if( this.m_iGateAnimation < 0 )
            this.m_iGateAnimation = monster.LookupSequence( "open_floor_grate" );

        return EntityOverriden::AddEntity( index, entity, ckv, monster );
    }

    bool IsHullFree( const Vector &in vecPos )
    {
        TraceResult tr;
        g_Utility.TraceHull( vecPos, vecPos, dont_ignore_monsters, head_hull, null, tr );
        return ( tr.fStartSolid == 0 ) and ( tr.fAllSolid == 0 );
    }

    uint EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( monster is null || !monster.IsAlive() )
            return EntityOverridenAction::Remove;

        if( monster.pev.sequence == this.m_iGateAnimation )
            return EntityOverridenAction::None;

        dictionary@ data = monster.GetUserData();

        if( float( data[ "sentry_cooldown" ] ) > g_Engine.time )
            return EntityOverridenAction::None;

        bool canSpawn = false;

        switch( monster.m_MonsterState )
        {
            case MONSTERSTATE::MONSTERSTATE_COMBAT:
            {
                canSpawn = true;
                data[ "sentry_cooldown" ] = g_Engine.time + m_fCooldownCombat;
                break;
            }
            case MONSTERSTATE::MONSTERSTATE_IDLE:
            case MONSTERSTATE::MONSTERSTATE_ALERT:
            {
                if( this.m_uiRandomChance > 0 && uint( Math.RandomLong( 1, 100 ) ) <= this.m_uiRandomChance )
                {
                    canSpawn = true;
                    data[ "sentry_cooldown" ] = g_Engine.time + m_fCooldownIdle +
                        Math.RandomFloat( -this.m_fCooldownRNG, this.m_fCooldownRNG );
                }
                break;
            }
        }

        if( !canSpawn )
            return EntityOverridenAction::None;

        // Don't spawn a sentry if there's already one nearby
        if( data.exists( "sentry_last" ) )
        {
            auto@ sentry = cast<CBaseEntity@>( data[ "sentry_last" ] );

            if( sentry !is null && sentry.IsAlive() && ( sentry.pev.origin - monster.pev.origin ).Length() <= 128 )
                return EntityOverridenAction::None;
        }

        float flAngRad = monster.pev.angles.y * Math.PI / 180.0;

        Vector vecDir( cos( flAngRad ), sin( flAngRad ), 0.0 );

        Vector vecPos = monster.pev.origin + vecDir * m_fRadius;

        if( !IsHullFree( vecPos ) )
        {
            canSpawn = false;
            for( int up = 0; up <= 4; up++ )
            {
                for( int step = 0; step <= 6; step++ )
                {
                    Vector vecTest = vecPos + vecDir * float( step * 24 ) + Vector( 0.0, 0.0, float( up * 16 ) );

                    if( IsHullFree( vecTest ) )
                    {
                        vecPos = vecTest;
                        canSpawn = true;
                        break;
                    }
                }
            }
        }

        if( !canSpawn )
            return EntityOverridenAction::None;

        if( g_Logger.trace.active )
            g_Logger.trace.print( "Engineer grunt spawn a sentry at {}", { monster.pev.origin.ToString() } );

        // -TODO Make the monster face towards the sentry
        monster.SetState( MONSTERSTATE::MONSTERSTATE_SCRIPT );
        monster.ResetSequenceInfo();
        monster.pev.sequence = this.m_iGateAnimation;

        auto@ sentry = g_EntityFuncs.Create( "monster_sentry", vecPos, g_vecZero, true, monster.edict() );

        sentry.pev.angles.y = monster.pev.angles.y;

        g_Scheduler.SetTimeout( @this, "SpawnSentry", 1.0f, @sentry );

        int remainingSentry = int( data[ "sentry_left" ] );
        remainingSentry--;

        if( remainingSentry <= 0 )
            return EntityOverridenAction::Remove;

        data[ "sentry_left" ] = remainingSentry;
        @data[ "sentry_last" ] = sentry;

        return EntityOverridenAction::None;
    }

    void SpawnSentry( CBaseEntity@ sentry )
    {
        if( sentry !is null )
        {
            g_EntityFuncs.DispatchSpawn( sentry.edict() );

            auto@ AimingLasersContext = g_MapConfig.GetContext( "aiming_lasers" );

            if( AimingLasersContext !is null )
            {
                auto@ AimingLasersOverrider = cast<ASAimingLasersConfig@>( AimingLasersContext );

                if( AimingLasersOverrider !is null )
                {
                    AimingLasersOverrider.AddEntity( sentry.entindex(), sentry, sentry.GetCustomKeyvalues(), cast<CBaseMonster@>( sentry ) );
                }
            }
        }
    }
}
