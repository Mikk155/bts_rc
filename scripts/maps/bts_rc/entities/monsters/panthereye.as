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
    Author: Nero
    Rewrited by mikk 27/5/2026
*/

final class ASPanthereyeConfig : IConfigurableContext
{
    const string& GetName() const override
    {
        return "monster_panthereye";
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Monster panthereye",
            "description": "Controls panthereye settings",
            "properties":
            {
            }
        }""";
    }

    array<ScriptSchedule@> m_Schedules =
    {
        ScriptSchedule( ( bits_COND_ENEMY_OCCLUDED | bits_COND_NO_AMMO_LOADED ), 0, "Panthereye Range Attack1" )
    };

    int Health = 210;
    float MaxLeapZ = 256.0; //panther won't pounce at enemies if they're higher up than this from the panther's location
    float MinLeap = 200.0; //panther won't pounce at enemies within this range
    float MaxLeap = 400.0; //panther won't pounce at enemies beyond this range
    float DamageHighSwipe = 25.0;
    float DamageLowSwipe = 15.0;
    float DamageLongSwipe = 25.0;
    float DamageLeap = 25.0;
    float DamageThrash = 10.0;
    float DamageThrashFrequency = 0.5;
    float StruggleMax = 100.0;
    float StruggleDrainRate = 15.0; //per second (~ish)
    float StruggleGrin = 8.0; //per key press
    int StealthVisibility = 15; //in percentage 0-100

    bool Register( meta_api::json::v2::json@ config ) override
    {
        // Attack schedule start
        ScriptSchedule@ RangeAttack1 = m_Schedules[0];
        RangeAttack1.AddTask( ScriptTask(TASK_STOP_MOVING) );
        RangeAttack1.AddTask( ScriptTask(TASK_FACE_IDEAL) );
        RangeAttack1.AddTask( ScriptTask(TASK_RANGE_ATTACK1) );
        RangeAttack1.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );

        g_Game.PrecacheModel( "models/bts_rc/monsters/panthereye.mdl" );

        g_SoundSystem.PrecacheSound( "garg/gar_idle2.wav" );
        g_SoundSystem.PrecacheSound( "bullchicken/bc_idle5.wav" );
        g_SoundSystem.PrecacheSound( "agrunt/ag_idle1.wav" );
        g_SoundSystem.PrecacheSound( "bullchicken/bc_die3.wav" );
        g_SoundSystem.PrecacheSound( "bullchicken/bc_idle3.wav" );
        g_SoundSystem.PrecacheSound( "agrunt/ag_alert3.wav" );
        g_SoundSystem.PrecacheSound( "garg/gar_pain1.wav" );
        g_SoundSystem.PrecacheSound( "zombie/claw_miss1.wav" );
        g_SoundSystem.PrecacheSound( "zombie/claw_miss2.wav" );
        g_SoundSystem.PrecacheSound( "zombie/claw_strike1.wav" );
        g_SoundSystem.PrecacheSound( "zombie/claw_strike2.wav" );
        g_SoundSystem.PrecacheSound( "zombie/claw_strike3.wav" );
        g_SoundSystem.PrecacheSound( "gonome/gonome_jumpattack.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/panthereye/pounceHit.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/panthereye/thrash1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/panthereye/thrash2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/panthereye/thrash3.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/panthereye/stealth.ogg" );
        g_SoundSystem.PrecacheSound( "garg/gar_pain2.wav" );
        g_SoundSystem.PrecacheSound( "agrunt/ag_attack2.wav" );
        g_SoundSystem.PrecacheSound( "agrunt/ag_pain2.wav" );
        g_SoundSystem.PrecacheSound( "barnacle/bcl_chew2.wav" );
        g_SoundSystem.PrecacheSound( "barnacle/bcl_chew1.wav" );

        CustomEntity( "monster_panthereye" );

        return true;
    }
}

ASPanthereyeConfig gpPanthereyeConfig;

class monster_panthereye : bts_rc_base_monster
{
    private bool m_bStealthed;
    private float m_iTargetRanderamt;

    private EHandle m_hVictim;
    private EHandle m_hPlayerDoll;

    private float m_flPinThinkRate; //HandleStruggling needs a faster thinkrate
    private bool m_bIsPinning;
    private float m_flNextThrashDamage;
    private float m_flNextThrashSound;
    private float m_flPinEndTime;

    private float m_flStruggle;

    monster_panthereye()
    {
        @this.m_Schedules = @gpPanthereyeConfig.m_Schedules;
    }

    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/bts_rc/monsters/panthereye.mdl" );

        g_EntityFuncs.SetSize( self.pev, Vector(-16.0, -16.0, 0.0), Vector(16.0, 16.0, 32.0) );

        self.pev.solid = SOLID_SLIDEBOX;
        self.pev.movetype = MOVETYPE_STEP;
        self.m_bloodColor = BLOOD_COLOR_YELLOW;

        self.pev.health = self.pev.max_health = gpPanthereyeConfig.Health;

        self.m_flFieldOfView = 0.5;
        self.m_MonsterState = MONSTERSTATE_NONE;
        self.m_afCapability = bits_CAP_HEAR;

        m_iTargetRanderamt = 255 * btscm::ptof( gpPanthereyeConfig.StealthVisibility );

        self.MonsterInit();
    }

    void SetYawSpeed()
    {
        int ys = 120;
        self.pev.yaw_speed = ys;
    }

    int Classify()
    {
        return CLASS_ALIEN_MILITARY;
    }

    void PainSound()
    {
        switch( RandomUint( 2, self ) )
        {
            case 0: g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "garg/gar_pain1.wav", VOL_NORM, ATTN_IDLE ); break;
            case 1: g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "garg/gar_pain2.wav", VOL_NORM, ATTN_IDLE ); break;
            case 2: g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "agrunt/ag_pain2.wav", VOL_NORM, ATTN_IDLE ); break;
        }
    }

    void DeathSound()
    {
        switch( RandomUint( 1, self ) )
        {
            case 0: g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "bullchicken/bc_die3.wav", VOL_NORM, ATTN_IDLE ); break;
            case 1: g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "barnacle/bcl_chew2.wav", VOL_NORM, ATTN_IDLE ); break;
        }
    }

    void IdleSound()
    {
        if( !IsStealthed() )
        {
            switch( RandomUint( 4, self ) )
            {
                case 0: g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "garg/gar_idle2.wav", VOL_NORM, ATTN_IDLE ); break;
                case 1: g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "bullchicken/bc_idle5.wav", VOL_NORM, ATTN_IDLE ); break;
                case 2: g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "agrunt/ag_idle1.wav", VOL_NORM, ATTN_IDLE ); break;
                case 3: g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "bullchicken/bc_idle3.wav", VOL_NORM, ATTN_IDLE ); break;
                case 4: g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "barnacle/bcl_chew1.wav", VOL_NORM, ATTN_IDLE ); break;
            }
        }
    }

    void AlertSound()
    {
        if( !IsStealthed() )
        {
            switch( RandomUint( 1, self ) )
            {
                case 0: g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "agrunt/ag_alert3.wav", VOL_NORM, ATTN_IDLE ); break;
                case 1: g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "agrunt/ag_attack2.wav", VOL_NORM, ATTN_IDLE ); break;
            }
        }
    }

    void AttackSound( bool hit )
    {
        if( hit )
        {
            switch( RandomUint( 2, self ) )
            {
                case 0: g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "zombie/claw_strike1.wav", VOL_NORM, ATTN_STATIC ); break;
                case 1: g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "zombie/claw_strike2.wav", VOL_NORM, ATTN_STATIC ); break;
                case 2: g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "zombie/claw_strike3.wav", VOL_NORM, ATTN_STATIC ); break;
            }
        }
        else
        {
            switch( RandomUint( 1, self ) )
            {
                case 0: g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "zombie/claw_miss1.wav", VOL_NORM, ATTN_STATIC ); break;
                case 1: g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "zombie/claw_miss2.wav", VOL_NORM, ATTN_STATIC ); break;
            }
        }
    }

    void LeapAttackSound()
    {
        g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "gonome/gonome_jumpattack.wav", VOL_NORM, ATTN_IDLE );
    }

    void PounceHitSound()
    {
        g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "bts_rc/panthereye/pounceHit.wav", VOL_NORM, ATTN_IDLE );
    }

    void ThrashSound()
    {
        switch( RandomUint( 2, self ) )
        {
            case 0: g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "bts_rc/panthereye/thrash1.wav", VOL_NORM, ATTN_IDLE ); break;
            case 1: g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "bts_rc/panthereye/thrash2.wav", VOL_NORM, ATTN_IDLE ); break;
            case 2: g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "bts_rc/panthereye/thrash3.wav", VOL_NORM, ATTN_IDLE ); break;
        }
    }

    void RunAI()
    {
        BaseClass.RunAI();

        //WHY ISN'T THIS BEING RUN IN THE BASECLASS ?!
        switch( self.m_MonsterState )
        {
            case MONSTERSTATE::MONSTERSTATE_IDLE:
            case MONSTERSTATE::MONSTERSTATE_ALERT:
            {
                if( ( pev.flags & 2 /*SF_MONSTER_GAG*/ ) == 0 && Math.RandomLong( 0, 99 ) == 0 ) // Why this low chance? lol
                    IdleSound();
                break;
            }
        }

        if( self.HasConditions( bits_COND_CAN_MELEE_ATTACK1 ) || self.HasConditions( bits_COND_CAN_MELEE_ATTACK1 ) )
            StealthOff();

        if( !IsStealthed()
        && ( self.m_MonsterState == MONSTERSTATE_COMBAT
            || self.pev.deadflag != DEAD_NO
            || self.m_Activity == ACT_RUN
            || ( self.pev.flags & FL_ONGROUND ) == 0
        ) )
        {
            m_iTargetRanderamt = 255;
        }
        else
        {
            m_iTargetRanderamt = 255 * btscm::ptof( gpPanthereyeConfig.StealthVisibility );
        }

        if( self.pev.renderamt > m_iTargetRanderamt )
        {
            if( self.pev.renderamt == 255 )
                StealthOn();

            self.pev.renderamt = Math.max( self.pev.renderamt - 50, m_iTargetRanderamt );
            self.pev.rendermode = kRenderTransTexture;
        }
        else if( self.pev.renderamt < m_iTargetRanderamt )
        {
            self.pev.renderamt = Math.min( self.pev.renderamt + 50, m_iTargetRanderamt );

            if( self.pev.renderamt == 255 )
            {
                StealthOff();
                self.pev.rendermode = kRenderNormal;
            }
        }
    }

    void StartTask( Task@ task )
    {
        self.m_iTaskStatus = 1; //TASKSTATUS_RUNNING

        switch( task.iTask )
        {
            case TASK_RANGE_ATTACK1:
            {
                self.m_IdealActivity = ACT_RANGE_ATTACK1;
                SetTouch( TouchFunction(this.LeapAttackTouch) );

                if( !IsStealthed() )
                    self.pev.framerate = 2.0;

                break;
            }
            case TASK_RUN_PATH:
            {
                if( IsStealthed() )
                    self.m_movementActivity = ACT_WALK_SCARED;
                else
                    self.m_movementActivity = ACT_RUN;

                self.TaskComplete();
                break;
            }
            default:
            {
                BaseClass.StartTask( task );
                break;
            }
        }
    }

    void RunTask( Task@ task )
    {
        switch( task.iTask )
        {
            case TASK_RANGE_ATTACK1:
            {
                if( !IsStealthed() )
                    self.pev.framerate = 2.0;

                if( self.m_fSequenceFinished )
                {
                    self.TaskComplete();
                    SetTouch( null );
                    self.m_IdealActivity = ACT_IDLE;
                    break;
                }
            }
            default:
            {
                BaseClass.RunTask(task);
                break;
            }
        }
    }

    void HandleAnimEvent( MonsterEvent@ monsterEvent )
    {
        switch( monsterEvent.event )
        {
            case 1:
            {
                CBaseEntity@ hurt = AttackNormal();

                if( hurt !is null )
                {
                    Math.MakeVectors( self.pev.angles );
                    hurt.pev.velocity = hurt.pev.velocity + g_Engine.v_forward * 100 + g_Engine.v_up * 200;
                    hurt.TakeDamage( self.pev, self.pev, gpPanthereyeConfig.DamageHighSwipe, DMG_CLUB );
                    AttackSound( true );
                }
                else
                {
                    AttackSound( false );
                }

                break;
            }

            case 2:
            {
                CBaseEntity@ hurt = AttackLow();

                if( hurt !is null )
                {
                    Math.MakeVectors( self.pev.angles );
                    hurt.pev.velocity = hurt.pev.velocity + g_Engine.v_forward * 75 + g_Engine.v_up * 75;
                    hurt.TakeDamage( self.pev, self.pev, gpPanthereyeConfig.DamageLowSwipe, DMG_SLASH );
                    AttackSound( true ) ;
                }
                else
                {
                    AttackSound( false );
                }

                break;
            }

            case 3:
            {
                CBaseEntity@ hurt = AttackFar();

                if( hurt !is null )
                {
                    Math.MakeVectors( self.pev.angles );
                    hurt.pev.velocity = hurt.pev.velocity + g_Engine.v_forward * 100 + g_Engine.v_up * 200;
                    hurt.TakeDamage( self.pev, self.pev, gpPanthereyeConfig.DamageLongSwipe, DMG_CLUB );
                    AttackSound( true );
                }
                else
                {
                    AttackSound( false );
                }

                break;
            }

            case 4:
            {
                StealthOff();
                LeapAttack();
                break;
            }
            default:
            {
                BaseClass.HandleAnimEvent( monsterEvent );
                break;
            }
        }
    }

    //From HL2 Fast Zombie
    bool CheckRangeAttack1( float flDot, float flDist )
    {
        if( GetEnemy() is null )
            return false;

        if( ( self.pev.flags & FL_ONGROUND ) == 0 )
            return false;

        if( g_Engine.time < self.m_flNextAttack )
            return false;

        //make sure the enemy isn't too high up
        float flZDist = abs( GetEnemy().GetOrigin().z - self.GetOrigin().z );

        if( flZDist > gpPanthereyeConfig.MaxLeapZ )
            return false;

        if( flDist > gpPanthereyeConfig.MaxLeap )
            return false;;

        if( flDist < gpPanthereyeConfig.MinLeap )
            return false;

        if( flDot < 0.8 )
            return false;

        //The final check! Is the path from my position to halfway between me and the player clear?
        TraceResult tr;
        Vector vecDirToEnemy;

        vecDirToEnemy = GetEnemy().GetOrigin() - self.GetOrigin();

        //only check half the distance. (the first part of the jump)
        vecDirToEnemy = vecDirToEnemy * 0.5;

        g_Utility.TraceHull( self.GetOrigin(), self.GetOrigin() + vecDirToEnemy, dont_ignore_monsters, head_hull, self.edict(), tr );

        if( tr.flFraction != 1.0 )
        {
            //There's some sort of obstacle pretty much right in front of me.
            return false;
        }

        return true;
    }

    CBaseEntity@ AttackNormal()
    {
        return MeleeAttack( 42.0, 64.0 );
    }

    CBaseEntity@ AttackLow()
    {
        return MeleeAttack( 30.0, 64.0 );
    }

    CBaseEntity@ AttackFar()
    {
        return MeleeAttack( 42.0, 82.0 ); //92
    }

    CBaseEntity@ MeleeAttack( float flHeight, float flRange )
    {
        TraceResult tr;

        Math.MakeVectors( self.pev.angles );
        Vector vecStart = self.pev.origin;
        vecStart.z += flHeight;

        Vector vecEnd = vecStart + (g_Engine.v_forward * flRange);

        g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, self.edict(), tr );

        if( tr.pHit !is null )
        {
            CBaseEntity@ entity = g_EntityFuncs.Instance( tr.pHit );
            return entity;
        }

        return null;
    }

    //from HL2 Fast Zombie
    void LeapAttack()
    {
        @pev.groundentity = null;

        LeapAttackSound();

        //Take him off ground so engine doesn't instantly reset FL_ONGROUND.
        g_EntityFuncs.SetOrigin( self, self.pev.origin + Vector(0.0, 0.0, 1.0) );

        Vector vecJumpDir;
        CBaseEntity@ enemy = GetEnemy();

        if( enemy !is null )
        {
            Vector vecEnemyPos = enemy.EyePosition();

            float gravity = g_EngineFuncs.CVarGetFloat( "sv_gravity" );
            if( gravity <= 1 )
                gravity = 1;

            float height = ( vecEnemyPos.z - self.pev.origin.z );

            if( height < 16 )
                height = 16;
            else if( height > 120 )
                height = 120;

            float speed = sqrt( 2 * gravity * height );
            float time = speed / gravity;

            vecJumpDir = vecEnemyPos - self.pev.origin;
            vecJumpDir = vecJumpDir / time;
            vecJumpDir.z = speed;

            float distance = vecJumpDir.Length();
            if( distance > 1000.0 ) //CLAMP
                vecJumpDir = vecJumpDir * ( 1000.0 / distance ); //CLAMP

            self.pev.velocity = vecJumpDir; //SetAbsVelocity( vecJumpDir );
            self.m_flNextAttack = g_Engine.time + 2.0;
        }
    }

    Schedule@ GetSchedule()
    {
        switch( self.m_MonsterState )
        {
            case MONSTERSTATE_COMBAT:
            {
                if( self.HasConditions(bits_COND_CAN_MELEE_ATTACK1) )
                    return GetScheduleOfType( SCHED_MELEE_ATTACK1 );

                if( self.HasConditions(bits_COND_CAN_MELEE_ATTACK2) )
                    return GetScheduleOfType( SCHED_MELEE_ATTACK2 );

                if( self.HasConditions(bits_COND_CAN_RANGE_ATTACK1) )
                    return GetScheduleOfType( SCHED_RANGE_ATTACK1 );

                if( self.pev.health <= 75 )
                    return self.GetScheduleOfType( SCHED_TAKE_COVER_FROM_ENEMY );
            }
        }

        return BaseClass.GetSchedule();
    }

    Schedule@ GetScheduleOfType( int type )
    {
        switch( type )
        {
            case SCHED_RANGE_ATTACK1:
                return this.m_Schedules[0];
        }

        return BaseClass.GetScheduleOfType( type );
    }

    void LeapAttackTouch( CBaseEntity@ other )
    {
        if( other.pev.takedamage == 0 )
            return;

        if( other.IRelationshipByClass( CLASS::CLASS_ALIEN_MILITARY ) != RELATIONSHIP::R_AL )
            return;

        Vector vecNewVelocity( 0.0, 0.0, self.pev.velocity.z );
        self.pev.velocity = vecNewVelocity;

        //Don't hit if back on ground
        if( ( self.pev.flags & FL_ONGROUND ) == 0 )
        {
            AttackSound( true );

            CBasePlayer@ player = cast<CBasePlayer@>( other ); 

            if( player !is null )
            {
                //player was hit from behind and isn't already being thrashed!
                if( IsBehindTarget(player) && ( player.pev.effects & EF_NODRAW ) == 0 )
                {
                    StartPin( player );
                    //g_Game.AlertMessage( at_notice, "RAPED BY PANTHER!\n" );
                    SetTouch( null );
                    return;
                }
            }

            other.TakeDamage( self.pev, self.pev, gpPanthereyeConfig.DamageLeap, DMG_SLASH );

            //Knock the player back
            Vector vecForward;
            g_EngineFuncs.AngleVectors( self.pev.angles, vecForward, void, void );
            vecForward = vecForward * 500;
            Vector vecPunch( 15.0, Math.RandomFloat(-5.0, 5.0), Math.RandomFloat(-5.0, 5.0) );

            other.pev.punchangle = vecPunch;
            other.pev.velocity = other.pev.velocity + vecForward;
        }

        SetTouch( null );
    }

    int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float damage, int bitsDamageType )
    {
        if( damage > 0.0 )
        {
            pevAttacker.frags += GetPointsForDamage( damage );

            if( IsStealthed() )
            {
                self.m_movementActivity = ACT_RUN;
                StealthOff();
            }
        }

        if( m_bIsPinning and damage > 5.0 )
            StopPin();

        return BaseClass.TakeDamage( pevInflictor, pevAttacker, damage, bitsDamageType );
    }

    void StealthOn()
    {
        g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "bts_rc/panthereye/stealth.ogg", VOL_NORM, ATTN_IDLE );
        m_bStealthed = true;
    }

    void StealthOff()
    {
        m_bStealthed = false;
    }

    bool IsStealthed()
    {
        return m_bStealthed;
    }

    bool IsBehindTarget( CBasePlayer@ player )
    {
        return !player.FInViewCone( self );
    }

    void StartPin( CBasePlayer@ player )
    {
        if( player is null or !player.IsAlive() )
            return;

        SpawnVictim( player );
        m_hVictim = EHandle( player );
        m_bIsPinning = true;

        m_flNextThrashDamage = g_Engine.time;
        m_flNextThrashSound  = g_Engine.time + 1.0;
        m_flPinEndTime = g_Engine.time + 5.0;

        PounceHitSound();

        player.SetViewMode( ViewMode_ThirdPerson );
        //player.EnableControl( false ); //this prevents struggling
        player.SetMaxSpeedOverride( 0 );
        DisablePlayerWeapons( player );
        player.pev.iuser3 = 1; //disable ducking
        player.pev.fuser4 = 1; //disable jumping
        player.pev.effects |= EF_NODRAW;
        player.pev.velocity = g_vecZero;
        player.pev.movetype = MOVETYPE_NOCLIP; //without this, the player gets pushed by the panthereye

        Vector vecOrigin = player.pev.origin;
        vecOrigin.z = player.pev.absmin.z;
        self.SetOrigin( vecOrigin );

        self.SetActivity( ACT_EAT );

        SetThink( ThinkFunction(this.PinThink) );
        self.pev.nextthink = g_Engine.time;
        m_flPinThinkRate = g_Engine.time;
    }

    void SpawnVictim( CBasePlayer@ player )
    {
        Vector vecOrigin = player.pev.origin;
        vecOrigin.z = player.pev.absmin.z;

        Vector vecAngles = player.pev.angles;
        vecAngles.y += 180; //the "deadstomach" sequence is facing the wrong way blyat

        CBaseEntity@ playerDoll = g_EntityFuncs.Create( "cycler", vecOrigin, vecAngles, true );
        playerDoll.pev.model = player.pev.model;
        playerDoll.pev.sequence = 179;
        g_EntityFuncs.DispatchSpawn( playerDoll.edict() );
        playerDoll.pev.solid = SOLID_NOT;
        playerDoll.pev.takedamage = DAMAGE_NO;
        playerDoll.pev.renderfx = kRenderFxDeadPlayer;
        playerDoll.pev.renderamt = player.entindex();

        m_hPlayerDoll = EHandle( playerDoll );
        //LookupSequence( "die_forwards" );
        //die_forwards, deadstomach
        //15, 179
    }

    void DisablePlayerWeapons( CBasePlayer@ player )
    {
        if( player is null )
            return;

        //this also works
        //player.m_flNextAttack = g_Engine.time + 0.1;

        // -TODO does this mess with our weapon system?
        CBasePlayerWeapon@ weapon = cast<CBasePlayerWeapon@>( player.m_hActiveItem.GetEntity() );
        if( weapon !is null )
            weapon.Holster();
    }

    void EnablePlayerWeapons( CBasePlayer@ player )
    {
        if( player is null )
            return;

        //this also works
        //player.m_flNextAttack = 0;

        CBasePlayerWeapon@ weapon = cast<CBasePlayerWeapon@>( player.m_hActiveItem.GetEntity() );
        if( weapon !is null )
            weapon.Deploy();
    }

    void PinThink()
    {
        CBasePlayer@ victim = cast<CBasePlayer@>( m_hVictim.GetEntity() );

        if( !m_bIsPinning or victim is null or !victim.IsAlive() )
        {
            StopPin();
            return;
        }

        if( g_Engine.time >= m_flPinEndTime )
        {
            StopPin();
            return;
        }

        if( HandleStruggling(victim) )
        {
            StopPin();
            return;
        }

        if( g_Engine.time >= m_flPinThinkRate )
        {
            DisablePlayerWeapons( victim );

            if( g_Engine.time >= m_flNextThrashDamage )
            {
                victim.TakeDamage( self.pev, self.pev, gpPanthereyeConfig.DamageThrash, DMG_SLASH );

                Vector vecBlood;
                    vecBlood.x = victim.pev.absmin.x + victim.pev.size.x * ( Math.RandomFloat(0 , 1) );
                    vecBlood.y = victim.pev.absmin.y + victim.pev.size.y * ( Math.RandomFloat(0 , 1) );
                    vecBlood.z = victim.pev.absmin.z + victim.pev.size.z * ( Math.RandomFloat(0 , 1) ) + 1;
                    vecBlood.z -= 32.0;
                g_WeaponFuncs.SpawnBlood( vecBlood, victim.BloodColor(), gpPanthereyeConfig.DamageThrash*6.9 );

                m_flNextThrashDamage = g_Engine.time + gpPanthereyeConfig.DamageThrashFrequency;
            }

            if( g_Engine.time >= m_flNextThrashSound )
            {
                ThrashSound();
                m_flNextThrashSound = g_Engine.time + 1.0;
            }

            Vector vecOrigin = victim.pev.origin;
            vecOrigin.z = victim.pev.absmin.z;
            self.SetOrigin( vecOrigin );
            self.StudioFrameAdvance( 0.1 );

            m_flPinThinkRate = g_Engine.time + 0.1;
        }

        self.pev.nextthink = g_Engine.time + 0.01;
    }

    bool HandleStruggling( CBasePlayer@ player )
    {
        float dt = 0.01; //match think rate

        m_flStruggle -= gpPanthereyeConfig.StruggleDrainRate * dt;

        if( ( player.m_afButtonPressed & IN_FORWARD ) != 0 ) m_flStruggle += gpPanthereyeConfig.StruggleGrin;
        if( ( player.m_afButtonPressed & IN_BACK ) != 0 ) m_flStruggle += gpPanthereyeConfig.StruggleGrin;
        if( ( player.m_afButtonPressed & IN_MOVELEFT ) != 0 ) m_flStruggle += gpPanthereyeConfig.StruggleGrin;
        if( ( player.m_afButtonPressed & IN_MOVERIGHT ) != 0 ) m_flStruggle += gpPanthereyeConfig.StruggleGrin;

        if( m_flStruggle < 0 ) m_flStruggle = 0;
        if( m_flStruggle > gpPanthereyeConfig.StruggleMax ) m_flStruggle = gpPanthereyeConfig.StruggleMax;

        ShowStruggleBar( player );

        if( m_flStruggle >= gpPanthereyeConfig.StruggleMax )
        {
            StopPin();
            return true;
        }

        return false;
    }

    //Thanks ChatGPT
    void ShowStruggleBar( CBasePlayer@ player )
    {
        float frac = m_flStruggle / gpPanthereyeConfig.StruggleMax;

        int bars = int( frac * 20 ); // 20 segments
        string bar = "";

        for( int i = 0; i < 20; i++ )
        {
            if( i < bars )
                bar += "|";
            else
                bar += ".";
        }

        HUDTextParams hudTextParams;
            hudTextParams.x = -1;
            hudTextParams.y = 0.8;
            hudTextParams.effect = 0;
            hudTextParams.r1 = RGBA_SVENCOOP_HUD.r; //255;
            hudTextParams.g1 = RGBA_SVENCOOP_HUD.g; //50;
            hudTextParams.b1 = RGBA_SVENCOOP_HUD.b; //50;
            hudTextParams.a1 = RGBA_SVENCOOP_HUD.a; //255;
            hudTextParams.fadeinTime = 0;
            hudTextParams.fadeoutTime = 0;
            hudTextParams.holdTime = 0.1;
            hudTextParams.channel = 3;
        g_PlayerFuncs.HudMessage( player, hudTextParams, "STRUGGLE: [" + bar + "]" );
    }

    void StopPin()
    {
        CBasePlayer@ player = cast<CBasePlayer@>( m_hVictim.GetEntity() );

        if( player !is null )
        {
            player.SetViewMode( ViewMode_FirstPerson );
            //player.EnableControl( true );
            player.SetMaxSpeedOverride( -1 );
            player.pev.iuser3 = 0; //enable ducking
            player.pev.fuser4 = 0; //enable jumping
            player.pev.effects &= ~EF_NODRAW;
            player.pev.movetype = MOVETYPE_WALK;

            EnablePlayerWeapons( player );
        }

        if( m_hPlayerDoll.IsValid() )
            g_EntityFuncs.Remove( m_hPlayerDoll.GetEntity() );

        m_bIsPinning = false;
        m_hVictim = null; //EHandle();
        m_hPlayerDoll = null;

        SetThink( null );
        self.pev.nextthink = g_Engine.time;
    }

    float GetPointsForDamage( float damage )
    {
        float flTemp = self.pev.max_health / gpPanthereyeConfig.Health;
        return damage / self.pev.max_health * (flTemp + flTemp);
    }

    void UpdateOnRemove()
    {
        StopPin();
        BaseClass.UpdateOnRemove();
    }
}

/* TODO ??
screen shake / fade while pinned
forced view angle (player can’t look around)


g_PlayerFuncs.ScreenShake(player.pev.origin, 4.0f, 2.0f, 0.1f, 200.0f);

g_SoundSystem.EmitSoundDyn(player.edict(), CHAN_BODY, "player/pain2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
*/