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

const RGBA ASRoboGruntGlowColor( 100, 100, 220, 0 );

bool ASRoboGruntSchema = g_MapConfig.RegisterSchemaDefinition( "ASRoboGruntSchema",
"""{
    "explosion_damage":
    {
        "type": "integer",
        "minimum": 0,
        "description": "Explosion damage on death."
    },
    "dmg_generic":
    {
        "type": "number",
        "minimum": 0.01,
        "description": "Multiplier for generic damage not fit in other multipliers."
    },
    "dmg_burn":
    {
        "type": "number",
        "minimum": 0.01,
        "description": "Multiplier for DMG_BURN type damage (Flares, flamethrower)."
    },
    "dmg_blast":
    {
        "type": "number",
        "minimum": 0.01,
        "description": "Multiplier for DMG_BLAST type damage (Grenades, Explosives)."
    },
    "dmg_melee":
    {
        "type": "number",
        "minimum": 0.01,
        "description": "Multiplier for DMG_CLUB | DMG_SLASH type damage (Crowbar, knife, pipe etc)."
    },
    "dmg_bullet":
    {
        "type": "number",
        "minimum": 0.01,
        "description": "Multiplier for DMG_BULLET type damage (All fire arms)."
    },
    "shock_touch":
    {
        "type": "integer",
        "minimum": 0,
        "description": "Damage dealt to nearby entities during a shock discharge."
    },
    "shock_delay":
    {
        "type": "number",
        "minimum": 0.1,
        "description": "Shock discharge delay after taking damage cooldown."
    },
    "shock_radius":
    {
        "type": "integer",
        "minimum": 64,
        "description": "Shock discharge radius."
    },
    "shock_active":
    {
        "type": "number",
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "Activate shock mode at this health percentage (0.0 - 1.0); 0.3 means 30%."
    },
    "explosion_delay":
    {
        "type": "array",
        "minItems": 2,
        "maxItems": 2,
        "items": 
        {
            "minimum": 0.0,
            "type": "number"
        },
        "description": "Activate explosion after this min/max random time."
    }
}""" );

class ASRoboGrunt : EntityOverriden, IConfigurable
{
    const string& GetName() const override
    {
        return "robo_grunt";
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Robot grunt configuration",
            "allOf":
            [
                "ASRoboGruntSchema"
            ]
        }""";
    }

    protected uint computergibs;
    protected uint chromegibs;
    // when to trigger low-health mode (percentage 0.0 - 1.0) eg: 0.3 = trigger when health is at 30%
    protected float shock_active;
    protected int shock_touch;
    protected float shock_delay;
    protected int shock_radius;
    protected float dmg_melee;
    protected float dmg_bullet;
    protected float dmg_burn;
    protected float dmg_blast;
    protected float dmg_generic;
    protected int explosion_damage;
    protected int[] explosion_delay;

    bool Register( btson@ config ) override
    {
        this.dmg_generic = float( config[ "dmg_generic" ] );
        this.dmg_burn = float( config[ "dmg_burn" ] );
        this.dmg_blast = float( config[ "dmg_blast" ] );
        this.dmg_melee = float( config[ "dmg_melee" ] );
        this.dmg_bullet = float( config[ "dmg_bullet" ] );
        this.explosion_damage = int( config[ "explosion_damage" ] );
        this.shock_touch = int( config[ "shock_touch" ] );
        this.shock_active = float( config[ "shock_active" ] );
        this.shock_delay = float( config[ "shock_delay" ] );
        this.shock_radius = int( config[ "shock_radius" ] );
        btson@ expDelay = config[ "explosion_delay" ];
        this.explosion_delay = { float( expDelay[0] ), float( expDelay[1] ) };

        if( g_MapConfig.MapLoading )
        {
            this.computergibs = g_Game.PrecacheModel( "models/computergibs.mdl" );
            this.chromegibs = g_Game.PrecacheModel( "models/chromegibs.mdl" );

            g_SoundSystem.PrecacheSound( "buttons/spark5.wav" );
            g_SoundSystem.PrecacheSound( "buttons/spark6.wav" );
            g_SoundSystem.PrecacheSound( "debris/beamstart14.wav" );

            EntityOverriden::SetThink( 0.1f );
            EntityOverriden::Register( this );
        }

        return true;
    }

    bool AddEntity( CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( monster is null || string( entity.pev.model ) != "models/bts_rc/monsters/rgrunt_opfor.mdl" )
            return false;

        BurningMonster::SetInmune( entity );

        return EntityOverriden::AddEntity( entity, monster );
    }

    uint EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( monster is null )
            return EntityOverridenAction::Remove;

        dictionary@ data = monster.GetUserData();

        int smokePuffs;

        if( data.get( "smokepuff", smokePuffs ) )
        {
            // Clamp in case somehow it gets massive damage
            smokePuffs = Math.clamp( 1, 8, smokePuffs );

            float heightPos = monster.pev.origin.z + monster.pev.size.z - 32.0;

            for( int i = 0; i < smokePuffs; i++ )
            {
                NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, monster.pev.origin );
                    m.WriteByte( TE_SMOKE );
                    m.WriteCoord( monster.pev.origin.x + Math.RandomFloat( -16.0, 16.0 ) );
                    m.WriteCoord( monster.pev.origin.y + Math.RandomFloat( -16.0, 16.0 ) );
                    m.WriteCoord( heightPos );
                    m.WriteShort( models::steam1 );
                    m.WriteByte( Math.RandomLong( 1, 9 ) );
                    m.WriteByte( 12 );
                m.End();
            }

            data.delete( "smokepuff" );
        }

        float nextShock;
        bool shockModeActive = data.get( "shockmode", nextShock );

        if( shockModeActive )
        {
            // Do shock discharge
            if( nextShock > 0 && nextShock < g_Engine.time )
            {
                data[ "shockmode" ] = 0.0f;
                ShockDischarge( monster.pev.origin, monster );
            }

            float nextSpark;
            data.get( "nextspark", nextSpark );

            if( nextSpark < g_Engine.time )
            {
                data[ "nextspark" ] = g_Engine.time + Math.RandomFloat( 0.0f, 1.0f );

                Vector vecOrigin = Vector(
                    Math.RandomFloat( monster.pev.absmin.x, monster.pev.absmax.x ),
                    Math.RandomFloat( monster.pev.absmin.y, monster.pev.absmax.y ),
                    Math.RandomFloat( monster.pev.origin.z, monster.pev.absmax.z )
                );

                g_Utility.Sparks( vecOrigin );

                switch( RandomUint( 1, monster ) )
                {
                    case 0: g_SoundSystem.EmitSoundDyn( monster.edict(), CHAN_BODY, "buttons/spark5.wav", 0.5, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) ); break;
                    case 1: g_SoundSystem.EmitSoundDyn( monster.edict(), CHAN_BODY, "buttons/spark6.wav", 0.5, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) ); break;
                }
            }
        }

        float dieThink;

        if( data.get( "diethink", dieThink ) )
        {
            if( dieThink <= g_Engine.time )
            {
                monster.pev.solid = SOLID_NOT;
                ExplosiveDeath( monster );
                EntityOverridenAction::Remove;
            }

            float timeRemaining = Math.max( 0.0f, dieThink - g_Engine.time );

#if ROBOSS_EXPAND_GLOW
            float dieDuration = Math.max( 0.01f, float( data[ "dieduration" ] ) );
            float countdownProgress = 1.0f - Math.clamp( 0.0f, 1.0f, timeRemaining / dieDuration );
            monster.pev.renderamt = 4.0f + 251.0f * countdownProgress;
#endif

            float maxDelay = Math.max( 0.01f, float( explosion_delay[1] ) );
            monster.pev.rendercolor.x = Math.clamp( 0.0f, 255.0f, 255.0f * timeRemaining / maxDelay );

            data[ "smokepuff" ] = RandomUint( 6, monster );
        }

        return EntityOverridenAction::None;
    }

    void ShockDischarge( const Vector&in origin, CBaseEntity@ owner )
    {
        if( owner is null )
            return;

        g_SoundSystem.EmitSoundDyn( owner.edict(), CHAN_AUTO, "debris/beamstart14.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );

        CBaseEntity@ entity = null;

        while( ( @entity = g_EntityFuncs.FindEntityInSphere( entity, origin, this.shock_radius, "*", "classname" ) ) !is null
        && entity.pev.takedamage != DAMAGE_NO
        && entity.IsAlive()
        && entity !is owner
        && entity.IRelationship( owner ) != R_AL
        ) {
            entity.TakeDamage( owner.pev, owner.pev, this.shock_touch, DMG_SHOCK | DMG_LAUNCH );
        }
    }

    void ExplosiveDeath( CBaseMonster@ monster )
    {
        monster.pev.flags |= EdictFlags::FL_KILLME;
        g_EntityFuncs.CreateExplosion( monster.pev.origin, g_vecZero, monster.edict(), this.explosion_damage, true );

        if( FreeEdicts( 15 ) )
        {
            NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, monster.pev.origin );
                m.WriteByte( TE_BREAKMODEL );
                m.WriteCoord( monster.pev.origin.x ); // position
                m.WriteCoord( monster.pev.origin.y );
                m.WriteCoord( monster.pev.origin.z );
                m.WriteCoord( 200 ); // size
                m.WriteCoord( 200 );
                m.WriteCoord( 64 );
                m.WriteCoord( 10 ); // velocity
                m.WriteCoord( 20 );
                m.WriteCoord( 80 );
                m.WriteByte( 30 ); // randomization
                m.WriteShort( this.computergibs ); // model id#
                m.WriteByte( 15 ); // # of shards
                m.WriteByte( 100 ); // duration (3.0 seconds)
                m.WriteByte( BREAK_METAL ); // flags
            m.End();
        }

        if( FreeEdicts( 15 ) )
        {
            NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, monster.pev.origin );
                m.WriteByte( TE_BREAKMODEL );
                m.WriteCoord( monster.pev.origin.x ); // position
                m.WriteCoord( monster.pev.origin.y );
                m.WriteCoord( monster.pev.origin.z );
                m.WriteCoord( 200 ); // size
                m.WriteCoord( 200 );
                m.WriteCoord( 96 );
                m.WriteCoord( 0 ); // velocity
                m.WriteCoord( 0 );
                m.WriteCoord( 10 );
                m.WriteByte( 30 ); // randomization
                m.WriteShort( this.chromegibs ); // model id#
                m.WriteByte( 15 ); // # of shards
                m.WriteByte( 100 ); // duration (3.0 seconds)
                m.WriteByte( BREAK_METAL ); // flags
            m.End();
        }

        g_SoundSystem.EmitSoundDyn( monster.edict(), CHAN_BODY, "debris/beamstart14.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

        if( FreeEdicts( 1 ) )
        {
            CBaseEntity@ smoker = g_EntityFuncs.Create( "env_smoker", monster.pev.origin, g_vecZero, false );
            smoker.pev.health = 1; // 1 smoke balls
            smoker.pev.scale = 10; // 4.6X normal size
            smoker.pev.dmg = 0; // 0 radial distribution
            smoker.pev.nextthink = g_Engine.time + 0.5; // Start in 0.5 seconds
        }
    }

    uint Killed( uint index, CBaseMonster@ monster, CBaseEntity@ attacker, bool gibbed ) override
    {
        if( gibbed )
        {
            ExplosiveDeath( monster );
            return EntityOverridenAction::Remove;
        }

        dictionary@ data = monster.GetUserData();

        monster.pev.velocity = g_vecZero;
        monster.pev.deadflag = DEAD_DYING;

        GetSoundEntInstance().InsertSound( bits_SOUND_DANGER, monster.pev.origin, 250, 2.5, monster );

        switch( Math.RandomLong( 0, 1 ) )
        {
            case 0: g_SoundSystem.EmitSound( monster.edict(), CHAN_VOICE, "bts_rc/rgrunt/rb_death1.wav", VOL_NORM, 0.5 ); break;
            case 1: g_SoundSystem.EmitSound( monster.edict(), CHAN_VOICE, "bts_rc/rgrunt/rb_death2.wav", VOL_NORM, 0.5 ); break;
        }

#if ROBOSS_EXPAND_GLOW
        float dieDuration = Math.RandomFloat( explosion_delay[0], explosion_delay[1] );
        data[ "diethink" ] = g_Engine.time + dieDuration;
        data[ "dieduration" ] = dieDuration;
#endif

        return EntityOverridenAction::None;
    }

    uint TakeDamage( uint index, CBaseMonster@ monster, DamageInfo@ info ) override
    {
        dictionary@ data = monster.GetUserData();

        bool bRicochet = false;

        if( ( info.bitsDamageType & DMG_BULLET ) != 0)
        {
            bRicochet = true;
            info.flDamage *= this.dmg_bullet;
        }
        else if( ( info.bitsDamageType & DMG_CLUB | DMG_SLASH ) != 0 )
        {
            bRicochet = true;
            info.flDamage *= this.dmg_melee;
        }
        else if( ( info.bitsDamageType & DMG_BLAST ) != 0 )
        {
            info.flDamage *= this.dmg_blast;
        }
        else if( ( info.bitsDamageType & DMG_BURN ) == 0 )
        {
            info.flDamage *= this.dmg_burn;
        }
        else
        {
            info.flDamage *= this.dmg_generic;
        }

        if( bRicochet )
        {
            if( info.pAttacker !is null )
            {
                TraceResult tr = g_Utility.GetGlobalTrace();

                NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, monster.pev.origin );
                    m.WriteByte( TE_ARMOR_RICOCHET );
                    m.WriteCoord( tr.vecEndPos.x );
                    m.WriteCoord( tr.vecEndPos.y );
                    m.WriteCoord( tr.vecEndPos.z );
                    m.WriteByte( 10 ); // scale in 0.1's
                m.End();
            }
        }

        if( info.flDamage > 0 )
        {
            data[ "smokepuff" ] = Math.max( int( 3 + ( info.flDamage / 5.0 ) ), int( data[ "smokepuff" ] ) );

            float nextShock;
            bool shockModeActive = data.get( "shockmode", nextShock );

            if( !shockModeActive )
            {
                // Set shock mode if health is going to be lesser than percent expected
                if( monster.pev.health - info.flDamage <= monster.pev.max_health * this.shock_active )
                {
                    shockModeActive = true;
                }
            }

            // Set up next shock
            if( shockModeActive )
            {
                float healthPercent = Math.clamp( 0.0f, 1.0f, Math.max( 1, monster.pev.health ) / monster.pev.max_health );

                monster.pev.renderamt = 4.0;
                monster.pev.renderfx = kRenderFxGlowShell;

                // Calculate shock color
                monster.pev.rendercolor[0] = ASRoboGruntGlowColor.r - ( 155 * healthPercent );
                monster.pev.rendercolor[1] = ASRoboGruntGlowColor.g * healthPercent;
                monster.pev.rendercolor[2] = ASRoboGruntGlowColor.b * healthPercent;

                if( nextShock <= 0.0 )
                    data[ "shockmode" ] = g_Engine.time + this.shock_delay;
            }
        }

        return EntityOverridenAction::None;
    }
}
