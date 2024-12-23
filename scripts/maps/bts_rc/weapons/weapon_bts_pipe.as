/* 
* Visitors Pipe
*/

namespace HL_PIPE
{

enum pipe_e
{
	PIPE_IDLE1 = 0,
	PIPE_IDLE2,
	PIPE_IDLE3,
	PIPE_DRAW,
	PIPE_HOLSTER,
	PIPE_ATTACK1HIT,
	PIPE_ATTACK1MISS,
	PIPE_ATTACK2HIT,
	PIPE_ATTACK2MISS,
	PIPE_ATTACK3HIT,
	PIPE_ATTACK3MISS,
	PIPE_ATTACKBIGWIND,
	PIPE_ATTACKBIGHIT,
	PIPE_ATTACKBIGMISS,
	PIPE_ATTACKBIGLOOP
};

array<string> HEV =
{
	"bts_helmet"
};

const string V_MODEL = "models/bts_rc/weapons/v_pipe.mdl";

float flDmg_Heavy = 19;

class weapon_bts_pipe : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{
	private CBasePlayer@ m_pPlayer = null;
	
	int m_iSwing;
	TraceResult m_trHit;
	private float m_flBigSwingStart;
	private int m_iSwingMode = 0;
	private bool isPullingBack;

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
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 1, 0 );
				break;
			case 1:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 1, 1 );
				break;
			case 2:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 1, 2 );
				break;
			case 3:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 1, 3 );
				break;
			case 4:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 1, 4 );
				break;
		}

		return m_iCurBodyConfig;
	}
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( "models/bts_rc/weapons/w_pipe.mdl") );
		self.m_iClip			= -1;
		self.m_flCustomDmg		= self.pev.dmg;

		//for heavy attack
		if( self.pev.fuser2 <= 0 )
			self.pev.fuser2 = flDmg_Heavy;

		self.FallInit();//get ready to fall down.
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( "models/bts_rc/weapons/v_pipe.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/weapons/w_pipe.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/weapons/p_pipe.mdl" );

		g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_hit1.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_hit2.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_hitbod1.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_hitbod2.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_hitbod3.wav" );
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_miss1.wav" );
		
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= 0;
		info.iPosition		= 5;
		info.iWeight		= 0;
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		@m_pPlayer = pPlayer;
		
		NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( self.m_iId );
		message.End();
		
		return true;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/bts_rc/weapons/v_pipe.mdl" ), self.GetP_Model( "models/bts_rc/weapons/p_pipe.mdl" ), PIPE_DRAW, "crowbar", 0, GetBodygroup() );
	}

	void Holster( int skiplocal /* = 0 */ )
	{
		self.m_fInReload = false;//cancel any reload in progress.

		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5; 

		m_pPlayer.pev.viewmodel = "";
		
		SetThink( null );
	}
	
	void PrimaryAttack()
	{
		if( !Swing( 1 ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}
	
	void Smack()
	{
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}


	void SwingAgain()
	{
		Swing( 0 );
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
					self.SendWeaponAnim( PIPE_ATTACK1MISS, 0, GetBodygroup() ); break;
				case 1:
					self.SendWeaponAnim( PIPE_ATTACK2MISS, 0, GetBodygroup() ); break;
				case 2:
					self.SendWeaponAnim( PIPE_ATTACK3MISS, 0, GetBodygroup() ); break;
				}
				self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
				//play wiff or swish sound
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/pipe_miss1.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

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
				self.SendWeaponAnim( PIPE_ATTACK1HIT, 0, GetBodygroup() ); break;
			case 1:
				self.SendWeaponAnim( PIPE_ATTACK2HIT, 0, GetBodygroup() ); break;
			case 2:
				self.SendWeaponAnim( PIPE_ATTACK3HIT, 0, GetBodygroup() ); break;
			}

			//player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

			//AdamR: Custom damage option
			float flDamage = 15;
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
				pEntity.TraceAttack( m_pPlayer.pev, flDamage * 0.5, g_Engine.v_forward, tr, DMG_CLUB );  
			}	
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			//m_flNextPrimaryAttack = gpGlobals->time + 0.30; //0.25

			//play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;

			//for monsters or breakable entity smacking speed function
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
					self.m_flNextPrimaryAttack = g_Engine.time + 0.5; //0.25
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
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/pipe_hitbod1.wav", 1, ATTN_NORM ); break;
					case 1:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/pipe_hitbod2.wav", 1, ATTN_NORM ); break;
					case 2:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/pipe_hitbod3.wav", 1, ATTN_NORM ); break;
					}
					m_pPlayer.m_iWeaponVolume = 32; 
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
				
				//difference in model for nextprimaryattack
				string modelName = g_EngineFuncs.GetInfoKeyBuffer( m_pPlayer.edict()).GetValue( "model" );

				if( HEV.find( modelName ) >= 0 )
				{
					self.m_flNextPrimaryAttack = g_Engine.time + 0.25; //0.25
				}
				else
				{
					self.m_flNextPrimaryAttack = g_Engine.time + 0.5; //0.25
				}
				
				//override the volume here, cause we don't play texture sounds in multiplayer, 
				//and fvolbar is going to be 0 from the above call.

				fvolbar = 1;

				//also play crowbar strike
				switch( Math.RandomLong( 0, 1 ) )
				{
				case 0:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/pipe_hit1.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				case 1:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/pipe_hit2.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				}
			}

			//delay the decal a bit
			m_trHit = tr;
			SetThink( ThinkFunction( this.Smack ) );
			self.pev.nextthink = g_Engine.time + 0.2;

			m_pPlayer.m_iWeaponVolume = int( flVol * 64 ); 
		}
		return fDidHit;
	}

	void SecondaryAttack()
	{
		if( m_iSwingMode != 1 )
		{
			self.SendWeaponAnim( PIPE_ATTACKBIGWIND, 0, GetBodygroup() );
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

	//Fetch it from KernCore's CoF weapons code. Thank you KernCore for providing a lot of help on modding community.
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
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/pipe_miss1.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
		m_pPlayer.m_szAnimExtension = "wrench";
		if( tr.flFraction >= 1.0 )
		{
			self.SendWeaponAnim( PIPE_ATTACKBIGMISS, 0, GetBodygroup() );
			self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.7;
			//Miss
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		}
		else
		{
			//Hit
			fDidHit = true;
			self.SendWeaponAnim( PIPE_ATTACKBIGHIT, 0, GetBodygroup() );
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			EHandle hEntity = g_EntityFuncs.Instance( tr.pHit );

			if( hEntity.GetEntity() !is null )
			{
				g_WeaponFuncs.ClearMultiDamage();
				float flDamageSmack = 19;
				if( self.m_flNextSecondaryAttack + 1 < g_Engine.time )
				{
					hEntity.GetEntity().TraceAttack( m_pPlayer.pev, flDamageSmack, g_Engine.v_forward, tr, DMG_CLUB );
				}
				else
				{
					hEntity.GetEntity().TraceAttack( m_pPlayer.pev, flDamageSmack / 2, g_Engine.v_forward, tr, DMG_CLUB );
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
					switch( Math.RandomLong( 0, 2 ) )
					{
						case 0:
							g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/pipe_hitbod1.wav", 1, ATTN_NORM );
							break;
						case 1:
							g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/pipe_hitbod2.wav", 1, ATTN_NORM ); 
							break;
						case 2:
							g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/pipe_hitbod3.wav", 1, ATTN_NORM );
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
						g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/pipe_hit1.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
						break;
					case 1:
						g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/pipe_hit2.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
						break;
				}
			}
		}

		g_WeaponFuncs.DecalGunshot( g_Utility.GetGlobalTrace(), BULLET_PLAYER_CROWBAR );
		return fDidHit;
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
					self.SendWeaponAnim( PIPE_IDLE1, 0, GetBodygroup() );
					self.m_flTimeWeaponIdle = g_Engine.time + 2.69f;
					break;
				case 1:
					self.SendWeaponAnim( PIPE_IDLE2, 0, GetBodygroup() );
					self.m_flTimeWeaponIdle = g_Engine.time + 5.33f;
					break;
				case 2:
					self.SendWeaponAnim( PIPE_IDLE3, 0, GetBodygroup() );
					self.m_flTimeWeaponIdle = g_Engine.time + 5.33f;
					break;
			}
		}
	}
	
}

string GetPipeName()
{
	return "weapon_bts_pipe";
}

void RegisterPipe()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_PIPE::weapon_bts_pipe", GetPipeName() );
	g_ItemRegistry.RegisterWeapon( GetPipeName(), "bts_rc/weapons" );
}

}
