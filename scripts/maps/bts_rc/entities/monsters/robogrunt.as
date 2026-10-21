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
    "shock_damage":
    {
        "type": "integer",
        "minimum": 0,
        "description": "Damage dealt to nearby entities during a shock discharge."
    },
    "shock_cooldown":
    {
        "type": "array",
        "minItems": 2,
        "maxItems": 2,
        "items": 
        {
            "minimum": 0.0,
            "type": "number"
        },
        "description": "Shock discharge min/max random intervals."
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
    protected uint shockwave;
    // when to trigger low-health mode (percentage 0.0 - 1.0) eg: 0.3 = trigger when health is at 30%
    protected float shock_active;
    protected int shock_damage;
    protected float[] shock_cooldown;
    protected int shock_radius;
    protected float dmg_melee;
    protected float dmg_bullet;
    protected float dmg_burn;
    protected float dmg_blast;
    protected float dmg_generic;
    protected int explosion_damage;
    protected float[] explosion_delay;

    bool Register( meta_api::json::v2::json@ config ) override
    {
        this.dmg_generic = float( config[ "dmg_generic" ] );
        this.dmg_burn = float( config[ "dmg_burn" ] );
        this.dmg_blast = float( config[ "dmg_blast" ] );
        this.dmg_melee = float( config[ "dmg_melee" ] );
        this.dmg_bullet = float( config[ "dmg_bullet" ] );
        this.explosion_damage = int( config[ "explosion_damage" ] );
        this.shock_damage = int( config[ "shock_damage" ] );
        this.shock_active = float( config[ "shock_active" ] );
        this.shock_radius = int( config[ "shock_radius" ] );
        meta_api::json::v2::json@ expDelay = config[ "explosion_delay" ];
        this.explosion_delay = { float( expDelay[0] ), float( expDelay[1] ) };
        meta_api::json::v2::json@ shockDelay = config[ "shock_cooldown" ];
        this.shock_cooldown = { float( shockDelay[0] ), float( shockDelay[1] ) };

        if( g_MapConfig.MapLoading )
        {
            this.computergibs = g_Game.PrecacheModel( "models/computergibs.mdl" );
            this.chromegibs = g_Game.PrecacheModel( "models/chromegibs.mdl" );
            this.shockwave = g_Game.PrecacheModel( "sprites/shockwave.spr" );

            g_SoundSystem.PrecacheSound( "buttons/spark5.wav" );
            g_SoundSystem.PrecacheSound( "buttons/spark6.wav" );
            g_SoundSystem.PrecacheSound( "debris/beamstart14.wav" );

            EntityOverriden::SetThink( 0.1f );
            EntityOverriden::Register( this );
        }

        return true;
    }

    bool RegisterRobogrunt( CBaseMonster@ monster, bool condition ) final
    {
        if( !condition )
            return false;

        g_EntityFuncs.DispatchKeyValue( monster.edict(), "$i_puddleskin", "3" );
        BurningMonster::SetInmune( monster );

        return EntityOverriden::AddEntity( monster, monster );
    }

    bool AddEntity( CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        return RegisterRobogrunt( monster, ( string( entity.pev.model ) == "models/bts_rc/monsters/rgrunt_opfor.mdl" ) );
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
                float shockAgain = Math.RandomFloat( this.shock_cooldown[0], this.shock_cooldown[1] );
                data[ "shockmode" ] = g_Engine.time + shockAgain;
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

    // Get RGB based on monster health, Alpha is the health percentage.
    RGBA GetGlowColor( CBaseMonster@ monster )
    {
        float maxHealth = Math.max( 1.0f, monster.pev.max_health );
        float healthPercent = Math.clamp( 0.0f, 1.0f, monster.pev.health / maxHealth );
        float glowProgress = 0.0f;

        if( this.shock_active > 0.0f && healthPercent <= this.shock_active )
        {
            glowProgress = Math.clamp( 0.0f, 1.0f, 1.0f - healthPercent / this.shock_active );
        }
        else if( this.shock_active <= 0.0f && healthPercent <= 0.0f )
        {
            glowProgress = 1.0f;
        }

        return RGBA(
            int( ASRoboGruntGlowColor.r + ( ( 255 - ASRoboGruntGlowColor.r ) * glowProgress ) ),
            int( ASRoboGruntGlowColor.g * ( 1.0f - glowProgress ) ),
            int( ASRoboGruntGlowColor.b * ( 1.0f - glowProgress ) ),
            int( 255.0f * healthPercent )
        );
    }

    private float m_NearbyLastCheck;
    private float m_NearbyLastRange;
    private array<EHandle> m_NearbyEnemies;

    // Get a list of all entities nearby
    const array<EHandle>@ EnemiesNearby( CBaseMonster@ monster, int range, float nextCheck = 1.0f )
    {
        if( this.m_NearbyLastCheck > g_Engine.time && this.m_NearbyLastRange == range )
            return @this.m_NearbyEnemies;

        // Rebuild list every second
        this.m_NearbyLastCheck = g_Engine.time + nextCheck;
        this.m_NearbyLastRange = range;

        this.m_NearbyEnemies.resize(0);

        CBaseEntity@ entity = null;
        while( ( @entity = g_EntityFuncs.FindEntityInSphere( entity, monster.pev.origin, range, "*", "classname" ) ) !is null
        && entity.pev.takedamage != DAMAGE_NO
        && ( entity.pev.flags & ( FL_MONSTER | FL_CLIENT ) ) != 0
        && entity.IsAlive()
        && entity !is monster
        && monster.FVisible( entity, true )
        && monster.IRelationship( entity ) != R_AL )
        {
            this.m_NearbyEnemies.insertLast( EHandle( entity ) );
        }

        return @this.m_NearbyEnemies;
    }

    void ShockDischarge( const Vector&in origin, CBaseMonster@ monster )
    {
        if( monster is null )
            return;

        Vector src;
        RGBA colour;
        Vector colour_v;
        Vector punch;

        const array<EHandle>@ nearbyEnemies = this.EnemiesNearby( monster, this.shock_radius, 0.3f );
        const uint length = nearbyEnemies.length();

        if( length > 0 )
        {
            src = origin;
            src.z += 15;
            colour = this.GetGlowColor( monster );
            colour_v = Vector( colour.r, colour.g, colour.b );
            punch = Vector(
                float( Math.RandomLong( -5, 5 ) ),
                float( Math.RandomLong( -5, 5 ) ),
                float( Math.RandomLong( -5, 5 ) )
            );
        }

        for( uint ui = 0; ui < length; ui++ )
        {
            EHandle handle = nearbyEnemies[ui];
            CBaseEntity@ entity;

            if( handle.IsValid() && ( @entity = handle.GetEntity() ) !is null )
            {
                entity.pev.velocity.x *= 0.2;
                entity.pev.velocity.y *= 0.2;

                if( entity.IsPlayer() )
                {
                    entity.pev.punchangle = punch;
                    g_PlayerFuncs.ScreenFade( entity, colour_v, 0.5f, 0.0f, 255.0f, FFADE_MODULATE | FFADE_IN );
                }

                entity.TakeDamage( monster.pev, monster.pev, this.shock_damage, DMG_SHOCK | DMG_LAUNCH );

                Vector target = entity.pev.origin;
                target.z += 15;

                {
                    NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, src );
                        m.WriteByte( TE_BEAMPOINTS );
                        m.WriteCoord( src.x );
                        m.WriteCoord( src.y );
                        m.WriteCoord( src.z );
                        m.WriteCoord( target.x );
                        m.WriteCoord( target.y );
                        m.WriteCoord( target.z );
                        m.WriteShort( models::laserbeam );
                        m.WriteByte( 0 ); // start frame
                        m.WriteByte( 25 ); // frame rate
                        m.WriteByte( 4 ); // life
                        m.WriteByte( 16 ); // width
                        m.WriteByte( 16 ); // noise
                        m.WriteByte( colour.r ); // red
                        m.WriteByte( colour.g ); // green
                        m.WriteByte( colour.b ); // blue
                        m.WriteByte( 220 ); // brightness
                        m.WriteByte( 0 ); // scroll speed
                    m.End();
                }
            }
        }

        if( length > 0 )
        {
            {
                NetworkMessage m( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, src );
                    m.WriteByte( TE_BEAMCYLINDER );
                    m.WriteCoord( src.x );
                    m.WriteCoord( src.y );
                    m.WriteCoord( src.z + 16 );
                    m.WriteCoord( src.x );
                    m.WriteCoord( src.y );
                    m.WriteCoord( src.z + 16 + this.shock_radius / 0.2 ); // reach damage radius over the 0.2-second effect life
                    m.WriteShort( this.shockwave );
                    m.WriteByte( 0 ); // startframe
                    m.WriteByte( 0 ); // framerate
                    m.WriteByte( 2 ); // life
                    m.WriteByte( 16 ); // width
                    m.WriteByte( 0 ); // noise
                    m.WriteByte( colour.r ); // r, g, b
                    m.WriteByte( colour.g ); // r, g, b
                    m.WriteByte( colour.b ); // r, g, b
                    m.WriteByte( 100 ); // brightness
                    m.WriteByte( 0 ); // speed
                m.End();
            }
            {
                NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, src );
                    m.WriteByte( TE_DLIGHT );
                    m.WriteCoord( src.x );
                    m.WriteCoord( src.y );
                    m.WriteCoord( src.z );
                    m.WriteByte( int( Math.clamp( 1.0f, 255.0f, this.shock_radius / 10.0f + 0.5f ) ) ); // radius in 10-unit increments
                    m.WriteByte( colour.r );
                    m.WriteByte( colour.g );
                    m.WriteByte( colour.b );
                    m.WriteByte( 2 );
                    m.WriteByte( 1 );
                m.End();
            }

            g_SoundSystem.EmitSoundDyn( monster.edict(), CHAN_AUTO, "debris/beamstart14.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );

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

        float dieDuration = Math.RandomFloat( this.explosion_delay[0], this.explosion_delay[1] );
        data[ "diethink" ] = g_Engine.time + dieDuration;

#if ROBOSS_EXPAND_GLOW
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

            int bloodSplash = RandomUint( 16, monster ) + 1;

            if( bloodSplash > 7 )
                bloodSplash = -1;

            g_EntityFuncs.DispatchKeyValue( monster.edict(), "$i_bloodcolor", bloodSplash );

            if( Math.RandomLong( 0, 10 ) < 4 )
            {
                TraceResult tr = g_Utility.GetGlobalTrace();
                NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, monster.pev.origin );
                    m.WriteByte( TE_BLOOD );
                    m.WriteCoord( tr.vecEndPos.x );
                    m.WriteCoord( tr.vecEndPos.y );
                    m.WriteCoord( tr.vecEndPos.z );
                    m.WriteCoord( 0 );
                    m.WriteCoord( 0 );
                    m.WriteCoord( -90);
                    m.WriteByte( 110 ); // Color pallete: https://github.com/baso88/SC_AngelScript/wiki/Temporary-Entities#palette-1
                    m.WriteByte( 16 );
                m.End();
            }

            // Set up next shock
            if( shockModeActive )
            {
                monster.pev.renderamt = 4.0;
                monster.pev.renderfx = kRenderFxGlowShell;

                RGBA colour = this.GetGlowColor( monster );

                monster.pev.rendercolor[0] = colour.r;
                monster.pev.rendercolor[1] = colour.g;
                monster.pev.rendercolor[2] = colour.b;

                data[ "shockmode" ] = g_Engine.time;
            }
        }

        return EntityOverridenAction::None;
    }
}
