/*
 * Smith & Wesson 637
 * Author: SV BOY
 */

namespace weapon_bts_sw637
{
    enum sw637_e
    {
        DRAW = 0,
        IDLE,
        SHOOT,
        RELOAD_START,
        RELOAD_PART,
        RELOAD_FINISH,
        HOLSTER
    };

    const string A_MODEL = "models/bts_rc/weapons/w_38ammobox.mdl";
    int MAX_CARRY = 60;
    int MAX_CLIP = 5;
    int AMMO_DROP = 5;
    int AMMO_GIVE = 20;
    int WEIGHT = 10;
    int SLOT = 1;
    int POSITION = 17;
    int DAMAGE = 25;
    const int BODYGROUP_ROUNDS = 2;
    const int BODYGROUP_HANDS = 1;

    class weapon_bts_sw637 : ScriptBasePlayerWeaponEntity, CBaseWeapon
    {
        private CBasePlayer @m_pPlayer
        {
            get const
            {
                return get_player();
            }
        }

        private bool m_fReloading = false;
        private float m_flNextInsert = 0.0f;

        // -----------------------------
        // Bodygroups
        // -----------------------------
        void UpdateViewBodygroups()
        {
            int mdl = g_ModelFuncs.ModelIndex( "models/bts_rc/weapons/v_sw637.mdl" );

            pev.body = g_ModelFuncs.SetBodygroup( mdl, pev.body, BODYGROUP_HANDS, g_PlayerClass[m_pPlayer] );

            pev.body = g_ModelFuncs.SetBodygroup( mdl, pev.body, BODYGROUP_ROUNDS, self.m_iClip );
        }

        void Spawn()
        {
            g_EntityFuncs.SetModel( self, self.GetW_Model( "models/bts_rc/weapons/w_sw637.mdl" ) );
            self.m_iDefaultAmmo = Math.RandomLong( 0, 0 );
            self.FallInit();
        }

        bool GetItemInfo( ItemInfo& out info )
        {
            info.iMaxAmmo1 = MAX_CARRY;
            info.iAmmo1Drop = AMMO_DROP;
            info.iMaxClip = MAX_CLIP;
            info.iSlot = SLOT;
            info.iPosition = POSITION;
            info.iId = g_ItemRegistry.GetIdForName( pev.classname );
            info.iWeight = WEIGHT;
            return true;
        }

        void ItemPostFrame()
        {
            BaseClass.ItemPostFrame();
            if( m_fReloading )
            {
                {
                    PrimaryAttack();
                }
            }
        }

        bool Deploy()
        {
            UpdateViewBodygroups();
            return bts_deploy( "models/bts_rc/weapons/v_sw637.mdl", "models/bts_rc/weapons/p_sw637.mdl", DRAW, "python", 1, 1.0f );
        }

        void Holster( int skiplocal = 0 )
        {
            m_fReloading = false;
            SetThink( null );
            BaseClass.Holster( skiplocal );
        }

        // -----------------------------
        // FIRE
        // -----------------------------
        void PrimaryAttack()
        {
            if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
            {
                self.PlayEmptySound();
                self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
                return;
            }

            if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK ) == 0 )
                return;

            m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
            m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

            Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
            Vector vecSrc = m_pPlayer.GetGunPosition();
            Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
            {
                float x, y;
                g_Utility.GetCircularGaussianSpread( x, y );

                float CONE = Accuracy( 0.01f, 0.05f, 0.05f, 0.05f );
                Vector vecDir = vecAiming + x * CONE * g_Engine.v_right + y * CONE * g_Engine.v_up;
                Vector vecEnd = vecSrc + vecDir * 8192.0f;

                TraceResult tr;
                g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
                self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, DAMAGE, m_pPlayer.pev );
                bts_post_attack( tr );

                if( tr.flFraction < 1.0f && tr.pHit !is null )
                {
                    CBaseEntity @pHit = g_EntityFuncs.Instance( tr.pHit );
                    if( ( pHit is null || pHit.IsBSPModel() ) && !pHit.pev.FlagBitSet( FL_WORLDBRUSH ) )
                        g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
                }
            }

            m_fReloading = false;

            --self.m_iClip;
            UpdateViewBodygroups();

            m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
            pev.effects |= EF_MUZZLEFLASH;
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

            self.SendWeaponAnim( SHOOT, 0, pev.body );

            switch( Math.RandomLong( 0, 1 ) )
            {
                case 0:
                    g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/38_shot1.wav", 1.0f, ATTN_NORM, 0, 95 );
                    break;
                case 1:
                    g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/38_shot2.wav", 1.0f, ATTN_NORM, 0, 95 );
                    break;
            }

            m_pPlayer.pev.punchangle.x = g_PlayerClass.is_trained_personal( m_pPlayer ) ? -3.0f : -7.0f;

            self.m_flNextPrimaryAttack = g_Engine.time + 0.25f;
            self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;
        }

        // -----------------------------
        // RELOAD
        // -----------------------------
        void Reload()
        {
            int mdl = g_ModelFuncs.ModelIndex( "models/bts_rc/weapons/v_sw637.mdl" );

            if( m_fReloading )
                return;

            if( self.m_iClip >= MAX_CLIP )
                return;

            if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
                return;

            m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) + self.m_iClip );
            self.m_iClip = 0;
            pev.body = g_ModelFuncs.SetBodygroup( mdl, pev.body, BODYGROUP_ROUNDS, 4 );

            m_fReloading = true;
            self.SendWeaponAnim( RELOAD_START, 0, pev.body );
            UpdateViewBodygroups();

            m_flNextInsert = g_Engine.time + 1.2f;
            self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;
            self.m_flTimeWeaponIdle = m_flNextInsert;
        }

        // -----------------------------
        // AUTO INSERT
        // -----------------------------
        void WeaponIdle()
        {
            int mdl = g_ModelFuncs.ModelIndex( "models/bts_rc/weapons/v_sw637.mdl" );

            // If not reloading, play normal idle
            if( !m_fReloading )
            {
                if( self.m_flTimeWeaponIdle <= g_Engine.time )
                {
                    self.SendWeaponAnim( IDLE, 0, pev.body );
                    UpdateViewBodygroups();
                    self.m_flTimeWeaponIdle = g_Engine.time + 3.0f;
                }
                return;
            }

            // Wait for next insert
            if( g_Engine.time < m_flNextInsert )
                return;

            // Insert next bullet if possible
            if( self.m_iClip < MAX_CLIP &&
                m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
            {
                self.m_iClip++;
                m_pPlayer.m_rgAmmo(
                    self.m_iPrimaryAmmoType,
                    m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

                self.SendWeaponAnim( RELOAD_PART, 0, pev.body );
                UpdateViewBodygroups();

                m_flNextInsert = g_Engine.time + 0.5f;
                self.m_flTimeWeaponIdle = m_flNextInsert;
                return;
            }

            // ----------------- FINISH RELOAD -----------------
            // Always play RELOAD_FINISH when reloading ends (full clip or no more ammo)
            pev.body = g_ModelFuncs.SetBodygroup(
                mdl,
                pev.body,
                BODYGROUP_ROUNDS,
                self.m_iClip - 1 // visual rounds (0-based)
            );
            self.SendWeaponAnim( RELOAD_FINISH, 0, pev.body );

            m_fReloading = false;
            self.m_flTimeWeaponIdle = g_Engine.time + 1.5f;
        }
    }

    class ammo_bts_sw637 : ScriptBasePlayerAmmoEntity
    {
        void Spawn()
        {
            g_EntityFuncs.SetModel( self, A_MODEL );

            pev.scale = 1.0;

            BaseClass.Spawn();
        }

        bool AddAmmo( CBaseEntity @pOther )
        {
            int iGive;

            iGive = MAX_CLIP;

            if( pOther.GiveAmmo( iGive, "sw637", MAX_CLIP ) != -1 )
            {
                g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "bts_rc/weapons/sw_bullet_insert_1.wav", 1, ATTN_NORM );
                return true;
            }

            return false;
        }
    }

    class ammo_bts_sw637lmao : ScriptBasePlayerAmmoEntity
    {
        void Spawn()
        {
            g_EntityFuncs.SetModel( self, A_MODEL );

            pev.scale = 1.0;

            BaseClass.Spawn();
        }

        bool AddAmmo( CBaseEntity @pOther )
        {
            int iGive;

            iGive = 1;

            if( pOther.GiveAmmo( iGive, "sw637", MAX_CLIP ) != -1 )
            {
                g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "bts_rc/weapons/sw_bullet_insert_1.wav", 1, ATTN_NORM );
                return true;
            }

            return false;
        }
    }

    string GetAmmoName1()
    {
        return "ammo_bts_sw637";
    }

    string GetAmmoName2()
    {
        return "ammo_bts_sw637lmao";
    }

    void Register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_sw637::ammo_bts_sw637lmao", GetAmmoName2() );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_sw637::ammo_bts_sw637", GetAmmoName1() );
        g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bts_sw637::weapon_bts_sw637", "weapon_bts_sw637" );
        g_ItemRegistry.RegisterWeapon( "weapon_bts_sw637", "bts_rc/weapons", "sw637", "", GetAmmoName1() );
    }

}
