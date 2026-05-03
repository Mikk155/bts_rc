/**   MIT License
*   
*   Copyright (c) 2025 Mikk155 https://github.com/Mikk155/bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies or substantial portions of the Software.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*   SOFTWARE.
*/

/*
    Author: Nero

    From Half-Life headcrab.cpp
*/

namespace monster_parasite
{

const float NPC_HEALTH                  = 20.0;
const float DAMAGE_BITE             = 10.0;

const string MODEL_NPC              = "models/bts_rc/monsters/parasite.mdl";
const string NPC_DISPLAYNAME        = "Parasite";


const int AE_JUMPATTACK             = 2;

const float NPC_IGNORE_WORLD_COLLISION_TIME = 0.5;

array<ScriptSchedule@>@ custom_parasite_schedules;

const array<string> pIdleSounds = 
{
    "headcrab/hc_idle1.wav",
    "headcrab/hc_idle2.wav",
    "headcrab/hc_idle3.wav"
};

const array<string> pAlertSounds = 
{
    "headcrab/hc_alert1.wav"
};

const array<string> pPainSounds = 
{
    "headcrab/hc_pain1.wav",
    "headcrab/hc_pain2.wav",
    "headcrab/hc_pain3.wav"
};

const array<string> pAttackSounds = 
{
    "headcrab/hc_attack1.wav",
    "headcrab/hc_attack2.wav",
    "headcrab/hc_attack3.wav"
};

const array<string> pDeathSounds = 
{
    "headcrab/hc_die1.wav",
    "headcrab/hc_die2.wav"
};

const array<string> pBiteSounds = 
{
    "headcrab/hc_headbite.wav"
};

class monster_parasite : bts_rc_base_monster
{
    protected float m_flIgnoreWorldCollisionTime;

    monster_parasite()
    {
        @this.m_Schedules = @custom_parasite_schedules;
    }

    void Spawn()
    {
        Precache();

        g_EntityFuncs.SetModel( self, MODEL_NPC );
        g_EntityFuncs.SetSize( self.pev, Vector(-12, -12, 0), Vector(12, 12, 24) );

        pev.solid                   = SOLID_SLIDEBOX;
        pev.movetype            = MOVETYPE_STEP;
        self.m_bloodColor       = BLOOD_COLOR_GREEN;

        if( pev.health <= 0 )
            pev.health              = NPC_HEALTH;

        self.m_flFieldOfView    = 0.5;
        self.m_MonsterState = MONSTERSTATE_NONE;

        if( string(self.m_FormattedName).IsEmpty() )
            self.m_FormattedName    = NPC_DISPLAYNAME;

        self.MonsterInit();
    }

    void Precache()
    {
        uint i;

        for( i = 0; i < pIdleSounds.length(); i++ )
            g_SoundSystem.PrecacheSound( pIdleSounds[i] );

        for( i = 0; i < pAlertSounds.length(); i++ )
            g_SoundSystem.PrecacheSound( pAlertSounds[i] );
            
        for( i = 0; i < pPainSounds.length(); i++ )
            g_SoundSystem.PrecacheSound( pPainSounds[i] );
            
        for( i = 0; i < pAttackSounds.length(); i++ )
            g_SoundSystem.PrecacheSound( pAttackSounds[i] );
            
        for( i = 0; i < pDeathSounds.length(); i++ )
            g_SoundSystem.PrecacheSound( pDeathSounds[i] );
            
        for( i = 0; i < pBiteSounds.length(); i++ )
            g_SoundSystem.PrecacheSound( pBiteSounds[i] );
            
        g_Game.PrecacheModel( MODEL_NPC );
    }

    void SetYawSpeed()
    {
        int ys = 120;

        /*switch( self.m_Activity )
        {
            case ACT_IDLE:          
                ys = 30;
                break;
            case ACT_RUN:           
            case ACT_WALK:          
                ys = 20;
                break;
            case ACT_TURN_LEFT:
            case ACT_TURN_RIGHT:
                ys = 60;
                break;
            case ACT_RANGE_ATTACK1: 
                ys = 30;
                break;
            default:
                ys = 30;
                break;
        }*/

        pev.yaw_speed = ys;
    }

    void RunTask( Task@ pTask )
    {
        switch( pTask.iTask )
        {
            case TASK_RANGE_ATTACK1:
            case TASK_RANGE_ATTACK2:
            {
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

    void StartTask( Task@ pTask )
    {
        self.m_iTaskStatus = 1; //TASKSTATUS_RUNNING

        switch( pTask.iTask )
        {
            case TASK_RANGE_ATTACK1:
            {
                g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, pAttackSounds[0], VOL_NORM, ATTN_IDLE, 0, PITCH_NORM );
                self.m_IdealActivity = ACT_RANGE_ATTACK1;
                SetTouch( TouchFunction(this.LeapTouch) );
                m_flIgnoreWorldCollisionTime = g_Engine.time + NPC_IGNORE_WORLD_COLLISION_TIME;
                break;
            }

            default: BaseClass.StartTask( pTask ); break;
        }
    }

    void LeapTouch( CBaseEntity@ pOther )
    {
        if( self.IRelationship(pOther) > R_NO )
        {
            // Don't hit if back on ground
            if( !pev.FlagBitSet(FL_ONGROUND) )
            {
                if( pOther.pev.takedamage != DAMAGE_NO )
                {
                    BiteSound();
                    TouchDamage( pOther );
                }
            }
        }
        else if( !pev.FlagBitSet(FL_ONGROUND) )
        {
            // Still in the air...
            if( pOther.pev.solid <= SOLID_TRIGGER ) //!pOther.IsSolid()
            {
                // Touching a trigger or something.
                return;
            }

            if( g_Engine.time < m_flIgnoreWorldCollisionTime )
            {
                // Headcrabs try to ignore the world, static props, and friends for a 
                // fraction of a second after they jump. This is because they often brush
                // doorframes or props as they leap, and touching those objects turns off
                // this touch function, which can cause them to hit the player and not bite.
                // A timer probably isn't the best way to fix this, but it's one of our 
                // safer options at this point (sjb).
                return;
            }
        }

        SetTouch( null );
    }

    void TouchDamage( CBaseEntity@ pOther )
    {
        if( pOther.pev.health > 1 )
        {
            float flDamage;
            if( DAMAGE_BITE >= pOther.pev.health )
                flDamage = pOther.pev.health - 1;

            pOther.TakeDamage( self.pev, self.pev, flDamage, DMG_SLASH );

            if( pOther.IsAlive() and pOther.pev.health > 1 )
            {
                if( pOther.IsPlayer() )
                {
                    // That didn't finish them. Take them down to one point with drown damage. It'll heal.
                    CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );
                    float flDamage = pPlayer.pev.health - 1;
                    pPlayer.TakeDamage( self.pev, self.pev, flDamage, DMG_DROWN );
                    pPlayer.m_iDrownDmg = flDamage;
                    pPlayer.m_iDrownRestored = 0;
                }
                else
                {
                    // Just take some amount of slash damage instead
                    pOther.TakeDamage( self.pev, self.pev, DAMAGE_BITE, DMG_SLASH );
                }
            }
        }
    }

    //=========================================================
    // Center - returns the real center of the headcrab.  The 
    // bounding box is much larger than the actual creature so 
    // this is needed for targeting
    //=========================================================
    Vector Center()
    {
        return Vector( pev.origin.x, pev.origin.y, pev.origin.z + 6 );
    }

    Vector BodyTarget( const Vector& in posSrc ) 
    { 
        return Center();
    }

    void PainSound()
    {
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, pPainSounds[Math.RandomLong(0,(pPainSounds.length() - 1))], VOL_NORM, ATTN_IDLE, 0, PITCH_NORM );
    }

    void DeathSound()
    {
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, pDeathSounds[Math.RandomLong(0,(pDeathSounds.length() - 1))], VOL_NORM, ATTN_IDLE, 0, PITCH_NORM );
    }

    void IdleSound()
    {
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, pIdleSounds[Math.RandomLong(0,(pIdleSounds.length() - 1))], VOL_NORM, ATTN_IDLE, 0, PITCH_NORM );
    }

    void AlertSound()
    {
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, pAlertSounds[Math.RandomLong(0,(pAlertSounds.length() - 1))], VOL_NORM, ATTN_IDLE, 0, PITCH_NORM );
    }

    void BiteSound()
    {
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, pBiteSounds[Math.RandomLong(0,(pBiteSounds.length() - 1))], VOL_NORM, ATTN_IDLE, 0, PITCH_NORM );
    }

    void PrescheduleThink()
    {
        // make the crab coo a little bit in combat state
        if( self.m_MonsterState == MONSTERSTATE_COMBAT and Math.RandomFloat(0,5) < 0.1 )
            IdleSound();
    }

    int Classify()
    {
        return  CLASS_ALIEN_PREY;
    }

    void RunAI()
    {
        BaseClass.RunAI();

        //WHY ISN'T THIS BEING RUN IN THE BASECLASS ?!
        if( (self.m_MonsterState == MONSTERSTATE_IDLE or self.m_MonsterState == MONSTERSTATE_ALERT) and Math.RandomLong(0, 99) == 0 and !btscm::HasFlags(pev.flags, 2) ) //SF_MONSTER_GAG
            IdleSound();
    }

    void HandleAnimEvent( MonsterEvent@ pEvent )
    {
        switch( pEvent.event )
        {
            case AE_JUMPATTACK:
            {
                //ClearBits( pev.flags, FL_ONGROUND );//#define ClearBits(flBitVector, bits)    ((flBitVector) = (int)(flBitVector) & ~(bits)) //??
                pev.flags &= ~FL_ONGROUND;

                g_EntityFuncs.SetOrigin( self, pev.origin + Vector(0.0, 0.0, 1.0) );// take him off ground so engine doesn't instantly reset onground 
                Math.MakeVectors( pev.angles );

                Vector vecJumpDir;
                if( self.m_hEnemy.GetEntity() !is null )
                {
                    float gravity = g_EngineFuncs.CVarGetFloat( "sv_gravity" );
                    if( gravity <= 1 )
                        gravity = 1;

                    // How fast does the headcrab need to travel to reach that height given gravity?
                    float height = ( self.m_hEnemy.GetEntity().pev.origin.z + self.m_hEnemy.GetEntity().pev.view_ofs.z - pev.origin.z );
                    if( height < 16 )
                        height = 16;

                    float speed = sqrt( 2 * gravity * height );
                    float time = speed / gravity;

                    // Scale the sideways velocity to get there at the right time
                    vecJumpDir = ( self.m_hEnemy.GetEntity().pev.origin + self.m_hEnemy.GetEntity().pev.view_ofs - pev.origin );
                    vecJumpDir = vecJumpDir * ( 1.0 / time );

                    // Speed to offset gravity at the desired height
                    vecJumpDir.z = speed;

                    // Don't jump too far/fast
                    float distance = vecJumpDir.Length();
                    
                    if( distance > 650 )
                    {
                        vecJumpDir = vecJumpDir * ( 650.0 / distance );
                    }
                }
                else
                {
                    // jump hop, don't care where
                    vecJumpDir = Vector( g_Engine.v_forward.x, g_Engine.v_forward.y, g_Engine.v_up.z ) * 350;
                }

                int iSound = Math.RandomLong(0,2);
                if( iSound != 0 )
                    g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, pAttackSounds[iSound], VOL_NORM, ATTN_IDLE, 0, PITCH_NORM );

                pev.velocity = vecJumpDir;
                self.m_flNextAttack = g_Engine.time + 2;
            }
            break;

            default: BaseClass.HandleAnimEvent( pEvent ); break;
        }
    }

    bool CheckRangeAttack1( float flDot, float flDist )
    {
        if( pev.FlagBitSet(FL_ONGROUND) and flDist <= 256 and flDot >= 0.65 )
            return true;

        return false;
    }

    int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
    {
        if( btscm::HasFlags(bitsDamageType, DMG_POISON) )
        {
            flDamage = 0;
            return 0;
        }

        if( flDamage > 0.0 )
            pevAttacker.frags += GetPointsForDamage( flDamage );

        return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
    }

    Schedule@ GetScheduleOfType( int Type )
    {
        switch( Type )
        {
            case SCHED_RANGE_ATTACK1: return slHCRangeAttack1;
        }

        return BaseClass.GetScheduleOfType( Type );
    }

    float GetPointsForDamage( float flDamage )
    {
        return flDamage / pev.max_health * (pev.max_health / NPC_HEALTH );
    }
}

ScriptSchedule slHCRangeAttack1
(
    bits_COND_ENEMY_OCCLUDED |
    bits_COND_NO_AMMO_LOADED,
    0,
    "HCRangeAttack1"
);
    
ScriptSchedule slHCRangeAttack1Fast
(
    bits_COND_ENEMY_OCCLUDED |
    bits_COND_NO_AMMO_LOADED,
    0,
    "HCRAFast"
);

void InitSchedules()
{
    slHCRangeAttack1.AddTask( ScriptTask(TASK_STOP_MOVING) );
    slHCRangeAttack1.AddTask( ScriptTask(TASK_FACE_IDEAL) );
    slHCRangeAttack1.AddTask( ScriptTask(TASK_RANGE_ATTACK1) );
    slHCRangeAttack1.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );
    slHCRangeAttack1.AddTask( ScriptTask(TASK_FACE_IDEAL) );
    slHCRangeAttack1.AddTask( ScriptTask(TASK_WAIT_RANDOM, 0.5) );
    
    slHCRangeAttack1Fast.AddTask( ScriptTask(TASK_STOP_MOVING) );
    slHCRangeAttack1Fast.AddTask( ScriptTask(TASK_FACE_IDEAL) );
    slHCRangeAttack1Fast.AddTask( ScriptTask(TASK_RANGE_ATTACK1) );
    slHCRangeAttack1Fast.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );

    array<ScriptSchedule@> scheds = { slHCRangeAttack1, slHCRangeAttack1Fast };

    @custom_parasite_schedules = @scheds;
}

void Register()
{
    InitSchedules();

    g_CustomEntityFuncs.RegisterCustomEntity( "monster_parasite::monster_parasite", "monster_parasite" );
    g_Game.PrecacheOther( "monster_parasite" );
}

} //namespace monster_parasite END