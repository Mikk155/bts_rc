/*
 * Snub Revolver
 * Author: Rizulix
*/

#include '../hl_utils'

namespace BTS_SNUBREVOLVER
{

enum python_e
{
  IDLE1 = 0,
  FIDGET,
  FIRE1,
  RELOAD,
  HOLSTER,
  DRAW,
  IDLE2,
  IDLE3
};

array<string> HEV =
{
  "bts_helmet"
};

//Weapon information
const int MAX_CARRY	= 18;
const int MAX_CLIP	 = Math.RandomLong( 2, 6 );
const int DEFAULT_GIVE = MAX_CLIP;
const int WEIGHT	   = 15;

const string MODEL_AMMO = "models/hlclassic/w_357ammobox.mdl";
const string MODEL_AMMO2 = "models/hlclassic/w_357ammo.mdl";
const string V_MODEL = "models/bts_rc/weapons/v_snub.mdl";

class weapon_bts_snub : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{
  private CBasePlayer@ m_pPlayer
  {
	get const { return cast<CBasePlayer>( self.m_hPlayer.GetEntity() ); }
	set	   { self.m_hPlayer = EHandle(@value); }
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
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 3, 0 );
				break;
			case 1:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 3, 1 );
				break;
			case 2:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 3, 2 );
				break;
			case 3:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 3, 3 );
				break;
			case 4:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 3, 4 );
				break;
		}

	  return m_iCurBodyConfig;
  }

  void Spawn()
  {
	Precache();
	g_EntityFuncs.SetModel( self, self.GetW_Model('models/bts_rc/weapons/w_snub.mdl') );
	self.m_iDefaultAmmo = DEFAULT_GIVE;
	self.FallInit();
  }

  void Precache()
  {
	self.PrecacheCustomModels();
	g_Game.PrecacheModel('models/bts_rc/weapons/v_snub.mdl');
	g_Game.PrecacheModel('models/bts_rc/weapons/w_snub.mdl');
	g_Game.PrecacheModel('models/bts_rc/weapons/p_357.mdl');
	g_Game.PrecacheModel( MODEL_AMMO );
	g_Game.PrecacheModel( MODEL_AMMO2 );

	g_SoundSystem.PrecacheSound('hlclassic/weapons/357_reload1.wav'); //default viewmodel; sequence: 3; frame: 70; event 5004
	g_SoundSystem.PrecacheSound('hlclassic/weapons/357_cock1.wav');
	g_SoundSystem.PrecacheSound('bts_rc/weapons/snub_fire1.wav');
  }

  bool GetItemInfo( ItemInfo& out info )
  {
	info.iMaxAmmo1 = MAX_CARRY;
	info.iMaxAmmo2 = -1;
	info.iAmmo1Drop = MAX_CLIP;
	info.iAmmo2Drop = -1;
	info.iMaxClip = MAX_CLIP;
	info.iFlags = 0;
	info.iSlot = 1;
	info.iPosition = 12;
	info.iId = g_ItemRegistry.GetIdForName( pev.classname );
	info.iWeight = WEIGHT;

	return true;
  }

  bool AddToPlayer( CBasePlayer@ pPlayer )
  {
	if( !BaseClass.AddToPlayer( pPlayer ) )
	  return false;

	NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
	  message.WriteLong( g_ItemRegistry.GetIdForName( pev.classname ) );
	message.End();

	return true;
  }

  bool PlayEmptySound()
  {
	if( self.m_bPlayEmptySound )
	{
	  g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, 'hlclassic/weapons/357_cock1.wav', 0.8, ATTN_NORM, 0, PITCH_NORM );
	  self.m_bPlayEmptySound = false;
	  return false;
	}
	return false;
  }

  bool Deploy()
  {
	//This one is for Laser Sight Features
  /*
	if( UseLaserSight() )
	{
	  pev.body = 1;
	}
	else
	{
	  pev.body = 0;
	}
  */

	bool bResult = self.DefaultDeploy( self.GetV_Model('models/bts_rc/weapons/v_snub.mdl'), self.GetP_Model('models/bts_rc/weapons/p_snub.mdl'), DRAW, 'python', 0, GetBodygroup() );
	self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0;
	return bResult;
  }

  void Holster( int skiplocal = 0 )
  {
	self.m_fInReload = false;

/*
	if( m_pPlayer.m_iFOV != 0 )
	{
	  SecondaryAttack();
	}
*/

	BaseClass.Holster( skiplocal );
  }

  void PrimaryAttack()
  {
	if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
	{
	  self.PlayEmptySound();
	  self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
	  return;
	}

	if( self.m_iClip <= 0 )
	{
	  if( self.m_bFireOnEmpty )
	  {
		self.PlayEmptySound();
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
	  }
	  return;
	}

	m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
	m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

	--self.m_iClip;

	m_pPlayer.pev.effects |= EF_MUZZLEFLASH;

	m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

	Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

	Vector vecSrc = m_pPlayer.GetGunPosition();
	Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

	self.FireBullets( 1, vecSrc, vecAiming, Vector( 0.05, 0.05, 0.05 ), 8192, BULLET_PLAYER_EAGLE, 4, 0, m_pPlayer.pev );

	pev.effects |= EF_MUZZLEFLASH;

	self.SendWeaponAnim( FIRE1, 0, GetBodygroup() );

	//difference in model for nextprimaryattack
		string modelName = g_EngineFuncs.GetInfoKeyBuffer( m_pPlayer.edict()).GetValue( "model" );

	if( HEV.find( modelName ) >= 0 )
	{
	  m_pPlayer.pev.punchangle.x = -8.0;
	}
	else
	{
	  m_pPlayer.pev.punchangle.x = -14.0;
	}

	g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, 'bts_rc/weapons/snub_fire1.wav', Math.RandomFloat(0.8, 0.9), ATTN_NORM, 0, PITCH_NORM );

	if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType) <= 0 )
	  m_pPlayer.SetSuitUpdate('!HEV_AMO0', false, 0 );

	self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.75;
	self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0, 15.0 );
  }

  void Reload()
  {
	if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType) <= 0 )
	  return;

	self.DefaultReload( MAX_CLIP, RELOAD, 2.0, GetBodygroup() );
	self.m_flTimeWeaponIdle = WeaponTimeBase() + 3.0;

	BaseClass.Reload();
  }

  void WeaponIdle()
  {
	self.ResetEmptySound();

	m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

	if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
	  return;

	int iAnim;
	float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0.0, 1.0 );
	if( flRand <= 0.5 )
	{
	  iAnim = IDLE1;
	  self.m_flTimeWeaponIdle = WeaponTimeBase() + ( 70.0 / 30.0 );
	}
	else if( flRand <= 0.7 )
	{
	  iAnim = IDLE2;
	  self.m_flTimeWeaponIdle = WeaponTimeBase() + ( 60.0 / 30.0 );
	}
	else if( flRand <= 0.9 )
	{
	  iAnim = IDLE3;
	  self.m_flTimeWeaponIdle = WeaponTimeBase() + ( 88.0 / 30.0 );
	}
	else
	{
	  iAnim = FIDGET;
	  self.m_flTimeWeaponIdle = WeaponTimeBase() + ( 170.0 / 30.0 );
	}

	self.SendWeaponAnim( iAnim, 0, GetBodygroup() );
  }
}

class ammo_bts_snub : ScriptBasePlayerAmmoEntity
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

		iGive = MAX_CLIP;

		if( pOther.GiveAmmo( iGive, "357", MAX_CARRY ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

class ammo_bts_357cyl : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		g_EntityFuncs.SetModel( self, MODEL_AMMO2 );

		pev.scale = 1.0;

		BaseClass.Spawn();
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		int iGive;

		iGive = Math.RandomLong( 2, 4 );

		if( pOther.GiveAmmo( iGive, "357", MAX_CARRY ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

string GetName()
{
  return 'weapon_bts_snub';
}

string GetAmmoName()
{
  return 'ammo_bts_snub';
}

string GetAmmoDropName()
{
  return 'ammo_bts_357cyl';
}

void Register()
{
  g_CustomEntityFuncs.RegisterCustomEntity( "BTS_SNUBREVOLVER::weapon_bts_snub", GetName() ); 
  g_CustomEntityFuncs.RegisterCustomEntity( "BTS_SNUBREVOLVER::ammo_bts_snub", GetAmmoName() );
  g_CustomEntityFuncs.RegisterCustomEntity( "BTS_SNUBREVOLVER::ammo_bts_357cyl", GetAmmoDropName() );
  g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", "357", "", GetAmmoName() );
}

}