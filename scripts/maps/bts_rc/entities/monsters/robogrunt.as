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

bool ASRoboGruntSchema = g_MapConfig.RegisterSchemaDefinition( "ASRoboGruntSchema",
"""{
    "explosion_damage":
    {
        "type": "integer",
        "minimum": 0,
        "description": "Explosion damage on death, set to 0 to disable."
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
        "description": "Damage dealt to nearby enemies when shock (double to player that triggered the shock with a melee weapon)"
    },
    "shock_active":
    {
        "type": "number",
        "minimum": 0.0,
        "maximum": 1.0,
        "description": " when to trigger shock mode (percentage 0.0 - 1.0) eg: 0.3 = trigger when health is at 30%"
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
    protected float dmg_melee;
    protected float dmg_bullet;
    protected float dmg_burn;
    protected float dmg_generic;
    protected int explosion_damage;

    bool Register( btson@ config ) override
    {
        this.dmg_generic = float( config[ "dmg_generic" ] );
        this.dmg_burn = float( config[ "dmg_burn" ] );
        this.dmg_melee = float( config[ "dmg_melee" ] );
        this.dmg_bullet = float( config[ "dmg_bullet" ] );
        this.explosion_damage = int( config[ "explosion_damage" ] );
        this.shock_touch = int( config[ "shock_touch" ] );
        this.shock_active = float( config[ "shock_active" ] );

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

        if( monster.IsAlive() )
        {
            int iDoSmokePuff = int( data[ "smokepuff" ] );

            if( iDoSmokePuff > 0 || Math.RandomLong( 0, 99 ) > monster.pev.health )
            {
                NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, monster.pev.origin );
                    m1.WriteByte( TE_SMOKE );
                    m1.WriteCoord( monster.pev.origin.x + Math.RandomFloat( -16.0, 16.0 ) );
                    m1.WriteCoord( monster.pev.origin.y + Math.RandomFloat( -16.0, 16.0 ) );
                    m1.WriteCoord( monster.pev.origin.z + monster.pev.size.z - 32.0 );
                    m1.WriteShort( models::steam1 );
                    m1.WriteByte( Math.RandomLong( 1, 9 ) );
                    m1.WriteByte( 12 );
                m1.End();
            }

            if( iDoSmokePuff > 0 )
                iDoSmokePuff--;

            data[ "smokepuff" ] = iDoSmokePuff;
            bool bShockTouch = bool( data[ "shocktouch" ] );

            if( ( monster.pev.health / monster.pev.max_health ) <= this.shock_active )
            {
                float flNextSpark = float( data[ "nextspark" ] );
                bool bDoubleSpark = bool( data[ "doublespark" ] );

                Vector vecOrigin = Vector( Math.RandomFloat( monster.pev.absmin.x, monster.pev.absmax.x ), Math.RandomFloat( monster.pev.absmin.y, monster.pev.absmax.y ), Math.RandomFloat( monster.pev.origin.z, monster.pev.absmax.z ) );

                if( ( flNextSpark - 0.1 ) <= g_Engine.time and bDoubleSpark )
                {
                    g_Utility.Sparks( vecOrigin );
                    data[ "doublespark" ] = false;
                }

                if( flNextSpark + Math.RandomFloat( 0, 1 ) <= g_Engine.time )
                {
                    g_Utility.Sparks( vecOrigin );
                    if( Math.RandomLong( 1, 2 ) == 1 )
                        g_SoundSystem.EmitSoundDyn( monster.edict(), CHAN_BODY, "buttons/spark5.wav", 0.5, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
                    else
                        g_SoundSystem.EmitSoundDyn( monster.edict(), CHAN_BODY, "buttons/spark6.wav", 0.5, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

                    data[ "doublespark" ] = true;
                    data[ "nextspark" ] = g_Engine.time + 0.3;

                    if( flNextSpark > g_Engine.time and !bShockTouch )
                    {
                        if( Math.RandomLong( 0, 30 ) > 26 )
                        {
                            g_SoundSystem.EmitSoundDyn( monster.edict(), CHAN_STATIC, "debris/beamstart14.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
                            GlowEffect( monster, true );
                            data[ "shocktouch" ] = bShockTouch = true;
                            data[ "nextshock" ] = g_Engine.time + 0.45;
                        }
                        else if( Math.RandomLong( 0, 40 ) == 15 )
                        {
                            g_SoundSystem.EmitSoundDyn( monster.edict(), CHAN_STATIC, "debris/beamstart14.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
                            GlowEffect( monster, true );
                            data[ "shocktouch" ] = bShockTouch = true;
                            data[ "nextshock" ] = g_Engine.time + 0.35;
                        }
                    }
                }
            }

            if( bShockTouch )
            {
                CBaseEntity@ pTarget = null;
                while( ( @pTarget = g_EntityFuncs.FindEntityInSphere( pTarget, monster.pev.origin, monster.pev.size.z, "*", "classname" ) ) !is null )
                {
                    if( pTarget is monster or !pTarget.IsAlive() or pTarget.pev.takedamage == DAMAGE_NO )
                        continue;

                    pTarget.TakeDamage( monster.pev, monster.pev, this.shock_touch, DMG_SHOCK | DMG_LAUNCH );
                }
                float flNextShockTouch = float( data[ "nextshock" ] );
                if( flNextShockTouch <= g_Engine.time )
                {
                    GlowEffect( monster, false );
                    data[ "shocktouch" ] = false;
                }
            }
        }

        float flNextDieThink = float( data[ "diethink" ] );

        if( flNextDieThink > 0.0 && flNextDieThink <= g_Engine.time )
        {
            if( monster.pev.deadflag != DEAD_DEAD )
                monster.pev.deadflag = DEAD_DEAD;

            if( float( data[ "removethink" ] ) <= g_Engine.time )
            {
                monster.pev.solid = SOLID_NOT;
                ExplosiveDeath( monster );
                EntityOverridenAction::Remove;
            }
            else
            {
                Vector vecOrigin;
                vecOrigin.x = monster.pev.absmin.x + monster.pev.size.x * ( Math.RandomFloat( 0, 1 ) );
                vecOrigin.y = monster.pev.absmin.y + monster.pev.size.y * ( Math.RandomFloat( 0, 1 ) );
                vecOrigin.z = monster.pev.absmin.z + monster.pev.size.z * ( Math.RandomFloat( 0, 1 ) ) + 1; // absmin.z is in the floor because the engine subtracts 1 to enlarge the box

                if( FreeEdicts( 1 ) )
                {
                    NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
                        m1.WriteByte( TE_SMOKE );
                        m1.WriteCoord( vecOrigin.x );
                        m1.WriteCoord( vecOrigin.y );
                        m1.WriteCoord( vecOrigin.z );
                        m1.WriteShort( models::steam1 );
                        m1.WriteByte( 15 ); // scale * 10
                        m1.WriteByte( 10 ); // framerate
                    m1.End();
                }

                g_Utility.Sparks( vecOrigin );

                data[ "diethink" ] = g_Engine.time + 0.1;
            }
        }

        return EntityOverridenAction::None;
    }

    void GlowEffect( CBaseMonster@ monster, bool bOn )
    {
        if( monster is null )
            return;

        if( bOn )
        {
            monster.pev.renderfx = kRenderFxGlowShell;
            monster.pev.renderamt = 4.0;
            monster.pev.rendercolor.x = 100;
            monster.pev.rendercolor.y = 100;
            monster.pev.rendercolor.z = 220;
        }
        else
        {
            monster.pev.renderfx = kRenderFxNone;
            monster.pev.renderamt = 255.0;
            monster.pev.rendercolor = g_vecZero;
        }
    }

    void ExplosiveDeath( CBaseMonster@ monster )
    {
        dictionary@ data = monster.GetUserData();

        if( this.explosion_damage > 0 )
        {
            monster.pev.flags |= EdictFlags::FL_KILLME;
            g_EntityFuncs.CreateExplosion( monster.pev.origin, g_vecZero, monster.edict(), this.explosion_damage, true );
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
            CBaseEntity@ pSmoker = g_EntityFuncs.Create( "env_smoker", monster.pev.origin, g_vecZero, false );
            pSmoker.pev.health = 1;                      // 1 smoke balls
            pSmoker.pev.scale = 10;                      // 4.6X normal size
            pSmoker.pev.dmg = 0;                         // 0 radial distribution
            pSmoker.pev.nextthink = g_Engine.time + 0.5; // Start in 0.5 seconds
        }

        Vector vecOrigin;
        vecOrigin.x = monster.pev.absmin.x + monster.pev.size.x * ( Math.RandomFloat( 0, 1 ) );
        vecOrigin.y = monster.pev.absmin.y + monster.pev.size.y * ( Math.RandomFloat( 0, 1 ) );
        vecOrigin.z = monster.pev.absmin.z + monster.pev.size.z * ( Math.RandomFloat( 0, 1 ) ) + 1; // absmin.z is in the floor because the engine subtracts 1 to enlarge the box

        g_Utility.Sparks( vecOrigin );

        data[ "diethink" ] = 0;
    }

    uint Killed( uint index, CBaseMonster@ monster, CBaseEntity@ attacker, bool gibbed ) override
    {
        dictionary@ data = monster.GetUserData();

        monster.pev.velocity = g_vecZero;
        monster.pev.deadflag = DEAD_DYING;

        if( gibbed )
        {
            ExplosiveDeath( monster );
            return EntityOverridenAction::Remove;
        }

        GlowEffect( monster, false );
        GetSoundEntInstance().InsertSound( bits_SOUND_DANGER, monster.pev.origin, 250, 2.5, monster );

        if( Math.RandomLong( 1, 2 ) == 1 )
            g_SoundSystem.EmitSound( monster.edict(), CHAN_VOICE, "bts_rc/rgrunt/rb_death1.wav", VOL_NORM, 0.5 );
        else
            g_SoundSystem.EmitSound( monster.edict(), CHAN_VOICE, "bts_rc/rgrunt/rb_death2.wav", VOL_NORM, 0.5 );

        data[ "removethink" ] = g_Engine.time + Math.RandomFloat( 3.0, 7.0 );
        data[ "diethink" ] = g_Engine.time;

        return EntityOverridenAction::None;
    }

    uint TakeDamage( uint index, CBaseMonster@ monster, DamageInfo@ info ) override
    {
        dictionary@ data = monster.GetUserData();

        bool bShockTouch = bool( data[ "shocktouch" ] );

        if( bShockTouch )
        {
            if( ( info.bitsDamageType & DMG_SLASH | DMG_CLUB ) != 0 )
            {
                info.pAttacker.TakeDamage(monster.pev, monster.pev, this.shock_touch, DMG_SHOCK );
                info.flDamage = 0.01;
            }
        }
        else if( ( info.bitsDamageType & DMG_SLASH | DMG_CLUB ) != 0 && monster.pev.health <= 20.0 && Math.RandomLong( 0, 2 ) > 1 )
        {
            GlowEffect( monster, true );
            data[ "shocktouch" ] = true;
        }

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
        else if( ( info.bitsDamageType & DMG_BLAST ) != 0 && monster.pev.health > 10.0 )
        {
            if( info.flDamage > 15.0 )
                info.flDamage -= 15.0;
        }
        else if( ( info.bitsDamageType & DMG_BURN ) == 0 || monster.pev.health <= 10.0 )
        {
            info.flDamage *= this.dmg_burn;
        }
        else
        {
            info.flDamage *= this.dmg_generic;
        }

        if( bRicochet )
        {
            TraceResult tr = g_Utility.GetGlobalTrace();

            if( info.pAttacker !is null and info.pAttacker.pev.FlagBitSet( FL_CLIENT ) )
            {
                NetworkMessage m( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, info.pAttacker.edict() );
                    m.WriteByte( TE_ARMOR_RICOCHET );
                    m.WriteCoord( tr.vecEndPos.x );
                    m.WriteCoord( tr.vecEndPos.y );
                    m.WriteCoord( tr.vecEndPos.z );
                    m.WriteByte( 10 ); // scale in 0.1's
                m.End();
            }
        }

        return EntityOverridenAction::None;
    }
}
