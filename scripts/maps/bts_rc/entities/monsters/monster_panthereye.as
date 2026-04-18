/*
    Author: Nero
*/

namespace monster_panthereye
{

// SETTINGS
const string NPC_MODEL                  = "models/bts_rc/monsters/panthereye.mdl";
const int NPC_HEALTH                        = 200;
const float NPC_MAXLEAP_Z               = 256.0; //panther won't pounce at enemies if they're higher up than this from the panther's location
const float NPC_MINLEAP                 = 200.0; //panther won't pounce at enemies within this range
const float NPC_MAXLEAP                 = 400.0; //panther won't pounce at enemies beyond this range

const float NPC_DMG_HIGH_SWIPE  = 25.0;
const float NPC_DMG_LOW_SWIPE       = 15.0;
const float NPC_DMG_LONG_SWIPE  = 25.0;
const float NPC_DMG_LEAP                    = 25.0;

const float NPC_THRASH_DAMAGE       = 10.0;
const float NPC_THRASH_DMG_FREQ = 0.5;
const float NPC_THRASH_SND_FREQ = 1.0;
const float NPC_THRASH_LENGTH       = 5.0;

const float STRUGGLE_MAX                = 100.0;
const float STRUGGLE_DRAINRATE      = 15.0; //per second (~ish)
const float STRUGGLE_GAIN               = 8.0; //per key press

const int NPC_STEALTH_VISIBILITY        = 15; //in percentage 0-100


// OTHER
const int AE_ATTACK_NORMAL          = 1;
const int AE_ATTACK_LOW                 = 2;
const int AE_ATTACK_FAR                 = 3;
const int AE_LEAPATTACK                 = 4;

const array<string> arrsSounds = 
{
    "garg/gar_idle2.wav",
    "bullchicken/bc_idle5.wav",
    "agrunt/ag_idle1.wav",
    "bullchicken/bc_die3.wav",
    "bullchicken/bc_idle3.wav",
    "agrunt/ag_alert3.wav",
    "garg/gar_pain1.wav",
    "zombie/claw_miss1.wav",
    "zombie/claw_miss2.wav",
    "zombie/claw_strike1.wav",
    "zombie/claw_strike2.wav",
    "zombie/claw_strike3.wav",
    "gonome/gonome_jumpattack.wav",
    "bts_rc/panthereye/pounceHit.wav",
    "bts_rc/panthereye/thrash1.wav",
    "bts_rc/panthereye/thrash2.wav",
    "bts_rc/panthereye/thrash3.wav",
    "bts_rc/panthereye/stealth.ogg",
    "garg/gar_pain2.wav",
    "agrunt/ag_attack2.wav",
    "agrunt/ag_pain2.wav",
    "barnacle/bcl_chew2.wav",
    "barnacle/bcl_chew1.wav"
};

enum sound_e
{
    SND_IDLE1 = 0,
    SND_IDLE2,
    SND_IDLE3,
    SND_IDLE4,
    SND_IDLE5,
    SND_ALERT1,
    SND_ALERT2,
    SND_ATTACK_MISS1,
    SND_ATTACK_MISS2,
    SND_ATTACK_HIT1,
    SND_ATTACK_HIT2,
    SND_ATTACK_HIT3,
    SND_ATTACK_LEAP,
    SND_POUNCE_HIT,
    SND_THRASH1,
    SND_THRASH2,
    SND_THRASH3,
    SND_STEALTH,
    SND_PAIN1,
    SND_PAIN2,
    SND_PAIN3,
    SND_DEATH1,
    SND_DEATH2
};

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
        @this.m_Schedules = @custom_panthereye_schedules;
    }

    void Spawn()
    {
        Precache();

        if( !self.SetupModel() )
            g_EntityFuncs.SetModel( self, NPC_MODEL );

        g_EntityFuncs.SetSize( self.pev, Vector(-16.0, -16.0, 0.0), Vector(16.0, 16.0, 32.0) );

        pev.solid                   = SOLID_SLIDEBOX;
        pev.movetype            = MOVETYPE_STEP;
        self.m_bloodColor       = BLOOD_COLOR_YELLOW;

        if( pev.health <= 0 )
            pev.health                  = NPC_HEALTH;

        //pev.view_ofs              = Vector( 0.0, 0.0, 6.0 ); //set ??
        self.m_flFieldOfView    = 0.5;
        self.m_MonsterState = MONSTERSTATE_NONE;
        self.m_afCapability     = bits_CAP_HEAR;

        m_iTargetRanderamt  = 255 * btscm::ptof( NPC_STEALTH_VISIBILITY );

        if( string(self.m_FormattedName).IsEmpty() )
            self.m_FormattedName    = "Panthereye";

        self.MonsterInit();
    }

    void Precache()
    {
        g_Game.PrecacheModel( NPC_MODEL );

        for( uint i = 0; i < arrsSounds.length(); i++ )
            g_SoundSystem.PrecacheSound( arrsSounds[i] );
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
        return self.GetClassification( CLASS_ALIEN_MONSTER );
    }

    void PainSound()
    {
        g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_PAIN1, SND_PAIN3)], VOL_NORM, ATTN_IDLE );
    }

    void DeathSound()
    {
        g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_DEATH1, SND_DEATH2)], VOL_NORM, ATTN_IDLE );
    }

    void IdleSound()
    {
        if( !IsStealthed() )
            g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_IDLE1, SND_IDLE5)], VOL_NORM, ATTN_IDLE );
    }

    void AlertSound()
    {
        if( !IsStealthed() )
            g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_ALERT1, SND_ALERT2)], VOL_NORM, ATTN_IDLE );
    }

    void AttackSound( bool bHit )
    {
        if( bHit )
            g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsSounds[Math.RandomLong(SND_ATTACK_HIT1, SND_ATTACK_HIT3)], VOL_NORM, ATTN_STATIC );
        else if( !bHit )
            g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsSounds[Math.RandomLong(SND_ATTACK_MISS1, SND_ATTACK_MISS2)], VOL_NORM, ATTN_STATIC );
    }

    void LeapAttackSound()
    {
        g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsSounds[SND_ATTACK_LEAP], VOL_NORM, ATTN_IDLE );
    }

    void PounceHitSound()
    {
        g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[SND_POUNCE_HIT], VOL_NORM, ATTN_IDLE );
    }

    void ThrashSound()
    {
        g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsSounds[Math.RandomLong(SND_THRASH1,SND_THRASH3)], VOL_NORM, ATTN_IDLE );
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
            m_iTargetRanderamt = 255 * btscm::ptof( NPC_STEALTH_VISIBILITY );

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
            case AE_ATTACK_NORMAL:
            {
                CBaseEntity@ pHurt = AttackNormal();
                if( pHurt !is null )
                {
                    Math.MakeVectors( pev.angles );
                    pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 100 + g_Engine.v_up * 200;
                    pHurt.TakeDamage( self.pev, self.pev, NPC_DMG_HIGH_SWIPE, DMG_CLUB );
                    AttackSound( true );
                }
                else
                    AttackSound( false );

                break;
            }

            case AE_ATTACK_LOW:
            {
                CBaseEntity@ pHurt = AttackLow();
                if( pHurt !is null )
                {
                    Math.MakeVectors( pev.angles );
                    pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 75 + g_Engine.v_up * 75;
                    pHurt.TakeDamage( self.pev, self.pev, NPC_DMG_LOW_SWIPE, DMG_SLASH );
                    AttackSound( true ) ;
                }
                else
                    AttackSound( false );

                break;
            }

            case AE_ATTACK_FAR:
            {
                CBaseEntity@ pHurt = AttackFar();
                if( pHurt !is null )
                {
                    Math.MakeVectors( pev.angles );
                    pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 100 + g_Engine.v_up * 200;
                    pHurt.TakeDamage( self.pev, self.pev, NPC_DMG_LONG_SWIPE, DMG_CLUB );
                    AttackSound( true );
                }
                else
                    AttackSound( false );

                break;
            }

            case AE_LEAPATTACK:
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
        if( flZDist > NPC_MAXLEAP_Z )
            return false;

        if( flDist > NPC_MAXLEAP )
            return false;;

        if( flDist < NPC_MINLEAP )
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
            case SCHED_RANGE_ATTACK1: return slPERangeAttack1;
        }

        return BaseClass.GetScheduleOfType( iType );
    }

    void LeapAttackTouch( CBaseEntity@ pOther )
    {
        if( pOther.pev.takedamage == 0 )
            return;

        if( pOther.Classify() == Classify() )
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

            pOther.TakeDamage( self.pev, self.pev, NPC_DMG_LEAP, DMG_SLASH );

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
        g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsSounds[SND_STEALTH], VOL_NORM, ATTN_IDLE );
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
        m_flPinEndTime = g_Engine.time + NPC_THRASH_LENGTH;

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
                pVictim.TakeDamage( self.pev, self.pev, NPC_THRASH_DAMAGE, DMG_SLASH );

                Vector vecBlood;
                    vecBlood.x = pVictim.pev.absmin.x + pVictim.pev.size.x * ( Math.RandomFloat(0 , 1) );
                    vecBlood.y = pVictim.pev.absmin.y + pVictim.pev.size.y * ( Math.RandomFloat(0 , 1) );
                    vecBlood.z = pVictim.pev.absmin.z + pVictim.pev.size.z * ( Math.RandomFloat(0 , 1) ) + 1;
                    vecBlood.z -= 32.0;
                g_WeaponFuncs.SpawnBlood( vecBlood, pVictim.BloodColor(), NPC_THRASH_DAMAGE*6.9 );

                m_flNextThrashDamage = g_Engine.time + NPC_THRASH_DMG_FREQ;
            }

            if( g_Engine.time >= m_flNextThrashSound )
            {
                ThrashSound();
                m_flNextThrashSound = g_Engine.time + NPC_THRASH_SND_FREQ;
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

        m_flStruggle -= STRUGGLE_DRAINRATE * dt;

        if( btscm::HasFlags(pPlayer.m_afButtonPressed, IN_FORWARD) ) m_flStruggle += STRUGGLE_GAIN;
        if( btscm::HasFlags(pPlayer.m_afButtonPressed, IN_BACK) ) m_flStruggle += STRUGGLE_GAIN;
        if( btscm::HasFlags(pPlayer.m_afButtonPressed, IN_MOVELEFT) ) m_flStruggle += STRUGGLE_GAIN;
        if( btscm::HasFlags(pPlayer.m_afButtonPressed, IN_MOVERIGHT) ) m_flStruggle += STRUGGLE_GAIN;

        if( m_flStruggle < 0 ) m_flStruggle = 0;
        if( m_flStruggle > STRUGGLE_MAX ) m_flStruggle = STRUGGLE_MAX;

        ShowStruggleBar( pPlayer );

        if( m_flStruggle >= STRUGGLE_MAX )
        {
            StopPin();
            return true;
        }

        return false;
    }

    //Thanks ChatGPT
    void ShowStruggleBar( CBasePlayer@ pPlayer )
    {
        float frac = m_flStruggle / STRUGGLE_MAX;

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
        float flTemp = pev.max_health / NPC_HEALTH;
        return flDamage / pev.max_health * (flTemp + flTemp);
    }

    void UpdateOnRemove()
    {
        StopPin();
        BaseClass.UpdateOnRemove();
    }
}

array<ScriptSchedule@>@ custom_panthereye_schedules;

ScriptSchedule slPERangeAttack1
(
    bits_COND_ENEMY_OCCLUDED |
    bits_COND_NO_AMMO_LOADED,

    0,
    "Panthereye Range Attack1"
);

void InitSnapbugSchedules()
{
    slPERangeAttack1.AddTask( ScriptTask(TASK_STOP_MOVING) );
    slPERangeAttack1.AddTask( ScriptTask(TASK_FACE_IDEAL) );
    slPERangeAttack1.AddTask( ScriptTask(TASK_RANGE_ATTACK1) );
    slPERangeAttack1.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );

    array<ScriptSchedule@> scheds = { slPERangeAttack1 };
    
    @custom_panthereye_schedules = @scheds;
}

void Register()
{
    InitSnapbugSchedules();

    g_CustomEntityFuncs.RegisterCustomEntity( "monster_panthereye::monster_panthereye", "monster_panthereye" );
    g_Game.PrecacheOther( "monster_panthereye" );
}

} //end of namespace monster_panthereye

/* TODO ??
screen shake / fade while pinned
forced view angle (player can’t look around)


g_PlayerFuncs.ScreenShake(pPlayer.pev.origin, 4.0f, 2.0f, 0.1f, 200.0f);

g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_BODY, "player/pain2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
*/