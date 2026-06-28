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
                "health":
                {
                    "type": "integer",
                    "default": 210,
                    "minimum": 1,
                    "description": "Monster health"
                },
                "max_leap_z":
                {
                    "type": "number",
                    "default": 256,
                    "minimum": 0,
                    "description": "Panther won't pounce at enemies if they're higher up than this from the panther's location"
                },
                "min_leap":
                {
                    "type": "number",
                    "default": 200,
                    "minimum": 0,
                    "description": "Panther won't pounce at enemies within this range"
                },
                "max_leap":
                {
                    "type": "number",
                    "default": 400,
                    "minimum": 0,
                    "description": "Panther won't pounce at enemies beyond this range"
                },
                "dmg_high_swipe":
                {
                    "type": "integer",
                    "default": 25,
                    "minimum": 1,
                    "description": "Damage on high swipe attack"
                },
                "dmg_low_swipe":
                {
                    "type": "integer",
                    "default": 15,
                    "minimum": 1,
                    "description": "Damage on low swipe attack"
                },
                "dmg_long_swipe":
                {
                    "type": "integer",
                    "default": 25,
                    "minimum": 1,
                    "description": "Damage on long swipe attack"
                },
                "dmg_leap":
                {
                    "type": "integer",
                    "default": 25,
                    "minimum": 1,
                    "description": "Damage on leap attack"
                },
                "dmg_thrash":
                {
                    "type": "integer",
                    "default": 10,
                    "minimum": 1,
                    "description": "Damage on thrash attack"
                },
                "dmg_thrash_frequency":
                {
                    "type": "number",
                    "default": 0.5,
                    "minimum": 0,
                    "description": "Cooldown for thrash attack"
                },
                "struggle_max":
                {
                    "type": "integer",
                    "default": 100,
                    "minimum": 1,
                    "description": ""
                },
                "struggle_drain_rate":
                {
                    "type": "number",
                    "default": 15.0,
                    "minimum": 1,
                    "description": "per second"
                },
                "struggle_grin":
                {
                    "type": "number",
                    "default": 8.0,
                    "minimum": 1,
                    "description": "per key press"
                },
                "stealth_visibility":
                {
                    "type": "integer",
                    "default": 15,
                    "minimum": 0,
                    "maximum": 100,
                    "description": "Visibility percentage"
                }
            }
        }""";
    }

    array<ScriptSchedule@> m_Schedules =
    {
        ScriptSchedule( ( bits_COND_ENEMY_OCCLUDED | bits_COND_NO_AMMO_LOADED ), 0, "Panthereye Range Attack1" )
    };

    int Health;
    float MaxLeapZ;
    float MinLeap;
    float MaxLeap;
    int DamageHighSwipe;
    int DamageLowSwipe;
    int DamageLongSwipe;
    int DamageLeap;
    int DamageThrash;
    float DamageThrashFrequency;
    int StruggleMax;
    float StruggleDrainRate;
    int StruggleGrin;
    int StealthVisibility;

    bool Register( meta_api::json::v2::json@ config ) override
    {
        this.Health = int( config[ "health" ] );
        this.MaxLeapZ = float( config[ "max_leap_z" ] );
        this.MinLeap = float( config[ "min_leap" ] );
        this.MaxLeap = float( config[ "max_leap" ] );
        this.DamageHighSwipe = int( config[ "dmg_high_swipe" ] );
        this.DamageLowSwipe = int( config[ "dmg_low_swipe" ] );
        this.DamageLongSwipe = int( config[ "dmg_long_swipe" ] );
        this.DamageLeap = int( config[ "dmg_leap" ] );
        this.DamageThrash = int( config[ "dmg_thrash" ] );
        this.DamageThrashFrequency = float( config[ "dmg_thrash_frequency" ] );
        this.StruggleMax = int( config[ "struggle_max" ] );
        this.StruggleDrainRate = float( config[ "struggle_drain_rate" ] );
        this.StruggleGrin = int( config[ "struggle_grin" ] );
        this.StealthVisibility = int( config[ "stealth_visibility" ] );

        g_EngineFuncs.ServerPrint( config.ToString() );
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
        g_SoundSystem.PrecacheSound( "bts_rc/panthereye/pouncehit.wav" );
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

class monster_panthereye : ScriptBaseMonsterEntity
{
    private bool m_bStealthed;
    private float m_iTargetRanderamt;

    private EHandle m_hVictim;
    private EHandle m_hPlayerDoll;

    private float m_flPinThinkRate;
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

        m_iTargetRanderamt = 255 * ( float( gpPanthereyeConfig.StealthVisibility ) / 100.0 );

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
        if( !this.m_bStealthed )
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
        if( !this.m_bStealthed )
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
            this.m_bStealthed = false;

        if( !this.m_bStealthed
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
            m_iTargetRanderamt = 255 * ( float( gpPanthereyeConfig.StealthVisibility ) / 100.0 );
        }

        if( self.pev.renderamt > m_iTargetRanderamt )
        {
            if( self.pev.renderamt == 255 )
            {
                g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "bts_rc/panthereye/stealth.ogg", VOL_NORM, ATTN_IDLE );
                m_bStealthed = true;
            }

            self.pev.renderamt = Math.max( self.pev.renderamt - 50, m_iTargetRanderamt );
            self.pev.rendermode = kRenderTransTexture;
        }
        else if( self.pev.renderamt < m_iTargetRanderamt )
        {
            self.pev.renderamt = Math.min( self.pev.renderamt + 50, m_iTargetRanderamt );

            if( self.pev.renderamt == 255 )
            {
                this.m_bStealthed = false;
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

                if( !this.m_bStealthed )
                    self.pev.framerate = 2.0;

                break;
            }
            case TASK_RUN_PATH:
            {
                if( this.m_bStealthed )
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
                if( !this.m_bStealthed )
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
                CBaseEntity@ hurt = MeleeAttack( 42.0, 64.0 );

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
                CBaseEntity@ hurt = MeleeAttack( 30.0, 64.0 );

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
                CBaseEntity@ hurt = MeleeAttack( 42.0, 82.0 ); //92

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
                this.m_bStealthed = false;

                //from HL2 Fast Zombie
                @pev.groundentity = null;

                g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "gonome/gonome_jumpattack.wav", VOL_NORM, ATTN_IDLE );

                //Take him off ground so engine doesn't instantly reset FL_ONGROUND.
                g_EntityFuncs.SetOrigin( self, self.pev.origin + Vector(0.0, 0.0, 1.0) );

                Vector vecJumpDir;
                CBaseEntity@ enemy = self.m_hEnemy.GetEntity();

                if( enemy !is null )
                {
                    Vector vecEnemyPos = enemy.EyePosition();

                    float height = ( vecEnemyPos.z - self.pev.origin.z );

                    if( height < 16 )
                        height = 16;
                    else if( height > 120 )
                        height = 120;

                    float speed = sqrt( 2 * 800 * height ); // 800 sv_gravity
                    float time = speed / 800;
                    g_Game.AlertMessage( at_console, "Called the gravity thing part" + "\n" );

                    vecJumpDir = vecEnemyPos - self.pev.origin;
                    vecJumpDir = vecJumpDir / time;
                    vecJumpDir.z = speed;

                    float distance = vecJumpDir.Length();
                    if( distance > 1000.0 ) //CLAMP
                        vecJumpDir = vecJumpDir * ( 1000.0 / distance ); //CLAMP

                    self.pev.velocity = vecJumpDir; //SetAbsVelocity( vecJumpDir );
                    self.m_flNextAttack = g_Engine.time + 2.0;
                }
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
        if( !self.m_hEnemy.IsValid() )
            return false;

        auto enemy = self.m_hEnemy.GetEntity();

        if( enemy is null )
            return false;

        if( ( self.pev.flags & FL_ONGROUND ) == 0 )
            return false;

        if( g_Engine.time < self.m_flNextAttack )
            return false;

        //make sure the enemy isn't too high up
        float flZDist = abs( enemy.GetOrigin().z - self.GetOrigin().z );

        if( gpPanthereyeConfig.MaxLeapZ > 0 && flZDist > gpPanthereyeConfig.MaxLeapZ )
            return false;

        if( gpPanthereyeConfig.MaxLeap > 0 && flDist > gpPanthereyeConfig.MaxLeap )
            return false;; // -TODO Tf with this being valid? Maybe report to anjo

        if( gpPanthereyeConfig.MinLeap > 0 && flDist < gpPanthereyeConfig.MinLeap )
            return false;

        if( flDot < 0.8 )
            return false;

        //The final check! Is the path from my position to halfway between me and the player clear?
        TraceResult tr;
        Vector vecDirToEnemy;

        vecDirToEnemy = enemy.GetOrigin() - self.GetOrigin();

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
        if( other is null )
            return;

        if( other.pev.takedamage == 0 )
            return;

        if( other.IRelationshipByClass( CLASS::CLASS_ALIEN_MILITARY ) == RELATIONSHIP::R_AL )
            return;

        Vector vecNewVelocity( 0.0, 0.0, self.pev.velocity.z );
        self.pev.velocity = vecNewVelocity;

        SetTouch( null );

        //Don't hit if back on ground
        if( ( self.pev.flags & FL_ONGROUND ) == 0 )
        {
            AttackSound( true );

            CBasePlayer@ player; 

            if( ( other.pev.effects & EF_NODRAW ) == 0 // Target is not being thrashed
            && other.IsAlive() // Target is alive
            && other.IsPlayer() // Target is player
            && ( @player = cast<CBasePlayer@>( other ) ) !is null // Cast to class
            && !player.FInViewCone( self ) ) // Target was hit from behind
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

                m_hVictim = EHandle( player );
                m_bIsPinning = true;

                m_flNextThrashDamage = g_Engine.time;
                m_flNextThrashSound  = g_Engine.time + 1.0;
                m_flPinEndTime = g_Engine.time + 5.0;

                g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "bts_rc/panthereye/pouncehit.wav", VOL_NORM, ATTN_IDLE );

                player.SetViewMode( ViewMode_ThirdPerson );
                //player.EnableControl( false ); //this prevents struggling
                player.SetMaxSpeedOverride( 0 );
                player.BlockWeapons(self);
                player.pev.iuser3 = 1; //disable ducking
                player.pev.fuser4 = 1; //disable jumping
                player.pev.effects |= EF_NODRAW;
                player.pev.velocity = g_vecZero;
                player.pev.movetype = MOVETYPE_NOCLIP; //without this, the player gets pushed by the panthereye

                self.pev.origin.x = player.pev.origin.x;
                self.pev.origin.y = player.pev.origin.y;
                self.pev.origin.z = player.pev.absmin.z;
                self.SetOrigin( self.pev.origin );

                self.SetActivity( ACT_EAT );

                SetThink( ThinkFunction(this.PinThink) );
                self.pev.nextthink = g_Engine.time;
                m_flPinThinkRate = g_Engine.time;
                return;
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
    }

    int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float damage, int bitsDamageType )
    {
        if( damage > 0.0 )
        {
            float flTemp = self.pev.max_health / gpPanthereyeConfig.Health;
            pevAttacker.frags += ( damage / self.pev.max_health * (flTemp + flTemp) );

            if( this.m_bStealthed )
            {
                self.m_movementActivity = ACT_RUN;
                this.m_bStealthed = false;
            }
        }

        if( m_bIsPinning and damage > 5.0 )
            StopPin();

        return BaseClass.TakeDamage( pevInflictor, pevAttacker, damage, bitsDamageType );
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

        float dt = 0.01; //match think rate

        m_flStruggle -= gpPanthereyeConfig.StruggleDrainRate * dt;

        if( ( victim.m_afButtonPressed & IN_FORWARD ) != 0 ) m_flStruggle += gpPanthereyeConfig.StruggleGrin;
        if( ( victim.m_afButtonPressed & IN_BACK ) != 0 ) m_flStruggle += gpPanthereyeConfig.StruggleGrin;
        if( ( victim.m_afButtonPressed & IN_MOVELEFT ) != 0 ) m_flStruggle += gpPanthereyeConfig.StruggleGrin;
        if( ( victim.m_afButtonPressed & IN_MOVERIGHT ) != 0 ) m_flStruggle += gpPanthereyeConfig.StruggleGrin;

        if( m_flStruggle < 0 ) m_flStruggle = 0;
        if( m_flStruggle > gpPanthereyeConfig.StruggleMax ) m_flStruggle = gpPanthereyeConfig.StruggleMax;

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
        g_PlayerFuncs.HudMessage( victim, hudTextParams, "STRUGGLE: [" + bar + "]" );

        if( m_flStruggle >= gpPanthereyeConfig.StruggleMax )
        {
            StopPin();
            return;
        }

        if( g_Engine.time >= m_flPinThinkRate )
        {
            victim.BlockWeapons(self);

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
                switch( RandomUint( 2, self ) )
                {
                    case 0: g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "bts_rc/panthereye/thrash1.wav", VOL_NORM, ATTN_IDLE ); break;
                    case 1: g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "bts_rc/panthereye/thrash2.wav", VOL_NORM, ATTN_IDLE ); break;
                    case 2: g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "bts_rc/panthereye/thrash3.wav", VOL_NORM, ATTN_IDLE ); break;
                }
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
            player.UnblockWeapons(self);
        }

        if( m_hPlayerDoll.IsValid() )
            g_EntityFuncs.Remove( m_hPlayerDoll.GetEntity() );

        m_bIsPinning = false;
        m_hVictim = null; //EHandle();
        m_hPlayerDoll = null;

        SetThink( null );
        self.pev.nextthink = g_Engine.time;
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

#if SERVER
monster_panthereye@ GetNearPanther( const Vector&in pos )
{
    CBaseEntity@ entity = null;

    while( ( @entity = g_EntityFuncs.FindEntityInSphere( entity, pos, 1024, "monster_panthereye", "classname" ) ) !is null && entity.IsAlive() ) {
        return cast<monster_panthereye>( CastToScriptClass( entity ) );
    }
    return null;
}

RegisterCommand __gpPanthereyeTestCmd__(
    "test_panthereye",
    "",
    "Spawn a panthereye ahead",
    function( CBasePlayer@ player, array<string>@ arguments )
    {
        TraceResult tr;
        Math.MakeVectors( player.pev.v_angle );
        g_Utility.TraceLine( player.GetGunPosition(), player.GetGunPosition() + ( g_Engine.v_forward * 128 ), dont_ignore_monsters, player.edict(), tr );

        CBaseEntity@ panthereye = g_EntityFuncs.CreateEntity( "monster_panthereye", {}, true );
        panthereye.SetOrigin( tr.vecEndPos );
    }
);
#endif
