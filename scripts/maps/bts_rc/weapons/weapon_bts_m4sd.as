// Standard Black Operators Tactical Suppressed M4A1
// Models: HAPE B
// Scripts: Giegue, Rizulix, Valve Software
// Sounds: TurtleRock Studios, Valve Software, HAPE B, RaptorSKA
// Sprites: TurtleRock Studios, Valve Software, SV BOY

namespace BTS_M4SD
{

enum M4SDAnimation
{
	LONGIDLE = 0,
	IDLE1,
	LAUNCH,
	RELOAD,
	DEPLOY,
	FIRE1,
	FIRE2,
	FIRE3,
};

enum M4ScopedMode_e
{
	MODE_UNSCOPE = 0,
	MODE_SCOPE
};

array<string> HEV =
{
	"bts_helmet"
};

const int M4SD_DEFAULT_GIVE 	= Math.RandomLong( 9, 30 );
const int M4SD_MAX_AMMO		= 150;
const int M4SD_MAX_CLIP 		= 30;
const int M4SD_WEIGHT 		= 5;
//const int M4SD_MAX_DMG        = 13;

const string MODEL_AMMO		= "models/bts_rc/weapons/w_556nato.mdl";
const string V_MODEL = "models/bts_rc/weapons/v_m4sd.mdl";

class weapon_bts_m4sd : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{
	private CBasePlayer@ m_pPlayer = null;
	
	float m_flNextAnimTime;
	int m_iShell;
	int g_iCurrentMode;
	int m_iShotsFired;

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
		string modelName = g_EngineFuncs.GetInfoKeyBuffer(m_pPlayer.edict()).GetValue( "model" );

    	switch( int(g_Models[ modelName ]) )
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
		Precache();
		g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/w_m4sd.mdl" );

		self.m_iDefaultAmmo = M4SD_DEFAULT_GIVE;
		m_iShotsFired = 0;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/bts_rc/weapons/v_m4sd.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/weapons/w_m4sd.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/weapons/p_m4sd.mdl" );
		g_Game.PrecacheModel( MODEL_AMMO );

		m_iShell = g_Game.PrecacheModel( "models/bts_rc/weapons/saw_shell.mdl" );

		g_Game.PrecacheModel( "models/w_saw_clip.mdl" );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );              

		//These are played by the model, needs changing there
		g_SoundSystem.PrecacheSound( "hl/items/clipinsert1.wav" );
		g_SoundSystem.PrecacheSound( "hl/items/cliprelease1.wav" );
		g_SoundSystem.PrecacheSound( "hl/items/guncock1.wav" );

		g_SoundSystem.PrecacheSound( "bts_rc/weapons/m4sd_fire1.wav" );

		g_SoundSystem.PrecacheSound( "hl/weapons/357_cock1.wav" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= M4SD_MAX_AMMO;
		info.iMaxClip 	= M4SD_MAX_CLIP;
		info.iSlot 		= 2;
		info.iPosition 	= 9;
		info.iFlags 	= 0;
		info.iWeight 	= M4SD_WEIGHT;

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
	
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl/weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}

	bool Deploy()
	{
		bool bResult;
		{
	        bResult = self.DefaultDeploy( self.GetV_Model( "models/bts_rc/weapons/v_m4sd.mdl" ), self.GetP_Model( "models/bts_rc/weapons/p_m4sd.mdl" ), DEPLOY, "m16", 0, GetBodygroup() );

			float deployTime = 1.2;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;

		if ( g_iCurrentMode == MODE_SCOPE )
		{
			g_iCurrentMode = MODE_UNSCOPE;
		}
		m_iShotsFired = 0;
		ToggleZoom( 0 );

		BaseClass.Holster( skipLocal );
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

    // Setting FOV command for ToggleZoom void call line
	void SetFOV( int fov )
	{
		m_pPlayer.pev.fov = m_pPlayer.m_iFOV = fov;
	}

    // Utilizing SetFOV function inside this call line
	void ToggleZoom( int zoomedFOV )
	{
		if ( self.m_fInZoom == true )
		{
			SetFOV( 0 ); // 0 means reset to default fov
		}
		else if ( self.m_fInZoom == false )
		{
			SetFOV( zoomedFOV );
		}
	}

	void PrimaryAttack()
	{
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound( );
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.12;
			return;
		}

		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.12;
			return;
		}

		m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;

		if( g_iCurrentMode == MODE_SCOPE )
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.13;
		}
		else if( g_iCurrentMode == MODE_UNSCOPE)
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.124;
		}

		--self.m_iClip;
		
		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
		{
		case 0: self.SendWeaponAnim( FIRE1, 0, GetBodygroup() ); break;
		case 1: self.SendWeaponAnim( FIRE2, 0, GetBodygroup() ); break;
		case 2: self.SendWeaponAnim( FIRE3, 0, GetBodygroup() ); break;
		}
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/m4sd_fire1.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		g_EngineFuncs.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		
		Vector vecShellVelocity = m_pPlayer.pev.velocity + g_Engine.v_right * Math.RandomFloat( 50.0, 70.0 ) + g_Engine.v_up * Math.RandomFloat( 100.0, 150.0 ) + g_Engine.v_forward * 25;
		g_EntityFuncs.EjectBrass( self.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_up * -12 + g_Engine.v_forward * 32 + g_Engine.v_right * 6, vecShellVelocity, self.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		// Weapon spread
		Vector vecSpread;

		if( !(m_pPlayer.pev.flags & FL_DUCKING != 0 ) )
		{
			vecSpread = VECTOR_CONE_2DEGREES; //spread when standing
		}
		else
		{
			vecSpread = Vector( 0.01, 0.01, 0.01 ); //spread when crouching
		}

		vecSpread = vecSpread * 1.0f;
		
		// optimized multiplayer. Widened to make it easier to hit a moving player
		self.FireBullets( 1, vecSrc, vecAiming, vecSpread, 8192, BULLET_PLAYER_SAW, 4, 0, m_pPlayer.pev );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			// HEV suit - indicate out of ammo condition
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		//model difference (HEV has higher stability for weaponary than the one without it) - HL Lore
		string modelName = g_EngineFuncs.GetInfoKeyBuffer(m_pPlayer.edict()).GetValue( "model" );

		if ( HEV.find(modelName) >= 0 )
		{
			m_pPlayer.pev.punchangle.x = -2.75; // recoil

	//		self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.125;
			if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
				self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.125;
		}
		else
		{
			// crouching recoil logic
			if( m_pPlayer.pev.flags & FL_DUCKING != 0 )
			{
				m_pPlayer.pev.punchangle.x = Math.RandomLong( -3, 2 ); //recoil when crouching
			}
			else
			{
				m_pPlayer.pev.punchangle.x = Math.RandomLong( -6, 3 ); //recoil when stand
			}

			if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
				self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.125;
		}

//		self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.125;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.125;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming + x * vecSpread.x * g_Engine.v_right + y * vecSpread.y * g_Engine.v_up;
		Vector vecEnd = vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );
			}
		}
	}

	void SecondaryAttack()
	{
		self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.3f;
		switch ( g_iCurrentMode )
		{
			case MODE_UNSCOPE:
			{
				g_iCurrentMode = MODE_SCOPE;
				ToggleZoom( 45 );

				break;
			}
		
			case MODE_SCOPE:
			{
				g_iCurrentMode = MODE_UNSCOPE;
				ToggleZoom( 0 );

				break;
			}
		}
	}

	void Reload()
	{
		self.DefaultReload( M4SD_MAX_CLIP, RELOAD, 3.0, GetBodygroup() );

		g_iCurrentMode = 0;
		ToggleZoom( 0 );
		m_iShotsFired = 0;

		//Set 3rd person reloading animation -Sniper
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		int iAnim;
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 1 ) )
		{
		case 0:	
			iAnim = LONGIDLE;	
			break;
		
		case 1:
			iAnim = IDLE1;
			break;
			
		default:
			iAnim = LONGIDLE;
			break;
		}

		self.SendWeaponAnim( iAnim, 0, GetBodygroup() );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );// how long till we do this again.
	}
}

class ammo_bts_m4sd : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		g_EntityFuncs.SetModel( self, MODEL_AMMO );

		pev.scale = 1.0;

		BaseClass.Spawn();
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		int iGive;

		iGive = M4SD_MAX_CLIP;

		if( pOther.GiveAmmo( iGive, "556", M4SD_MAX_AMMO ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

string GetM4SDName()
{
	return "weapon_bts_m4sd";
}

string GetM4SDAmmoName()
{
	return "ammo_bts_m4sd";
}

void RegisterM4SD()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M4SD::weapon_bts_m4sd", GetM4SDName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M4SD::ammo_bts_m4sd", GetM4SDAmmoName() );
	g_ItemRegistry.RegisterWeapon( GetM4SDName(), "bts_rc/weapons", "556", "", GetM4SDAmmoName() );
}

}