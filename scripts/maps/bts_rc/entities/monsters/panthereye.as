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
            "title": "Blood puddles",
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
    private EHandle m_hFakeBody;

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

        pev.solid                   = SOLID_SLIDEBOX;
        pev.movetype            = MOVETYPE_STEP;
        self.m_bloodColor       = BLOOD_COLOR_YELLOW;

        self.pev.health = self.pev.max_health = gpPanthereyeConfig.Health;

        //pev.view_ofs              = Vector( 0.0, 0.0, 6.0 ); //set ??
        self.m_flFieldOfView    = 0.5;
        self.m_MonsterState = MONSTERSTATE_NONE;
        self.m_afCapability     = bits_CAP_HEAR;

        m_iTargetRanderamt  = 255 * btscm::ptof( gpPanthereyeConfig.StealthVisibility );

        self.MonsterInit();
    }

    void SetYawSpeed()
    {
        int ys = 120;
        pev.yaw_speed = ys;
    }

    int ObjectCaps()
    {
        if( self.IsPlayerAlly() )
            return FCAP_IMPULSE_USE;
        else
            return BaseClass.ObjectCaps();
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

    void AttackSound( bool bHit )
    {
        if( bHit )
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
        if( (self.m_MonsterState == MONSTERSTATE_IDLE or self.m_MonsterState == MONSTERSTATE_ALERT) and Math.RandomLong(0, 99) == 0 and !btscm::HasFlags(pev.flags, 2) ) //SF_MONSTER_GAG
            IdleSound();

        if( self.HasConditions(bits_COND_CAN_MELEE_ATTACK1) or self.HasConditions(bits_COND_CAN_MELEE_ATTACK1) )
            StealthOff();

        if( !IsStealthed() and (self.m_MonsterState == MONSTERSTATE_COMBAT or pev.deadflag != DEAD_NO or self.m_Activity == ACT_RUN or !btscm::HasFlags(pev.flags, FL_ONGROUND)) )
            m_iTargetRanderamt = 255;
        else
            m_iTargetRanderamt = 255 * btscm::ptof( gpPanthereyeConfig.StealthVisibility );

        if( pev.renderamt > m_iTargetRanderamt )
        {
            if( pev.renderamt == 255 )
                StealthOn();

            pev.renderamt = Math.max( pev.renderamt - 50, m_iTargetRanderamt );
            pev.rendermode = kRenderTransTexture;
        }
        else if( pev.renderamt < m_iTargetRanderamt )
        {
            pev.renderamt = Math.min( pev.renderamt + 50, m_iTargetRanderamt );

            if( pev.renderamt == 255 )
            {
                StealthOff();
                pev.rendermode = kRenderNormal;
            }
        }
    }

    void StartTask( Task@ pTask )
    {
        self.m_iTaskStatus = 1; //TASKSTATUS_RUNNING

        switch( pTask.iTask )
        {
            case TASK_RANGE_ATTACK1:
            {
                self.m_IdealActivity = ACT_RANGE_ATTACK1;
                SetTouch( TouchFunction(this.LeapAttackTouch) );

                if( !IsStealthed() )
                    pev.framerate = 2.0;

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

            default: BaseClass.StartTask( pTask ); break;
        }
    }

    void RunTask( Task@ pTask )
    {
        switch( pTask.iTask )
        {
            case TASK_RANGE_ATTACK1:
            {
                if( !IsStealthed() )
                    pev.framerate = 2.0;

                if( self.m_fSequenceFinished )
                {
                    self.TaskComplete();
                    SetTouch( null );
                    self.m_IdealActivity = ACT_IDLE;
                    break;
                }
            }

            default: BaseClass.RunTask(pTask); break;
        }
    }

    void HandleAnimEvent( MonsterEvent@ pEvent )
    {
        switch( pEvent.event )
        {
            case 1:
            {
                CBaseEntity@ pHurt = AttackNormal();
                if( pHurt !is null )
                {
                    Math.MakeVectors( pev.angles );
                    pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 100 + g_Engine.v_up * 200;
                    pHurt.TakeDamage( self.pev, self.pev, gpPanthereyeConfig.DamageHighSwipe, DMG_CLUB );
                    AttackSound( true );
                }
                else
                    AttackSound( false );

                break;
            }

            case 2:
            {
                CBaseEntity@ pHurt = AttackLow();
                if( pHurt !is null )
                {
                    Math.MakeVectors( pev.angles );
                    pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 75 + g_Engine.v_up * 75;
                    pHurt.TakeDamage( self.pev, self.pev, gpPanthereyeConfig.DamageLowSwipe, DMG_SLASH );
                    AttackSound( true ) ;
                }
                else
                    AttackSound( false );

                break;
            }

            case 3:
            {
                CBaseEntity@ pHurt = AttackFar();
                if( pHurt !is null )
                {
                    Math.MakeVectors( pev.angles );
                    pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 100 + g_Engine.v_up * 200;
                    pHurt.TakeDamage( self.pev, self.pev, gpPanthereyeConfig.DamageLongSwipe, DMG_CLUB );
                    AttackSound( true );
                }
                else
                    AttackSound( false );

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
                BaseClass.HandleAnimEvent( pEvent );
                break;
            }
        }
    }

    //From HL2 Fast Zombie
    bool CheckRangeAttack1( float flDot, float flDist )
    {
        if( GetEnemy() is null )
            return false;

        if( !pev.FlagBitSet(FL_ONGROUND) )
            return false;

        if( g_Engine.time < self.m_flNextAttack )
            return false;

        //make sure the enemy isn't too high up
        float flZDist;
        flZDist = abs( GetEnemy().GetOrigin().z - self.GetOrigin().z );
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

        Math.MakeVectors( pev.angles );
        Vector vecStart = pev.origin;
        vecStart.z += flHeight;

        Vector vecEnd = vecStart + (g_Engine.v_forward * flRange);

        g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, self.edict(), tr );

        if( tr.pHit !is null )
        {
            CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
            return pEntity;
        }

        return null;
    }

    //from HL2 Fast Zombie
    void LeapAttack()
    {
        @pev.groundentity = null;

        LeapAttackSound();

        //Take him off ground so engine doesn't instantly reset FL_ONGROUND.
        g_EntityFuncs.SetOrigin( self, pev.origin + Vector(0.0, 0.0, 1.0) );

        Vector vecJumpDir;
        CBaseEntity@ pEnemy = GetEnemy();

        if( pEnemy !is null )
        {
            Vector vecEnemyPos = pEnemy.EyePosition();

            float gravity = g_EngineFuncs.CVarGetFloat( "sv_gravity" );
            if( gravity <= 1 )
                gravity = 1;

            float height = ( vecEnemyPos.z - pev.origin.z );

            if( height < 16 )
                height = 16;
            else if( height > 120 )
                height = 120;

            float speed = sqrt( 2 * gravity * height );
            float time = speed / gravity;

            vecJumpDir = vecEnemyPos - pev.origin;
            vecJumpDir = vecJumpDir / time;
            vecJumpDir.z = speed;

            float distance = vecJumpDir.Length();
            if( distance > 1000.0 ) //CLAMP
                vecJumpDir = vecJumpDir * ( 1000.0 / distance ); //CLAMP

            pev.velocity = vecJumpDir; //SetAbsVelocity( vecJumpDir );
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

                if( pev.health <= 75 )
                    return self.GetScheduleOfType( SCHED_TAKE_COVER_FROM_ENEMY );
            }
        }

        return BaseClass.GetSchedule();
    }

    Schedule@ GetScheduleOfType( int iType )
    {
        switch( iType )
        {
            case SCHED_RANGE_ATTACK1:
            return this.m_Schedules[0];
        }

        return BaseClass.GetScheduleOfType( iType );
    }

    void LeapAttackTouch( CBaseEntity@ pOther )
    {
        if( pOther.pev.takedamage == 0 )
            return;

        if( pOther.IRelationshipByClass( CLASS::CLASS_ALIEN_MILITARY ) != RELATIONSHIP::R_AL )
            return;

        Vector vecNewVelocity( 0.0, 0.0, pev.velocity.z );
        pev.velocity = vecNewVelocity;

        //Don't hit if back on ground
        if( !pev.FlagBitSet(FL_ONGROUND) )
        {
            AttackSound( true );

            CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther ); 

            if( pPlayer !is null )
            {
                //player was hit from behind and isn't already being thrashed!
                if( IsBehindTarget(pPlayer) and !btscm::HasFlags(pPlayer.pev.effects, EF_NODRAW) )
                {
                    StartPin( pPlayer );
                    //g_Game.AlertMessage( at_notice, "RAPED BY PANTHER!\n" );
                    SetTouch( null );
                    return;
                }
            }

            pOther.TakeDamage( self.pev, self.pev, gpPanthereyeConfig.DamageLeap, DMG_SLASH );

            //Knock the player back
            Vector vecForward;
            g_EngineFuncs.AngleVectors( pev.angles, vecForward, void, void );
            vecForward = vecForward * 500;
            Vector vecPunch( 15.0, Math.RandomFloat(-5.0, 5.0), Math.RandomFloat(-5.0, 5.0) );

            pOther.pev.punchangle = vecPunch;
            pOther.pev.velocity = pOther.pev.velocity + vecForward;
        }

        SetTouch( null );
    }

    int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
    {
        if( flDamage > 0.0 )
        {
            pevAttacker.frags += GetPointsForDamage( flDamage );
            if( IsStealthed() )
            {
                self.m_movementActivity = ACT_RUN;
                StealthOff();
            }
        }

        if( m_bIsPinning and flDamage > 5.0 )
            StopPin();

        return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
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

    bool IsBehindTarget(CBasePlayer@ pPlayer)
    {
        /*Vector forward;
        g_EngineFuncs.AngleVectors( pPlayer.pev.angles, forward, void, void );

        Vector dirToMonster = (pev.origin - pPlayer.pev.origin).Normalize();

        float dot = DotProduct( forward, dirToMonster );

        return dot > 0.5; //tweak threshold*/
        return !pPlayer.FInViewCone( self );
    }

    void StartPin( CBasePlayer@ pPlayer )
    {
        if( pPlayer is null or !pPlayer.IsAlive() )
            return;

        SpawnVictim( pPlayer );
        m_hVictim = EHandle( pPlayer );
        m_bIsPinning = true;

        m_flNextThrashDamage = g_Engine.time;
        m_flNextThrashSound  = g_Engine.time + 1.0;
        m_flPinEndTime = g_Engine.time + 5.0;

        PounceHitSound();

        pPlayer.SetViewMode( ViewMode_ThirdPerson );
        //pPlayer.EnableControl( false ); //this prevents struggling
        pPlayer.SetMaxSpeedOverride( 0 );
        DisablePlayerWeapons( pPlayer );
        pPlayer.pev.iuser3 = 1; //disable ducking
        pPlayer.pev.fuser4 = 1; //disable jumping
        pPlayer.pev.effects |= EF_NODRAW;
        pPlayer.pev.velocity = g_vecZero;
        pPlayer.pev.movetype = MOVETYPE_NOCLIP; //without this, the player gets pushed by the panthereye

        Vector vecOrigin = pPlayer.pev.origin;
        vecOrigin.z = pPlayer.pev.absmin.z;
        self.SetOrigin( vecOrigin );

        self.SetActivity( ACT_EAT );

        SetThink( ThinkFunction(this.PinThink) );
        pev.nextthink = g_Engine.time;
        m_flPinThinkRate = g_Engine.time;
    }

    void SpawnVictim( CBasePlayer@ pPlayer )
    {
        Vector vecOrigin = pPlayer.pev.origin;
        vecOrigin.z = pPlayer.pev.absmin.z;

        Vector vecAngles = pPlayer.pev.angles;
        vecAngles.y += 180; //the "deadstomach" sequence is facing the wrong way blyat

        CBaseEntity@ pFake = g_EntityFuncs.Create( "cycler", vecOrigin, vecAngles, true );
        pFake.pev.model = pPlayer.pev.model;
        pFake.pev.sequence = 179;
        g_EntityFuncs.DispatchSpawn( pFake.edict() );
        pFake.pev.solid = SOLID_NOT;
        pFake.pev.takedamage = DAMAGE_NO;
        pFake.pev.renderfx = kRenderFxDeadPlayer;
        pFake.pev.renderamt = pPlayer.entindex();

        m_hFakeBody = EHandle( pFake );
        //LookupSequence( "die_forwards" );
        //die_forwards, deadstomach
        //15, 179
    }

    void DisablePlayerWeapons( CBasePlayer@ pPlayer )
    {
        if( pPlayer is null )
            return;

        //this also works
        //pPlayer.m_flNextAttack = g_Engine.time + 0.1;

        CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pPlayer.m_hActiveItem.GetEntity() );
        if( pWeapon !is null )
            pWeapon.Holster();
    }

    void EnablePlayerWeapons( CBasePlayer@ pPlayer )
    {
        if( pPlayer is null )
            return;

        //this also works
        //pPlayer.m_flNextAttack = 0;

        CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pPlayer.m_hActiveItem.GetEntity() );
        if( pWeapon !is null )
            pWeapon.Deploy();
    }

    void PinThink()
    {
        CBasePlayer@ pVictim = cast<CBasePlayer@>( m_hVictim.GetEntity() );

        if( !m_bIsPinning or pVictim is null or !pVictim.IsAlive() )
        {
            StopPin();
            return;
        }

        if( g_Engine.time >= m_flPinEndTime )
        {
            StopPin();
            return;
        }

        if( HandleStruggling(pVictim) )
        {
            StopPin();
            return;
        }

        if( g_Engine.time >= m_flPinThinkRate )
        {
            DisablePlayerWeapons( pVictim );

            if( g_Engine.time >= m_flNextThrashDamage )
            {
                pVictim.TakeDamage( self.pev, self.pev, gpPanthereyeConfig.DamageThrash, DMG_SLASH );

                Vector vecBlood;
                    vecBlood.x = pVictim.pev.absmin.x + pVictim.pev.size.x * ( Math.RandomFloat(0 , 1) );
                    vecBlood.y = pVictim.pev.absmin.y + pVictim.pev.size.y * ( Math.RandomFloat(0 , 1) );
                    vecBlood.z = pVictim.pev.absmin.z + pVictim.pev.size.z * ( Math.RandomFloat(0 , 1) ) + 1;
                    vecBlood.z -= 32.0;
                g_WeaponFuncs.SpawnBlood( vecBlood, pVictim.BloodColor(), gpPanthereyeConfig.DamageThrash*6.9 );

                m_flNextThrashDamage = g_Engine.time + gpPanthereyeConfig.DamageThrashFrequency;
            }

            if( g_Engine.time >= m_flNextThrashSound )
            {
                ThrashSound();
                m_flNextThrashSound = g_Engine.time + 1.0;
            }

            Vector vecOrigin = pVictim.pev.origin;
            vecOrigin.z = pVictim.pev.absmin.z;
            self.SetOrigin( vecOrigin );
            self.StudioFrameAdvance( 0.1 );

            m_flPinThinkRate = g_Engine.time + 0.1;
        }

        pev.nextthink = g_Engine.time + 0.01;
    }

    bool HandleStruggling( CBasePlayer@ pPlayer )
    {
        float dt = 0.01; //match think rate

        m_flStruggle -= gpPanthereyeConfig.StruggleDrainRate * dt;

        if( btscm::HasFlags(pPlayer.m_afButtonPressed, IN_FORWARD) ) m_flStruggle += gpPanthereyeConfig.StruggleGrin;
        if( btscm::HasFlags(pPlayer.m_afButtonPressed, IN_BACK) ) m_flStruggle += gpPanthereyeConfig.StruggleGrin;
        if( btscm::HasFlags(pPlayer.m_afButtonPressed, IN_MOVELEFT) ) m_flStruggle += gpPanthereyeConfig.StruggleGrin;
        if( btscm::HasFlags(pPlayer.m_afButtonPressed, IN_MOVERIGHT) ) m_flStruggle += gpPanthereyeConfig.StruggleGrin;

        if( m_flStruggle < 0 ) m_flStruggle = 0;
        if( m_flStruggle > gpPanthereyeConfig.StruggleMax ) m_flStruggle = gpPanthereyeConfig.StruggleMax;

        ShowStruggleBar( pPlayer );

        if( m_flStruggle >= gpPanthereyeConfig.StruggleMax )
        {
            StopPin();
            return true;
        }

        return false;
    }

    //Thanks ChatGPT
    void ShowStruggleBar( CBasePlayer@ pPlayer )
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
        g_PlayerFuncs.HudMessage( pPlayer, hudTextParams, "STRUGGLE: [" + bar + "]" );
    }

    void StopPin()
    {
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( m_hVictim.GetEntity() );

        if( pPlayer !is null )
        {
            pPlayer.SetViewMode( ViewMode_FirstPerson );
            //pPlayer.EnableControl( true );
            pPlayer.SetMaxSpeedOverride( -1 );
            pPlayer.pev.iuser3 = 0; //enable ducking
            pPlayer.pev.fuser4 = 0; //enable jumping
            pPlayer.pev.effects &= ~EF_NODRAW;
            pPlayer.pev.movetype = MOVETYPE_WALK;

            EnablePlayerWeapons( pPlayer );
        }

        if( m_hFakeBody.IsValid() )
            g_EntityFuncs.Remove( m_hFakeBody.GetEntity() );

        m_bIsPinning = false;
        m_hVictim = null; //EHandle();
        m_hFakeBody = null;

        SetThink( null );
        pev.nextthink = g_Engine.time;
    }

    float GetPointsForDamage( float flDamage )
    {
        float flTemp = pev.max_health / gpPanthereyeConfig.Health;
        return flDamage / pev.max_health * (flTemp + flTemp);
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


g_PlayerFuncs.ScreenShake(pPlayer.pev.origin, 4.0f, 2.0f, 0.1f, 200.0f);

g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_BODY, "player/pain2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
*/