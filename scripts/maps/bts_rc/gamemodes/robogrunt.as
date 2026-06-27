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

class ASRoboGrunt : EntityOverriden, IConfigurableContext
{
    const string& GetName() const override {
        return "robo_grunt";
    }

    const string GetSchema() const {
        return String::EMPTY_STRING;
    }

    protected uint m_iSmokeSprite;
    protected uint m_iGibs1;
    protected uint m_iGibs2;
    // when to trigger low-health mode (percentage 0.0 - 1.0) eg: 0.3 = trigger when health is at 30%
    protected float m_fLowHealthChance = 0.3;
    // when low-health is active, periodically shock anything in close proximity
    protected int m_iShockTouchDamage = 125;
    protected float m_fDmgMultiplierMelee = 0.08;
    protected float m_fDmgMultiplierBlast = 0.7;
    protected float m_fDmgMultiplierPoison = 0.07;
    protected float m_fDmgMultiplierBurn = 0.18;
    protected float m_fDmgMultiplierGeneric = 0.6;
    // robots will explode shortly after death, can be set to 0
    protected int m_iDmgExplode = 125;

    bool Register( meta_api::json::v2::json@ config ) override
    {
        this.m_iSmokeSprite = g_Game.PrecacheModel( "sprites/steam1.spr" );
        this.m_iGibs1 = g_Game.PrecacheModel( "models/computergibs.mdl" );
        this.m_iGibs2 = g_Game.PrecacheModel( "models/chromegibs.mdl" );

        g_SoundSystem.PrecacheSound( "buttons/spark5.wav" );
        g_SoundSystem.PrecacheSound( "buttons/spark6.wav" );
        g_SoundSystem.PrecacheSound( "debris/beamstart14.wav" );

#if SERVER
        g_Game.PrecacheOther( "monster_human_grunt_ally" );
        g_Game.PrecacheModel( "models/bts_rc/monsters/rgrunt_opfor.mdl" );
#endif

        EntityOverriden::SetThink( 0.1f );
        return true;
    }

#if SERVER
    dictionary@ get_TestKeys() {
        return { { "classname", "monster_human_grunt_ally" }, { "model", "models/bts_rc/monsters/rgrunt_opfor.mdl" }, { "is_player_ally", "1" } };
    }
#endif

    bool IsValid( const string&in classname, const string&in model )
    {
        return ( classname == "monster_human_grunt_ally"
            && model == "models/bts_rc/monsters/rgrunt_opfor.mdl" );
    }

    bool AddEntity( uint index, CBaseEntity@ entity, CustomKeyvalues@ ckv, CBaseMonster@ monster ) override
    {
        if( !this.IsValid( entity.GetClassname(), string( entity.pev.model ) ) )
            return false;

#if SERVER
        SetDebugName( entity, "Robo grunt" );
#endif

        return EntityOverriden::AddEntity( index, entity, ckv, monster );
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
                    m1.WriteShort( this.m_iSmokeSprite );
                    m1.WriteByte( Math.RandomLong( 1, 9 ) );
                    m1.WriteByte( 12 );
                m1.End();
            }

            if( iDoSmokePuff > 0 )
                iDoSmokePuff--;

            data[ "smokepuff" ] = iDoSmokePuff;
            bool bShockTouch = bool( data[ "shocktouch" ] );

            if( ( monster.pev.health / monster.pev.max_health ) <= this.m_fLowHealthChance )
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

                    pTarget.TakeDamage( monster.pev, monster.pev, this.m_iShockTouchDamage, DMG_SHOCK | DMG_LAUNCH );
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
            }
            else
            {
                Vector vecOrigin;
                vecOrigin.x = monster.pev.absmin.x + monster.pev.size.x * ( Math.RandomFloat( 0, 1 ) );
                vecOrigin.y = monster.pev.absmin.y + monster.pev.size.y * ( Math.RandomFloat( 0, 1 ) );
                vecOrigin.z = monster.pev.absmin.z + monster.pev.size.z * ( Math.RandomFloat( 0, 1 ) ) + 1; // absmin.z is in the floor because the engine subtracts 1 to enlarge the box

                if( FreeEdicts( 1 ) )
                {
                    NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
                        m1.WriteByte( TE_SMOKE );
                        m1.WriteCoord( vecOrigin.x );
                        m1.WriteCoord( vecOrigin.y );
                        m1.WriteCoord( vecOrigin.z );
                        m1.WriteShort( this.m_iSmokeSprite );
                        m1.WriteByte( 15 ); // scale * 10
                        m1.WriteByte( 10 ); // framerate
                    m1.End();
                }

                g_Utility.Sparks( vecOrigin );

                data[ "diethink" ] = g_Engine.time + 0.1;
            }
        }

        if( g_Logger.trace.active )
            g_Logger.trace.print( "Engineer grunt spawn a sentry at {}", { monster.pev.origin.ToString() } );

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

        g_EntityFuncs.CreateExplosion( monster.pev.origin, g_vecZero, monster.edict(), this.m_iDmgExplode, true );

        if( FreeEdicts( 15 ) )
        {
            NetworkMessage gib1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, monster.pev.origin );
            gib1.WriteByte( TE_BREAKMODEL );
            gib1.WriteCoord( monster.pev.origin.x );                     // position
            gib1.WriteCoord( monster.pev.origin.y );
            gib1.WriteCoord( monster.pev.origin.z );
            gib1.WriteCoord( 200 );                                       // size
            gib1.WriteCoord( 200 );
            gib1.WriteCoord( 64 );
            gib1.WriteCoord( 10 );                                        // velocity
            gib1.WriteCoord( 20 );
            gib1.WriteCoord( 80 );
            gib1.WriteByte( 30 );                                         // randomization
            gib1.WriteShort( this.m_iGibs1 ); // model id#
            gib1.WriteByte( 15 );                                         // # of shards
            gib1.WriteByte( 100 );                                        // duration (3.0 seconds)
            gib1.WriteByte( BREAK_METAL );                                // flags
            gib1.End();
        }

        if( FreeEdicts( 15 ) )
        {
            NetworkMessage gib2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, monster.pev.origin );
            gib2.WriteByte( TE_BREAKMODEL );
            gib2.WriteCoord( monster.pev.origin.x );                     // position
            gib2.WriteCoord( monster.pev.origin.y );
            gib2.WriteCoord( monster.pev.origin.z );
            gib2.WriteCoord( 200 );                                       // size
            gib2.WriteCoord( 200 );
            gib2.WriteCoord( 96 );
            gib2.WriteCoord( 0 );                                         // velocity
            gib2.WriteCoord( 0 );
            gib2.WriteCoord( 10 );
            gib2.WriteByte( 30 );                                         // randomization
            gib2.WriteShort( this.m_iGibs2 ); // model id#
            gib2.WriteByte( 15 );                                         // # of shards
            gib2.WriteByte( 100 );                                        // duration (3.0 seconds)
            gib2.WriteByte( BREAK_METAL );                                // flags
            gib2.End();
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
        g_EntityFuncs.Remove( monster );
    }

    void Killed( CBaseMonster@ monster, CBaseEntity@ attacker, bool gibbed, int gib )
    {
        dictionary@ data = monster.GetUserData();

        monster.pev.velocity = g_vecZero;
        monster.pev.deadflag = DEAD_DYING;

        if( gibbed )
        {
            ExplosiveDeath( monster );
            return;
        }

        GlowEffect( monster, false );
        GetSoundEntInstance().InsertSound( bits_SOUND_DANGER, monster.pev.origin, 250, 2.5, monster );

        if( Math.RandomLong( 1, 2 ) == 1 )
            g_SoundSystem.EmitSound( monster.edict(), CHAN_VOICE, "bts_rc/rgrunt/rb_death1.wav", VOL_NORM, 0.5 );
        else
            g_SoundSystem.EmitSound( monster.edict(), CHAN_VOICE, "bts_rc/rgrunt/rb_death2.wav", VOL_NORM, 0.5 );

        data[ "removethink" ] = g_Engine.time + Math.RandomFloat( 3.0, 7.0 );
        data[ "diethink" ] = g_Engine.time;
    }

    void TakeDamage( CBaseMonster@ victim, DamageInfo@ info )
    {
        dictionary@ data = victim.GetUserData();

        bool bShockTouch = bool( data[ "shocktouch" ] );

        if( bShockTouch )
        {
            if( ( info.bitsDamageType & DMG_SLASH | DMG_CLUB ) != 0 )
            {
                info.pAttacker.TakeDamage( info.pVictim.pev, info.pVictim.pev, this.m_iShockTouchDamage / 4, DMG_SHOCK );
                info.flDamage = 0.01;
            }
        }
        else if( ( info.bitsDamageType & DMG_SLASH | DMG_CLUB ) != 0 && info.pVictim.pev.health <= 20.0 && Math.RandomLong( 0, 2 ) > 1 )
        {
            GlowEffect( victim, true );
            data[ "shocktouch" ] = true;
        }

        bool bRicochet = false;

        if( ( info.bitsDamageType & DMG_BULLET ) != 0)
        {
            bRicochet = true;
            info.flDamage *= this.m_fDmgMultiplierMelee;
        }
        else if( ( info.bitsDamageType & DMG_CLUB | DMG_SLASH ) != 0 )
        {
            bRicochet = true;
            info.flDamage *= this.m_fDmgMultiplierMelee;
        }
        else if( ( info.bitsDamageType & DMG_BLAST ) != 0 && info.pVictim.pev.health > 10.0 )
        {
            if( info.flDamage > 15.0 )
                info.flDamage -= 15.0;
        }
        else if( ( info.bitsDamageType & DMG_POISON ) == 0 )
        {
            // robots can't get poisoned
            info.bitsDamageType &= ~DMG_POISON;
            info.flDamage *= this.m_fDmgMultiplierPoison;
        }
        else if( ( info.bitsDamageType & DMG_BURN ) == 0 || info.pVictim.pev.health <= 10.0 )
            info.flDamage *= this.m_fDmgMultiplierBurn;
        else
            info.flDamage *= this.m_fDmgMultiplierGeneric;

        if( bRicochet )
        {
            TraceResult tr = g_Utility.GetGlobalTrace();

            if( info.pAttacker !is null and info.pAttacker.pev.FlagBitSet( FL_CLIENT ) )
            {
                NetworkMessage ricochet( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, info.pAttacker.edict() );
                ricochet.WriteByte( TE_ARMOR_RICOCHET );
                ricochet.WriteCoord( tr.vecEndPos.x );
                ricochet.WriteCoord( tr.vecEndPos.y );
                ricochet.WriteCoord( tr.vecEndPos.z );
                ricochet.WriteByte( 10 ); // scale in 0.1's
                ricochet.End();
            }
        }
    }
}

ASRoboGrunt gpRoboGrunt;

class ASRoboGruntBoss : ASRoboGrunt
{
    const string& GetName() const override {
        return "robo_grunt_boss";
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
#if SERVER
        g_Game.PrecacheOther( "monster_hwgrunt" );
        g_Game.PrecacheModel( "models/bts_rc/monsters/robothwgrunt.mdl" );
#endif
        ASRoboGrunt::Register( json );
        return true;
    }

#if SERVER
    dictionary@ get_TestKeys() override {
        return { { "classname", "monster_hwgrunt" }, { "model", "models/bts_rc/monsters/robothwgrunt.mdl" } };
    }
#endif

    bool IsValid( const string&in classname, const string&in model ) override
    {
        return ( classname == "monster_hwgrunt"
            && model == "models/bts_rc/monsters/robothwgrunt.mdl" );
    }

    void TakeDamage( CBaseMonster@ victim, DamageInfo@ info )
    {
        if( ( info.bitsDamageType & DMG_BLAST ) != 0 && victim.pev.health > 10.0 )
        {
            info.bitsDamageType &= ~DMG_BLAST | DMG_LAUNCH;
            info.flDamage *= this.m_fDmgMultiplierBlast;
        }

        ASRoboGrunt::TakeDamage( victim, info );
    }
}

ASRoboGruntBoss gpRoboGruntBoss;

#if SERVER
RegisterCommand __gpRoboGruntTestCmd__(
    "robogrunt_test",
    "0/1 for regular or boss",
    "Spawn a robogrunt ahead",
    function( CBasePlayer@ player, array<string>@ arguments )
    {
        TraceResult tr;
        Math.MakeVectors( player.pev.v_angle );
        g_Utility.TraceLine( player.GetGunPosition(), player.GetGunPosition() + ( g_Engine.v_forward * 128 ), dont_ignore_monsters, player.edict(), tr );

        bool isBoss = ( arguments !is null && arguments.length() > 0 && atoi( arguments[0] ) == 1 );

        auto@ roboGrunt = ( isBoss ? gpRoboGruntBoss : gpRoboGrunt );
        dictionary@ keys = roboGrunt.TestKeys;

        CBaseEntity@ robo = g_EntityFuncs.CreateEntity( string( keys[ "classname" ] ), keys, true );

        robo.SetOrigin( tr.vecEndPos );

        roboGrunt.AddEntity( robo.entindex(), robo, null, null );
    }
);
#endif
