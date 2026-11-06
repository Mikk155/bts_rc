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

final class ASGruntEngineer : EntityOverriden, IConfigurable
{
    dictionary@ m_ScriptedSequence = {
        { "m_flRadius", "400" },
        { "m_iszEntity", "monster_human_torch_ally" },
        { "m_fMoveTo", "2" },
        { "m_flRepeat", "300" },
        { "m_iszPlay", "open_floor_grate" },
        { "moveto_radius", "5" },
        { "spawnflags", "32" }
    };

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
                "IConfigurable"
            ],
            "properties":
            {
                "interval":
                {
                    "title": "Think rate",
                    "type": "number",
                    "minimum": 0.0,
                    "description": "Internal think rate interval. the lower the value the more cpu usage"
                },
                "capacity":
                {
                    "type": "integer",
                    "minimum": 1,
                    "description": "Max sentry spawn capacity per engineer"
                },
                "distance":
                {
                    "type": "number",
                    "minimum": 32,
                    "description": "Distance from the engineer to spawn"
                },
                "spacing":
                {
                    "type": "number",
                    "minimum": 32,
                    "description": "Minimum distance between sentry locations"
                },
                "delay":
                {
                    "type": "number",
                    "minimum": 0.0,
                    "description": "Delay to spawn sentry after playing animation"
                }
            }
        }""";
    }

    uint capacity;
    float distance;
    float spacing;
    float delay;

    bool Register( meta_api::json::v2::json@ config ) override
    {
        if( !bool( config[ "active" ] ) )
            return false;

        this.capacity = uint( int( config[ "capacity" ] ) );
        this.distance = float( config[ "distance" ] );
        this.delay = float( config[ "delay" ] );
        this.spacing = float( config[ "spacing" ] );

        if( g_MapConfig.MapLoading )
        {
            EntityOverriden::SetThink( float( config[ "interval" ] ) );
            EntityOverriden::Register( this );
        }

        return true;
    }

    bool AddEntity( CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( monster is null || monster.GetClassname() != "monster_human_torch_ally" )
            return false;

        if( monster.GetTargetname().IsEmpty() )
            monster.pev.targetname = string_t( "engineergrunt_" + monster.entindex() );

        dictionary@ data = monster.GetUserData();

        data[ "sentry_left" ] = capacity;

        return EntityOverriden::AddEntity( entity, monster );
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

        switch( monster.m_MonsterState )
        {
            case MONSTERSTATE::MONSTERSTATE_IDLE:
            case MONSTERSTATE::MONSTERSTATE_ALERT:
                break;
            default:
                return EntityOverridenAction::None;
        }

        dictionary@ data = monster.GetUserData();

        array<EHandle>@ deployedSentries;
        if( !data.get( "sentry_list", @deployedSentries ) || deployedSentries is null )
        {
            @deployedSentries = {};
            @data[ "sentry_list" ] = deployedSentries;
        }

        for( uint ui = deployedSentries.length(); ui > 0; )
        {
            EHandle handle = deployedSentries[--ui];
            CBaseEntity@ sentry;

            if( !handle.IsValid() || ( @sentry = handle.GetEntity() ) is null || !sentry.IsAlive() )
            {
                deployedSentries.removeAt(ui);
                continue;
            }

            if( ( sentry.pev.origin - monster.pev.origin ).Length() <= this.spacing )
            {
                return EntityOverridenAction::None;
            }
        }

        float flAngRad = monster.pev.angles.y * Math.PI / 180.0;

        Vector vecDir( cos( flAngRad ), sin( flAngRad ), 0.0 );

        Vector vecPos = monster.pev.origin + vecDir * distance;

        bool canSpawn = false;

        if( !IsHullFree( vecPos ) )
        {
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

        if( m_Logger.get() !is null && m_Logger.get().trace.active )
            m_Logger.get().trace( "Spawn a sentry at {}", String::from_Vector( vecPos, true ) );

        CBaseEntity@ seq = g_EntityFuncs.CreateEntity( "scripted_sequence", this.m_ScriptedSequence, true );
        g_EntityFuncs.SetOrigin( seq, monster.pev.origin );
        seq.pev.angles[1] = monster.pev.angles[1];
        seq.Use( null, null, USE_ON, 0.0f );

        CBaseEntity@ sentry = g_EntityFuncs.Create( "monster_sentry", vecPos, g_vecZero, true, monster.edict() );
        g_EntityFuncs.DispatchKeyValue( sentry.edict(), "displayname", "H.E.C.U. Automatic Sentry MK1" );
        g_EntityFuncs.DispatchKeyValue( sentry.edict(), "classify", "4" );
        sentry.pev.angles.y = monster.pev.angles.y;
        sentry.pev.targetname = "sentry_" + monster.GetTargetname();
        Entity@ handle = Entity( sentry );

        deployedSentries.insertLast( handle.toHandle );

        g_Scheduler.SetTimeout( @this, "SpawnSentry", this.delay, handle, Entity(seq) );

        int remainingSentry = int( data[ "sentry_left" ] );
        remainingSentry--;

        if( remainingSentry <= 0 )
            return EntityOverridenAction::Remove;

        data[ "sentry_left" ] = remainingSentry;

        return EntityOverridenAction::None;
    }

    void SpawnSentry( Entity@ sentry, Entity@ sequence )
    {
        sequence.Remove(true);

        if( sentry.toEntity !is null )
        {
            g_EntityFuncs.DispatchSpawn( sentry.toEdict );

            g_SoundSystem.PlaySound( sentry.toEdict, SOUND_CHANNEL::CHAN_AUTO, "tfc/weapons/turrset.wav", 1.0f, ATTN_NORM );

            auto@ AimingLasersContext = g_MapConfig.GetContext( "aiming_lasers" );

            if( AimingLasersContext !is null )
            {
                auto@ AimingLasersOverrider = cast<ASAimingLasersConfig@>( AimingLasersContext );

                if( AimingLasersOverrider !is null )
                {
                    AimingLasersOverrider.AddEntity( sentry.toEntity, sentry.toMonster );
                }
            }
        }
    }
}
