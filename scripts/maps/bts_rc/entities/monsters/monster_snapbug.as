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
*/

// From Half-Life headcrab.cpp

namespace monster_snapbug
{

    // SETTINGS
    const float NPC_HEALTH = 20.0;
    const float DAMAGE_BITE = 10.0;
    const float DAMAGE_POISON = 1.0;      // deal this damage every DAMAGE_TIME seconds
    const float DAMAGE_TIME_NORMAL = 2.0; //
    const float DAMAGE_TIME_FAST = 1.0;   // 100 seconds passed, this is the threshold that wouldve killed them already
    const float DAMAGE_TIME_FASTER = 0.4; // 240 seconds (4 minutes) passed, snapbug really getting hungry there
    const float DAMAGE_TYPE = DMG_POISON; // only using this to cause the poison hud indicator to show up, the player doesn't actually get poisoned

    const array<string> arrsLargerBody =
        {
            "bts_gus",
            "bts_op_gus" };

    // IMMUNE (wearing visible armor or backpack, or a protective suit)
    const array<string> arrsImmune =
        {
            "bts_barney",
            "bts_barney2",
            "bts_cleansuit",
            "bts_construction",
            "bts_construction3",
            "bts_helmet",
            "bts_op",
            "bts_op2",
            "bts_op_back",
            "bts_op_free",
            "bts_op_hgrunt",
            "bts_op_otis",
            "bts_op_otis2",
            "bts_op_vet",
            "bts_otis",
            "bts_otis2",
            "bts_otis_blk",
            "bts_vet" };

    const string NPC_CLASSNAME2 = "snapbug"; // attachment entity
    const string KVN_SNAPBUGGED = "$i_snapbugged";
    const int HUD_SPRITE_SNAPBUG = 1;        // 0-15
    const float HUD_SNAPBUG_X = 0.002;       // on the damagetype icon
    const float HUD_SNAPBUG_Y = 0.88;

    const string NPC_MODEL = "models/bts_rc/monsters/snapbug.mdl";
    const string NPC_MODEL_ATT1 = "models/bts_rc/monsters/snapbugattach.mdl";
    const string SPRITE_SNAPBUG = "bts_rc/bts_rc_snapbug.spr";

    const int AE_JUMPATTACK = 2;
    const int TASKSTATUS_RUNNING = 1;

    const array<string> arrsSounds =
        {
            "bts_rc/snapbug/sb_idle1.wav",
            "bts_rc/snapbug/sb_idle2.wav",
            "bts_rc/snapbug/sb_idle1.wav",
            "bts_rc/snapbug/sb_alert3.wav",
            "bts_rc/snapbug/sb_pain1.wav",
            "bts_rc/snapbug/sb_pain2.wav",
            "bts_rc/snapbug/sb_pain1.wav",
            "bts_rc/snapbug/sb_attack1.wav",
            "bts_rc/snapbug/sb_attack2.wav",
            "bts_rc/snapbug/sb_attack1.wav",
            "bts_rc/snapbug/sb_die1.wav",
            "bts_rc/snapbug/sb_die2.wav",
            "headcrab/hc_headbite.wav" };

    enum sound_e
    {
        SND_IDLE1 = 0,
        SND_IDLE2,
        SND_IDLE3,
        SND_ALERT,
        SND_PAIN1,
        SND_PAIN2,
        SND_PAIN3,
        SND_ATTACK1,
        SND_ATTACK2,
        SND_ATTACK3,
        SND_DEATH1,
        SND_DEATH2,
        SND_BITE
    };

    class monster_snapbug : bts_rc_base_monster
    {
        void Spawn()
        {
            Precache();

            g_EntityFuncs.SetModel( self, NPC_MODEL );
            g_EntityFuncs.SetSize( self.pev, Vector( -12, -12, 0 ), Vector( 12, 12, 24 ) );

            pev.solid = SOLID_SLIDEBOX;
            pev.movetype = MOVETYPE_STEP;
            self.m_bloodColor = BLOOD_COLOR_GREEN;
            pev.effects = 0;

            if( pev.health <= 0 )
                pev.health = NPC_HEALTH;

            pev.view_ofs = Vector( 0, 0, 20 );
            pev.yaw_speed = 5;
            self.m_flFieldOfView = 0.5;
            self.m_MonsterState = MONSTERSTATE_NONE;
            self.m_FormattedName = "Snapbug";

            @ this.m_Schedules = @custom_snapbug_schedules;

            self.MonsterInit();
        }

        void Precache()
        {
            g_Game.PrecacheModel( NPC_MODEL );
            g_Game.PrecacheModel( "sprites/" + SPRITE_SNAPBUG );

            for( uint i = 0; i < arrsSounds.length(); i++ )
                g_SoundSystem.PrecacheSound( arrsSounds[i] );
        }

        void SetYawSpeed()
        {
            int ys = 240;

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

                default:
                    BaseClass.RunTask( pTask );
                    break;
            }
        }

        void StartTask( Task@ pTask )
        {
            self.m_iTaskStatus = TASKSTATUS_RUNNING;

            switch( pTask.iTask )
            {
                case TASK_RANGE_ATTACK1:
                {
                    g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsSounds[SND_ATTACK1], VOL_NORM, ATTN_IDLE );
                    self.m_IdealActivity = ACT_RANGE_ATTACK1;
                    SetTouch( TouchFunction( this.LeapTouch ) );
                    break;
                }

                default:
                    BaseClass.StartTask( pTask );
                    break;
            }
        }

        /*Vector Center()
        {
            return Vector( pev.origin.x, pev.origin.y, pev.origin.z + 6 );
        }

        Vector BodyTarget( const Vector& in posSrc )
        {
            return Center();
        }*/

        int Classify()
        {
            if( self.IsPlayerAlly() )
                return CLASS_PLAYER_ALLY;

            return CLASS_ALIEN_PREY;
        }

        void PainSound()
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong( SND_PAIN1, SND_PAIN3 )], VOL_NORM, ATTN_IDLE );
        }

        void DeathSound()
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong( SND_DEATH1, SND_DEATH2 )], VOL_NORM, ATTN_IDLE );
        }

        void IdleSound()
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong( SND_IDLE1, SND_IDLE3 )], VOL_NORM, ATTN_IDLE );
        }

        void AlertSound()
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[SND_ALERT], VOL_NORM, ATTN_IDLE );
        }

        void PrescheduleThink()
        {
            // make the crab coo a little bit in combat state
            if( self.m_MonsterState == MONSTERSTATE_COMBAT and Math.RandomFloat( 0, 5 ) < 0.1 )
                IdleSound();
        }

        void HandleAnimEvent( MonsterEvent@ pEvent )
        {
            switch( pEvent.event )
            {
                case AE_JUMPATTACK:
                {
                    pev.flags &= ~FL_ONGROUND;

                    g_EntityFuncs.SetOrigin( self, pev.origin + Vector( 0, 0, 1 ) ); // take him off ground so engine doesn't instantly reset onground
                    Math.MakeVectors( pev.angles );

                    Vector vecJumpDir;
                    if( self.m_hEnemy.IsValid() )
                    {
                        float gravity = g_EngineFuncs.CVarGetFloat( "sv_gravity" );
                        if( gravity <= 1 )
                            gravity = 1;

                        // How fast does the snapbug need to travel to reach that height given gravity?
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
                            vecJumpDir = vecJumpDir * ( 650.0 / distance );
                    }
                    else
                    {
                        // jump hop, don't care where
                        vecJumpDir = Vector( g_Engine.v_forward.x, g_Engine.v_forward.y, g_Engine.v_up.z ) * 350;
                    }

                    int iSound = Math.RandomLong( SND_ATTACK1, SND_ATTACK3 );
                    if( iSound != SND_ATTACK1 )
                        g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[iSound], VOL_NORM, ATTN_IDLE );

                    pev.velocity = vecJumpDir;
                    self.m_flNextAttack = g_Engine.time + 6.0;
                }
                break;

                default:
                    BaseClass.HandleAnimEvent( pEvent );
                    break;
            }
        }

        bool CheckRangeAttack1( float flDot, float flDist )
        {
            if( pev.FlagBitSet( FL_ONGROUND ) and flDist <= 256.0 and flDot >= 0.65 )
                return true;

            return false;
        }

        Schedule@ GetScheduleOfType( int iType )
        {
            switch( iType )
            {
                case SCHED_RANGE_ATTACK1:
                    return slSBRangeAttack1Fast; // slSBRangeAttack1;
            }

            return BaseClass.GetScheduleOfType( iType );
        }

        void LeapTouch( CBaseEntity@ pOther )
        {
            if( pOther.pev.takedamage == 0 )
                return;

            if( pOther.Classify() == Classify() )
                return;

            // Don't hit if back on ground
            if( !pev.FlagBitSet( FL_ONGROUND ) )
            {
                g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsSounds[SND_BITE], VOL_NORM, ATTN_IDLE );

                pOther.TakeDamage( self.pev, self.pev, DAMAGE_BITE, DMG_SLASH );

                AttachSnapbug( pOther );
            }

            SetTouch( null );
        }

        void AttachSnapbug( CBaseEntity@ pOther )
        {
            if( !pOther.pev.FlagBitSet( FL_CLIENT ) )
                return;

            CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );

            CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
            if( pCustom.GetKeyvalue( KVN_SNAPBUGGED ).GetInteger() == 1 )
                return;

            KeyValueBuffer@ pInfo = g_EngineFuncs.GetInfoKeyBuffer( pPlayer.edict() );
            string sModel = pInfo.GetValue( "model" );

            if( arrsImmune.find( sModel ) >= 0 )
                return;

            CBaseEntity@ pSnapbug = g_EntityFuncs.Create( NPC_CLASSNAME2, pPlayer.pev.origin, g_vecZero, false, pPlayer.edict() );
            @pSnapbug.pev.aiment = pPlayer.edict();
            pSnapbug.pev.movetype = MOVETYPE_FOLLOW;

            if( arrsLargerBody.find( sModel ) >= 0 )
                pSnapbug.pev.body = 1;

            ShowHUD( pPlayer );
            pCustom.SetKeyvalue( KVN_SNAPBUGGED, 1 );
            g_EntityFuncs.Remove( self );
        }

        void ShowHUD( CBasePlayer@ pPlayer )
        {
            HUDSpriteParams hudParamsSnapbug;
            hudParamsSnapbug.fadeinTime = 0.0;
            hudParamsSnapbug.fadeoutTime = 0.0;
            hudParamsSnapbug.holdTime = 99999;
            hudParamsSnapbug.effect = 0;
            hudParamsSnapbug.channel = HUD_SPRITE_SNAPBUG;
            hudParamsSnapbug.spritename = SPRITE_SNAPBUG;
            hudParamsSnapbug.x = HUD_SNAPBUG_X;
            hudParamsSnapbug.y = HUD_SNAPBUG_Y;
            hudParamsSnapbug.color1 = RGBA_WHITE;

            hudParamsSnapbug.frame = 0;
            g_PlayerFuncs.HudCustomSprite( pPlayer, hudParamsSnapbug );
        }
    }

    array<ScriptSchedule@>@ custom_snapbug_schedules;

    ScriptSchedule slSBRangeAttack1(
        bits_COND_ENEMY_OCCLUDED |
            bits_COND_NO_AMMO_LOADED,
        0,
        "SBRangeAttack1" );

    // baby headcrabs use this, remove it ??
    ScriptSchedule slSBRangeAttack1Fast(
        bits_COND_ENEMY_OCCLUDED |
            bits_COND_NO_AMMO_LOADED,
        0,
        "SBRAFast" );

    void InitSnapbugSchedules()
    {
        slSBRangeAttack1.AddTask( ScriptTask( TASK_STOP_MOVING ) );
        slSBRangeAttack1.AddTask( ScriptTask( TASK_FACE_IDEAL ) );
        slSBRangeAttack1.AddTask( ScriptTask( TASK_RANGE_ATTACK1 ) );
        slSBRangeAttack1.AddTask( ScriptTask( TASK_SET_ACTIVITY, float( ACT_IDLE ) ) );
        slSBRangeAttack1.AddTask( ScriptTask( TASK_FACE_IDEAL ) );
        slSBRangeAttack1.AddTask( ScriptTask( TASK_WAIT_RANDOM, 0.5 ) );

        slSBRangeAttack1Fast.AddTask( ScriptTask( TASK_STOP_MOVING ) );
        slSBRangeAttack1Fast.AddTask( ScriptTask( TASK_FACE_IDEAL ) );
        slSBRangeAttack1Fast.AddTask( ScriptTask( TASK_RANGE_ATTACK1 ) );
        slSBRangeAttack1Fast.AddTask( ScriptTask( TASK_SET_ACTIVITY, float( ACT_IDLE ) ) );

        array<ScriptSchedule@> scheds = { slSBRangeAttack1, slSBRangeAttack1Fast };

        @custom_snapbug_schedules = @scheds;
    }

    class snapbug : ScriptBaseEntity
    {
        private float m_flDealDamage;
        private float m_flAttachTime;

        protected CBasePlayer@ m_pOwner
        {
            get
            {
                return cast<CBasePlayer@>( g_EntityFuncs.Instance( pev.owner ) );
            }
        }

        void Spawn()
        {
            Precache();

            g_EntityFuncs.SetModel( self, NPC_MODEL_ATT1 );
            g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );

            pev.scale = 0.3;
            m_flAttachTime = g_Engine.time;
            m_flDealDamage = g_Engine.time + DAMAGE_TIME_NORMAL;

            SetThink( ThinkFunction( this.AttachedThink ) );
            pev.nextthink = g_Engine.time;
        }

        void Precache()
        {
            g_Game.PrecacheModel( NPC_MODEL_ATT1 );
        }

        void AttachedThink()
        {
            if( m_pOwner is null or !m_pOwner.IsConnected() )
            {
                g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong( SND_DEATH1, SND_DEATH2 )], VOL_NORM, ATTN_IDLE );
                g_EntityFuncs.Remove( self );
                return;
            }

            if( !m_pOwner.IsAlive() )
                btscm::RemoveSnapbug( m_pOwner );

            if( m_flDealDamage > 0 and m_flDealDamage < g_Engine.time )
            {
                g_SoundSystem.EmitSoundDyn( m_pOwner.edict(), CHAN_WEAPON, arrsSounds[SND_BITE], VOL_NORM, ATTN_IDLE, 0, PITCH_HIGH );
                g_SoundSystem.EmitSound( m_pOwner.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong( SND_IDLE1, SND_IDLE3 )], VOL_NORM, ATTN_IDLE );

                m_pOwner.pev.punchangle.x = -2;

                // This is all so the damage indicator shows damage from behind and the player doesn't get poisoned (damage over time) but still flashes the poisoned icon
                TraceResult tr;
                Math.MakeVectors( m_pOwner.pev.angles );

                Vector vecTraceEnd = m_pOwner.Center() + Vector( 0.0, 0.0, 16.0 );
                Vector vecBehindPlayer = vecTraceEnd + g_Engine.v_forward * -128.0;
                g_Utility.TraceLine( vecBehindPlayer, vecBehindPlayer + g_Engine.v_forward * 120.0, dont_ignore_monsters, self.edict(), tr );

                Vector vecBlood = vecTraceEnd + g_Engine.v_forward * -8.0;
                g_WeaponFuncs.SpawnBlood( vecBlood, BLOOD_COLOR_RED, DAMAGE_POISON );
                m_pOwner.TraceBleed( DAMAGE_POISON, ( tr.vecEndPos - vecBehindPlayer ).Normalize(), tr, DAMAGE_TYPE );

                NetworkMessage m1( MSG_ONE, NetworkMessages::Damage, m_pOwner.edict() );
                m1.WriteByte( DAMAGE_POISON ); // pev->dmg_save
                m1.WriteByte( DAMAGE_POISON ); // pev->dmg_take
                m1.WriteLong( DAMAGE_TYPE );   // visibleDamageBits
                m1.WriteCoord( vecBehindPlayer.x );
                m1.WriteCoord( vecBehindPlayer.y );
                m1.WriteCoord( vecBehindPlayer.z );
                m1.End();

                // this deals the actual damage
                m_pOwner.pev.health -= DAMAGE_POISON;
                if( m_pOwner.pev.health <= 0 )
                    m_pOwner.Killed( self.pev, GIB_NEVER );

                float flElapsed = g_Engine.time - m_flAttachTime;
                float flNextBite;

                if( flElapsed >= 240.0 )
                    flNextBite = DAMAGE_TIME_FASTER;
                else if( flElapsed >= 100.0 )
                    flNextBite = DAMAGE_TIME_FAST;
                else
                    flNextBite = DAMAGE_TIME_NORMAL;

                m_flDealDamage = g_Engine.time + flNextBite;
            }

            pev.nextthink = g_Engine.time + 0.1;
        }
    }

    void SnapbugAntidote( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
    {
        if( !pActivator.pev.FlagBitSet( FL_CLIENT ) )
            return;

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );
        btscm::RemoveSnapbug( pPlayer );
    }

    void Register()
    {
        InitSnapbugSchedules();
        g_CustomEntityFuncs.RegisterCustomEntity( "monster_snapbug::monster_snapbug", "monster_snapbug" );
        g_Game.PrecacheOther( "monster_snapbug" );

        g_CustomEntityFuncs.RegisterCustomEntity( "monster_snapbug::snapbug", NPC_CLASSNAME2 );
        g_Game.PrecacheOther( NPC_CLASSNAME2 );
    }

} // namespace monster_snapbug END
