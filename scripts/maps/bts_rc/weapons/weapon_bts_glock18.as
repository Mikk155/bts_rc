/*
* Glock 18
*/

namespace BTS_GLOCK18
{

enum btsglock18Animation
{
	IDLE1 = 0,
	IDLE2,
	IDLE3,
	SHOOT,
	SHOOT_EMPTY,
	RELOAD,
	RELOAD_NOT_EMPTY,
	DRAW,
	HOLSTER,
	ADD_SILENCER
};

enum glock18modes_e
{
	MODE_SEMIAUTO = 0,
	MODE_FULLAUTO
};

array<string> HEV =
{
	"bts_helmet"
};

const int MAX_CLIP = 19;
const int MAX_AMMO = 120;
const int MAX_DMG = 12;
const int DEFAULT_GIVE = Math.RandomLong( 9, 19 );

const string MODEL_AMMO = "models/hlclassic/w_9mmclip.mdl";
const string V_MODEL = "models/bts_rc/weapons/v_glock18.mdl";

class weapon_bts_glock18 : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{

	private CBasePlayer@ m_pPlayer = null;
	int m_iShotsFired;
	int m_iShell;
	private int m_iMode;
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
		string modelName = g_EngineFuncs.GetInfoKeyBuffer( m_pPlayer.edict() ).GetValue( "model" );

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
		Precache();
		g_EntityFuncs.SetModel( self, "models/hlclassic/w_9mmhandgun.mdl" );
		self.m_iDefaultAmmo = DEFAULT_GIVE;
		self.FallInit();
		m_iMode = MODE_SEMIAUTO;
		m_iShotsFired = 0;
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/bts_rc/weapons/v_glock18.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/p_9mmhandgun.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/w_9mmhandgun.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/w_9mmclip.mdl" );

		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );

		g_SoundSystem.PrecacheSound( "bts_rc/weapons/glock18_fire1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/reload1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );

		g_SoundSystem.PrecacheSound( "buttons/lightswitch2.wav" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = MAX_AMMO;
		info.iMaxAmmo2 = -1;
		info.iAmmo1Drop = MAX_CLIP;
		info.iMaxClip = MAX_CLIP;
		info.iSlot = 1;
		info.iPosition = 10;
		info.iWeight = 10;
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
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		return false;
	}

	bool Deploy()
	{
		bool bResult = self.DefaultDeploy( self.GetV_Model( "models/bts_rc/weapons/v_glock18.mdl" ), self.GetP_Model( "models/hlclassic/p_9mmhandgun.mdl" ), DRAW, "onehanded", 0, GetBodygroup() );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0;
		return bResult;
	}

	void Holster( int skiplocal = 0 )
	{
		self.m_fInReload = false;

		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5;

		m_pPlayer.pev.viewmodel = 0;
	}

	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

	void PrimaryAttack()
	{
		//difference in model for shooting spread
		string modelName = g_EngineFuncs.GetInfoKeyBuffer( m_pPlayer.edict() ).GetValue( "model" );

		if( HEV.find( modelName ) >= 0 )
		{
			if( m_iMode == MODE_SEMIAUTO )
			{
				SemiAutoFire( 0.01, 0.30 );
			}
			else if( m_iMode == MODE_FULLAUTO )
			{
				FullAutoFire( 0.01, 0.0625 );
			}
		}
		else
		{
			if( m_iMode == MODE_SEMIAUTO )
			{
				SemiAutoFire( 0.01, 0.325 );
			}
			else if( m_iMode == MODE_FULLAUTO )
			{
				FullAutoFire( 0.01, 0.0755 );
			}
		}
	}

	void SecondaryAttack()
	{
		if( m_iMode == MODE_SEMIAUTO )
		{
			m_iMode = MODE_FULLAUTO;
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, " Full-Auto Mode \n" );
		}
		else if( m_iMode == MODE_FULLAUTO )
		{
			m_iMode = MODE_SEMIAUTO;
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, " Semi-Auto Mode \n" );
		}

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "buttons/lightswitch2.wav", 1, ATTN_NORM, 0, 92 );
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
		self.m_flTimeWeaponIdle = g_Engine.time + 0.5;
	}


	void SemiAutoFire( float& in flSpread, float& in flCycleTime )
	{
		if( self.m_iClip <= 0 )
		{
			if( self.m_bFireOnEmpty )
			{
				PlayEmptySound();
				self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
			}

			return;
		}

		self.m_iClip--;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;

		if( self.m_iClip != 0 )
			self.SendWeaponAnim( SHOOT, 0, GetBodygroup() );
		else
			self.SendWeaponAnim( SHOOT_EMPTY, 0, GetBodygroup() );

		//player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		g_EngineFuncs.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		Vector vecShellVelocity = m_pPlayer.pev.velocity + g_Engine.v_right * Math.RandomFloat( 50.0, 70.0 ) + g_Engine.v_up * Math.RandomFloat( 100.0, 150.0 ) + g_Engine.v_forward * 25;
		g_EntityFuncs.EjectBrass( self.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_up * -12 + g_Engine.v_forward * 32 + g_Engine.v_right * 6, vecShellVelocity, self.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );

		//non-silenced
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/glock18_fire1.wav", Math.RandomFloat( 0.92, 1.0 ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming;

		vecAiming = g_Engine.v_forward;

		self.FireBullets( 1, vecSrc, vecAiming, Vector( flSpread, flSpread, flSpread ), 8192, BULLET_PLAYER_9MM, 4, 0, m_pPlayer.pev );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + flCycleTime;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10.0, 15.0 );

		//model difference
		string modelName = g_EngineFuncs.GetInfoKeyBuffer( m_pPlayer.edict() ).GetValue( "model" );

		if( HEV.find( modelName ) >= 0 )
		{
			m_pPlayer.pev.punchangle.x = -2.0;
		}
		else
		{
			m_pPlayer.pev.punchangle.x = -4.0; //recoil
		}

		//Decal
		TraceResult tr;
		float x, y;

		g_Utility.GetCircularGaussianSpread( x, y );

		Vector vecSpread = Vector( flSpread, flSpread, flSpread );
		Vector vecDir = vecAiming + x * vecSpread.x * g_Engine.v_right + y * vecSpread.y * g_Engine.v_up;
		Vector vecEnd = vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

				if( pHit is null || pHit.IsBSPModel() )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_9MM );
			}
		}
	}

	void FullAutoFire( float& in flSpread, float& in flCycleTime )
	{
		if( self.m_iClip <= 0 )
		{
			if( self.m_bFireOnEmpty )
			{
				PlayEmptySound();
				self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
			}

			return;
		}

		self.m_iClip--;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;

		if( self.m_iClip != 0 )
			self.SendWeaponAnim( SHOOT, 0, GetBodygroup() );
		else
			self.SendWeaponAnim( SHOOT_EMPTY, 0, GetBodygroup() );

		//player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		g_EngineFuncs.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		Vector vecShellVelocity = m_pPlayer.pev.velocity + g_Engine.v_right * Math.RandomFloat( 50.0, 70.0 ) + g_Engine.v_up * Math.RandomFloat( 100.0, 150.0 ) + g_Engine.v_forward * 25;
		g_EntityFuncs.EjectBrass( self.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_up * -12 + g_Engine.v_forward * 32 + g_Engine.v_right * 6, vecShellVelocity, self.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );

		//non-silenced
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/glock18_fire1.wav", Math.RandomFloat( 0.92, 1.0 ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming;

		vecAiming = g_Engine.v_forward;

		self.FireBullets( 1, vecSrc, vecAiming, Vector( flSpread, flSpread, flSpread ), 8192, BULLET_PLAYER_9MM, 4, 0, m_pPlayer.pev );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + flCycleTime;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10.0, 15.0 );

		//model difference
		string modelName = g_EngineFuncs.GetInfoKeyBuffer( m_pPlayer.edict() ).GetValue( "model" );

		if( HEV.find( modelName ) >= 0 )
		{
			m_pPlayer.pev.punchangle.x = -2.0;
		}
		else
		{
			m_pPlayer.pev.punchangle.x = Math.RandomLong( -6, 3 ); //recoil
		}

		//Decal
		TraceResult tr;
		float x, y;

		g_Utility.GetCircularGaussianSpread( x, y );

		Vector vecSpread = Vector( flSpread, flSpread, flSpread );
		Vector vecDir = vecAiming + x * vecSpread.x * g_Engine.v_right + y * vecSpread.y * g_Engine.v_up;
		Vector vecEnd = vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

				if( pHit is null || pHit.IsBSPModel() )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_9MM );
			}
		}
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		int iAnim;
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 3 ) )
		{
		case 0:
			iAnim = IDLE1;
			break;

		case 1:
			iAnim = IDLE2;
			break;

		default:
			iAnim = IDLE3;
			break;
		}

		self.SendWeaponAnim( iAnim, 0, GetBodygroup() );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 6, 8 );//how long till we do this again.
	}

	void Reload()
	{
		if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType) <= 0 )
			return;

		const bool bResult = self.DefaultReload( MAX_CLIP, self.m_iClip > 0 ? RELOAD_NOT_EMPTY : RELOAD, 1.5, GetBodygroup() );

		if( bResult )
		{
			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0, 15.0 );
		}

		BaseClass.Reload();
	}
}

class ammo_bts_glock18 : ScriptBasePlayerAmmoEntity
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

		if( pOther.GiveAmmo( iGive, "9mm", MAX_AMMO ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

string GetName()
{
	return "weapon_bts_glock18";
}

string GetAmmoName()
{
	return "ammo_bts_glock18";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_GLOCK18::weapon_bts_glock18", GetName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_GLOCK18::ammo_bts_glock18", GetAmmoName() );
	g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", "9mm", "", GetAmmoName() );
}

}
