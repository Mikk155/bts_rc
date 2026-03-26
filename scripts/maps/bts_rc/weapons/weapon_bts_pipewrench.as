/*
 * Maintenance Pipewrench
 */
// Rewrited by Rizulix for bts_rc (january 2025)
// Revisited by AraseFiq._

namespace weapon_bts_pipewrench
{
	enum pipe_e
	{
		IDLE1 = 0,
		IDLE2,
		IDLE3,
		DRAW,
		HOLSTER,
		ATTACK1HIT,
		ATTACK1MISS,
		ATTACK2HIT,
		ATTACK2MISS,
		ATTACK3HIT,
		ATTACK3MISS,
		ATTACKBIGWIND,
		ATTACKBIGHIT,
		ATTACKBIGMISS,
		ATTACKBIGLOOP
	};

	// array<string> SOUNDS = {
	//  "weapons/wrench_draw.wav",
	//  "weapons/wrench_pull.wav"
	// };
	// Weapon info
	int MAX_CARRY = -1;
	int MAX_CLIP = WEAPON_NOCLIP;
	int DEFAULT_GIVE = 0;
	int AMMO_DROP = MAX_CLIP;
	int WEIGHT = 10;
	// Weapon HUD
	int SLOT = 0;
	int POSITION = 5;
	// Vars
	float RANGE = 32.0f;
	float DAMAGE = 14.0f;
	float RANGE2 = 35.0f;
	float DAMAGE2 = 28.0f;

	class weapon_bts_pipewrench : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon, bts_rc_base_melee
	{
		private CBasePlayer @m_pPlayer
		{
			get const
			{
				return get_player();
			}
		}
		
		string GetName()
		{
		  return "weapon_bts_pipewrench";
		}


		private bool m_fWhack;

		void Spawn()
		{
			// pev.fuser2 = Math.max( pev.fuser2, DAMAGE2 );
			g_EntityFuncs.SetModel(self, self.GetW_Model("models/bts_rc/weapons/w_pipe_wrench.mdl"));
			self.m_iDefaultAmmo = DEFAULT_GIVE;
			self.FallInit();
			m_fWhack = false;
		}

		bool GetItemInfo(ItemInfo& out info)
		{
			info.iMaxAmmo1 = MAX_CARRY;
			info.iAmmo1Drop = AMMO_DROP;
			info.iMaxAmmo2 = -1;
			info.iAmmo2Drop = -1;
			info.iMaxClip = MAX_CLIP;
			info.iSlot = SLOT;
			info.iPosition = POSITION;
			info.iId = g_ItemRegistry.GetIdForName(pev.classname);
			info.iFlags = m_flags;
			info.iWeight = WEIGHT;
			return true;
		}

		bool Deploy()
		{
			return bts_deploy("models/bts_rc/weapons/v_pipe_wrench.mdl", "models/bts_rc/weapons/p_pipe_wrench.mdl", DRAW, "crowbar", 1, 0.6f);
		}

		void Holster(int skiplocal = 0)
		{
			SetThink(null);
			m_fWhack = false;
			BaseClass.Holster(skiplocal);
		}

		void ItemPostFrame()
		{
			if (m_fWhack && (m_pPlayer.pev.button & IN_ATTACK2) == 0)
			{
				m_pPlayer.m_flNextAttack = 0.5f; // ( 29.0f / 30.0f );
				m_fWhack = false;
				BigSwing();
			}
			BaseClass.ItemPostFrame();
		}

		void TertiaryAttack()
		{
			if (int(g_EngineFuncs.CVarGetFloat("mp_dropweapons")) == 0)
			  return;

			if (!m_fWhack)
			{
				m_pPlayer.m_flNextAttack = 1.0f; // ( 26.0f / 30.0f );
				self.SendWeaponAnim(ATTACKBIGWIND, 0, pev.body);
				ForceAnimation(25, 28);			  // ref_cock_wrench, crouch_cock_wrench
			}
			else
				ForceAnimation(26, 29);			  // ref_hold_wrench, crouch_hold_wrench

			m_fWhack = true;
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.0f;

			SetThink(ThinkFunction(Throw));
			pev.nextthink = g_Engine.time + 0.9f;
		}
	
		  // THROW LOGIC STARTS HERE!!!
		private void Throw()
		{
			Math.MakeVectors(m_pPlayer.pev.v_angle);
			CBaseEntity@ pOwner = self.m_hPlayer.GetEntity();
			Vector vecSrc = m_pPlayer.GetGunPosition() + (g_Engine.v_right * 8.0f) + (g_Engine.v_up * -8.0f);

			// This will be null when dropweapons is disabled
			if (m_pPlayer.DropItem(GetName()) is null)
			  return;

			SetThink(ThinkFunction(DummyThink));
			pev.nextthink = g_Engine.time + 0.15f;
			SetTouch(TouchFunction(ThrowTouch));

			g_EntityFuncs.SetOrigin(self, vecSrc);
			pev.velocity = (g_Engine.v_forward * 1200.0f) + (g_Engine.v_up * 2.53f);
			pev.angles = Math.VecToAngles(pev.velocity.Normalize());
			pev.angles.z -= 90.0f;
			pev.avelocity = Vector(-800.0f, 0.0f, 0.0f);
			pev.movetype = MOVETYPE_BOUNCE;
			pev.solid = SOLID_BBOX;
			pev.effects &= ~EF_NODRAW;
			pev.friction = 0.3f;
			@pev.owner = pOwner.edict();
			pev.spawnflags |= SF_DODAMAGE;
		}

		private void ThrowThink()
		{
			pev.nextthink = g_Engine.time + 0.1f;

			if ((pev.flags & FL_ONGROUND) != 0)
			{
			  Math.MakeVectors(pev.angles);
			  pev.angles.y = Math.VecToAngles(g_Engine.v_forward).y;

			  // Lie flat
			  pev.angles.x = 0.0f;
			  pev.angles.z = 0.0f;

			  // This is equivalent to
			  // SetThink( &CBasePlayerItem::FallThink );
			  // Why? No idea... but it seems that the same applies for Touch
			  SetThink(null);
			}
		}

		private void ThrowTouch(CBaseEntity@ pOther)
		{
			if (pOther.pev.ClassNameIs(pev.classname))
			  return;

			// Don't set Touch to DefaultTouch because later
			// when the surface is a lift we will not clank on bounce
			if (pev.velocity.Length() < 10.0f)
			  self.DefaultTouch(pOther); // This do the weapon drop sound

			if (pOther.edict() is pev.owner)
			  return;

			// Add a bit of static friction
			pev.velocity = pev.velocity * 0.5f;
			pev.avelocity = pev.avelocity * 0.5f;
			pev.angles.z = 0.0f;

			if ((pev.spawnflags & SF_DODAMAGE) != 0)
			{
			  pev.angles.z = 320.0f;
			  pev.spawnflags &= ~SF_DODAMAGE;

			  TraceResult tr = g_Utility.GetGlobalTrace();
			  if (pev.owner !is null)
			  {
				// AdamR: Custom damage option
				float flDamage = DAMAGE2;
				if (self.m_flCustomDmg > 0.0f)
				  flDamage = self.m_flCustomDmg;
				// AdamR: End

				g_WeaponFuncs.ClearMultiDamage();
				pOther.TraceAttack(pev.owner.vars, flDamage * 1.0f, g_Engine.v_forward, tr, DMG_CLUB);
				g_WeaponFuncs.ApplyMultiDamage(pev, pev.owner.vars);
			  }

			  if (pOther.IsBSPModel())
			  {
				g_Utility.Sparks(tr.vecEndPos);
				g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_VOICE, "debris/metal2.wav", 1.0f, ATTN_NORM, 0, 90 + Math.RandomLong(0, 29));
			  }
			  else
			  {
				switch (Math.RandomLong(0, 1))
				{
				case 0:
				  g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_ITEM, "weapons/pwrench_hitbod1.wav", 1.0f, ATTN_NORM, 0, PITCH_NORM);
				  break;
				case 1:
				  g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_ITEM, "weapons/pwrench_hitbod2.wav", 1.0f, ATTN_NORM, 0, PITCH_NORM);
				  break;
				}
			  }

			  g_Utility.TraceLine(pev.origin, pev.origin - Vector(0.0f, 0.0f, 5.0f), ignore_monsters, self.edict(), tr);
			  if (pOther.pev.ClassNameIs("worldspawn") && tr.flFraction >= 1.0f)
			  {
				SetThink(ThinkFunction(UnstuckThrow));
				pev.nextthink = g_Engine.time + 0.3f;
				SetTouch(TouchFunction(DummyTouch));

				// If what we hit is static architecture, can stay around for a while.
				pev.movedir = pev.velocity.Normalize();
				g_EntityFuncs.SetOrigin(self, pev.origin + (pev.movedir * -5.0f));

				pev.velocity = g_vecZero;
				pev.avelocity = g_vecZero;
				pev.angles = Math.VecToAngles(pev.movedir);
				pev.angles.z -= 90.0f;
				pev.movetype = MOVETYPE_FLY;
			  }
			  else
			  {
				SetThink(ThinkFunction(ThrowThink));
				pev.nextthink = g_Engine.time + 0.1f;
			  }
			  return;
			}

		  if (pOther.IsBSPModel())
			g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_VOICE, "debris/metal2.wav", 1.0f, ATTN_NORM, 0, 90 + Math.RandomLong(0, 29));
		}

		private void UnstuckThrow()
		{
			SetThink(ThinkFunction(ThrowThink));
			pev.nextthink = g_Engine.time + 0.1f;
			SetTouch(TouchFunction(ThrowTouch));

			pev.velocity = pev.movedir * -64.0f;
			pev.avelocity = Vector(200.0f, 0.0f, 0.0f);
			pev.movetype = MOVETYPE_BOUNCE;
		}

		  // Guess why these exists? :D
		  private void DummyThink() { }

		private void DummyTouch(CBaseEntity@ pOther) { }
		// THROW LOGIC ENDS HERE!!!

		void SecondaryAttack()
		{
			if (!m_fWhack)
			{
				m_pPlayer.m_flNextAttack = 0.75f; // ( 26.0f / 30.0f );
				self.SendWeaponAnim(ATTACKBIGWIND, 0, pev.body);
				ForceAnimation(25, 28);			  // ref_cock_wrench, crouch_cock_wrench
			}
			else
				ForceAnimation(26, 29);			  // ref_hold_wrench, crouch_hold_wrench

			m_fWhack = true;
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.1f;
			self.m_flTimeWeaponIdle = g_Engine.time + 0.5f;
		}

		void WeaponIdle()
		{
			self.ResetEmptySound();
			m_pPlayer.GetAutoaimVector(AUTOAIM_5DEGREES);

			if (self.m_flTimeWeaponIdle > g_Engine.time)
				return;

			switch (Math.RandomLong(0, 2))
			{
				case 0:
					self.SendWeaponAnim(IDLE1, 0, pev.body);
					self.m_flTimeWeaponIdle = g_Engine.time + 2.69f;
					break;
				case 1:
					self.SendWeaponAnim(IDLE2, 0, pev.body);
					self.m_flTimeWeaponIdle = g_Engine.time + 5.33f;
					break;
				case 2:
					self.SendWeaponAnim(IDLE3, 0, pev.body);
					self.m_flTimeWeaponIdle = g_Engine.time + 5.33f;
					break;
			}
		}

		private bool Swing(bool fFirst)
		{
			bool fDidHit = false;

			TraceResult tr;

			Math.MakeVectors(m_pPlayer.pev.v_angle);
			Vector vecSrc = m_pPlayer.GetGunPosition();
			Vector vecEnd = vecSrc + g_Engine.v_forward * RANGE;

			g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr);

			if (tr.flFraction >= 1.0f)
			{
				g_Utility.TraceHull(vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr);
				if (tr.flFraction < 1.0f)
				{
					// Calculate the point of intersection of the line (or hull) and the object we hit
					// This is and approximation of the "best" intersection
					CBaseEntity @pHit = g_EntityFuncs.Instance(tr.pHit);
					if (pHit is null || pHit.IsBSPModel())
						g_Utility.FindHullIntersection(vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict());
					vecEnd = tr.vecEndPos; // This is the point on the actual surface (the hull could have hit space)
				}
			}

			bool is_trained_personal = g_PlayerClass.is_trained_personal(m_pPlayer);

			if (tr.flFraction >= 1.0f)
			{
				if (fFirst)
				{
					// miss
					switch ((m_iSwing++) % 3)
					{
						case 0:
							self.SendWeaponAnim(ATTACK1MISS, 0, pev.body);
							break;
						case 1:
							self.SendWeaponAnim(ATTACK2MISS, 0, pev.body);
							break;
						case 2:
							self.SendWeaponAnim(ATTACK3MISS, 0, pev.body);
							break;
					}
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + (is_trained_personal ? 0.5f : 0.75f);
					self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

					// play wiff or swish sound
					g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "weapons/pwrench_miss1.wav", 1.0f, ATTN_NORM, 0, 94 + Math.RandomLong(0, 0xF));

					// player "shoot" animation
					m_pPlayer.SetAnimation(PLAYER_ATTACK1);
				}
			}
			else
			{
				// hit
				fDidHit = true;

				CBaseEntity @pEntity = g_EntityFuncs.Instance(tr.pHit);

				switch (((m_iSwing++) % 2) + 1)
				{
					case 0:
						self.SendWeaponAnim(ATTACK1HIT, 0, pev.body);
						break;
					case 1:
						self.SendWeaponAnim(ATTACK2HIT, 0, pev.body);
						break;
					case 2:
						self.SendWeaponAnim(ATTACK3HIT, 0, pev.body);
						break;
				}

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + (is_trained_personal ? 0.5f : 0.75f);
				self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

				// player "shoot" animation
				m_pPlayer.SetAnimation(PLAYER_ATTACK1);

				g_WeaponFuncs.ClearMultiDamage();

				if (self.m_flNextPrimaryAttack + 1.0f < g_Engine.time)
					pEntity.TraceAttack(m_pPlayer.pev, DAMAGE, g_Engine.v_forward, tr, DMG_CLUB);		 // first swing does full damage
				else
					pEntity.TraceAttack(m_pPlayer.pev, DAMAGE * 0.5f, g_Engine.v_forward, tr, DMG_CLUB); // subsequent swings do 50% (Changed -Sniper) (Half)

				g_WeaponFuncs.ApplyMultiDamage(m_pPlayer.pev, m_pPlayer.pev);

				// play thwack, smack, or dong sound
				float flVol = 1.0f;
				bool fHitWorld = true;

				// for monsters or breakable entity smacking speed function
				if (pEntity !is null)
				{
					if (pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED)
					{
						// aone
						if (pEntity.IsPlayer()) // lets pull them
							pEntity.pev.velocity = pEntity.pev.velocity + (pev.origin - pEntity.pev.origin).Normalize() * 120.0f;
						// end aone

						// play thwack or smack sound
						switch (Math.RandomLong(1, 3))
						{
							case 3:
								g_SoundSystem.EmitSound(m_pPlayer.edict(), CHAN_WEAPON, "weapons/pwrench_hitbod3.wav", 1.0f, ATTN_NORM);
								break;
							case 2:
								g_SoundSystem.EmitSound(m_pPlayer.edict(), CHAN_WEAPON, "weapons/pwrench_hitbod2.wav", 1.0f, ATTN_NORM);
								break;
							default:
								g_SoundSystem.EmitSound(m_pPlayer.edict(), CHAN_WEAPON, "weapons/pwrench_hitbod1.wav", 1.0f, ATTN_NORM);
								break;
						}

						m_pPlayer.m_iWeaponVolume = 128;

						if (!pEntity.IsAlive())
							return true;
						else
							flVol = 0.1f;

						fHitWorld = false;
					}
				}

				// play texture hit sound
				// UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

				if (fHitWorld)
				{
					g_SoundSystem.PlayHitSound(tr, vecSrc, vecSrc + (vecEnd - vecSrc) * 2.0f, BULLET_PLAYER_CROWBAR);

					// also play crowbar strike
					switch (Math.RandomLong(1, 2))
					{
						case 2:
							g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "weapons/pwrench_hit2.wav", 1.0f, ATTN_NORM, 0, 98 + Math.RandomLong(0, 3));
							break;
						default:
							g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "weapons/pwrench_hit1.wav", 1.0f, ATTN_NORM, 0, 98 + Math.RandomLong(0, 3));
							break;
					}
				}

				// delay the decal a bit
				m_trHit = tr;
				bts_post_attack(tr);
				SetThink(ThinkFunction(this.Smack));
				pev.nextthink = g_Engine.time + 0.2f;

				m_pPlayer.m_iWeaponVolume = int(flVol * 64);
			}
			return fDidHit;
		}

		private void BigSwing()
		{
			TraceResult tr;

			Math.MakeVectors(m_pPlayer.pev.v_angle);
			Vector vecSrc = m_pPlayer.GetGunPosition();
			Vector vecEnd = vecSrc + g_Engine.v_forward * RANGE2;

			g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr);

			g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "weapons/pwrench_big_miss.wav", Math.RandomFloat(0.98f, 1.0f), ATTN_NORM, 0, 98 + Math.RandomLong(0, 3));

			if (tr.flFraction >= 1.0f)
			{
				g_Utility.TraceHull(vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr);
				if (tr.flFraction < 1.0f)
				{
					// Calculate the point of intersection of the line (or hull) and the object we hit
					// This is and approximation of the "best" intersection
					CBaseEntity @pHit = g_EntityFuncs.Instance(tr.pHit);
					if (pHit is null || pHit.IsBSPModel())
						g_Utility.FindHullIntersection(vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict());
					vecEnd = tr.vecEndPos; // This is the point on the actual surface (the hull could have hit space)
				}
			}

			if (tr.flFraction >= 1.0f)
			{
				// miss
				m_iSwing++;
				self.SendWeaponAnim(ATTACKBIGMISS, 0, pev.body);

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.85f;
				self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

				// play wiff or swish sound
				g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "weapons/pwrench_big_miss.wav", 1.0f, ATTN_NORM, 0, 94 + Math.RandomLong(0, 0xF));

				// player "shoot" animation
				ForceAnimation(27, 30); // ref_shoot_wrench, crouch_shoot_wrench
			}
			else
			{
				// hit
				CBaseEntity @pEntity = g_EntityFuncs.Instance(tr.pHit);

				m_iSwing++;
				self.SendWeaponAnim(ATTACKBIGHIT, 0, pev.body);

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.64f;
				self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

				// player "shoot" animation
				ForceAnimation(27, 30); // ref_shoot_wrench, crouch_shoot_wrench

				// AdamR: Custom damage option
				float flDamage = DAMAGE2;
				if (pev.fuser2 > 0.0f)
					flDamage = pev.fuser2;
				// AdamR: End

				g_WeaponFuncs.ClearMultiDamage();

				if (self.m_flNextPrimaryAttack + 1.0f < g_Engine.time)
					pEntity.TraceAttack(m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB);		   // first swing does full damage
				else
					pEntity.TraceAttack(m_pPlayer.pev, flDamage * 0.5f, g_Engine.v_forward, tr, DMG_CLUB); // subsequent swings do 50% (Changed -Sniper) (Half)

				g_WeaponFuncs.ApplyMultiDamage(m_pPlayer.pev, m_pPlayer.pev);

				// play thwack, smack, or dong sound
				float flVol = 1.0f;
				bool fHitWorld = true;

				// for monsters or breakable entity smacking speed function
				if (pEntity !is null)
				{
					if (pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED)
					{
						// aone
						if (pEntity.IsPlayer()) // lets pull them
							pEntity.pev.velocity = pEntity.pev.velocity + (pev.origin - pEntity.pev.origin).Normalize() * 120.0f;
						// end aone

						// play thwack or smack sound
						switch (Math.RandomLong(1, 2))
						{
							case 2:
								g_SoundSystem.EmitSound(m_pPlayer.edict(), CHAN_WEAPON, "weapons/pwrench_big_hitbod2.wav", 1.0f, ATTN_NORM);
								break;
							default:
								g_SoundSystem.EmitSound(m_pPlayer.edict(), CHAN_WEAPON, "weapons/pwrench_big_hitbod1.wav", 1.0f, ATTN_NORM);
								break;
						}

						m_pPlayer.m_iWeaponVolume = 128;

						if (!pEntity.IsAlive())
							return;
						else
							flVol = 0.1f;

						fHitWorld = false;
					}
				}

				// play texture hit sound
				// UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

				if (fHitWorld)
				{
					g_SoundSystem.PlayHitSound(tr, vecSrc, vecSrc + (vecEnd - vecSrc) * 2.0f, BULLET_PLAYER_CROWBAR);

					// also play crowbar strike
					switch (Math.RandomLong(1, 2))
					{
						case 2:
							g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "weapons/pwrench_hit2.wav", 1.0f, ATTN_NORM, 0, 98 + Math.RandomLong(0, 3));
							break;
						default:
							g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "weapons/pwrench_hit1.wav", 1.0f, ATTN_NORM, 0, 98 + Math.RandomLong(0, 3));
							break;
					}
				}

				Math.MakeVectors(m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
				m_pPlayer.pev.punchangle.x = -2.0f;

				// delay the decal a bit
				g_WeaponFuncs.DecalGunshot(tr, BULLET_PLAYER_CROWBAR);
				m_pPlayer.m_iWeaponVolume = int(flVol * 512);
			}
		}

		private void ForceAnimation(int iStandSequence, int iDuckSequence)
		{
			int iGaitSequence;
			switch (m_pPlayer.m_Activity)
			{
				case ACT_HOVER:
				case ACT_SWIM:
				case ACT_HOP:
				case ACT_LEAP:
				case ACT_DIESIMPLE:
					break;
				default:
					iGaitSequence = m_pPlayer.pev.gaitsequence;
					m_pPlayer.m_Activity = ACT_RELOAD;
					m_pPlayer.pev.sequence = ((m_pPlayer.pev.flags & FL_DUCKING) != 0) ? iDuckSequence : iStandSequence;
					m_pPlayer.pev.gaitsequence = iGaitSequence;
					m_pPlayer.pev.frame = 0.0f;
					m_pPlayer.ResetSequenceInfo();
					break;
			}
		}
	}
}
