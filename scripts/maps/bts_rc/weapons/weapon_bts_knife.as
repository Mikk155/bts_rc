//weapon_knife Version 1.3
//Custom knife weapon from Opposing Force- created using weapon_hlcrowbar and weapon_csknife from the Counter Strike Weapons Pack by KernCore
//Usage: Primary attack - Normal operation similar to crowbar
//		  Secondary attack - Stab, does 3.5x the damage as primary but much slower. It can be delayed to time stabs
//		  Tertiary attack - Throws knife
namespace BTS_KNIFE
{

enum knife_e
{
	KNIFE_IDLE = 0,
	KNIFE_DRAW,
	KNIFE_HOLSTER,
	KNIFE_ATTACK1,
	KNIFE_ATTACK1MISS,
	KNIFE_ATTACK2,
	KNIFE_ATTACK2HIT,
	KNIFE_ATTACK3,
	KNIFE_ATTACK3HIT,
	KNIFE_IDLE2,
	KNIFE_IDLE3,
	KNIFE_CHARGE,
	KNIFE_STAB
};

array<string> HEV =
{
	"bts_helmet"
};

const array<string> STR_MDLS =
{
	"models/bts_rc/weapons/v_knife.mdl",
	"models/opfor/w_knife.mdl",
	"models/opfor/p_knife.mdl",
	"sprites/bts_rc/weapon_knife.spr"
};

const array<string> STR_SNDS =
{
	"weapons/knife1.wav",
	"weapons/knife2.wav",
	"weapons/knife3.wav",
	"weapons/knife_hit_wall1.wav",
	"weapons/knife_hit_wall2.wav",
	"weapons/knife_hit_flesh1.wav",
	"weapons/knife_hit_flesh2.wav",
	"weapons/cbar_miss1.wav"
};

float 
	flDmg = 17,
	flDmg_Sub = 10,
	flDmg_Heavy = 40,
	flDmg_Throw = 40;

const string V_MODEL = "models/bts_rc/weapons/v_knife.mdl";

class weapon_bts_knife : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{
	private float m_flBigSwingStart;
	private int m_iSwingMode = 0;
	private bool isPullingBack;
	int m_iSwing;
	TraceResult m_trHit;

	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set	   	{ self.m_hPlayer = EHandle( @value ); }
	}

	dictionary g_Models = 
	{
		{ "bts_barney", 0 }, { "bts_otis", 0 },
	{ "bts_barney2", 0 }, { "bts_barney3", 0 },
		{ "bts_scientist", 1 }, { "bts_scientist2", 1 },
	{ "bts_scientist3", 3 }, { "bts_scientist4", 1 },
	{ "bts_scientist5", 1 }, { "bts_scientist6", 1 },
		{ "bts_construction", 2 }, { "bts_helmet", 4 }
	};

	int GetBodygroup()
	{
		string modelName = g_EngineFuncs.GetInfoKeyBuffer( m_pPlayer.edict()).GetValue( "model" );

		switch( int( g_Models[ modelName ]) )
		{
			case 0:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 0, 0 );
				break;
			case 1:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 0, 1 );
				break;
			case 2:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 0, 2 );
				break;
			case 3:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 0, 3 );
				break;
			case 4:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 0, 4 );
				break;
		}

		return m_iCurBodyConfig;
	}

	void Spawn()
	{
		if( self.pev.dmg <= 0 )
			self.pev.dmg = flDmg;

		if( self.pev.fuser1 <= 0 )
			self.pev.fuser1 = flDmg_Sub;

		if( self.pev.fuser2 <= 0 )
			self.pev.fuser2 = flDmg_Heavy;

		if( self.pev.fuser3 <= 0 )
			self.pev.fuser3 = flDmg_Throw;

		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( "models/opfor/w_knife.mdl" ) );
		self.m_iClip			= -1;
		self.m_flCustomDmg		= self.pev.dmg;

		self.FallInit();//get ready to fall down.
	}

	void Precache()
	{
		for( uint i = 0; i < STR_MDLS.length(); i++ )
			g_Game.PrecacheModel( STR_MDLS[i] );
		
		g_Game.PrecacheGeneric( "sprites/bts_rc/weapon_knife.spr" );
		g_Game.PrecacheGeneric( "sprites/bts_rc/weapons/weapon_bts_knife.txt" );
		
		for( uint i = 0; i < STR_SNDS.length(); i++ )
			g_SoundSystem.PrecacheSound( STR_SNDS[i] );

		self.PrecacheCustomModels();
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= -1;
		info.iAmmo1Drop	= -1;
		info.iMaxAmmo2 	= -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot  	= 0;
		info.iPosition 	= 9;
		info.iId	 	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= 0;
		info.iWeight 	= 0;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;

		SetThink( null );

		NetworkMessage weapon( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			weapon.WriteLong( self.m_iId );
		weapon.End();

		return true;
	}

	float WeaponTimeBase()
	{
		return g_Engine.time;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/bts_rc/weapons/v_knife.mdl" ), self.GetP_Model( "models/opfor/p_knife.mdl" ), KNIFE_DRAW, "squeak", 0, GetBodygroup() );
	}

	void Holster( int skipLocal = 0 )
	{
		m_iSwing = 0;
		m_pPlayer.pev.viewmodel = string_t();
		SetThink( null );

		self.m_fInReload = false;
		BaseClass.Holster( skipLocal );
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_iSwingMode > 0 )
		{
			if( m_iSwingMode == 1 )
			{
				HeavySmack();
				m_iSwingMode = 2;
				m_flBigSwingStart = 0;
				isPullingBack = false;
			}
			else
				m_iSwingMode = 0;
		}

		if( m_iSwingMode == 0 )
		{
			m_pPlayer.m_szAnimExtension = "crowbar";
			switch( Math.RandomLong( 0, 2 ) )
			{
				case 0:
					self.SendWeaponAnim( KNIFE_IDLE, 0, GetBodygroup() );
					self.m_flTimeWeaponIdle = g_Engine.time + 2.69f;
					break;
				case 1:
					self.SendWeaponAnim( KNIFE_IDLE2, 0, GetBodygroup() );
					self.m_flTimeWeaponIdle = g_Engine.time + 5.33f;
					break;
				case 2:
					self.SendWeaponAnim( KNIFE_IDLE3, 0, GetBodygroup() );
					self.m_flTimeWeaponIdle = g_Engine.time + 5.33f;
					break;
			}
		}
	}
	
	void PrimaryAttack()
	{
		if( !Swing( 1 ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	bool Swing( int fFirst )
	{
		bool fDidHit = false;

		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 32;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if( tr.flFraction < 1.0 )
			{
				//Calculate the point of intersection of the line ( or hull ) and the object we hit
				//This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				vecEnd = tr.vecEndPos;	//This is the point on the actual surface ( the hull could have hit space )
			}
		}

		if( tr.flFraction >= 1.0 )
		{
			if( fFirst != 0 )
			{
				//miss
				switch( ( m_iSwing++ ) % 3 )
				{
					case 0:
						self.SendWeaponAnim( KNIFE_ATTACK1MISS, 0, GetBodygroup() ); break;
					case 1:
						self.SendWeaponAnim( KNIFE_ATTACK2, 0, GetBodygroup() ); break;
					case 2:
						self.SendWeaponAnim( KNIFE_ATTACK3, 0, GetBodygroup() ); break;
				}
				self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
				//play wiff or swish sound
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife3.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

				//player "shoot" animation
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
			}
		}
		else
		{
			//hit
			fDidHit = true;
			
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			switch( ( ( m_iSwing++ ) % 2 ) + 1 )
			{
				case 0:
					self.SendWeaponAnim( KNIFE_ATTACK1, 0, GetBodygroup() ); break;
				case 1:
					self.SendWeaponAnim( KNIFE_ATTACK2HIT, 0, GetBodygroup() ); break;
				case 2:
					self.SendWeaponAnim( KNIFE_ATTACK3HIT, 0, GetBodygroup() ); break;
			}

			//player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

			//AdamR: Custom damage option
			float flDamage = 18;
			if( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;
			//AdamR: End

			g_WeaponFuncs.ClearMultiDamage();
			if( self.m_flNextPrimaryAttack + 1 < g_Engine.time )
			{
				//first swing does full damage
				pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB );  
			}
			else
			{
				//subsequent swings do 50% ( Changed -Sniper) ( Half )
				pEntity.TraceAttack( m_pPlayer.pev, self.pev.fuser1, g_Engine.v_forward, tr, DMG_CLUB );  
			}	
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			//m_flNextPrimaryAttack = gpGlobals->time + 0.30; //0.25

			//play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				//difference in model for nextprimaryattack
				string modelName = g_EngineFuncs.GetInfoKeyBuffer( m_pPlayer.edict()).GetValue( "model" );

				if( HEV.find( modelName ) >= 0 )
				{
					self.m_flNextPrimaryAttack = g_Engine.time + 0.25; //0.25
				}
				else
				{
					self.m_flNextPrimaryAttack = g_Engine.time + 0.35; //0.25
				}

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
	//aone
					if( pEntity.IsPlayer() )		//lets pull them
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}
	//end aone
					//play thwack or smack sound
					switch( Math.RandomLong( 0, 2 ) )
					{
						case 0:
							g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_flesh1.wav", 1, ATTN_NORM ); break;
						case 1:
							g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_flesh2.wav", 1, ATTN_NORM ); break;
						case 2:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_flesh1.wav", 1, ATTN_NORM ); break;
					}
					m_pPlayer.m_iWeaponVolume = 128; 
					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			//play texture hit sound
			//UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
				
				//model difference
				string modelName = g_EngineFuncs.GetInfoKeyBuffer( m_pPlayer.edict()).GetValue( "model" );

				if( HEV.find( modelName ) >= 0 )
				{
					self.m_flNextPrimaryAttack = g_Engine.time + 0.25;
				}
				else
				{
					self.m_flNextPrimaryAttack = g_Engine.time + 0.35; //0.25
				}
				
				//override the volume here, cause we don't play texture sounds in multiplayer, 
				//and fvolbar is going to be 0 from the above call.

				fvolbar = 1;

				//also play knife strike
				switch( Math.RandomLong( 0, 1 ) )
				{
					case 0:
						g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_wall1.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
						break;
					case 1:
						g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_wall2.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
						break;
				}
			}

			//delay the decal a bit
			m_trHit = tr;
			SetThink( ThinkFunction( this.Smack ) );
			self.pev.nextthink = g_Engine.time + 0.2;

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}
		return fDidHit;
	}

	void SecondaryAttack()
	{
		if( m_iSwingMode != 1 )
		{
			self.SendWeaponAnim( KNIFE_CHARGE, 0, GetBodygroup() );
			m_flBigSwingStart = g_Engine.time;
			self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.7;
			m_iSwingMode = 1;
			isPullingBack = true;
		}
		if( isPullingBack == true && self.m_flTimeWeaponIdle <= g_Engine.time )
		{
			//Manually set wrench windup loop animation
			m_pPlayer.m_Activity = ACT_RELOAD;
			m_pPlayer.pev.frame = 0;
			m_pPlayer.pev.sequence = 26;
			m_pPlayer.ResetSequenceInfo();
			self.m_flNextSecondaryAttack = g_Engine.time + 2.0f;
		}

		m_iSwingMode = 1;
	}
	
	void Smack()
	{
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}

	void SwingAgain()
	{
		Swing( 0 );
	}
	//My humble thanks to KernCore for the secondary attack functions from weapon_csknife code- used in the CS weapons pack :D
	bool HeavySmack()
	{
		bool fDidHit = false;

		TraceResult tr;
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 35;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		if( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if( tr.flFraction < 1.0 )
			{
				EHandle hHit = g_EntityFuncs.Instance( tr.pHit );
				if( hHit.GetEntity() is null || hHit.GetEntity().IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );

				vecEnd = tr.vecEndPos;
			}
		}
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife1.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
		m_pPlayer.m_szAnimExtension = "wrench";
		if( tr.flFraction >= 1.0 )
		{
			self.SendWeaponAnim( KNIFE_STAB, 0, GetBodygroup() );
			self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.7;
			//Miss
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		}
		else
		{
			//Hit
			fDidHit = true;
			self.SendWeaponAnim( KNIFE_STAB, 0, GetBodygroup() );
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			EHandle hEntity = g_EntityFuncs.Instance( tr.pHit );

			if( hEntity.GetEntity() !is null )
			{
				g_WeaponFuncs.ClearMultiDamage();
				float flDamageSmack = 35;
				if( self.m_flNextSecondaryAttack + 1 < g_Engine.time )
				{
					hEntity.GetEntity().TraceAttack( m_pPlayer.pev, flDamageSmack, g_Engine.v_forward, tr, DMG_CLUB | DMG_NEVERGIB );
				}
				else
				{
					hEntity.GetEntity().TraceAttack( m_pPlayer.pev, flDamageSmack / 2, g_Engine.v_forward, tr, DMG_CLUB | DMG_NEVERGIB );
				}
				g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
			}

			//play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;
			if( hEntity.GetEntity() !is null )
			{
				self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.64;
				if( hEntity.GetEntity().Classify() != CLASS_NONE && hEntity.GetEntity().Classify() != CLASS_MACHINE && hEntity.GetEntity().BloodColor() != DONT_BLEED )
				{
					if( hEntity.GetEntity().IsPlayer() ) //lets pull them
					{
						hEntity.GetEntity().pev.velocity = hEntity.GetEntity().pev.velocity + ( self.pev.origin - hEntity.GetEntity().pev.origin ).Normalize() * 120;
					}

					//play thwack or smack sound
					switch( Math.RandomLong( 0, 1 ) )
					{
						case 0:
							g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_flesh1.wav", 1, ATTN_NORM );
							break;
						case 1:
							g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_flesh2.wav", 1, ATTN_NORM ); 
							break;
					}

					m_pPlayer.m_iWeaponVolume = 128;
					if( !hEntity.GetEntity().IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );

				//override the volume here, cause we don't play texture sounds in multiplayer, 
				//and fvolbar is going to be 0 from the above call.
				fvolbar = 1;
				//also play crowbar strike
				switch( Math.RandomLong( 0, 1 ) )
				{
					case 0:
						g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_wall1.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
						break;
					case 1:
						g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_wall2.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
						break;
				}
			}
		}

		g_WeaponFuncs.DecalGunshot( g_Utility.GetGlobalTrace(), BULLET_PLAYER_CROWBAR );
		return fDidHit;
	}

	void DestroyThink()
	{
		g_EntityFuncs.Remove( self );
	}

	void FadeOut()
	{
		pev.nextthink = g_Engine.time + 0.1;

		if( pev.rendermode == kRenderNormal )
		{
			pev.renderamt = 255;
			pev.rendermode = kRenderTransTexture;
		}

		if( pev.renderamt > 7 )
		{
			pev.renderamt -= 7;
		}
		else
		{
			pev.renderamt = 0;
			pev.nextthink = g_Engine.time + 0.1f;
			SetThink( ThinkFunction( this.DestroyThink ) );
			return;
		}
	}
}

string GetOP4KnifeName( )
{
	return "weapon_bts_knife";
}

void RegisterOP4Knife( )
{
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_KNIFE::weapon_bts_knife", GetOP4KnifeName() );
	g_ItemRegistry.RegisterWeapon( GetOP4KnifeName(), "bts_rc/weapons" );
}

}

//Credit to KernCore for secondary attack functions
