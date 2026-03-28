/*
    Author: Nero
*/

// based on the original Half-Life zombie
// pev.weapons changes between barney and blackops
// 0 = Barney
// 1 = Blackops
// 2 = Random

namespace monster_zombie_gunner
{

    // SETTINGS
    const string NPC_DISPLAYNAME1 = "Zombie Barney";
    const string NPC_DISPLAYNAME2 = "Zombie Blackops";

    const int NPC_FLINCH_DELAY = 2; // at most one flinch every n secs
    const int NPC_HEALTH = 120;
    const int NPC_DMG_ONE_SLASH = 25;
    const int NPC_DMG_BOTH_SLASH = 40;

    const int GUN_TRIGGER = 80;           // pull the gun out when at or below this health percentage, 1-100
    const int GUN_RANDOM_CHANCE = 40;     // randomly pull the gun out when spotting a player, 1-100
    const int GUN_AMMO_MAX1 = 15;         // barney
    const int GUN_AMMO_MAX2 = 17;         // blackops
    const float GUN_DAMAGE1 = 9.0;        // barney
    const float GUN_DAMAGE2 = 9.0;        // blackops
    const string GUN_DROP1 = "";          // classname of the weapon to drop (leave empty to just drop a temporary model)
    const string GUN_DROP2 = "";
    const float GUN_DROP_LIFETIME = 20.0; // how long the temporary model stays after being dropped

    const string NPC_MODEL1 = "models/bts_rc/monsters/zombie_barney3.mdl";
    const string NPC_MODEL2 = "models/bts_rc/monsters/zombie_blackops3.mdl";
    const string GUN_MODEL1 = "models/bts_rc/weapons/w_beretta.mdl";
    const string GUN_MODEL2 = "models/bts_rc/weapons/w_9mmhandgunsd.mdl";

    const int NPC_AE_ATTACK_RIGHT = 1;
    const int NPC_AE_ATTACK_LEFT = 2;
    const int NPC_AE_ATTACK_BOTH = 3;
    const int NPC_AE_ATTACK_GUN = 11;

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
            "bts_rc/weapons/beretta_fire1.wav",
            "hlclassic/weapons/pl_gun2.wav",
            "weapons/357_cock1.wav" };

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
        SND_SHOOT_BARNEY,
        SND_SHOOT_BLACKOPS,
        SND_EMPTY
    };

    class monster_zombie_gunner : bts_rc_base_monster
    {
        private float m_flNextFlinch;
        private bool m_bGunOut;
        private bool m_bHasGun = true;
        private int m_iAmmo;
        private int m_iShell;

        void Spawn()
        {
            Precache();

            if( pev.weapons == 2 )
                pev.weapons = Math.RandomLong( 0, 1 );

            int iStartAmmo = GUN_AMMO_MAX1;

            if( IsBarney() )
            {
                g_EntityFuncs.SetModel( self, NPC_MODEL1 );
                g_EntityFuncs.DispatchKeyValue( self.edict(), "displayname", NPC_DISPLAYNAME1 );
            }
            else
            {
                g_EntityFuncs.SetModel( self, NPC_MODEL2 );
                g_EntityFuncs.DispatchKeyValue( self.edict(), "displayname", NPC_DISPLAYNAME2 );
                iStartAmmo = GUN_AMMO_MAX2;
            }

            g_EntityFuncs.SetSize( self.pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX );

            pev.solid = SOLID_SLIDEBOX;
            pev.movetype = MOVETYPE_STEP;
            self.m_bloodColor = BLOOD_COLOR_RED;

            if( pev.health <= 0 )
                pev.health = NPC_HEALTH;

            pev.view_ofs = VEC_VIEW;
            self.m_flFieldOfView = 0.5;
            self.m_MonsterState = MONSTERSTATE_NONE;
            self.m_afCapability = bits_CAP_DOORS_GROUP;

            if( m_iAmmo <= 0 )
                m_iAmmo = iStartAmmo;

            self.MonsterInit();
        }

        void Precache()
        {
            g_Game.PrecacheModel( NPC_MODEL1 );
            g_Game.PrecacheModel( NPC_MODEL2 );
            g_Game.PrecacheModel( GUN_MODEL1 );
            g_Game.PrecacheModel( GUN_MODEL2 );
            m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );

            for( uint i = 0; i < arrsSounds.length(); i++ )
                g_SoundSystem.PrecacheSound( arrsSounds[i] );
        }

        void PainSound()
        {
            int pitch = 95 + Math.RandomLong( 0, 9 );

            if( Math.RandomLong( 0, 5 ) < 2 )
                g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong( SND_PAIN1, SND_PAIN2 )], VOL_NORM, ATTN_NORM, 0, pitch );
        }

        void AlertSound()
        {
            int pitch = 95 + Math.RandomLong( 0, 9 );

            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong( SND_ALERT1, SND_ALERT3 )], VOL_NORM, ATTN_NORM, 0, pitch );

            if( m_bHasGun and !m_bGunOut and Math.RandomLong( 1, 100 ) <= GUN_RANDOM_CHANCE and self.m_Activity != ACT_RUN )
            {
                m_bGunOut = true;
                self.ChangeSchedule( self.GetScheduleOfType( SCHED_RANGE_ATTACK1 ) );
                AttackSound();
            }
        }

        void IdleSound()
        {
            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong( SND_IDLE1, SND_IDLE4 )], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) );
        }

        void AttackSound()
        {
            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong( SND_ATTACK1, SND_ATTACK2 )], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) );
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

            if( ( self.m_Activity == ACT_MELEE_ATTACK1 ) or ( self.m_Activity == ACT_MELEE_ATTACK1 ) )
            {
                if( m_flNextFlinch >= g_Engine.time )
                    iIgnore |= ( bits_COND_LIGHT_DAMAGE | bits_COND_HEAVY_DAMAGE );
            }

            if( ( self.m_Activity == ACT_SMALL_FLINCH ) or ( self.m_Activity == ACT_BIG_FLINCH ) )
            {
                if( m_flNextFlinch < g_Engine.time )
                    m_flNextFlinch = g_Engine.time + NPC_FLINCH_DELAY;
            }

            // don't run away at low health
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
                CCineMonster @pCine = cast<CCineMonster @>( self.m_hCine.GetEntity() );
                if( pCine !is null )
                    iIgnoreConditions |= pCine.IgnoreConditions();
            }

            return iIgnoreConditions;
        }

        void HandleAnimEvent( MonsterEvent @pEvent )
        {
            switch( pEvent.event )
            {
                case NPC_AE_ATTACK_RIGHT:
                {
                    CBaseEntity @pHurt = CheckTraceHullAttack( self, 70, NPC_DMG_ONE_SLASH, DMG_SLASH );
                    if( pHurt !is null )
                    {
                        if( ( pHurt.pev.flags & ( FL_MONSTER | FL_CLIENT ) ) == 1 )
                        {
                            pHurt.pev.punchangle.z = -18;
                            pHurt.pev.punchangle.x = 5;
                            pHurt.pev.velocity = pHurt.pev.velocity - g_Engine.v_right * 100;
                        }

                        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsSounds[Math.RandomLong( SND_ATTACK_HIT1, SND_ATTACK_HIT3 )], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) );
                    }
                    else
                        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsSounds[Math.RandomLong( SND_ATTACK_MISS1, SND_ATTACK_MISS2 )], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) );

                    if( Math.RandomLong( 0, 1 ) == 1 )
                        AttackSound();

                    break;
                }

                case NPC_AE_ATTACK_LEFT:
                {
                    CBaseEntity @pHurt = CheckTraceHullAttack( self, 70, NPC_DMG_ONE_SLASH, DMG_SLASH );
                    if( pHurt !is null )
                    {
                        if( ( pHurt.pev.flags & ( FL_MONSTER | FL_CLIENT ) ) == 1 )
                        {
                            pHurt.pev.punchangle.z = 18;
                            pHurt.pev.punchangle.x = 5;
                            pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_right * 100;
                        }

                        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsSounds[Math.RandomLong( SND_ATTACK_HIT1, SND_ATTACK_HIT3 )], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) );
                    }
                    else
                        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsSounds[Math.RandomLong( SND_ATTACK_MISS1, SND_ATTACK_MISS2 )], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) );

                    if( Math.RandomLong( 0, 1 ) == 1 )
                        AttackSound();

                    break;
                }

                case NPC_AE_ATTACK_BOTH:
                {
                    CBaseEntity @pHurt = CheckTraceHullAttack( self, 70, NPC_DMG_BOTH_SLASH, DMG_SLASH );
                    if( pHurt !is null )
                    {
                        if( btscm::HasFlags( pHurt.pev.flags, FL_MONSTER | FL_CLIENT ) )
                        {
                            pHurt.pev.punchangle.x = 5;
                            pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * -100;
                        }

                        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsSounds[Math.RandomLong( SND_ATTACK_HIT1, SND_ATTACK_HIT3 )], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) );
                    }
                    else
                        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsSounds[Math.RandomLong( SND_ATTACK_MISS1, SND_ATTACK_MISS2 )], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong( -5, 5 ) );

                    if( Math.RandomLong( 0, 1 ) == 1 )
                        AttackSound();
                }

                case NPC_AE_ATTACK_GUN:
                {
                    if( m_bHasGun )
                    {
                        int iPitchShift = Math.RandomLong( 0, 20 );

                        // Only shift about half the time
                        if( iPitchShift > 10 )
                            iPitchShift = 0;
                        else
                            iPitchShift -= 5;

                        if( m_iAmmo > 0 )
                        {
                            Vector vecShootOrigin, vecShootDir;
                            self.GetAttachment( 0, vecShootOrigin, void );

                            Math.MakeVectors( pev.angles );

                            vecShootDir = g_Engine.v_forward;

                            Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat( 40, 90 ) + g_Engine.v_up * Math.RandomFloat( 75, 200 ) + g_Engine.v_forward * Math.RandomFloat( -40, 40 );
                            g_EntityFuncs.EjectBrass( vecShootOrigin + vecShootDir * 24 + g_Engine.v_right * 8, vecShellVelocity, pev.angles.y, m_iShell, TE_BOUNCE_SHELL );
                            self.FireBullets( 1, vecShootOrigin, vecShootDir, VECTOR_CONE_2DEGREES, 1024.0, BULLET_PLAYER_CUSTOMDAMAGE, 0, IsBarney() ? GUN_DAMAGE1 : GUN_DAMAGE2, self.pev );

                            pev.effects |= EF_MUZZLEFLASH;

                            m_iAmmo--;

                            int iSound = IsBarney() ? SND_SHOOT_BARNEY : SND_SHOOT_BLACKOPS;
                            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsSounds[iSound], VOL_NORM, ATTN_NORM, 0, 100 + iPitchShift );
                            GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.3, self );
                        }
                        else
                            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsSounds[SND_EMPTY], 0.8, ATTN_NORM, 0, 100 + iPitchShift );
                    }

                    break;
                }

                default:
                {
                    BaseClass.HandleAnimEvent( pEvent );
                    break;
                }
            }
        }

        int TakeDamage( entvars_t @pevInflictor, entvars_t @pevAttacker, float flDamage, int bitsDamageType )
        {
            // take no damage when pulling out the gun
            if( self.m_Activity == ACT_RANGE_ATTACK1 )
                return 0;

            // Take 30% damage from bullets
            if( bitsDamageType == DMG_BULLET )
            {
                Vector vecDir = pev.origin - ( pevInflictor.absmin + pevInflictor.absmax ) * 0.5;
                vecDir = vecDir.Normalize();
                float flForce = self.DamageForce( flDamage );
                pev.velocity = pev.velocity + vecDir * flForce;
                flDamage *= 0.3;
            }

            // pevAttacker.frags += self.GetPointsForDamage( flDamage ); //broken :aRage:
            pevAttacker.frags += ( flDamage / 40 );

            if( self.IsAlive() )
                PainSound();

            return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
        }

        void StartTask( Task @pTask )
        {
            switch( pTask.iTask )
            {
                case TASK_RUN_PATH:
                {
                    if( m_bHasGun and m_bGunOut )
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

        // when in melee range; drop gun and resume regular zombie behavior
        bool CheckMeleeAttack1( float flDot, float flDist )
        {
            bool bCheckMeleeAttack1 = BaseClass.CheckMeleeAttack1( flDot, flDist );

            if( m_bGunOut and self.m_Activity == ACT_RUN and bCheckMeleeAttack1 )
                DropGun();

            if( m_bGunOut or self.m_Activity == ACT_RANGE_ATTACK1 )
                return false;

            return bCheckMeleeAttack1;
        }

        bool CheckRangeAttack1( float flDot, float flDist )
        {
            if( m_bHasGun and !m_bGunOut and pev.health <= ( pev.max_health * btscm::ptof( GUN_TRIGGER ) ) and self.m_Activity != ACT_RUN )
            {
                m_bGunOut = true;
                self.ChangeSchedule( self.GetScheduleOfType( SCHED_RANGE_ATTACK1 ) ); // this shouldn't be needed but for some reason it is, blyat
                AttackSound();

                return true;
            }

            return false;
        }

        CBaseEntity @CheckTraceHullAttack( CBaseMonster @pThis, float flDist, int iDamage, int iDmgType )
        {
            TraceResult tr;

            if( pThis.IsPlayer() )
                Math.MakeVectors( pThis.pev.angles );
            else
                Math.MakeAimVectors( pThis.pev.angles );

            Vector vecStart = pev.origin;
            vecStart.z += pev.size.z * 0.5;
            Vector vecEnd = vecStart + ( g_Engine.v_forward * flDist );

            g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, pThis.edict(), tr );

            if( tr.pHit !is null )
            {
                CBaseEntity @pEntity = g_EntityFuncs.Instance( tr.pHit );

                if( iDamage > 0 )
                    pEntity.TakeDamage( pThis.pev, pThis.pev, iDamage, iDmgType );

                return pEntity;
            }

            return null;
        }

        void DropGun()
        {
            string sGunDrop = IsBarney() ? GUN_DROP1 : GUN_DROP2;
            Vector vecOrigin;
            g_EngineFuncs.GetBonePosition( self.edict(), 17, vecOrigin, void ); // using the hand bone

            if( !sGunDrop.IsEmpty() )
                g_EntityFuncs.Create( sGunDrop, vecOrigin, g_vecZero, false, null );
            else
            {
                string sModel = IsBarney() ? GUN_MODEL1 : GUN_MODEL2;
                NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
                m1.WriteByte( TE_BREAKMODEL );
                m1.WriteCoord( vecOrigin.x );      // position
                m1.WriteCoord( vecOrigin.y );
                m1.WriteCoord( vecOrigin.z );
                m1.WriteCoord( 1.0 );              // size
                m1.WriteCoord( 1.0 );
                m1.WriteCoord( 1.0 );
                m1.WriteCoord( 0.0 );              // velocity
                m1.WriteCoord( 0.0 );
                m1.WriteCoord( 0.0 );
                m1.WriteByte( 0 );                 // random velocity in 10's
                m1.WriteShort( g_Game.PrecacheModel( sModel ) );
                m1.WriteByte( 1 );                 // count
                m1.WriteByte( GUN_DROP_LIFETIME ); // life in 0.1 secs
                m1.WriteByte( 0 );
                m1.End();
            }

            m_bGunOut = m_bHasGun = false;
        }

        bool IsBarney()
        {
            return pev.weapons == 0;
        }
    }

    void Register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "monster_zombie_gunner::monster_zombie_gunner", "monster_zombie_gunner" );
        g_Game.PrecacheOther( "monster_zombie_gunner" );
    }

} // end of namespace monster_zombie_gunner
