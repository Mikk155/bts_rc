/*
	Half-Life: Recovery's/Team Fortress Classic's Flamethrower (BTS_RC Port)
	Models: Valve Software, Gamit (Models rigging)
	Script: KernCore, Nero0, Rizulix, Nevermore2790
	Sounds: Valve Software
	Sprites: Valve Software
*/

namespace BTS_FLAMETHROWER
{

	const int DEFAULT_GIVE = 40;
	const int MAX_CLIP = 40;
	const int MAX_AMMO = 120;
	const float DAMAGE = 18; // 28?
	const float DAMAGE2 = 108;
	const float DAMAGE_RADIUS = 240;
	const float TIME_DELAY = 0.1;
	const float TIME_DELAY2 = 1.25;
	const float TIME_DRAW = 0.7;   // 1.0
	const float TIME_IDLE = 6.7;
	const float TIME_FIRE_TO_IDLE = 0.5;
	const float TIME_RELOAD = 3.5; // 3.0
	const float FLAME_SPEED = 800; // 4096 max
	const float FLAME_BALL_VELOCITY = 900;
	const Vector2D RECOIL_STANDING_X = Vector2D(-1.75, 1.75);
	const Vector2D RECOIL_STANDING_Y = Vector2D(0, 0);
	const Vector2D RECOIL_DUCKING_X = Vector2D(0, 0);
	const Vector2D RECOIL_DUCKING_Y = Vector2D(0, 0);
	const Vector OFFSET = Vector(34.333031, 12.009664, -5.616758);

	const int FLAMETHROWER_SLOT = 5;
	const int FLAMETHROWER_POSITION = 5;
	const int FLAMETHROWER_WEIGHT = 30;

	const string V_MODEL = "models/bts_rc/weapons/v_flame.mdl";
	const string P_MODEL = "models/bts_rc/weapons/p_flame.mdl";
	const string W_MODEL = "models/bts_rc/weapons/w_flame.mdl";
	const string A_MODEL = "models/hunger/w_gas.mdl";

	const string SPRITE_FLAME = "sprites/bts_rc/fthrow.spr";

	const string FLAME_SHOOT = "bts_rc/weapons/flmfire2.wav";
	const string FLAME_SHOOT2 = "bts_rc/weapons/flmgrexp.wav";

	enum flamethrower_e
	{
		FLTHRW_IDLE1 = 0,
		FLTHRW_FIDGET1,
		FLTHRW_ALTFIREON,
		FLTHRW_ALTFIRECYCLE,
		FLTHRW_ALTFIREOFF,
		FLTHRW_FIRE1,
		FLTHRW_FIRE2,
		FLTHRW_FIRE3,
		FLTHRW_FIRE4,
		FLTHRW_DRAW,
		FLTHRW_HOLSTER
	};

	class weapon_bts_flamethrower : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon
	{
		private CBasePlayer @m_pPlayer
		{
			get const
			{
				return get_player();
			}
		}

		void Spawn()
		{
			self.Precache();
			g_EntityFuncs.SetModel(self, W_MODEL);
			self.m_iDefaultAmmo = DEFAULT_GIVE;

			pev.scale = 1.5;

			self.FallInit();
		}

		void Precache()
		{
			self.PrecacheCustomModels();

			g_Game.PrecacheModel(V_MODEL);
			g_Game.PrecacheModel(P_MODEL);
			g_Game.PrecacheModel(W_MODEL);
			g_Game.PrecacheModel(A_MODEL);
			g_Game.PrecacheModel(SPRITE_FLAME);

			g_Game.PrecacheOther(GetAmmoName());

			g_SoundSystem.PrecacheSound(FLAME_SHOOT);
			g_SoundSystem.PrecacheSound(FLAME_SHOOT2);
			g_SoundSystem.PrecacheSound("hlclassic/weapons/357_cock1.wav");

			g_Game.PrecacheGeneric("sprites/bts_rc/weapons/weapon_bts_flamethrower.txt");
			g_Game.PrecacheGeneric("sprites/bts_rc/fthrow.spr");
		}

		bool GetItemInfo(ItemInfo& out info)
		{
			info.iMaxAmmo1 = MAX_AMMO;
			info.iAmmo1Drop = MAX_CLIP;
			info.iMaxClip = WEAPON_NOCLIP;
			info.iSlot = FLAMETHROWER_SLOT;
			info.iPosition = FLAMETHROWER_POSITION;
			info.iWeight = FLAMETHROWER_WEIGHT;

			return true;
		}

		bool AddToPlayer(CBasePlayer @pPlayer)
		{
			if (!BaseClass.AddToPlayer(pPlayer))
				return false;

			NetworkMessage message(MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict());
			message.WriteLong(g_ItemRegistry.GetIdForName(pev.classname));
			message.End();

			return true;
		}

		bool PlayEmptySound()
		{
			if (self.m_bPlayEmptySound)
			{
				self.m_bPlayEmptySound = false;
				g_SoundSystem.EmitSound(m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/357_cock1.wav", VOL_NORM, ATTN_NORM);
			}

			return false;
		}

		bool Deploy()
		{
			return bts_deploy("models/bts_rc/weapons/v_flame.mdl", "models/bts_rc/weapons/p_flame.mdl", FLTHRW_DRAW, "egon", 1);
		}

		void PrimaryAttack()
		{
			FireFlame();
		}

		void FireFlame()
		{
			// don't fire underwater
			if (m_pPlayer.pev.waterlevel == 3)
			{
				self.PlayEmptySound();
				self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
				return;
			}

			int ammo1 = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType);
			if (ammo1 <= 0)
			{
				self.PlayEmptySound();
				self.m_flNextPrimaryAttack = g_Engine.time + 0.75f;
				return;
			}

			--ammo1;
			m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, ammo1); // ammo1 = 1

			g_SoundSystem.EmitSound(m_pPlayer.edict(), CHAN_WEAPON, FLAME_SHOOT, 1, ATTN_NORM);

			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;

			self.SendWeaponAnim(Math.RandomLong(FLTHRW_FIRE1, FLTHRW_FIRE4), 0, pev.body);
			m_pPlayer.SetAnimation(PLAYER_ATTACK1);

			bool is_trained_personal = g_PlayerClass.is_trained_personal(m_pPlayer);

			m_pPlayer.pev.punchangle.x -= is_trained_personal ? Math.RandomLong(-2, 2) : Math.RandomLong(-6, 6);
			m_pPlayer.pev.punchangle.y -= is_trained_personal ? Math.RandomLong(-2, 2) : Math.RandomLong(-6, 6);

			Vector vecSrc = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 16 + g_Engine.v_right * 2 + g_Engine.v_up * -2;
			Vector vecDir = m_pPlayer.pev.v_angle * Vector(-1, 1, 1);

			CBaseEntity @pFlame = g_EntityFuncs.Create("flame_proj", vecSrc, vecDir, false, m_pPlayer.edict());

			Vector vecVelocity = g_Engine.v_forward * FLAME_SPEED;

			pFlame.pev.velocity = vecVelocity;
			pFlame.pev.angles = Math.VecToAngles(pFlame.pev.velocity.Normalize());
			pFlame.pev.avelocity.z = 10;

			self.m_flNextPrimaryAttack = g_Engine.time + TIME_DELAY;
			self.m_flTimeWeaponIdle = g_Engine.time + TIME_FIRE_TO_IDLE;
		}

		void WeaponIdle()
		{
			self.ResetEmptySound();
			m_pPlayer.GetAutoaimVector(AUTOAIM_5DEGREES);

			if (self.m_flTimeWeaponIdle > g_Engine.time)
				return;

			float flRand = g_PlayerFuncs.SharedRandomFloat(m_pPlayer.random_seed, 0.0f, 1.0f);
			if (flRand <= 0.5f)
			{
				self.SendWeaponAnim(FLTHRW_IDLE1, 0, pev.body);
				self.m_flTimeWeaponIdle = g_Engine.time + 4.2f; // ( 70.0f / 30.0f );
			}
			else
			{
				self.SendWeaponAnim(FLTHRW_FIDGET1, 0, pev.body);
				self.m_flTimeWeaponIdle = g_Engine.time + 3.6f; // ( 170.0f / 30.0f );
			}
		}
	}

	// Flame projectile entity
	class flame_proj : ScriptBaseEntity
	{
		void Spawn()
		{
			self.Precache();

			g_EntityFuncs.SetSize(self.pev, Vector(-1, -1, -1), Vector(1, 1, 1));
			g_EntityFuncs.SetOrigin(self, self.pev.origin);

			self.pev.movetype = MOVETYPE_FLY;
			self.pev.solid = SOLID_BBOX;
			self.pev.dmg = DAMAGE;

			SetTouch(TouchFunction(this.FlameTouch));
			SetThink(ThinkFunction(this.FlameThink));
			self.pev.nextthink = g_Engine.time + 0.1;
		}

		void Precache()
		{
			g_Game.PrecacheModel(SPRITE_FLAME);
		}

		void FlameThink()
		{
			Vector vecOrigin = pev.origin - pev.velocity.Normalize();

			// Star
			NetworkMessage m1(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
			m1.WriteByte(TE_EXPLOSION);
			m1.WriteCoord(vecOrigin.x);
			m1.WriteCoord(vecOrigin.y);
			m1.WriteCoord(vecOrigin.z - 10);
			m1.WriteShort(g_EngineFuncs.ModelIndex(SPRITE_FLAME));
			m1.WriteByte(8);  // scale
			m1.WriteByte(16); // framerate //15
			m1.WriteByte(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES);
			m1.End();

			self.pev.frame += 1.0f;

			// how far the flame sprite will travel before being removed
			if (self.pev.frame > 8)
			{
				self.pev.frame = 0;
				g_EntityFuncs.Remove(self);
				return;
			}

			pev.nextthink = g_Engine.time + 0.08;
		}

		// Fetch it from KernCore's INS2 proj_ins2flame.as
		void FlameTouch(CBaseEntity @pOther)
		{
			TraceResult tr = g_Utility.GetGlobalTrace();

			// OP4's Pit worm hack so it doesn't hit itself
			if (pOther.pev.modelindex == self.pev.modelindex && tr.pHit !is null && self.pev.modelindex != tr.pHit.vars.modelindex)
			{
				return;
			}

			/*
				// don't hit the guy that launched this flame
				if (pOther.edict() is self.pev.owner)
					return;
			*/

			entvars_t @pevOwner;
			if (self.pev.owner !is null)
				@pevOwner = @self.pev.owner.vars;
			else
				@pevOwner = self.pev;

			if (pOther.pev.takedamage != DAMAGE_NO && pOther.IsAlive())
			{
				g_WeaponFuncs.ClearMultiDamage();

				if (pOther.pev.classname == "monster_cleansuit_scientist" || pOther.IsMachine())
					pOther.TraceAttack(pevOwner, self.pev.dmg * 0.50, self.pev.velocity.Normalize(), tr, DMG_SLOWBURN | DMG_NEVERGIB);
				else if (pOther.pev.classname == "monster_gargantua" || pOther.pev.classname == "monster_babygarg")
					pOther.TraceAttack(pevOwner, self.pev.dmg * 0.45, self.pev.velocity.Normalize(), tr, DMG_BURN | DMG_SLOWBURN | DMG_NEVERGIB);
				else if (pOther.pev.model == "models/bts_rc/monsters/zombie_hev.mdl")
					pOther.TraceAttack(pevOwner, self.pev.dmg * 0.40, self.pev.velocity.Normalize(), tr, DMG_SLOWBURN | DMG_NEVERGIB);
				else
					pOther.TraceAttack(pevOwner, self.pev.dmg, self.pev.velocity.Normalize(), tr, DMG_BURN | DMG_SLOWBURN | DMG_NEVERGIB | DMG_POISON);

				g_WeaponFuncs.ApplyMultiDamage(self.pev, pevOwner);
			}

			if (pOther.IsBSPModel())
			{
				g_WeaponFuncs.RadiusDamage(self.GetOrigin() + Vector(0, 0, 4), self.pev, pevOwner, self.pev.dmg * 0.5, self.pev.dmg + 32, CLASS_NONE, DMG_BURN | DMG_SLOWBURN);
			}

			if (pOther is null || pOther.IsBSPModel())
				g_Utility.DecalTrace(tr, DECAL_SMALLSCORCH1 + Math.RandomLong(1, 2));

			SetTouch(null);

			self.pev.solid = SOLID_NOT;
			self.pev.movetype = MOVETYPE_NONE;
		}
	}

	class ammo_bts_fuel : ScriptBasePlayerAmmoEntity
	{
		void Spawn()
		{
			g_EntityFuncs.SetModel(self, A_MODEL);

			pev.scale = 1.0;

			BaseClass.Spawn();
		}

		bool AddAmmo(CBaseEntity @pOther)
		{
			int iGive;

			iGive = MAX_CLIP;

			if (pOther.GiveAmmo(iGive, "fuel", MAX_AMMO) != -1)
			{
				g_SoundSystem.EmitSound(self.edict(), CHAN_ITEM, "hlclassic/weapons/g_bounce3.wav", 1, ATTN_NORM);
				return true;
			}

			return false;
		}
	}

	string GetAmmoName()
	{
		return "ammo_bts_flamethrower";
	}

	void Register()
	{
		g_CustomEntityFuncs.RegisterCustomEntity("BTS_FLAMETHROWER::ammo_bts_fuel", GetAmmoName());
		g_CustomEntityFuncs.RegisterCustomEntity("BTS_FLAMETHROWER::flame_proj", "flame_proj");
		g_CustomEntityFuncs.RegisterCustomEntity("BTS_FLAMETHROWER::weapon_bts_flamethrower", "weapon_bts_flamethrower");
		g_ItemRegistry.RegisterWeapon("weapon_bts_flamethrower", "bts_rc/weapons", "fuel", "", GetAmmoName());
	}

}
