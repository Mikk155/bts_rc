/* 
* Custom Player Medkit for bts_rc (january 2025)
* Credits: Gaftherman
* Ref: https://github.com/wootguy/SevenKewp/blob/0fd4ca7d7598712e122aeef83e8a4f88150301c4/dlls/weapon/CMedkit.cpp
*      https://github.com/Rizulix/Classic-Weapons/blob/main/scripts/maps/opfor/weapon_ofshockrifle.as
*      && kmkz && Rizulix
*/

#include "../utils/player_class"

namespace BTS_MEDKIT
{
    enum medkit_e
    {
        IDLE = 0,
        LONGIDLE,
        LONGUSE,
        SHORTUSE,
        HOLSTER,
        DRAW,
    };

    enum bodygroups_e
    {
        HANDS = 0
    };

    // Models
    const string W_MODEL = "models/bts_rc/weapons/w_medkit.mdl";
    const string V_MODEL = "models/bts_rc/weapons/v_medkit.mdl";
    const string P_MODEL = "models/bts_rc/weapons/p_medkit.mdl";

    // Weapon info
    const int MAX_CARRY = 100;
    const int MAX_CARRY2 = WEAPON_NOCLIP;
    const int MAX_CLIP = WEAPON_NOCLIP;
    const int MAX_DROP = 10;
    const int DEFAULT_GIVE = 50;
    const int AMMO_DROP = 10;
    const int AMMO_DROP2 = WEAPON_NOCLIP;
    const int WEIGHT = 0;
    const int FLAGS = ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
    const string AMMO_TYPE = "health";

    // Weapon HUD
    const int SLOT = 0;
    const int POSITION = 12;

    // Vars
    const int HEAL_AMMOUNT = 10;
    const int REVIVE_COST = 50;
    const int VOLUME = 128;
    const int REVIVE_RADIUS = 64;
    const int RECHARGE_AMOUNT = 1;
    const float RECHARGE_DELAY = 0.6f;

    // Sounds
    const string MED_SHOT_MISS = "items/medshotno1.wav";
    const string MED_SHOT_HEAL = "items/medshot4.wav";
    const string MED_SHOT_ERROR = "items/suitchargeok1.wav";
    const string MED_SHOT_REVIVE = "weapons/electro4.wav";

    class weapon_bts_medkit : ScriptBasePlayerWeaponEntity
    {
        private CBasePlayer@ m_pPlayer
        {
            get const	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
            set		    { self.m_hPlayer = EHandle( @value ); }
        }
        private float m_reviveChargedTime; // time when target will be revive charge will complete
	    private float m_rechargeTime; // time until regenerating ammo

        int GetBodygroup()
        {
            pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), pev.body, HANDS, g_PlayerClass[m_pPlayer] );
            return pev.body;
        }

        void Spawn()
        {
            Precache();
            g_EntityFuncs.SetModel(self, self.GetW_Model(W_MODEL));
            self.m_iDefaultAmmo = DEFAULT_GIVE;
            self.FallInit();
        }

        void Precache()
        {
            self.PrecacheCustomModels();
            g_Game.PrecacheModel( W_MODEL );
            g_Game.PrecacheModel( V_MODEL );
            g_Game.PrecacheModel( P_MODEL );

            g_Game.PrecacheOther( GetAmmoName() );

            g_SoundSystem.PrecacheSound( MED_SHOT_MISS );
            g_SoundSystem.PrecacheSound( MED_SHOT_HEAL );
            g_SoundSystem.PrecacheSound( MED_SHOT_ERROR );
            g_SoundSystem.PrecacheSound( MED_SHOT_REVIVE );

            g_Game.PrecacheGeneric( "sprites/bts_rc/weapons/" + self.GetClassname()+ ".txt" );
        }

        bool AddToPlayer( CBasePlayer@ pPlayer )
        {
            if( !BaseClass.AddToPlayer( pPlayer ) )
                return false;

            if(RECHARGE_DELAY != 0.0f)
                m_rechargeTime = g_Engine.time + RECHARGE_DELAY;

            NetworkMessage weapon( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
                weapon.WriteLong( g_ItemRegistry.GetIdForName( self.GetClassname() ) );
            weapon.End();
            return true;
        }

        bool GetItemInfo( ItemInfo& out info )
        {
            info.iMaxAmmo1 = MAX_CARRY;
            info.iAmmo1Drop = AMMO_DROP;
            info.iMaxAmmo2 = MAX_CARRY2;
            info.iAmmo2Drop = AMMO_DROP2;
            info.iMaxClip = MAX_CLIP;
            info.iSlot = SLOT;
            info.iPosition = POSITION;
            info.iId = g_ItemRegistry.GetIdForName( self.GetClassname() );
            info.iFlags = FLAGS;
            info.iWeight = WEIGHT;
            return true;
        }

        bool CanDeploy()
        {
            return true;
        }

        bool Deploy()
        {
            return self.DefaultDeploy( self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), DRAW, "trip", 0, GetBodygroup() );
        }

        void Holster( int skiplocal /*= 0*/ )
        {
            m_pPlayer.m_flNextAttack = g_Engine.time + 0.5f;
            self.SendWeaponAnim( HOLSTER );
            BaseClass.Holster( skiplocal );
        }

        void AttachToPlayer(CBasePlayer@ pPlayer)
        {
            if (self.m_iDefaultAmmo == 0)
            self.m_iDefaultAmmo = 1;

            BaseClass.AttachToPlayer(pPlayer);
        }

        void ItemPostFrame()
        {
            RechargeAmmo();
            BaseClass.ItemPostFrame();
        }

        void InactiveItemPostFrame()
        {
            RechargeAmmo();
            BaseClass.InactiveItemPostFrame();
        }

        void WeaponIdle()
        {
            if(m_reviveChargedTime != 0.0f)
            {
                m_reviveChargedTime = 0.0f;
                self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
                g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_ITEM, MED_SHOT_MISS, 1.0f, ATTN_NORM);
            }

            if(self.m_flTimeWeaponIdle > g_Engine.time)
                return;

            int iAnim;
            float flRand = g_PlayerFuncs.SharedRandomFloat(m_pPlayer.random_seed, 0.0f, 1.0f);

            if(flRand <= 0.2f)
            {
                iAnim = IDLE;
                self.m_flTimeWeaponIdle = g_Engine.time + 1.2*2;
            }
            else
            {
                iAnim = LONGIDLE;
                self.m_flTimeWeaponIdle = g_Engine.time + 2.4*2;
            }

            self.SendWeaponAnim(iAnim, 0, GetBodygroup());
        }

        // void GiveScorePoints(entvars_t@ pevAttacker, entvars_t@ pevInflictor, const float &in flDamage)
        // {
        //     float flFrags = Math.min( 4, (flDamage / pevAttacker.pev.max_health) * (4 * (pevAttacker.pev.max_health / pevInflictor.pev.max_health)) );
        //     pevAttacker.frags += flFrags;
        // }

        void PrimaryAttack()
        {
            TraceResult tr;
            Math.MakeVectors(m_pPlayer.pev.v_angle);
            Vector vecSrc = m_pPlayer.GetGunPosition();
            Vector vecEnd = vecSrc + g_Engine.v_forward * 32;

            g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr);

            if (tr.flFraction >= 1.0)
            {
                g_Utility.TraceHull(vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr);
            }

            CBaseMonster@ pMonster = (tr.pHit !is null) ? g_EntityFuncs.Instance( tr.pHit ).MyMonsterPointer() : null;
            int iAmmoLeft = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType);

            if(pMonster is null || iAmmoLeft <= 0)
                return;

            float flHealthAmount = Math.min(HEAL_AMMOUNT, pMonster.pev.max_health - pMonster.pev.health);

            // slowly lower pitch
            if (iAmmoLeft < HEAL_AMMOUNT*2) 
            {
                flHealthAmount = Math.min(HEAL_AMMOUNT*0.5f, flHealthAmount);
            }
            else if (iAmmoLeft < HEAL_AMMOUNT) 
            {
                flHealthAmount = Math.min(HEAL_AMMOUNT*0.2f, flHealthAmount);
            }

            flHealthAmount = int(Math.Ceil(Math.min(float(iAmmoLeft), flHealthAmount)));

            if(pMonster.IsAlive() && pMonster.IRelationship( m_pPlayer ) == R_AL && CanHealTarget(pMonster) && flHealthAmount > 0)
            {
                m_pPlayer.SetAnimation(PLAYER_ATTACK1);
                self.SendWeaponAnim(SHORTUSE, 0, GetBodygroup());
                m_pPlayer.m_iWeaponVolume = VOLUME;

                pMonster.TakeHealth(flHealthAmount, DMG_MEDKITHEAL);
                // m_pPlayer.GetPointsForDamage(-flHealthAmount);

                //https://github.com/KernCore91/-SC-Cry-of-Fear-Weapons-Project/blob/aeb624bd55b890c90df20f993a76979c86eac25b/scripts/maps/cof/special/weapon_cofsyringe.as#L306-L307
				pMonster.Forget( bits_MEMORY_PROVOKED | bits_MEMORY_SUSPICIOUS );
				pMonster.ClearSchedule();

                m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, int(Math.Ceil(iAmmoLeft - flHealthAmount)));
            
                int pitch = 100;

                if (iAmmoLeft < HEAL_AMMOUNT * 2) 
                {
                    pitch = int((float(iAmmoLeft) / (HEAL_AMMOUNT*2)) * 20.5f + 80);
                }

                g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, MED_SHOT_HEAL, 1.0f, ATTN_NORM, 0, pitch);

                self.m_flNextPrimaryAttack = g_Engine.time + 0.5f;
            }
        }

        void SecondaryAttack()
        {
            if (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= REVIVE_COST) 
            {
                g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_ITEM, MED_SHOT_MISS, 1.0f, ATTN_NORM);
                self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
                m_reviveChargedTime = 0;
                return;
            }

            CBaseMonster@ pBestTarget = null;
	        float flBestDist = 1000000.0f;

            CBaseEntity@ pEntity;
            while((@pEntity = g_EntityFuncs.FindEntityInSphere(pEntity, m_pPlayer.GetOrigin(), REVIVE_RADIUS, "*", "classname")) !is null)
            {
                CBaseMonster@ pMonster = (pEntity !is null) ? pEntity.MyMonsterPointer() : null;

                if(pMonster is null || pMonster.IRelationship( m_pPlayer ) >= R_NO || pMonster.IsAlive() || (!pMonster.IsMonster() && !pMonster.IsPlayer()) || pMonster.IsMachine())
                    continue;

                if(pMonster.IsPlayer() && pMonster.pev.iuser1 == 1)
                    continue; // don't revive spectators

                float flDist = (pMonster.pev.origin - m_pPlayer.pev.origin).Length();

                if(pBestTarget is null)
                {
                    flBestDist = flDist;
                    @pBestTarget = pMonster;
                    continue;
                }

                // prefer reviving players over monsters, which sometimes have death poses far from where they died
                bool isBetterClass = pMonster.IsPlayer() && !pBestTarget.IsPlayer();
                bool isWorseClass = !pMonster.IsPlayer() && pBestTarget.IsPlayer();

                if ((flDist < flBestDist && !isWorseClass) || isBetterClass) 
                {
                    flBestDist = flDist;
                    @pBestTarget = pMonster;
                }
            }

            if (pBestTarget is null) 
            {
                g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_ITEM, MED_SHOT_MISS, 1.0f, ATTN_NORM);
                self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
                m_reviveChargedTime = 0;
                return;
            }

            if (pBestTarget.m_fCanFadeStart) 
            {
                pBestTarget.pev.renderamt = 255;
                pBestTarget.pev.nextthink = g_Engine.time + 2.0f;
            }

            if (m_reviveChargedTime == 0.0f) 
            {
                self.SendWeaponAnim(LONGUSE, 0, GetBodygroup());
                m_reviveChargedTime = g_Engine.time + 2.0f;
                g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, MED_SHOT_ERROR, 1.0f, ATTN_NORM);
                return;
            }

            if (m_reviveChargedTime < g_Engine.time)
            {
                m_reviveChargedTime = 0;
                m_pPlayer.SetAnimation(PLAYER_ATTACK1);
                self.SendWeaponAnim(SHORTUSE, 0, GetBodygroup());
                g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, MED_SHOT_REVIVE, 1.0f, ATTN_NORM);
                self.m_flNextSecondaryAttack = g_Engine.time + 2.0f;

                pBestTarget.Revive();
                pBestTarget.pev.health = (pBestTarget.pev.max_health / 2);

                // m_pPlayer.GetPointsForDamage(-pBestTarget.pev.health);

                //https://github.com/KernCore91/-SC-Cry-of-Fear-Weapons-Project/blob/aeb624bd55b890c90df20f993a76979c86eac25b/scripts/maps/cof/special/weapon_cofsyringe.as#L306-L307
				pBestTarget.Forget( bits_MEMORY_PROVOKED | bits_MEMORY_SUSPICIOUS );
				pBestTarget.ClearSchedule();

                m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - REVIVE_COST);
            }

            self.m_flNextSecondaryAttack = g_Engine.time + 2.0f;
        }

        bool CanHealTarget(CBaseEntity@ pEntity)
        {
            CBaseMonster@ pMonster = (pEntity !is null) ? pEntity.MyMonsterPointer() : null;

            if(pMonster is null)
                return false;
            
            if(pMonster.pev.health >= pMonster.pev.max_health)
                return false;

            return true;
        }

        void RechargeAmmo()
        {
            if(m_rechargeTime != 0.0f)
            {
                while(m_rechargeTime < g_Engine.time)
                {   
                    m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) + RECHARGE_AMOUNT);

                    if(m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > MAX_CARRY)
                    {
                        m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, MAX_CARRY);
                        m_rechargeTime = g_Engine.time + RECHARGE_DELAY;
                        break;
                    }

                    m_rechargeTime = m_rechargeTime + RECHARGE_DELAY;
                }
            }
        }
    }

    string GetName()
    {
        return "weapon_bts_medkit";
    }

    string GetAmmoName()
    {
        return "ammo_medkit";
    }

    void Register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "BTS_MEDKIT::weapon_bts_medkit", GetName() );
        g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", "health", "", GetAmmoName() );
    }
}