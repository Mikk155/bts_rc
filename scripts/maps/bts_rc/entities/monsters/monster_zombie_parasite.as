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

    From Half-Life zombie.cpp and Half-Life 2 npc_BaseZombie.cpp
*/

namespace monster_zombie_parasite
{

//SETTINGS
const string NPC_DISPLAYNAME            = "Parasite Zombie";

const float NPC_FLINCH_DELAY            = 3.0; // at most one flinch every n secs
const float NPC_HEALTH                  = 120;
const float NPC_DMG_ONE_SLASH       = 20;
const float NPC_DMG_BOTH_SLASH  = 30;

const float POISON_FREQUENCY            = 0.3;
const float POISON_DURATION         = 6.0;
const float POISON_DAMAGE_START = 15; //decreases over time
const float POISON_DAMAGE_RADIUS    = 64;

const string MODEL_NPC                  = "models/bts_rc/monsters/zombie_parasite.mdl";
const string SPRITE_POISON              = "sprites/poison.spr"; //"sprites/particles/blacksmoke.spr"


const int NPC_AE_ATTACK_RIGHT       = 1;
const int NPC_AE_ATTACK_LEFT            = 2;
const int NPC_AE_ATTACK_BOTH            = 3;

enum HeadcrabRelease_t
{
    RELEASE_NO = 0,
    RELEASE_IMMEDIATE,  // release the headcrab right now!
    RELEASE_VAPORIZE,       // just destroy the crab.   
    RELEASE_RAGDOLL     // release a dead crab
};

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
    "zombie/zo_pain2.wav"
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
    SND_PAIN2
};

class monster_zombie_parasite : bts_rc_base_monster
{
    private float m_flNextFlinch;
    private bool m_bCloudDropped;
    private bool m_bHeadShot;
    private bool m_bHeadcrabReleased;

    protected Vector m_vecDamageForce;

    void Spawn()
    {
        Precache();

        if( !self.SetupModel() )
            g_EntityFuncs.SetModel( self, MODEL_NPC );

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

        if( string(self.m_FormattedName).IsEmpty() )
            self.m_FormattedName    = NPC_DISPLAYNAME;

        self.MonsterInit();
    }

    void Precache()
    {
        g_Game.PrecacheModel( MODEL_NPC );
        g_Game.PrecacheModel( SPRITE_POISON );

        for( uint i = 0; i < arrsSounds.length(); i++ )
            g_SoundSystem.PrecacheSound( arrsSounds[i] );
    }

    void SetYawSpeed()
    {
        int ys = 120;
        pev.yaw_speed = ys;
    }

    int Classify()
    {
        return self.GetClassification( CLASS_ALIEN_MONSTER );
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

    void PainSound()
    {
        int pitch = 95 + Math.RandomLong(0, 9);

        if( Math.RandomLong(0,5) < 2 )
            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_PAIN1, SND_PAIN2)], VOL_NORM, ATTN_NORM, 0, pitch );
    }

    void AlertSound()
    {
        int pitch = 95 + Math.RandomLong(0, 9);

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
            case NPC_AE_ATTACK_RIGHT:
            {
                CBaseEntity@ pHurt = CheckTraceHullAttack( 70, NPC_DMG_ONE_SLASH, DMG_POISON );
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
                CBaseEntity@ pHurt = CheckTraceHullAttack( 70, NPC_DMG_ONE_SLASH, DMG_POISON );
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

                if( Math.RandomLong(0, 1) == 1 )
                    AttackSound();

                break;
            }

            case NPC_AE_ATTACK_BOTH:
            {
                CBaseEntity@ pHurt = CheckTraceHullAttack( 70, NPC_DMG_BOTH_SLASH, DMG_POISON );
                if( pHurt !is null )
                {
                    if( btscm::HasFlags(pHurt.pev.flags, FL_MONSTER|FL_CLIENT) )
                    {
                        pHurt.pev.punchangle.x = 5;
                        pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * -100;
                    }

                    g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsSounds[Math.RandomLong(SND_ATTACK_HIT1, SND_ATTACK_HIT3)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
                }
                else
                    g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsSounds[Math.RandomLong(SND_ATTACK_MISS1, SND_ATTACK_MISS2)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );

                if( Math.RandomLong(0, 1) == 1 )
                    AttackSound();
            }

            default:
            {
                BaseClass.HandleAnimEvent( pEvent );
                break;
            }
        }
    }

    CBaseEntity@ CheckTraceHullAttack( float flDist, int iDamage, int iDmgType )
    {
        TraceResult tr;

        Math.MakeAimVectors( pev.angles );

        Vector vecStart = pev.origin;
        vecStart.z += pev.size.z * 0.5;
        Vector vecEnd = vecStart + (g_Engine.v_forward * flDist );

        g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, self.edict(), tr );

        if( tr.pHit !is null )
        {
            CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

            if( iDamage > 0 )
                pEntity.TakeDamage( self.pev, self.pev, iDamage, iDmgType );

            return pEntity;
        }

        return null;
    }

    int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
    {
        if( btscm::HasFlags(bitsDamageType, DMG_POISON) )
        {
            flDamage = 0;
            return 0;
        }

        Vector vecDir = pev.origin - (pevAttacker.absmin + pevAttacker.absmax) * 0.5;
        vecDir = vecDir.Normalize();
        float flForce = self.DamageForce( flDamage );
        m_vecDamageForce = vecDir * flForce;

        if( !m_bHeadShot and btscm::HasFlags(bitsDamageType, DMG_BULLET) and !btscm::HasFlags(bitsDamageType, DMG_SNIPER) and !btscm::IsUsingSniperRifle(g_EntityFuncs.Instance(pevAttacker)) )
            flDamage *= 0.5;

        int tookDamage = BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
        float flDamageThreshold = Math.min( 1, flDamage / pev.max_health );

        HeadcrabRelease_t release = ShouldReleaseHeadcrab( bitsDamageType, flDamageThreshold );

        switch( release )
        {
            case RELEASE_IMMEDIATE:
            {
                Vector vecOrigin = pev.origin;
                vecOrigin.z += pev.size.z;
                ReleaseHeadcrab( vecOrigin, g_vecZero, true, true );
                break;
            }

            case RELEASE_RAGDOLL:
            {
                Vector vecOrigin = pev.origin;
                vecOrigin.z += pev.size.z;
                ReleaseHeadcrab( vecOrigin, GetDamageForce() * 0.25, true, false, true );
                break;
            }

            case RELEASE_VAPORIZE:
            {
                RemoveHead();
                break;
            }
        }

        if( flDamage > 0.0 )
            pevAttacker.frags += GetPointsForDamage( flDamage );

        if( self.IsAlive() )
            PainSound();

        m_bHeadShot = false;

        return tookDamage;
    }

    void TraceAttack( entvars_t@ pevAttacker, float flDamage, const Vector &in vecDir, TraceResult &in ptr, int bitsDamageType ) 
    {
        if( ptr.iHitgroup == HITGROUP_HEAD )
            m_bHeadShot = true;

        BaseClass.TraceAttack( pevAttacker, flDamage, vecDir, ptr, bitsDamageType );
    }

    void Killed( entvars_t@ pevAttacker, int iGib )
    {
        if( !m_bCloudDropped )
        {
            g_EntityFuncs.Create( "zombie_parasite_cloud", pev.origin, g_vecZero, false, null );
            m_bCloudDropped = true;
        }

        BaseClass.Killed( pevAttacker, iGib );
    }

    HeadcrabRelease_t ShouldReleaseHeadcrab( int bitsDamageType, float flDamageThreshold )
    {
        if( pev.deadflag != DEAD_NO ) //if( pev.health <= 0 )
        {
            // If I was killed by a bullet...
            if( btscm::HasFlags(bitsDamageType, DMG_BULLET) )
            {
                if( m_bHeadShot )
                {
                    if( flDamageThreshold > 0.25 )
                    {
                        // Enough force to kill the crab.
                        return RELEASE_RAGDOLL;
                    }
                }
                else
                {
                    // Killed by a shot to body or something. Crab is ok!
                    return RELEASE_IMMEDIATE;
                }
            }

            // If I was killed by an explosion, release the crab.
            if( btscm::HasFlags(bitsDamageType, DMG_BLAST) )
                return RELEASE_RAGDOLL;
        }

        return RELEASE_NO;
    }

    void ReleaseHeadcrab( const Vector &in vecOrigin, const Vector &in vecVelocity, bool fRemoveHead, bool fRagdollBody, bool fRagdollCrab = false )
    {
        if( m_bHeadcrabReleased )
            return;

        m_bHeadcrabReleased = true;

        CBaseEntity@ cbeCrab;
        Vector vecSpot = vecOrigin;

        if( fRagdollCrab )
        {
            @cbeCrab = g_EntityFuncs.Create( GetHeadcrabClassname(), vecSpot, pev.angles, false, self.edict() );

            if( !HeadcrabFits(cbeCrab) )
            {
                g_EntityFuncs.Remove( cbeCrab );
                return;
            }

            g_Utility.BloodStream( cbeCrab.pev.origin, Vector(0, 0, 1), BLOOD_COLOR_YELLOW, 1 );

            for ( int i = 0 ; i < 3 ; i++ )
            {
                Vector vecSpot = cbeCrab.pev.origin;

                vecSpot.x += Math.RandomFloat( -8.0, 8.0 ); 
                vecSpot.y += Math.RandomFloat( -8.0, 8.0 ); 
                vecSpot.z += Math.RandomFloat( -8.0, 8.0 ); 

                g_Utility.BloodDrips( vecSpot, g_vecZero, BLOOD_COLOR_YELLOW, 50 );
            }

            cbeCrab.Killed( self.pev, GIB_NEVER );
            cbeCrab.pev.flags &= ~FL_ONGROUND;
            cbeCrab.pev.movetype = MOVETYPE_TOSS;
            cbeCrab.pev.velocity = vecVelocity;
        }
        else
        {
            @cbeCrab = g_EntityFuncs.Create( GetHeadcrabClassname(), vecSpot, pev.angles, true, self.edict() );

            if( cbeCrab is null )
            {
                g_Game.AlertMessage( at_warning, "**%1: Can't make %2!\n", self.GetClassname(), GetHeadcrabClassname() );
                return;
            }

            // don't pop to floor, fall
            //cbeCrab->AddSpawnFlags( SF_NPC_FALL_TO_GROUND );
            
            // add on the parent flags
            //cbeCrab->AddSpawnFlags( m_spawnflags & ZOMBIE_CRAB_INHERITED_SPAWNFLAGS );
            cbeCrab.pev.spawnflags |= ( pev.spawnflags & 2 ); //SF_MONSTER_GAG
            
            g_EntityFuncs.SetOrigin( cbeCrab, vecSpot );
            g_EntityFuncs.DispatchSpawn( cbeCrab.edict() );

            pev.ideal_yaw = pev.angles.y;

            if( !HeadcrabFits(cbeCrab) )
            {
                g_EntityFuncs.Remove( cbeCrab );
                return;
            }

            CBaseMonster@ pCrab = cbeCrab.MyMonsterPointer();
            if( pCrab is null )
            {
                g_EntityFuncs.Remove( cbeCrab );
                return;
            }

            pCrab.m_Activity = ACT_IDLE;
            pCrab.pev.nextthink = g_Engine.time;
            pCrab.pev.velocity = vecVelocity;

            CBaseEntity@ pEnemy;
            @pEnemy = GetEnemy();

            pCrab.m_flNextAttack = g_Engine.time + 1.0;

            if( pEnemy !is null )
                pCrab.m_hEnemy = EHandle( pEnemy );

            pCrab.pev.rendercolor = Vector( pev.rendercolor.x, pev.rendercolor.y, pev.rendercolor.z );
            pCrab.pev.renderamt = pev.renderamt;
        }

        if( fRemoveHead )
            RemoveHead();
    }

    void RemoveHead()
    {
        pev.body = 1;
    }

    const string GetHeadcrabClassname()
    {
        return "monster_parasite";
    }

    const string GetHeadcrabModel()
    {
        return "models/bts_rc/monsters/parasite.mdl";
    }

    bool HeadcrabFits( CBaseEntity@ pCrab )
    {
        Vector vecSpawnLoc = pCrab.pev.origin; //GetAbsOrigin()

        TraceResult tr;
        //g_Utility.TraceHull( vecSpawnLoc, vecSpawnLoc - Vector(0, 0, 1), dont_ignore_monsters, head_hull, self.edict(), tr );
        g_Utility.TraceMonsterHull( pCrab.edict(), vecSpawnLoc, vecSpawnLoc + Vector(0, 0, 1), dont_ignore_monsters, self.edict(), tr ); 

        if( tr.flFraction != 1.0 )
            return false;

        return true;
    }

    Vector GetDamageForce()
    {
        //g_Game.AlertMessage( at_notice, "GetDamageForce(): %1\n", m_vecDamageForce.ToString() );
        return m_vecDamageForce;
    }

    float GetPointsForDamage( float flDamage )
    {
        float flTemp = pev.max_health / NPC_HEALTH;
        return flDamage / pev.max_health * (flTemp + flTemp);
    }
}

class CParasiteZombieCloud : ScriptBaseEntity
{
    private float m_flRemoveTime;
    private float m_flPoisonDamage = POISON_DAMAGE_START;
    private int m_iPoisonCloudCount = 8;
    private int m_iPoisonCloudRadius = 16;
    private int m_iPoisonCloudDuration = 64;

    bool KeyValue( const string& in szKey, const string& in szValue )
    {
        if( szKey == "count" )
        {
            m_iPoisonCloudCount = atoi( szValue );
            return true;
        }
        else if( szKey == "radius" )
        {
            m_iPoisonCloudRadius = atoi( szValue );
            return true;
        }
        else if( szKey == "duration" )
        {
            m_iPoisonCloudDuration = atoi( szValue );
            return true;
        }
        else
            return BaseClass.KeyValue( szKey, szValue );
    }

    void Spawn()
    {
        g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );

        NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
            m1.WriteByte( TE_FIREFIELD );
            m1.WriteCoord( pev.origin.x );
            m1.WriteCoord( pev.origin.y );
            m1.WriteCoord( pev.origin.z );
            m1.WriteShort( m_iPoisonCloudRadius ); //radius (fire is made in a square around origin. -radius, -radius to radius, radius) 
            m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_POISON) );
            m1.WriteByte( m_iPoisonCloudCount ); //count
            m1.WriteByte( TEFIRE_FLAG_ALLFLOAT | TEFIRE_FLAG_ADDITIVE );
            m1.WriteByte( m_iPoisonCloudDuration ); //duration (in seconds) * 10 (will be randomized a bit) 
        m1.End();

        m_flRemoveTime = g_Engine.time + POISON_DURATION;

        SetThink( ThinkFunction(this.EmitPoisonThink) );
        pev.nextthink = g_Engine.time;
    }

    void EmitPoisonThink()
    {
        if( m_flRemoveTime <= g_Engine.time )
        {
            g_EntityFuncs.Remove( self );
            return;
        }

        if( m_flPoisonDamage > 0 ) 
        {
            m_flPoisonDamage -= 0.5;
            g_WeaponFuncs.RadiusDamage( pev.origin, self.pev, self.pev, m_flPoisonDamage, POISON_DAMAGE_RADIUS, CLASS_MACHINE, DMG_POISON | DMG_NEVERGIB );
            //g_Game.AlertMessage( at_notice, "RadiusDamage flDamage: %1, flRadius: %2\n", m_flPoisonDamage, POISON_DAMAGE_RADIUS );
        }

        pev.nextthink = g_Engine.time + 0.3;
    }
}

void Register()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "monster_zombie_parasite::CParasiteZombieCloud", "zombie_parasite_cloud" );
    g_CustomEntityFuncs.RegisterCustomEntity( "monster_zombie_parasite::monster_zombie_parasite", "monster_zombie_parasite" );

    g_Game.PrecacheOther( "monster_zombie_parasite" );
}

} //end of namespace monster_zombie_parasite