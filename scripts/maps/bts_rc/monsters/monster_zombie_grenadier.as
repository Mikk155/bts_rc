/*
    Author: Nero
*/

//based on the original Half-Life zombie

namespace monster_zombie_grenadier
{

const string NPC_MODEL                  = "models/bts_rc/monsters/zombie_soldier3.mdl";

const int HITGROUP_GRENADE          = 10;
const float GRENADE_TIMER               = 6.0;
const float GRENADE_DAMAGE          = 125.0;
const int GRENADE_TRIGGER               = 80; //pull out the grenade when at or below this health percentage, 1-100
const float GRENADE_DROP_MAXTIME    = 0.1; //maximum amount of time before a dropped grenade explodes

const int NPC_AE_ATTACK_RIGHT       = 1;
const int NPC_AE_ATTACK_LEFT            = 2;
const int NPC_AE_GRENADE_PULL       = 11;

const int NPC_FLINCH_DELAY          = 2; // at most one flinch every n secs
const int NPC_HEALTH                        = 120;
const int NPC_DMG_ONE_SLASH         = 25;

const array<string> arrsSounds = 
{
    "zombie/claw_strike1.wav",
    "zombie/claw_strike2.wav",
    "zombie/claw_strike3.wav",
    "zombie/claw_miss1.wav",
    "zombie/claw_miss2.wav",
    "zombie/zo_attack1.wav",
    "zombie/zo_attack2.wav",
    "zombie/zo_idle1.wav",
    "zombie/zo_idle2.wav",
    "zombie/zo_idle3.wav",
    "zombie/zo_idle4.wav",
    "zombie/zo_alert10.wav",
    "zombie/zo_alert20.wav",
    "zombie/zo_alert30.wav",
    "zombie/zo_pain1.wav",
    "zombie/zo_pain2.wav",
    "bullchicken/bc_bite1.wav",
    "bullchicken/bc_bite2.wav",
    "bullchicken/bc_bite3.wav"
};

enum sound_e
{
    SND_ATTACK_HIT1 = 0,
    SND_ATTACK_HIT2,
    SND_ATTACK_HIT3,
    SND_ATTACK_MISS1,
    SND_ATTACK_MISS2,
    SND_ATTACK1,
    SND_ATTACK2,
    SND_IDLE1,
    SND_IDLE2,
    SND_IDLE3,
    SND_IDLE4,
    SND_ALERT1,
    SND_ALERT2,
    SND_ALERT3,
    SND_PAIN1,
    SND_PAIN2,
    SND_GRENPULL1,
    SND_GRENPULL2,
    SND_GRENPULL3
};

class monster_zombie_grenadier : bts_rc_base_monster
{
    private float m_flNextFlinch;
    private bool m_bHasGrenade = true;
    private bool m_bGrenadeOut;
    private bool m_bGrenadeHalftime;
    private float m_flGrenadeTimer;

    void Spawn()
    {
        Precache();

        g_EntityFuncs.SetModel( self, NPC_MODEL );

        g_EntityFuncs.SetSize( self.pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX );

        pev.solid                   = SOLID_SLIDEBOX;
        pev.movetype            = MOVETYPE_STEP;
        self.m_bloodColor       = BLOOD_COLOR_RED;

        if( pev.health <= 0 )
            pev.health                  = NPC_HEALTH;

        pev.view_ofs                = VEC_VIEW;
        self.m_flFieldOfView    = 0.5;
        self.m_MonsterState = MONSTERSTATE_NONE;
        self.m_afCapability     = bits_CAP_DOORS_GROUP;
        g_EntityFuncs.DispatchKeyValue( self.edict(), "displayname", "Zombie Soldier" );

        self.MonsterInit();
    }

    void Precache()
    {
        g_Game.PrecacheModel( NPC_MODEL );

        for( uint i = 0; i < arrsSounds.length(); i++ )
            g_SoundSystem.PrecacheSound( arrsSounds[i] );
    }

    void PainSound()
    {
        int pitch = 95 + Math.RandomLong(0,9);

        if( Math.RandomLong(0,5) < 2 )
            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_PAIN1, SND_PAIN2)], VOL_NORM, ATTN_NORM, 0, pitch );
    }

    void AlertSound()
    {
        int pitch = 95 + Math.RandomLong(0,9);

        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_ALERT1, SND_ALERT3)], VOL_NORM, ATTN_NORM, 0, pitch );
    }

    void IdleSound()
    {
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_IDLE1, SND_IDLE4)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
    }

    void AttackSound()
    {
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_ATTACK1, SND_ATTACK2)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
    }

    void SetYawSpeed()
    {
        int ys = 120;
        pev.yaw_speed = ys;
    }

    int Classify()
    {
        if( self.IsPlayerAlly() ) 
            return CLASS_PLAYER_ALLY;

        return CLASS_ALIEN_MONSTER;
    }

    int IgnoreConditions()
    {
        int iIgnore = BaseIgnoreConditions();

        if( (self.m_Activity == ACT_MELEE_ATTACK1) or (self.m_Activity == ACT_MELEE_ATTACK1) )
        {
            if( m_flNextFlinch >= g_Engine.time )
                iIgnore |= (bits_COND_LIGHT_DAMAGE|bits_COND_HEAVY_DAMAGE);
        }

        if( (self.m_Activity == ACT_SMALL_FLINCH) or (self.m_Activity == ACT_BIG_FLINCH) )
        {
            if( m_flNextFlinch < g_Engine.time )
                m_flNextFlinch = g_Engine.time + NPC_FLINCH_DELAY;
        }

        //don't run away at low health
        if( self.m_Activity == ACT_RANGE_ATTACK1 or self.m_Activity == ACT_RUN )
            iIgnore |= bits_COND_SEE_FEAR | bits_COND_LIGHT_DAMAGE | bits_COND_HEAVY_DAMAGE;

        return iIgnore;
        
    }

    int BaseIgnoreConditions()
    {
        int iIgnoreConditions = 0;

        if( !self.FShouldEat() )
        {
            // not hungry? Ignore food smell.
            iIgnoreConditions |= bits_COND_SMELL_FOOD;
        }

        if( self.m_MonsterState == MONSTERSTATE_SCRIPT and self.m_hCine.GetEntity() !is null )
        {
            CCineMonster@ pCine = cast<CCineMonster@>( self.m_hCine.GetEntity() );
            if( pCine !is null )
                iIgnoreConditions |= pCine.IgnoreConditions();
        }

        return iIgnoreConditions;
    }

    void RunAI()
    {
        BaseClass.RunAI();

        if( !m_bGrenadeHalftime and m_flGrenadeTimer > 0 and g_Engine.time > (m_flGrenadeTimer - (GRENADE_TIMER * 0.5)) )
            m_bGrenadeHalftime = true;
        else if( m_bGrenadeOut and m_flGrenadeTimer > 0 and g_Engine.time > m_flGrenadeTimer )
            DropOrExplode( g_vecZero );
    }

    void HandleAnimEvent( MonsterEvent@ pEvent )
    {
        switch( pEvent.event )
        {
            case NPC_AE_ATTACK_RIGHT:
            {
                CBaseEntity@ pHurt = CheckTraceHullAttack( self, 70, NPC_DMG_ONE_SLASH, DMG_SLASH );
                if( pHurt !is null )
                {
                    if( (pHurt.pev.flags & (FL_MONSTER|FL_CLIENT)) == 1 )
                    {
                        pHurt.pev.punchangle.z = -18;
                        pHurt.pev.punchangle.x = 5;
                        pHurt.pev.velocity = pHurt.pev.velocity - g_Engine.v_right * 100;
                    }

                    g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsSounds[Math.RandomLong(SND_ATTACK_HIT1, SND_ATTACK_HIT3)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
                }
                else
                    g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsSounds[Math.RandomLong(SND_ATTACK_MISS1, SND_ATTACK_MISS2)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );

                if( Math.RandomLong(0,1) == 1 )
                    AttackSound();

                break;
            }

            case NPC_AE_ATTACK_LEFT:
            {
                CBaseEntity@ pHurt = CheckTraceHullAttack( self, 70, NPC_DMG_ONE_SLASH, DMG_SLASH );
                if( pHurt !is null )
                {
                    if( (pHurt.pev.flags & (FL_MONSTER|FL_CLIENT)) == 1 )
                    {
                        pHurt.pev.punchangle.z = 18;
                        pHurt.pev.punchangle.x = 5;
                        pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_right * 100;
                    }

                    g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsSounds[Math.RandomLong(SND_ATTACK_HIT1, SND_ATTACK_HIT3)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
                }
                else
                    g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsSounds[Math.RandomLong(SND_ATTACK_MISS1, SND_ATTACK_MISS2)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );

                if( Math.RandomLong(0,1) == 1 )
                    AttackSound();

                break;
            }

            case NPC_AE_GRENADE_PULL:
            {
                Vector vecGutsPos;
                g_EngineFuncs.GetBonePosition( self.edict(), 17, vecGutsPos, void ); //using the hand bone

                Math.MakeVectors( pev.angles );
                Vector vecDir = g_Engine.v_forward;
                vecDir = vecDir + Vector( Math.RandomFloat(-0.05, 0.05), Math.RandomFloat(-0.05, 0.05), Math.RandomFloat(-0.05, 0) );

                g_Utility.BloodDrips( vecGutsPos, vecDir, self.BloodColor(), 42 );

                g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, arrsSounds[Math.RandomLong(SND_GRENPULL1, SND_GRENPULL3)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );             

                break;
            }

            default:
            {
                BaseClass.HandleAnimEvent( pEvent );
                break;
            }
        }
    }

    int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
    {
        //take no damage when pulling out a grenade
        if( self.m_Activity == ACT_RANGE_ATTACK1 )
            return 0;

        // Take 30% damage from bullets
        if( bitsDamageType == DMG_BULLET )
        {
            Vector vecDir = pev.origin - (pevInflictor.absmin + pevInflictor.absmax) * 0.5;
            vecDir = vecDir.Normalize();
            float flForce = self.DamageForce( flDamage );
            pev.velocity = pev.velocity + vecDir * flForce;
            flDamage *= 0.3;
        }

        if( m_bGrenadeOut and self.m_LastHitGroup == HITGROUP_GRENADE )
        {
            DropOrExplode( pevInflictor.origin );
            self.ChangeSchedule( self.GetScheduleOfType(SCHED_ARM_WEAPON) );

            flDamage *= 0.1;
        }

        //pevAttacker.frags += self.GetPointsForDamage( flDamage ); //broken :aRage:
        pevAttacker.frags += ( flDamage/40 );

        if( self.IsAlive() )
            PainSound();

        return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
    }

    void Killed( entvars_t@ pevAttacker, int iGib )
    {
        if( m_bGrenadeOut )
            DropOrExplode( g_vecZero );

        BaseClass.Killed( pevAttacker, iGib );
    }

    void DropOrExplode( Vector vecAttacker )
    {
        //g_Game.AlertMessage( at_notice, "DropOrExplode: %1\n", vecAttacker.ToString() );
        Vector vecOrigin;
        g_EngineFuncs.GetBonePosition( self.edict(), 17, vecOrigin, void ); //using the hand bone

        if( !m_bGrenadeHalftime )
            DropGrenade( vecAttacker );
        else
            ExplodeGrenade( vecOrigin );

        m_flGrenadeTimer = 0;
    }

    void DropGrenade( Vector vecAttacker )
    {
        m_bGrenadeOut = m_bHasGrenade = false;

        Vector vecOrigin;
        g_EngineFuncs.GetBonePosition( self.edict(), 17, vecOrigin, void ); //using the hand bone

        Vector vecVelocity = vecAttacker != g_vecZero ? (vecOrigin - vecAttacker).Normalize() * 240 : g_vecZero;
        g_EntityFuncs.ShootTimed( self.pev, vecOrigin, vecVelocity, Math.clamp(0.0, GRENADE_DROP_MAXTIME, (m_flGrenadeTimer - g_Engine.time)) );
    }

    void ExplodeGrenade( Vector vecOrigin )
    {
        m_bGrenadeOut = m_bHasGrenade = false;

        btscm::SpawnExplosion( vecOrigin, 0.0, 0.0, GRENADE_DAMAGE );
        self.Killed( self.pev, GIB_ALWAYS );
    }

    void StartTask( Task@ pTask )
    {
        switch( pTask.iTask )
        {
            case TASK_RUN_PATH:
            {
                if( m_bGrenadeOut )
                    self.m_movementActivity = ACT_RUN;
                else
                    self.m_movementActivity = ACT_WALK;

                self.TaskComplete();
                break;
            }

            default:
            {           
                BaseClass.StartTask( pTask );
                break;
            }
        }
    }

    //when in melee range; drop grenade if the halfway point hasn't been reached and resume normal zombie behaviour, explode otherwise
    bool CheckMeleeAttack1( float flDot, float flDist )
    {
        bool bCheckMeleeAttack1 = BaseClass.CheckMeleeAttack1( flDot, flDist );

        if( m_bGrenadeOut and self.m_Activity == ACT_RUN and bCheckMeleeAttack1 )
            DropOrExplode( g_vecZero );

        if( m_bGrenadeOut or self.m_Activity == ACT_RANGE_ATTACK1 )
            return false;

        return bCheckMeleeAttack1;
    }

    bool CheckRangeAttack1( float flDot, float flDist )
    {
        if( m_bHasGrenade and !m_bGrenadeOut and pev.health <= (pev.max_health * btscm::ptof(GRENADE_TRIGGER)) and self.m_Activity != ACT_RUN )
        {
            m_bGrenadeOut = true;
            self.ChangeSchedule( self.GetScheduleOfType(SCHED_RANGE_ATTACK1) ); //this shouldn't be needed but for some reason it is, blyat
            AttackSound();

            m_flGrenadeTimer = g_Engine.time + GRENADE_TIMER;

            return true;
        }

        return false;
    }

    CBaseEntity@ CheckTraceHullAttack( CBaseMonster@ pThis, float flDist, int iDamage, int iDmgType )
    {
        TraceResult tr;

        if( pThis.IsPlayer() )
            Math.MakeVectors( pThis.pev.angles );
        else
            Math.MakeAimVectors( pThis.pev.angles );

        Vector vecStart = pev.origin;
        vecStart.z += pev.size.z * 0.5;
        Vector vecEnd = vecStart + (g_Engine.v_forward * flDist );

        g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, pThis.edict(), tr );

        if( tr.pHit !is null )
        {
            CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

            if( iDamage > 0 )
                pEntity.TakeDamage( pThis.pev, pThis.pev, iDamage, iDmgType );

            return pEntity;
        }

        return null;
    }
}

void Register()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "monster_zombie_grenadier::monster_zombie_grenadier", "monster_zombie_grenadier" );
    g_Game.PrecacheOther( "monster_zombie_grenadier" );
}

} //end of namespace monster_zombie_grenadier