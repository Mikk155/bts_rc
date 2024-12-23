/* 
* Black Mesa/HECU Standard SPAS-12 Shotgun
* Sleeve Difference Code: KernCore, Mikk155
*/

#include "../hl_utils"

namespace HL_SHOTGUN
{

//special deathmatch shotgun spreads
const Vector VECTOR_CONE_DM_SHOTGUN( 0.08716, 0.04362, 0.00  );		//10 degrees by 5 degrees
const Vector VECTOR_CONE_DM_DOUBLESHOTGUN( 0.17365, 0.04362, 0.00 ); 	//20 degrees by 5 degrees

const int SHOTGUN_DEFAULT_AMMO 	= Math.RandomLong( 2, 8 );
const int SHOTGUN_MAX_CARRY 	= 30;
const int SHOTGUN_MAX_CLIP 		= 8;
const int SHOTGUN_MAX_DROP		= 3;
const int SHOTGUN_WEIGHT 		= 15;
const int SHOTGUN_MAX_DAMAGE	= 17;

const uint SHOTGUN_SINGLE_PELLETCOUNT = 4;
const uint SHOTGUN_DOUBLE_PELLETCOUNT = SHOTGUN_SINGLE_PELLETCOUNT * 2;

const string MODEL_AMMO	= "models/hlclassic/w_shotbox.mdl";
const string MODEL_DROP	= "models/w_shotshell.mdl";
const string V_MODEL = "models/bts_rc/weapons/v_shotgun.mdl";

enum ShotgunAnimation
{
	SHOTGUN_IDLE = 0,
	SHOTGUN_FIRE,
	SHOTGUN_FIRE2,
	SHOTGUN_RELOAD,
	SHOTGUN_PUMP,
	SHOTGUN_START_RELOAD,
	SHOTGUN_DRAW,
	SHOTGUN_HOLSTER,
	SHOTGUN_IDLE4,
	SHOTGUN_IDLE_DEEP
};

array<string> HEV =
{
	"bts_helmet"
};

class weapon_bts_shotgun : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{
	private CBasePlayer@ m_pPlayer = null;
	
	float m_flNextReload;
	int m_iShell;
	float m_flPumpTime;
	bool m_fPlayPumpSound;
	bool m_fShotgunReload;
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
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 2, 0 );
				break;
			case 1:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 2, 1 );
				break;
			case 2:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 2, 2 );
				break;
			case 3:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 2, 3 );
				break;
			case 4:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 2, 4 );
				break;
		}

		return m_iCurBodyConfig;
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/w_shotgun.mdl" );
		
		self.m_iDefaultAmmo = SHOTGUN_DEFAULT_AMMO;

		self.FallInit();//get ready to fall
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/bts_rc/weapons/v_shotgun.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/weapons/w_shotgun.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/weapons/p_shotgun.mdl" );
		g_Game.PrecacheModel( MODEL_AMMO );
		g_Game.PrecacheModel( MODEL_DROP ); //3 Shotshells Rounds

		m_iShell = g_Game.PrecacheModel( "models/shotgunshell.mdl" );//shotgun shell

		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );			  

		g_SoundSystem.PrecacheSound( "hlclassic/weapons/dbarrel1.wav" );//shotgun
		g_SoundSystem.PrecacheSound( "bts_rc/weapons/spas12_dbarrel1.wav" ); //shotgun
//		g_SoundSystem.PrecacheSound( "hlclassic/weapons/sbarrel1.wav" );//shotgun

		g_SoundSystem.PrecacheSound( "hlclassic/weapons/reload1.wav" );	//shotgun reload
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/reload3.wav" );	//shotgun reload

		g_SoundSystem.PrecacheSound("weapons/sshell1.wav");	//shotgun reload
		g_SoundSystem.PrecacheSound("weapons/sshell3.wav");	//shotgun reload
		
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" ); //gun empty sound
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/scock1.wav" );	//cock gun
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
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= SHOTGUN_MAX_CARRY;
		info.iMaxAmmo2 	= WEAPON_NOCLIP;
		info.iMaxClip 	= SHOTGUN_MAX_CLIP;
		info.iSlot 		= 2;
		info.iPosition 	= 7;
		info.iFlags 	= 0;
		info.iWeight 	= SHOTGUN_WEIGHT;

		return true;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/bts_rc/weapons/v_shotgun.mdl" ), self.GetP_Model( "models/bts_rc/weapons/p_shotgun.mdl" ), SHOTGUN_DRAW, "shotgun", 0, GetBodygroup() );
	}

	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	void Holster( int skipLocal = 0 )
	{
		m_fShotgunReload = false;
		
		BaseClass.Holster( skipLocal );
	}

	void ItemPostFrame()
	{
		if( m_flPumpTime != 0 && m_flPumpTime < g_Engine.time && m_fPlayPumpSound )
		{
			//play pumping sound
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "hlclassic/weapons/scock1.wav", 1, ATTN_NORM, 0, 95 + Math.RandomLong( 0,0x1f ) );

			m_fPlayPumpSound = false;
		}

		BaseClass.ItemPostFrame();
	}
	
	void CreatePelletDecals( const Vector& in vecSrc, const Vector& in vecAiming, const Vector& in vecSpread, const uint uiPelletCount )
	{
		TraceResult tr;
		
		float x, y;
		
		for( uint uiPellet = 0; uiPellet < uiPelletCount; ++uiPellet )
		{
			g_Utility.GetCircularGaussianSpread( x, y );
			
			Vector vecDir = vecAiming 
							+ x * vecSpread.x * g_Engine.v_right 
							+ y * vecSpread.y * g_Engine.v_up;

			Vector vecEnd	= vecSrc + vecDir * 2048;
			
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
			
			if( tr.flFraction < 1.0 )
			{
				if( tr.pHit !is null )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
					
					if( pHit is null || pHit.IsBSPModel() )
						g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_BUCKSHOT );
				}
			}
		}
	}

	void PrimaryAttack()
	{
		//don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
			return;
		}

		if( self.m_iClip <= 0 )
		{
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
			self.Reload();
			self.PlayEmptySound();
			return;
		}

		self.SendWeaponAnim( SHOTGUN_FIRE, 0, GetBodygroup() );
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/sbarrel1.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0x1f ) );
		
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;

		//player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		self.FireBullets( 4, vecSrc, vecAiming, VECTOR_CONE_DM_SHOTGUN, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 0, SHOTGUN_MAX_DAMAGE, m_pPlayer.pev ); //m_pPlayer.FireBullets( 4, vecSrc, vecAiming, VECTOR_CONE_DM_SHOTGUN, 2048, BULLET_PLAYER_BUCKSHOT, 0 );

		//Shell ejection
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		
		Vector	vecShellVelocity = m_pPlayer.pev.velocity 
							 + g_Engine.v_right * Math.RandomFloat( 50, 70) 
							 + g_Engine.v_up* Math.RandomFloat( 100, 150) 
							 + g_Engine.v_forward * 25;
		
		g_EntityFuncs.EjectBrass( vecSrc + m_pPlayer.pev.view_ofs + g_Engine.v_up * -34 + g_Engine.v_forward * 14 + g_Engine.v_right * 6, vecShellVelocity, m_pPlayer.pev.angles.y, m_iShell, TE_BOUNCE_SHOTSHELL );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			//HEV suit - indicate out of ammo condition
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		if( self.m_iClip != 0 )
			m_flPumpTime = g_Engine.time + 0.5;
			
		//difference in model for nextprimaryattack
		string modelName = g_EngineFuncs.GetInfoKeyBuffer( m_pPlayer.edict()).GetValue( "model" );

		if( HEV.find( modelName ) >= 0 )
		{
			m_pPlayer.pev.punchangle.x = -5.0;

			self.m_flNextPrimaryAttack = g_Engine.time + 0.85;
			self.m_flNextSecondaryAttack = g_Engine.time + 0.85;

			if( self.m_iClip != 0 )
				self.m_flTimeWeaponIdle = g_Engine.time + 5.0;
			else
				self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
		}
		else
		{
			m_pPlayer.pev.punchangle.x = -11.0;
			m_pPlayer.pev.velocity = -64 * g_Engine.v_forward; //Knockback!

			self.m_flNextPrimaryAttack = g_Engine.time + 1.0;
			self.m_flNextSecondaryAttack = g_Engine.time + 1.0;

			if( self.m_iClip != 0 )
				self.m_flTimeWeaponIdle = g_Engine.time + 5.0;
			else
				self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
		}

		if( self.m_iClip != 0 )
			self.m_flTimeWeaponIdle = g_Engine.time + 5.0;
		else
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;

		m_fShotgunReload = false;
		m_fPlayPumpSound = true;
		
		CreatePelletDecals( vecSrc, vecAiming, VECTOR_CONE_DM_SHOTGUN, SHOTGUN_SINGLE_PELLETCOUNT );
	}

	void SecondaryAttack()
	{
		//don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
			return;
		}

		if( self.m_iClip <= 1 )
		{
			self.Reload();
			self.PlayEmptySound();
			return;
		}
		
		self.SendWeaponAnim( SHOTGUN_FIRE2, 0, GetBodygroup() );
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/spas12_dbarrel1.wav", Math.RandomFloat( 0.98, 1.0 ), ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		self.m_iClip -= 2;

		//player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		self.FireBullets( 8, vecSrc, vecAiming, VECTOR_CONE_DM_DOUBLESHOTGUN, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 0, SHOTGUN_MAX_DAMAGE, m_pPlayer.pev );  //m_pPlayer.FireBullets( 8, vecSrc, vecAiming, VECTOR_CONE_DM_DOUBLESHOTGUN, 2048, BULLET_PLAYER_BUCKSHOT, 0 );

		//Shell ejection
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		
		Vector	vecShellVelocity = m_pPlayer.pev.velocity 
							 + g_Engine.v_right * Math.RandomFloat( 50, 70) 
							 + g_Engine.v_up* Math.RandomFloat( 100, 150) 
							 + g_Engine.v_forward * 25;
		
		g_EntityFuncs.EjectBrass( vecSrc + m_pPlayer.pev.view_ofs + g_Engine.v_up * -34 + g_Engine.v_forward * 14 + g_Engine.v_right * 3, vecShellVelocity, m_pPlayer.pev.angles.y, m_iShell, TE_BOUNCE_SHOTSHELL );
		g_EntityFuncs.EjectBrass( vecSrc + m_pPlayer.pev.view_ofs + g_Engine.v_up * -32 + g_Engine.v_forward * 18 + g_Engine.v_right * 6, vecShellVelocity, m_pPlayer.pev.angles.y, m_iShell, TE_BOUNCE_SHOTSHELL );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			//HEV suit - indicate out of ammo condition
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		if( self.m_iClip != 0 )
			m_flPumpTime = g_Engine.time + 0.95;

		self.m_flNextPrimaryAttack = g_Engine.time + 1.5;
		self.m_flNextSecondaryAttack = g_Engine.time + 1.5;
		
		if( self.m_iClip != 0 )
			self.m_flTimeWeaponIdle = g_Engine.time + 6.0;
		else
			self.m_flTimeWeaponIdle = g_Engine.time + 1.5;
		
		//difference in model for shotgun recoil
		string modelName = g_EngineFuncs.GetInfoKeyBuffer( m_pPlayer.edict()).GetValue( "model" );

		if( HEV.find( modelName ) >= 0 )
		{
			m_pPlayer.pev.punchangle.x = -10.0;
		}
		else
		{
			m_pPlayer.pev.punchangle.x = -24.0;
			m_pPlayer.pev.velocity = -128 * g_Engine.v_forward; //Knockback!
		}

		m_fShotgunReload = false;
		m_fPlayPumpSound = true;
		
		CreatePelletDecals( vecSrc, vecAiming, VECTOR_CONE_DM_DOUBLESHOTGUN, SHOTGUN_DOUBLE_PELLETCOUNT );
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip == SHOTGUN_MAX_CLIP )
			return;

		if( m_flNextReload > g_Engine.time )
			return;

		//don't reload until recoil is done
		if( self.m_flNextPrimaryAttack > g_Engine.time && !m_fShotgunReload )
			return;

		//check to see if we're ready to reload
		if( !m_fShotgunReload )
		{
			self.SendWeaponAnim( SHOTGUN_START_RELOAD, 0, GetBodygroup() );
			m_pPlayer.m_flNextAttack 	= 0.6;	//Always uses a relative time due to prediction
			self.m_flTimeWeaponIdle			= g_Engine.time + 0.6;
			self.m_flNextPrimaryAttack 		= g_Engine.time + 1.0;
			self.m_flNextSecondaryAttack	= g_Engine.time + 1.0;
			m_fShotgunReload = true;
			return;
		}
		else if( m_fShotgunReload )
		{
			if( self.m_flTimeWeaponIdle > g_Engine.time )
				return;

			if( self.m_iClip == SHOTGUN_MAX_CLIP )
			{
				m_fShotgunReload = false;
				return;
			}

			//animation
			self.SendWeaponAnim( SHOTGUN_RELOAD, 0, GetBodygroup() );

			//difference in model for reload speed
			string modelName = g_EngineFuncs.GetInfoKeyBuffer( m_pPlayer.edict()).GetValue( "model" );

			if( HEV.find( modelName ) >= 0 )
			{
				m_flNextReload 					= g_Engine.time + 0.5;
				self.m_flNextPrimaryAttack 		= g_Engine.time + 0.5;
				self.m_flNextSecondaryAttack 	= g_Engine.time + 0.5;
				self.m_flTimeWeaponIdle 		= g_Engine.time + 0.5;
			}
			else
			{
				m_flNextReload 					= g_Engine.time + 0.64;
				self.m_flNextPrimaryAttack 		= g_Engine.time + 0.64;
				self.m_flNextSecondaryAttack 	= g_Engine.time + 0.64;
				self.m_flTimeWeaponIdle 		= g_Engine.time + 0.64;
			}
				
			//Add them to the clip
			self.m_iClip += 1;
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
			
			switch( Math.RandomLong( 0, 1 ) )
			{
			case 0:
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "hlclassic/weapons/reload1.wav", 1, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
				break;
			case 1:
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "hlclassic/weapons/reload3.wav", 1, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
				break;
			}
		}

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle < g_Engine.time )
		{
			if( self.m_iClip == 0 && !m_fShotgunReload && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0 )
			{
				self.Reload();
			}
			else if( m_fShotgunReload )
			{
				if( self.m_iClip != SHOTGUN_MAX_CLIP && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
				{
					self.Reload();
				}
				else
				{
					//reload debounce has timed out
					self.SendWeaponAnim( SHOTGUN_PUMP, 0, GetBodygroup() );

					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "hlclassic/weapons/scock1.wav", 1, ATTN_NORM, 0, 95 + Math.RandomLong( 0,0x1f ) );
					m_fShotgunReload = false;
					self.m_flTimeWeaponIdle = g_Engine.time + 1.5;
				}
			}
			else
			{
				int iAnim;
				switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
				{
					case 0:
					iAnim = SHOTGUN_IDLE_DEEP;
					self.m_flTimeWeaponIdle = WeaponTimeBase() + ( 60.0/12.0 );
					break;

					case 1:
					iAnim = SHOTGUN_IDLE;
					self.m_flTimeWeaponIdle = WeaponTimeBase() + ( 20.0/9.0 );
					break;

					case 2:
					iAnim = SHOTGUN_IDLE4;
					self.m_flTimeWeaponIdle = WeaponTimeBase() + ( 20.0/9.0 );
					break;
				}
				/*float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0, 1 );
				if( flRand <= 0.8 )
				{
					iAnim = SHOTGUN_IDLE_DEEP;
					self.m_flTimeWeaponIdle = g_Engine.time + ( 60.0/12.0); //* RANDOM_LONG(2, 5 );
				}
				else if( flRand <= 0.95 )
				{
					iAnim = SHOTGUN_IDLE;
					self.m_flTimeWeaponIdle = g_Engine.time + ( 20.0/9.0 );
				}
				else
				{
					iAnim = SHOTGUN_IDLE4;
					self.m_flTimeWeaponIdle = g_Engine.time + ( 20.0/9.0 );
				}*/
				self.SendWeaponAnim( iAnim, 0, GetBodygroup() );
			}
		}
	}
}

class ammo_bts_shotgun : ScriptBasePlayerAmmoEntity
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

		iGive = SHOTGUN_MAX_CLIP;

		if( pOther.GiveAmmo( iGive, "buckshot", SHOTGUN_MAX_CARRY ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

class ammo_bts_shotshell : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		g_EntityFuncs.SetModel( self, MODEL_DROP );

		pev.scale = 1.0;

		BaseClass.Spawn();
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		int iGive;

		iGive = SHOTGUN_MAX_DROP;

		if( pOther.GiveAmmo( iGive, "buckshot", SHOTGUN_MAX_CARRY ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

string GetHLShotgunName()
{
	return "weapon_bts_shotgun";
}

string GetHLShotgunAmmoName()
{
	return "ammo_bts_shotgun";
}

string GetHLShotgunDAmmoName()
{
	return "ammo_bts_shotshell";
}

void RegisterHLShotgun()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_SHOTGUN::weapon_bts_shotgun", GetHLShotgunName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_SHOTGUN::ammo_bts_shotgun", GetHLShotgunAmmoName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_SHOTGUN::ammo_bts_shotshell", GetHLShotgunDAmmoName() );
	g_ItemRegistry.RegisterWeapon( GetHLShotgunName(), "bts_rc/weapons", "buckshot", "", GetHLShotgunAmmoName(), GetHLShotgunDAmmoName() );
}

}
