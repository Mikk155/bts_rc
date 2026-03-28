/*
 * Electric Crossbow (Prototype Synthetic)
 * Script: Giegue
 * Models: MTB (Animations), MarshFreakingHoppers[MFH] (Rigging)
 */

namespace BTS_XBOW
{

    const int BOLT_AIR_VELOCITY = 2000;
    const int BOLT_WATER_VELOCITY = 1000;

    const int CROSSBOW_DEFAULT_GIVE = 5;
    const int CROSSBOW_MAX_CARRY = 15;
    const int CROSSBOW_MAX_CLIP = 5;
    const int CROSSBOW_WEIGHT = 10;

    class electro_bolt : ScriptBaseEntity
    {
        void Spawn()
        {
            pev.movetype = MOVETYPE_FLY;
            pev.solid = SOLID_BBOX;
            pev.gravity = 0.5;
            self.SetClassification( CLASS_NONE );

            g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/electro_bolt.mdl" );
            g_EntityFuncs.SetOrigin( self, pev.origin );
            g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );

            NetworkMessage m2( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
            m2.WriteByte( TE_BEAMFOLLOW );
            m2.WriteShort( self.entindex() );
            m2.WriteShort( models::laserbeam );
            m2.WriteByte( 1 );   // life
            m2.WriteByte( 1 );   // width
            m2.WriteByte( 76 );  // r
            m2.WriteByte( 167 ); // g
            m2.WriteByte( 195 ); // b
            m2.WriteByte( 200 ); // brightness
            m2.End();

            SetTouch( TouchFunction( this.BoltTouch ) );
            SetThink( ThinkFunction( this.BubbleThink ) );
            pev.nextthink = g_Engine.time + 0.2;
        }

        void BoltThink()
        {
            if( pev.dmgtime != -1.0f )
            {
                if( pev.dmgtime < g_Engine.time )
                {
                    // BoltLight(2, 64);
                    g_EntityFuncs.Remove( self );
                    return;
                }
            }

            if( pev.waterlevel > WATERLEVEL_FEET )
            {
                g_Utility.Bubbles( pev.absmin, pev.absmax, 1 );
            }
            else
            {
                if( Math.RandomLong( 0, 8 ) == 1 )
                {
                    g_Utility.Sparks( pev.origin );
                }
            }

            // BoltLight(1, 1);
            pev.nextthink = g_Engine.time + 0.1f;
        }

        /*
            void BoltLight(uint8 life, uint8 decayRate)
            {
                // RGBA(255, 21, 18)
                NetworkMessage msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                msg.WriteByte(TE_DLIGHT);                                 // temp entity you want to implement
                msg.WriteCoord(pev.origin.x);                             // vector x
                msg.WriteCoord(pev.origin.y);                             // vector y
                msg.WriteCoord(pev.origin.z);                             // vector z
                msg.WriteByte(pev.waterlevel > WATERLEVEL_FEET ? 9 : 18); // Radius
                msg.WriteByte(76);                                        // R
                msg.WriteByte(167);                                       // G
                msg.WriteByte(195);                                       // B
                msg.WriteByte(life);                                      // Life
                msg.WriteByte(decayRate);                                 // Decay
                msg.End();
            }

            void Start(float flLifeTime)
            {
                if (flLifeTime > 0.0f)
                    pev.dmgtime = g_Engine.time + flLifeTime;
                else
                    pev.dmgtime = -1.0f;

                pev.effects &= ~EF_NODRAW;

                SetThink(ThinkFunction(BoltThink));
                pev.nextthink = g_Engine.time + 0.1f;
            }
        */

        void Precache()
        {
            g_Game.PrecacheModel( "models/bts_rc/weapons/electro_bolt.mdl" );
        }

        void BoltTouch( CBaseEntity @pOther )
        {
            if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
            {
                g_EntityFuncs.Remove( self );
                return;
            }

            SetTouch( null );
            SetThink( null );

            if( pOther.pev.takedamage != DAMAGE_NO )
            {
                TraceResult tr = g_Utility.GetGlobalTrace();
                entvars_t @pevOwner = pev.owner.vars;

                g_WeaponFuncs.ClearMultiDamage();

                if( pOther.IsPlayer() )
                    pOther.TraceAttack( pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_NEVERGIB );
                else
                    pOther.TraceAttack( pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_NERVEGAS | DMG_NEVERGIB );

                g_WeaponFuncs.ApplyMultiDamage( pev, pevOwner );

                pev.velocity = g_vecZero;

                g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "bts_rc/weapons/xbow_hitbod1.wav", 1, ATTN_NORM );

                self.Killed( pev, GIB_NEVER );
            }
            else
            {
                g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "bts_rc/weapons/xbow_hit1.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 7 ) );

                SetThink( ThinkFunction( this.SUB_Remove ) );
                pev.nextthink = g_Engine.time;

                if( pOther.pev.ClassNameIs( "worldspawn" ) )
                {
                    Vector vecDir = pev.velocity.Normalize() * 10;
                    g_EntityFuncs.SetOrigin( self, pev.origin - vecDir ); // Pull out of the wall a bit
                    pev.angles = Math.VecToAngles( vecDir );
                    pev.solid = SOLID_NOT;
                    pev.movetype = MOVETYPE_FLY;
                    pev.velocity = Vector( 0, 0, 0 );
                    pev.avelocity.z = 0;
                    pev.angles.z = Math.RandomLong( 0, 360 );
                    pev.nextthink = g_Engine.time + 10.0;
                }

                if( g_EngineFuncs.PointContents( pev.origin ) != CONTENTS_WATER )
                    g_Utility.Sparks( pev.origin );
            }
        }

        void BubbleThink()
        {
            pev.nextthink = g_Engine.time + 0.1;

            if( pev.waterlevel == WATERLEVEL_DRY )
                return;

            g_Utility.BubbleTrail( pev.origin - pev.velocity * 0.1, pev.origin, 1 );
        }

        void SUB_Remove()
        {
            self.SUB_Remove();
        }
    }

    electro_bolt @BoltCreate()
    {
        // Create a new entity with electro_bolt private data
        CBaseEntity @pre_pBolt = g_EntityFuncs.CreateEntity( "electro_bolt", null, false );
        electro_bolt @pBolt = cast<electro_bolt @>( CastToScriptClass( pre_pBolt ) );

        pBolt.Spawn();
        // pBolt.Start(180.f);

        return pBolt;
    }

    enum crossbow_e
    {
        CROSSBOW_IDLE1 = 0, // full
        CROSSBOW_IDLE2,     // empty
        CROSSBOW_FIDGET1,   // full
        CROSSBOW_FIDGET2,   // empty
        CROSSBOW_FIRE1,     // full
        CROSSBOW_FIRE2,     // reload
        CROSSBOW_FIRE3,     // empty
        CROSSBOW_RELOAD,    // from empty
        CROSSBOW_DRAW1,     // full
        CROSSBOW_DRAW2,     // empty
        CROSSBOW_HOLSTER1,  // full
        CROSSBOW_HOLSTER2   // empty
    };

    class weapon_bts_xbow : ScriptBasePlayerWeaponEntity, CBaseWeapon
    {
        private CBasePlayer @m_pPlayer = null;

        void Spawn()
        {
            Precache();
            g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/w_crossbow.mdl" );

            self.m_iDefaultAmmo = CROSSBOW_DEFAULT_GIVE;

            pev.scale = 0.8;

            self.FallInit(); // get ready to fall down.
        }

        void Precache()
        {
            g_Game.PrecacheModel( "models/bts_rc/weapons/v_crossbow.mdl" );
            g_Game.PrecacheModel( "models/bts_rc/weapons/w_crossbow.mdl" );
            g_Game.PrecacheModel( "models/bts_rc/weapons/p_crossbow.mdl" );
            g_Game.PrecacheModel( "models/bts_rc/weapons/w_crossbow_clip.mdl" );

            g_SoundSystem.PrecacheSound( "hlclassic/items/9mmclip1.wav" );

            g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_fire1.wav" );
            g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_bolt.wav" );
            g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_fidget2.wav" );
            g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_hit1.wav" );
            g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_hitbod1.wav" );
            g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_hitbod2.wav" );
            g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_magin.wav" );
            g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_magready.wav" );
            g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_draw2.wav" );

            g_Game.PrecacheOther( "electro_bolt" );

            g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );

            g_Game.PrecacheGeneric( "sprites/bts_rc/weapons/weapon_bts_xbow.txt" );
        }

        bool AddToPlayer( CBasePlayer @pPlayer )
        {
            if( BaseClass.AddToPlayer( pPlayer ) )
            {
                NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
                message.WriteLong( self.m_iId );
                message.End();

                @m_pPlayer = pPlayer;

                return true;
            }

            return false;
        }

        bool PlayEmptySound()
        {
            if( self.m_bPlayEmptySound )
            {
                self.m_bPlayEmptySound = false;

                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
            }

            return false;
        }

        bool GetItemInfo( ItemInfo& out info )
        {
            info.iMaxAmmo1 = CROSSBOW_MAX_CARRY;
            info.iMaxAmmo2 = -1;
            info.iMaxClip = CROSSBOW_MAX_CLIP;
            info.iSlot = 2;
            info.iPosition = 11;
            info.iFlags = 0;
            info.iWeight = CROSSBOW_WEIGHT;

            return true;
        }

        bool Deploy()
        {
            return bts_deploy( "models/bts_rc/weapons/v_crossbow.mdl", "models/bts_rc/weapons/p_crossbow.mdl", CROSSBOW_DRAW1, "bow", 1 );
        }

        void Holster( int skipLocal /* = 0 */ )
        {
            self.m_fInReload = false; // cancel any reload in progress.

            if( self.m_fInZoom )
            {
                SecondaryAttack();
            }

            self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
            if( self.m_iClip > 0 )
                self.SendWeaponAnim( CROSSBOW_HOLSTER1, 0, pev.body );
            else
                self.SendWeaponAnim( CROSSBOW_HOLSTER2, 0, pev.body );

            BaseClass.Holster( skipLocal );
        }

        void PrimaryAttack()
        {
            FireBolt();
        }

        void FireBolt()
        {
            TraceResult tr;

            if( self.m_iClip == 0 )
            {
                PlayEmptySound();
                return;
            }

            m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
            self.m_iClip--;

            if( self.m_iClip > 0 )
            {
                self.SendWeaponAnim( CROSSBOW_FIRE1, 0, pev.body );
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/xbow_fire1.ogg", 1.0, ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xF ) );
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_BODY, "bts_rc/weapons/xbow_magin.wav", 0.25, ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xF ) );
            }
            else
            {
                self.SendWeaponAnim( CROSSBOW_FIRE3, 0, pev.body );
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/xbow_fire1.ogg", 1.1, ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xF ) );
            }

            // player "shoot" animation
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

            Vector anglesAim = m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle;
            g_EngineFuncs.MakeVectors( anglesAim );

            Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
            anglesAim.x = -anglesAim.x;
            Vector vecSrc = m_pPlayer.GetGunPosition() - g_Engine.v_up * 2;
            Vector vecDir = g_Engine.v_forward;

            float flDamage = 48;
            if( self.m_flCustomDmg > 0 )
                flDamage = self.m_flCustomDmg;

            electro_bolt @pBolt = BoltCreate();
            pBolt.pev.origin = vecSrc;
            pBolt.pev.angles = anglesAim;
            pBolt.pev.dmg = flDamage;
            @pBolt.pev.owner = m_pPlayer.edict();

            if( m_pPlayer.pev.waterlevel == 3 )
            {
                pBolt.pev.velocity = vecDir * BOLT_WATER_VELOCITY;
                pBolt.pev.speed = BOLT_WATER_VELOCITY;
            }
            else
            {
                pBolt.pev.velocity = vecDir * BOLT_AIR_VELOCITY;
                pBolt.pev.speed = BOLT_AIR_VELOCITY;
            }
            pBolt.pev.avelocity.z = 10;

            m_pPlayer.pev.punchangle.x = -3.0f;

            self.m_flNextPrimaryAttack = g_Engine.time + 1.8; // GetNextAttackDelay?

            self.m_flNextSecondaryAttack = g_Engine.time + 1.8;

            if( self.m_iClip != 0 )
                self.m_flTimeWeaponIdle = g_Engine.time + 5.0;
            else
                self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
        }

        void SecondaryAttack()
        {
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, 'weapons/sniper_zoom.wav', 30, ATTN_NORM, 0, 125 );
            if( m_pPlayer.pev.fov != 0 )
            {
                m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0; // 0 means reset to default fov
                m_pPlayer.m_szAnimExtension = "bow";
                self.m_fInZoom = false;
            }
            else if( m_pPlayer.pev.fov != 20 )
            {
                m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 20;
                m_pPlayer.m_szAnimExtension = "bowscope";
                self.m_fInZoom = true;
            }

            self.pev.nextthink = g_Engine.time + 0.1;
            self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
        }

        void Reload()
        {
            if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
                return;

            if( self.m_iClip == 5 )
                return;

            if( m_pPlayer.pev.fov != 0 )
            {
                SecondaryAttack();
            }

            if( self.DefaultReload( 5, CROSSBOW_RELOAD, 4.5, pev.body ) )
            {
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "bts_rc/weapons/xbow_magready.wav", 1.0, ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xF ) );
            }

            BaseClass.Reload();
        }

        void WeaponIdle()
        {
            self.ResetEmptySound();

            if( self.m_flTimeWeaponIdle < g_Engine.time )
            {
                float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0, 1 );
                if( flRand <= 0.75 )
                {
                    if( self.m_iClip > 0 )
                    {
                        self.SendWeaponAnim( CROSSBOW_IDLE1, 0, pev.body );
                    }
                    else
                    {
                        self.SendWeaponAnim( CROSSBOW_IDLE2, 0, pev.body );
                    }
                    self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
                }
                else
                {
                    if( self.m_iClip > 0 )
                    {
                        self.SendWeaponAnim( CROSSBOW_FIDGET1, 0, pev.body );
                        self.m_flTimeWeaponIdle = g_Engine.time + 90.0 / 30.0;
                    }
                    else
                    {
                        self.SendWeaponAnim( CROSSBOW_FIDGET2, 0, pev.body );
                        self.m_flTimeWeaponIdle = g_Engine.time + 80.0 / 30.0;
                    }
                }
            }
        }
    }

    class ammo_bts_xbow : ScriptBasePlayerAmmoEntity
    {
        void Spawn()
        {
            g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/w_crossbow_clip.mdl" );

            pev.scale = 0.8;

            BaseClass.Spawn();
        }

        bool AddAmmo( CBaseEntity @pOther )
        {
            int iGive;

            iGive = CROSSBOW_MAX_CLIP;

            if( pOther.GiveAmmo( iGive, "bolts", CROSSBOW_MAX_CLIP ) != -1 )
            {
                g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1, ATTN_NORM );
                return true;
            }

            return false;
        }
    }

    string GetName()
    {
        return "weapon_bts_xbow";
    }

    string GetAmmoName()
    {
        return "ammo_bts_xbow";
    }

    void Register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "BTS_XBOW::electro_bolt", "electro_bolt" );
        g_CustomEntityFuncs.RegisterCustomEntity( "BTS_XBOW::weapon_bts_xbow", GetName() );
        g_CustomEntityFuncs.RegisterCustomEntity( "BTS_XBOW::ammo_bts_xbow", GetAmmoName() );
        g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", "bolts", "", GetAmmoName() );
    }

}
