/*
    Author: Nero
*/

namespace btscm
{

    HookReturnCode RobotTakeDamage( DamageInfo @pDamageInfo )
    {
        if( IsRobot( pDamageInfo.pVictim ) )
        {
            if( pDamageInfo.flDamage <= 0.0 or pDamageInfo.pVictim.pev.takedamage == DAMAGE_NO )
                return HOOK_CONTINUE;

            HandleRobotDamage( pDamageInfo );
        }

        return HOOK_CONTINUE;
    }

    void RoboThink()
    {
        CBaseEntity @pEntity = null;
        while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_human_grunt_ally" ) ) !is null )
        {
            if( pEntity.pev.model != "models/bts_rc/monsters/rgrunt_opfor.mdl" )
                continue;

            CustomKeyvalues @pCustom = pEntity.GetCustomKeyvalues();
            float flNextThink = pCustom.GetKeyvalue( KVN_MONSTERTHINK ).GetFloat();

            if( flNextThink <= g_Engine.time )
            {
                if( pEntity.pev.deadflag == DEAD_NO )
                {
                    ShowDamage( EHandle( pEntity ) );
                    LowHealth( EHandle( pEntity ) );
                    DoShockTouch( EHandle( pEntity ) );
                }

                DieThink( EHandle( pEntity ) );

                pCustom.SetKeyvalue( KVN_MONSTERTHINK, g_Engine.time + THINKRATE_OTHER );
            }
        }
    }

    void LowHealth( EHandle hMonster )
    {
        CBaseEntity @pMonster = hMonster.GetEntity();
        if( pMonster is null )
            return;

        if( ( pMonster.pev.health / pMonster.pev.max_health ) <= ROBOT_LOWHEALTH and pMonster.pev.deadflag != DEAD_DEAD )
        {
            CustomKeyvalues @pCustom = pMonster.GetCustomKeyvalues();
            float flNextSpark = pCustom.GetKeyvalue( KVN_NEXTSPARK ).GetFloat();
            bool bDoubleSpark = pCustom.GetKeyvalue( KVN_DOUBLESPARK ).GetInteger() == 1 ? true : false;

            Vector vecOrigin = Vector( Math.RandomFloat( pMonster.pev.absmin.x, pMonster.pev.absmax.x ), Math.RandomFloat( pMonster.pev.absmin.y, pMonster.pev.absmax.y ), Math.RandomFloat( pMonster.pev.origin.z, pMonster.pev.absmax.z ) );

            if( ( flNextSpark - 0.1 ) <= g_Engine.time and bDoubleSpark )
            {
                g_Utility.Sparks( vecOrigin );
                pCustom.SetKeyvalue( KVN_DOUBLESPARK, 0 );
            }

            if( flNextSpark + Math.RandomFloat( 0, 1 ) <= g_Engine.time )
            {
                g_Utility.Sparks( vecOrigin );
                if( Math.RandomLong( 1, 2 ) == 1 )
                    g_SoundSystem.EmitSoundDyn( pMonster.edict(), CHAN_BODY, "buttons/spark5.wav", 0.5, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
                else
                    g_SoundSystem.EmitSoundDyn( pMonster.edict(), CHAN_BODY, "buttons/spark6.wav", 0.5, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

                pCustom.SetKeyvalue( KVN_NEXTSPARK, g_Engine.time + 0.3 );
                UpdateGlow( hMonster );
                pCustom.SetKeyvalue( KVN_DOUBLESPARK, 1 );
            }
        }
    }

    void UpdateGlow( EHandle hMonster )
    {
        CBaseEntity @pMonster = hMonster.GetEntity();
        if( pMonster is null )
            return;

        CustomKeyvalues @pCustom = pMonster.GetCustomKeyvalues();
        float flNextSpark = pCustom.GetKeyvalue( KVN_NEXTSPARK ).GetFloat();
        bool bShockTouch = pCustom.GetKeyvalue( KVN_SHOCKTOUCH ).GetInteger() == 1 ? true : false;

        if( flNextSpark > g_Engine.time and !bShockTouch )
        {
            if( Math.RandomLong( 0, 30 ) > 26 )
            {
                g_SoundSystem.EmitSoundDyn( pMonster.edict(), CHAN_STATIC, "debris/beamstart14.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
                GlowEffect( hMonster, true );
                pCustom.SetKeyvalue( KVN_SHOCKTOUCH, 1 );
                pCustom.SetKeyvalue( KVN_NEXTSHOCK, g_Engine.time + 0.45 );
            }
            else if( Math.RandomLong( 0, 40 ) == 15 )
            {
                g_SoundSystem.EmitSoundDyn( pMonster.edict(), CHAN_STATIC, "debris/beamstart14.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
                GlowEffect( hMonster, true );
                pCustom.SetKeyvalue( KVN_SHOCKTOUCH, 1 );
                pCustom.SetKeyvalue( KVN_NEXTSHOCK, g_Engine.time + 0.35 );
            }
        }
    }

    void DoShockTouch( EHandle hMonster )
    {
        CBaseEntity @pMonster = hMonster.GetEntity();
        if( pMonster is null )
            return;

        CustomKeyvalues @pCustom = pMonster.GetCustomKeyvalues();
        bool bShockTouch = pCustom.GetKeyvalue( KVN_SHOCKTOUCH ).GetInteger() == 1 ? true : false;

        if( bShockTouch )
        {
            CBaseEntity @pTarget = null;
            while( ( @pTarget = g_EntityFuncs.FindEntityInSphere( pTarget, pMonster.pev.origin, pMonster.pev.size.z, "*", "classname" ) ) !is null )
            {
                if( pTarget is pMonster or !pTarget.IsAlive() or pTarget.pev.takedamage == DAMAGE_NO )
                    continue;

                pTarget.TakeDamage( pMonster.pev, pMonster.pev, SHOCKTOUCH_DAMAGE, DMG_SHOCK | DMG_LAUNCH );
            }
            /*this only damages one player blyat
                    TraceResult tr;
                    float flTraceOffset = pMonster.pev.size.z * pMonster.pev.scale;

                    g_Utility.TraceHull( pMonster.pev.origin, pMonster.pev.origin + Vector(0, 0, flTraceOffset), dont_ignore_monsters, large_hull, pMonster.edict(), tr );

                    if( tr.pHit !is null and !g_EntityFuncs.Instance(tr.pHit).IsBSPModel() and tr.pHit.vars.takedamage != DAMAGE_NO )
                    {
                        CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
                        pEntity.TakeDamage( pMonster.pev, pMonster.pev, SHOCKTOUCH_DAMAGE, DMG_SHOCK|DMG_LAUNCH );
                    }
            */
            float flNextShockTouch = pCustom.GetKeyvalue( KVN_NEXTSHOCK ).GetFloat();
            if( flNextShockTouch <= g_Engine.time )
            {
                GlowEffect( hMonster, false );
                pCustom.SetKeyvalue( KVN_SHOCKTOUCH, 0 );
            }
        }
    }

    void GlowEffect( EHandle hMonster, bool bOn )
    {
        CBaseEntity @pMonster = hMonster.GetEntity();
        if( pMonster is null )
            return;

        if( bOn )
        {
            pMonster.pev.rendermode = kRenderNormal;
            pMonster.pev.renderfx = kRenderFxGlowShell;
            pMonster.pev.renderamt = 4.0;
            pMonster.pev.rendercolor = Vector( 100, 100, 220 );
        }
        else
        {
            pMonster.pev.rendermode = kRenderNormal;
            pMonster.pev.renderfx = kRenderFxNone;
            pMonster.pev.renderamt = 255.0;
            pMonster.pev.rendercolor = g_vecZero;
        }
    }

    void HandleRobotDamage( DamageInfo @pDamageInfo, bool bBoss = false )
    {
        CustomKeyvalues @pCustom = pDamageInfo.pVictim.GetCustomKeyvalues();
        bool bShockTouch = pCustom.GetKeyvalue( KVN_SHOCKTOUCH ).GetInteger() == 1 ? true : false;

        if( bShockTouch )
        {
            if( HasFlags( pDamageInfo.bitsDamageType, DMG_SLASH | DMG_CLUB ) )
            {
                pDamageInfo.pAttacker.TakeDamage( pDamageInfo.pVictim.pev, pDamageInfo.pVictim.pev, SHOCKTOUCH_DAMAGE / 4, DMG_SHOCK );
                pDamageInfo.flDamage = 0.01;
            }
        }
        else if( HasFlags( pDamageInfo.bitsDamageType, DMG_SLASH | DMG_CLUB ) and pDamageInfo.pVictim.pev.health <= 20.0 and Math.RandomLong( 0, 2 ) > 1 )
        {
            GlowEffect( EHandle( pDamageInfo.pVictim ), true );
            pCustom.SetKeyvalue( KVN_SHOCKTOUCH, 1 );
        }

        bool bRicochet = false;

        if( HasFlags( pDamageInfo.bitsDamageType, DMG_BULLET ) )
        {
            bRicochet = true;
            pDamageInfo.flDamage *= DAMAGE_MULT_BULLET;
        }
        else if( HasFlags( pDamageInfo.bitsDamageType, DMG_CLUB | DMG_SLASH ) )
        {
            bRicochet = true;
            pDamageInfo.flDamage *= DAMAGE_MULT_MELEE;
        }
        else if( HasFlags( pDamageInfo.bitsDamageType, DMG_BLAST ) and pDamageInfo.pVictim.pev.health > 10.0 )
        {
            if( pDamageInfo.flDamage > 15.0 )
                pDamageInfo.flDamage -= 15.0;

            // prevents launching the boss
            if( bBoss )
            {
                pDamageInfo.bitsDamageType &= ~DMG_BLAST | DMG_LAUNCH;
                pDamageInfo.flDamage *= DAMAGE_MULT_BLAST;
            }
        }
        else if( !HasFlags( pDamageInfo.bitsDamageType, DMG_POISON ) )
        {
            // robots can't get poisoned
            pDamageInfo.bitsDamageType &= ~DMG_POISON;
            pDamageInfo.flDamage *= DAMAGE_MULT_POISON;
        }
        else if( !HasFlags( pDamageInfo.bitsDamageType, DMG_BURN ) or pDamageInfo.pVictim.pev.health <= 10.0 )
            pDamageInfo.flDamage *= DAMAGE_MULT_BURN;
        else
            pDamageInfo.flDamage *= DAMAGE_MULT_GENERIC;

        if( bRicochet )
        {
            TraceResult tr = g_Utility.GetGlobalTrace();

            if( pDamageInfo.pAttacker !is null and pDamageInfo.pAttacker.pev.FlagBitSet( FL_CLIENT ) )
            {
                NetworkMessage ricochet( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, pDamageInfo.pAttacker.edict() );
                ricochet.WriteByte( TE_ARMOR_RICOCHET );
                ricochet.WriteCoord( tr.vecEndPos.x );
                ricochet.WriteCoord( tr.vecEndPos.y );
                ricochet.WriteCoord( tr.vecEndPos.z );
                ricochet.WriteByte( 10 ); // scale in 0.1's
                ricochet.End();
            }
        }
    }

    void DoRobotDeath( EHandle hMonster, bool bGibbed = false, bool bBoss = false )
    {
        CBaseMonster @pMonster = hMonster.GetEntity().MyMonsterPointer();
        if( pMonster is null )
            return;

        pMonster.pev.velocity = g_vecZero;
        pMonster.pev.deadflag = DEAD_DYING;

        if( bGibbed )
        {
            ExplosiveDeath( hMonster );
            return;
        }

        GlowEffect( hMonster, false );
        GetSoundEntInstance().InsertSound( bits_SOUND_DANGER, pMonster.pev.origin, 250, 2.5, pMonster );

        if( Math.RandomLong( 1, 2 ) == 1 )
            g_SoundSystem.EmitSound( pMonster.edict(), CHAN_VOICE, "bts_rc/rgrunt/rb_death1.wav", VOL_NORM, 0.5 );
        else
            g_SoundSystem.EmitSound( pMonster.edict(), CHAN_VOICE, "bts_rc/rgrunt/rb_death2.wav", VOL_NORM, 0.5 );

        CustomKeyvalues @pCustom = pMonster.GetCustomKeyvalues();
        pCustom.SetKeyvalue( KVN_REMOVETIME, g_Engine.time + Math.RandomFloat( 3.0, 7.0 ) );
        pCustom.SetKeyvalue( KVN_DIETHINK, g_Engine.time );
    }

    void ShowDamage( EHandle hMonster )
    {
        CBaseEntity @pMonster = hMonster.GetEntity();
        if( pMonster is null )
            return;

        CustomKeyvalues @pCustom = pMonster.GetCustomKeyvalues();
        int iDoSmokePuff = pCustom.GetKeyvalue( KVN_DOSMOKEPUFF ).GetInteger();
        Vector vecOrigin = pMonster.pev.origin + Vector( 0, 0, pMonster.pev.size.z ); // GetEyePosition() ??

        if( iDoSmokePuff > 0 or Math.RandomLong( 0, 99 ) > pMonster.pev.health )
        {
            NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
            m1.WriteByte( TE_SMOKE );
            m1.WriteCoord( vecOrigin.x + Math.RandomFloat( -16.0, 16.0 ) );
            m1.WriteCoord( vecOrigin.y + Math.RandomFloat( -16.0, 16.0 ) );
            m1.WriteCoord( vecOrigin.z - 32.0 );
            m1.WriteShort( g_Game.PrecacheModel( SPRITE_RGRUNT_SMOKE ) );
            m1.WriteByte( Math.RandomLong( 1, 9 ) ); // scale * 10
            m1.WriteByte( 12 );                      // framerate
            m1.End();
        }

        if( iDoSmokePuff > 0 )
            iDoSmokePuff--;

        pCustom.SetKeyvalue( KVN_DOSMOKEPUFF, iDoSmokePuff );
    }

    void ExplosiveDeath( EHandle hMonster )
    {
        CBaseMonster @pMonster = hMonster.GetEntity().MyMonsterPointer();
        if( pMonster is null )
            return;
        CustomKeyvalues @pCustom = pMonster.GetCustomKeyvalues();

        SpawnExplosion( pMonster.pev.origin, 0.0, 0.0, EXPLODE_DAMAGE );

        if( freeedicts( 15 ) )
        {
            NetworkMessage gib1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pMonster.pev.origin );
            gib1.WriteByte( TE_BREAKMODEL );
            gib1.WriteCoord( pMonster.pev.origin.x );                     // position
            gib1.WriteCoord( pMonster.pev.origin.y );
            gib1.WriteCoord( pMonster.pev.origin.z );
            gib1.WriteCoord( 200 );                                       // size
            gib1.WriteCoord( 200 );
            gib1.WriteCoord( 64 );
            gib1.WriteCoord( 10 );                                        // velocity
            gib1.WriteCoord( 20 );
            gib1.WriteCoord( 80 );
            gib1.WriteByte( 30 );                                         // randomization
            gib1.WriteShort( g_Game.PrecacheModel( MODEL_RGRUNT_GIB1 ) ); // model id#
            gib1.WriteByte( 15 );                                         // # of shards
            gib1.WriteByte( 100 );                                        // duration (3.0 seconds)
            gib1.WriteByte( BREAK_METAL );                                // flags
            gib1.End();
        }

        if( freeedicts( 15 ) )
        {
            NetworkMessage gib2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pMonster.pev.origin );
            gib2.WriteByte( TE_BREAKMODEL );
            gib2.WriteCoord( pMonster.pev.origin.x );                     // position
            gib2.WriteCoord( pMonster.pev.origin.y );
            gib2.WriteCoord( pMonster.pev.origin.z );
            gib2.WriteCoord( 200 );                                       // size
            gib2.WriteCoord( 200 );
            gib2.WriteCoord( 96 );
            gib2.WriteCoord( 0 );                                         // velocity
            gib2.WriteCoord( 0 );
            gib2.WriteCoord( 10 );
            gib2.WriteByte( 30 );                                         // randomization
            gib2.WriteShort( g_Game.PrecacheModel( MODEL_RGRUNT_GIB2 ) ); // model id#
            gib2.WriteByte( 15 );                                         // # of shards
            gib2.WriteByte( 100 );                                        // duration (3.0 seconds)
            gib2.WriteByte( BREAK_METAL );                                // flags
            gib2.End();
        }

        g_SoundSystem.EmitSoundDyn( pMonster.edict(), CHAN_BODY, "debris/beamstart14.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

        if( freeedicts( 1 ) )
        {
            CBaseEntity @pSmoker = g_EntityFuncs.Create( "env_smoker", pMonster.pev.origin, g_vecZero, false );
            pSmoker.pev.health = 1;                      // 1 smoke balls
            pSmoker.pev.scale = 10;                      // 4.6X normal size
            pSmoker.pev.dmg = 0;                         // 0 radial distribution
            pSmoker.pev.nextthink = g_Engine.time + 0.5; // Start in 0.5 seconds
        }

        Vector vecOrigin;
        vecOrigin.x = pMonster.pev.absmin.x + pMonster.pev.size.x * ( Math.RandomFloat( 0, 1 ) );
        vecOrigin.y = pMonster.pev.absmin.y + pMonster.pev.size.y * ( Math.RandomFloat( 0, 1 ) );
        vecOrigin.z = pMonster.pev.absmin.z + pMonster.pev.size.z * ( Math.RandomFloat( 0, 1 ) ) + 1; // absmin.z is in the floor because the engine subtracts 1 to enlarge the box

        g_Utility.Sparks( vecOrigin );

        pCustom.SetKeyvalue( KVN_DIETHINK, 0.0 );
        g_EntityFuncs.Remove( pMonster );
    }

    void DieThink( EHandle hMonster )
    {
        CBaseMonster @pMonster = hMonster.GetEntity().MyMonsterPointer();
        if( pMonster is null )
            return;

        CustomKeyvalues @pCustom = pMonster.GetCustomKeyvalues();
        float flNextDieThink = pCustom.GetKeyvalue( KVN_DIETHINK ).GetFloat();

        if( flNextDieThink > 0.0 and flNextDieThink <= g_Engine.time )
        {
            if( pMonster.pev.deadflag != DEAD_DEAD )
                pMonster.pev.deadflag = DEAD_DEAD;

            if( pCustom.GetKeyvalue( KVN_REMOVETIME ).GetFloat() <= g_Engine.time )
            {
                pMonster.pev.solid = SOLID_NOT;

                ExplosiveDeath( hMonster );
            }
            else
            {
                Vector vecOrigin;
                vecOrigin.x = pMonster.pev.absmin.x + pMonster.pev.size.x * ( Math.RandomFloat( 0, 1 ) );
                vecOrigin.y = pMonster.pev.absmin.y + pMonster.pev.size.y * ( Math.RandomFloat( 0, 1 ) );
                vecOrigin.z = pMonster.pev.absmin.z + pMonster.pev.size.z * ( Math.RandomFloat( 0, 1 ) ) + 1; // absmin.z is in the floor because the engine subtracts 1 to enlarge the box

                if( freeedicts( 1 ) )
                {
                    NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
                    m1.WriteByte( TE_SMOKE );
                    m1.WriteCoord( vecOrigin.x );
                    m1.WriteCoord( vecOrigin.y );
                    m1.WriteCoord( vecOrigin.z );
                    m1.WriteShort( g_Game.PrecacheModel( SPRITE_RGRUNT_SMOKE ) );
                    m1.WriteByte( 15 ); // scale * 10
                    m1.WriteByte( 10 ); // framerate
                    m1.End();
                }

                g_Utility.Sparks( vecOrigin );

                pCustom.SetKeyvalue( KVN_DIETHINK, g_Engine.time + 0.1 );
            }
        }
    }

    bool IsRobot( CBaseEntity @pMonster )
    {
        if( pMonster.GetClassname() == "monster_human_grunt_ally" and pMonster.pev.model == "models/bts_rc/monsters/rgrunt_opfor.mdl" )
            return true;

        return false;
    }

    bool IsRobotBoss( CBaseEntity @pMonster )
    {
        if( pMonster.GetClassname() == "monster_hwgrunt" and pMonster.pev.model == "models/bts_rc/monsters/robothwgrunt.mdl" )
            return true;

        return false;
    }

    void RobogruntMapInit()
    {
        g_Game.PrecacheModel( SPRITE_RGRUNT_SMOKE );

        // explode on death
        g_Game.PrecacheModel( MODEL_RGRUNT_GIB1 );
        g_Game.PrecacheModel( MODEL_RGRUNT_GIB2 );
        g_SoundSystem.PrecacheSound( "debris/beamstart14.wav" );

        // low health stuff
        g_SoundSystem.PrecacheSound( "buttons/spark5.wav" );
        g_SoundSystem.PrecacheSound( "buttons/spark6.wav" );

        // handles different hitgroups (head, shield), ricochets, and damage reduction for various damage types, probably needs tweaking :eheh:
        g_Hooks.RegisterHook( Hooks::Monster::MonsterTakeDamage, @RobotTakeDamage );
    }

} // namespace btscm END