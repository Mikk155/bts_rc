/*
* M9 Beretta w/ Torchlight attached
* Author: Giegue, Mikk
* Animation: MTB
*/


namespace HL_BERETTA
{

enum hlberettaAnimation
{
	HLBERETTA_IDLE1 = 0,
	HLBERETTA_IDLE2,
	HLBERETTA_IDLE3,
	HLBERETTA_SHOOT,
	HLBERETTA_SHOOT_EMPTY,
	HLBERETTA_RELOAD,
	HLBERETTA_RELOAD_NOT_EMPTY,
	HLBERETTA_DRAW,
	HLBERETTA_HOLSTER,
	HLBERETTA_ADD_SILENCER
};

array<string> HEV =
{
	"bts_helmet"
};

const int MAX_CLIP = 15;
const int MAX_AMMO = 120;
const int MAX_DMG = 14;
const int DEFAULT_GIVE = Math.RandomLong( 1, 15 );

const int BATTERY_MAX_AMMO	  = 60;
const int BATTERY_DEFAULT_GIVE  = Math.RandomLong( 0, 3 ); //3
const bool g_bShowFlashlightToAll = true;
const float LIGHT_DISTANCE = 3072.0f;
const int DRAIN_RATE = 440;

const string V_MODEL = "models/bts_rc/weapons/v_beretta.mdl";
const string MODEL_AMMO = "models/hlclassic/w_9mmclip.mdl";

class weapon_bts_beretta : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{
	bool m_bIsFlashlightOn;

	private CBasePlayer@ m_pPlayer = null;
	int m_iShotsFired;
	int m_iShell;
	private TraceResult tr;
	private float m_flNextFlashlightTime;
	private int m_iNextDainTime;

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

	void ItemPreFrame()
	{
		if( g_Engine.time > m_flNextFlashlightTime )
		{
			if( m_bIsFlashlightOn )
			{
				g_Utility.TraceLine( m_pPlayer.GetGunPosition(), m_pPlayer.GetGunPosition() + g_Engine.v_forward * LIGHT_DISTANCE, dont_ignore_monsters, m_pPlayer.edict(), tr );

				if( g_bShowFlashlightToAll )
				{
					NetworkMessage flon( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
						flon.WriteByte( TE_DLIGHT );
						flon.WriteCoord( tr.vecEndPos.x );
						flon.WriteCoord( tr.vecEndPos.y );
						flon.WriteCoord( tr.vecEndPos.z );
						flon.WriteByte( 9 );
						flon.WriteByte( 150 );
						flon.WriteByte( 150 );
						flon.WriteByte( 150 );
						flon.WriteByte( 1 );
						flon.WriteByte( 1 );
					flon.End();
				}
				else
				{
					NetworkMessage flon( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, m_pPlayer.edict() );
						flon.WriteByte( TE_DLIGHT );
						flon.WriteCoord( tr.vecEndPos.x );
						flon.WriteCoord( tr.vecEndPos.y );
						flon.WriteCoord( tr.vecEndPos.z );
						flon.WriteByte( 9 );
						flon.WriteByte( 150 );
						flon.WriteByte( 150 );
						flon.WriteByte( 150 );
						flon.WriteByte( 1 );
						flon.WriteByte( 1 );
					flon.End();
				}

				if( m_iNextDainTime > DRAIN_RATE )
				{
					m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );
					m_iNextDainTime = 0;
				}
				else
					m_iNextDainTime++;

				if( !HasBattery() )
					m_bIsFlashlightOn = false;
			}

			m_flNextFlashlightTime = g_Engine.time + 0.0125f; //torchlight's light flickering per seconds
		}

		BaseClass.ItemPreFrame();
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/w_beretta.mdl");
		self.m_iDefaultAmmo = DEFAULT_GIVE;
		self.m_iDefaultSecAmmo = BATTERY_DEFAULT_GIVE;
		self.FallInit();
		m_iShotsFired = 0;
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/bts_rc/weapons/v_beretta.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/weapons/p_beretta.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/weapons/w_beretta.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/w_9mmclip.mdl" );

		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );

		g_SoundSystem.PrecacheSound( "bts_rc/weapons/beretta_fire1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/reload1.wav" );
		g_SoundSystem.PrecacheSound( "hl/weapons/357_cock1.wav" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = MAX_AMMO;
		info.iMaxAmmo2 = BATTERY_MAX_AMMO;
		info.iAmmo1Drop = MAX_CLIP;
		info.iMaxClip = MAX_CLIP;
		info.iSlot = 1;
		info.iPosition = 6;
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
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl/weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		return false;
	}

	bool Deploy()
	{
		m_bIsFlashlightOn = false;

		bool bResult = self.DefaultDeploy( self.GetV_Model('models/bts_rc/weapons/v_beretta.mdl'), self.GetP_Model('models/bts_rc/weapons/p_beretta.mdl'), HLBERETTA_DRAW, 'onehanded', 0, GetBodygroup() );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0;
		return bResult;
	}

	void Holster( int skiplocal = 0 )
	{
		m_bIsFlashlightOn = false;
		self.m_fInReload = false;

		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5;

		m_pPlayer.pev.viewmodel = 0;
	}

	bool HasBattery()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0 )
		{
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			return false;
		}
		return true;
	}

	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

	void PrimaryAttack()
	{
		//difference in model for recoil
		string modelName = g_EngineFuncs.GetInfoKeyBuffer( m_pPlayer.edict() ).GetValue( "model" );

		if( HEV.find( modelName ) >= 0 )
		{
			BerettaFire( 0.01, 0.30 );
		}
		else
		{
			BerettaFire( 0.01, 0.325 );
		}
	}

	void BerettaFire( float& in flSpread, float& in flCycleTime )
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
			self.SendWeaponAnim( HLBERETTA_SHOOT, 0, GetBodygroup() );
		else
			self.SendWeaponAnim( HLBERETTA_SHOOT_EMPTY, 0, GetBodygroup() );

		//player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		g_EngineFuncs.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		Vector vecShellVelocity = m_pPlayer.pev.velocity + g_Engine.v_right * Math.RandomFloat( 50.0, 70.0 ) + g_Engine.v_up * Math.RandomFloat( 100.0, 150.0 ) + g_Engine.v_forward * 25;
		g_EntityFuncs.EjectBrass( self.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_up * -12 + g_Engine.v_forward * 32 + g_Engine.v_right * 6, vecShellVelocity, self.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );

		//non-silenced
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/beretta_fire1.wav", Math.RandomFloat( 0.92, 1.0 ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming;

		vecAiming = g_Engine.v_forward;

		self.FireBullets( 1, vecSrc, vecAiming, Vector( flSpread, flSpread, flSpread ), 8192, BULLET_PLAYER_9MM, 4, 0, m_pPlayer.pev );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + flCycleTime;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10.0, 15.0 );

		//difference in model for recoil
		string modelName = g_EngineFuncs.GetInfoKeyBuffer( m_pPlayer.edict() ).GetValue( "model" );

		if( HEV.find( modelName ) >= 0 )
		{
			m_pPlayer.pev.punchangle.x = -2.0;
		}
		else
		{
			m_pPlayer.pev.punchangle.x = -2.5; //recoil
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

	void SecondaryAttack()
	{
		if( !HasBattery() )
			return;

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/items/flashlight1.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

		m_bIsFlashlightOn = !m_bIsFlashlightOn;

		self.m_flNextPrimaryAttack = g_Engine.time + 0.5f;
		self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
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
			iAnim = HLBERETTA_IDLE1;
			break;

		case 1:
			iAnim = HLBERETTA_IDLE2;
			break;

		default:
			iAnim = HLBERETTA_IDLE3;
			break;
		}

		self.SendWeaponAnim( iAnim, 0, GetBodygroup() );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 6, 8 );//how long till we do this again.
	}

	void Reload()
	{
		if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType) <= 0 )
			return;

		const bool bResult = self.DefaultReload( MAX_CLIP, self.m_iClip > 0 ? HLBERETTA_RELOAD_NOT_EMPTY : HLBERETTA_RELOAD, 1.5, GetBodygroup() );

		if( bResult )
		{
			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0, 15.0 );
		}

		BaseClass.Reload();
	}
}

class ammo_bts_beretta : ScriptBasePlayerAmmoEntity
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

		iGive = Math.RandomLong( 2, 15 );

		if( pOther.GiveAmmo( iGive, "9mm", MAX_AMMO ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

string GetHLBerettaName()
{
	return "weapon_bts_beretta";
}

string GetHLBerettaAmmoName()
{
	return "ammo_bts_beretta";
}

void RegisterHLBeretta()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_BERETTA::weapon_bts_beretta", GetHLBerettaName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_BERETTA::ammo_bts_beretta", GetHLBerettaAmmoName() );
	g_ItemRegistry.RegisterWeapon( GetHLBerettaName(), "bts_rc/weapons", "9mm", "flashlightbattery", GetHLBerettaAmmoName() );
}

}
