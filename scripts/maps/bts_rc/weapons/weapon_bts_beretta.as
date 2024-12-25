/*
* M9 Beretta w/ Torchlight attached
* Author: Giegue, Mikk
* Animation: MTB
*/
// Rewrited by Rizulix (december 2024)

namespace HL_BERETTA
{

enum hlberetta_e
{
	IDLE1 = 0,
	IDLE2,
	IDLE3_1,
	SHOOT,
	SHOOT_EMPTY,
	RELOAD,
	RELOAD_NOT_EMPTY,
	DRAW,
	HOLSTER,
	IDLE3_2
};

// Models
string W_MODEL = "models/bts_rc/weapons/w_beretta.mdl";
string V_MODEL = "models/bts_rc/weapons/v_beretta.mdl";
string P_MODEL = "models/bts_rc/weapons/p_beretta.mdl";
string A_MODEL = "models/hlclassic/w_9mmclip.mdl";
// Sounds
string SHOOT_SND = "bts_rc/weapons/beretta_fire1.wav";
string EMPTY_SND = "hlclassic/weapons/357_cock1.wav";
string SWITCH_SND = "bts_rc/items/flashlight1.wav";
array<string> SOUNDS = {
	"bts_rc/weapons/beretta_draw.wav",
	"bts_rc/items/9mmclip1.wav",
	"bts_rc/items/9mmclip2.wav",
	"bts_rc/items/9mmcock3.wav"
};
// Weapon info
int MAX_CARRY = 120;
int MAX_CARRY2 = 60;
int MAX_CLIP = 15;
int MAX_CLIP2 = WEAPON_NOCLIP;
// int DEFAULT_GIVE = Math.RandomLong( 1, 15 );
// int DEFAULT_GIVE2 = Math.RandomLong( 0, 3 );
int AMMO_GIVE = MAX_CLIP;
int AMMO_DROP = AMMO_GIVE;
int WEIGHT = 10;
int FLAGS = 0;
string AMMO_TYPE = "9mm";
string AMMO_TYPE2 = "flashlightbattery";
// Weapon HUD
int SLOT = 1;
int POSITION = 6;
// Vars
int DAMAGE = 14;
string FLASHLIGHT = "$i_flashBattery";
Vector CONE( 0.01f, 0.01f, 0.01f );
Vector SHELL( 32.0f, 6.0f, -12.0f );

class weapon_bts_beretta : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer>( self.m_hPlayer.GetEntity() ); }
		set       { self.m_hPlayer = EHandle( @value ); }
	}
	private int m_iFlashBattery // saved battery shared between weapons
	{
		get const
		{
			CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
			if( pCustom.HasKeyvalue( FLASHLIGHT ) )
				return pCustom.GetKeyvalue( FLASHLIGHT ).GetInteger();
			else
				return m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0 ? 0 : m_pPlayer.m_iFlashBattery;
		}
		set
		{
			g_EntityFuncs.DispatchKeyValue( m_pPlayer.edict(), FLASHLIGHT, "" + value );
		}
	}
	private int m_iCurBaterry; // for clamping
	private int m_iShell;

	/*dictionary g_Models =
	{
		{ "bts_barney", 0 }, { "bts_otis", 0 },
		{ "bts_barney2", 0 }, { "bts_barney3", 0 },
		{ "bts_scientist", 1 }, { "bts_scientist2", 1 },
		{ "bts_scientist3", 3 }, { "bts_scientist4", 1 },
		{ "bts_scientist5", 1 }, { "bts_scientist6", 1 },
		{ "bts_construction", 2 }, { "bts_helmet", 4 }
	};*/

	int GetBodygroup()
	{
		/*string modelName = g_EngineFuncs.GetInfoKeyBuffer( m_pPlayer.edict() ).GetValue( "model" );

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
		}*/

		return /*m_iCurBodyConfig*/0;
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, W_MODEL );
		self.m_iDefaultAmmo = Math.RandomLong( 1, MAX_CLIP );
		self.m_iDefaultSecAmmo = Math.RandomLong( 0, 3 );
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( W_MODEL );
		g_Game.PrecacheModel( V_MODEL );
		g_Game.PrecacheModel( P_MODEL );
		g_Game.PrecacheModel( A_MODEL );

		m_iShell = g_Game.PrecacheModel( "models/hlclassic/shell.mdl" );

		g_SoundSystem.PrecacheSound( SHOOT_SND );
		g_SoundSystem.PrecacheSound( EMPTY_SND );
		g_SoundSystem.PrecacheSound( SWITCH_SND );

		for( uint i = 0; i < SOUNDS.length(); i++ )
			g_SoundSystem.PrecacheSound( SOUNDS[i] );

		g_Game.PrecacheGeneric( "sprites/bts_rc/weapons/" + pev.classname + ".txt" );
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;

		NetworkMessage weapon( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			weapon.WriteLong( g_ItemRegistry.GetIdForName( pev.classname ) );
		weapon.End();
		return true;
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = MAX_CARRY;
		info.iAmmo1Drop = AMMO_DROP;
		info.iMaxAmmo2 = MAX_CARRY2;
		info.iAmmo2Drop = -1;
		info.iMaxClip = MAX_CLIP;
		info.iSlot = SLOT;
		info.iPosition = POSITION;
		info.iId = g_ItemRegistry.GetIdForName( pev.classname );
		info.iFlags = FLAGS;
		info.iWeight = WEIGHT;
		return true;
	}

	bool Deploy()
	{
		m_pPlayer.m_iFlashBattery = m_iCurBaterry = m_iFlashBattery;
		m_pPlayer.m_iHideHUD &= ~HIDEHUD_FLASHLIGHT;

		self.DefaultDeploy( self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), DRAW, "onehanded", 0, GetBodygroup() );
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
		m_pPlayer.m_flNextAttack = 0.0f;
		return true;
	}

	void Holster( int skiplocal = 0 )
	{
		if( m_pPlayer.FlashlightIsOn() )
			m_pPlayer.FlashlightTurnOff();

		m_pPlayer.m_iHideHUD |= HIDEHUD_FLASHLIGHT;
		m_iFlashBattery = m_iCurBaterry;

		BaseClass.Holster( skiplocal );
	}

	void ItemPostFrame()
	{
		if( m_pPlayer.m_iFlashBattery > m_iCurBaterry )
			m_pPlayer.m_iFlashBattery = m_iCurBaterry;

		if( m_iCurBaterry == 0 )
		{
			m_pPlayer.pev.effects &= ~EF_DIMLIGHT;
			NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, m_pPlayer.edict() );
				msg.WriteByte( 0 );
				msg.WriteByte( 0 );
			msg.End();
		}
		else
			m_iCurBaterry = m_pPlayer.m_iFlashBattery;

		BaseClass.ItemPostFrame();
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, EMPTY_SND, 0.8f, ATTN_NORM, 0, PITCH_NORM );
		}
		return false;
	}

	void PrimaryAttack()
	{
		if( false/*HEV.find( modelName ) >= 0*/ )
			BerettaFire( 0.30f, -2.0, true );
		else
			BerettaFire( 0.325f, -2.5, false );
	}

	void SecondaryAttack()
	{
		if( m_iCurBaterry != 0 || m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0 )
			return;

		m_pPlayer.m_iFlashBattery = m_iCurBaterry = 100;
		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );
		// g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SWITCH_SND, 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
	}

	void Reload()
	{
		if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return;

		self.DefaultReload( MAX_CLIP, self.m_iClip != 0 ? RELOAD_NOT_EMPTY : RELOAD, 1.5f, GetBodygroup() );
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0f, 15.0f );
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 3 ) )
		{
			// these 2 are the same but whatever
			case 0:  self.SendWeaponAnim( IDLE1, 0, GetBodygroup() ); break; 
			case 1:  self.SendWeaponAnim( IDLE2, 0, GetBodygroup() ); break; 
			default: self.SendWeaponAnim( IDLE3_1, 0, GetBodygroup() ); break;
		}

		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 6.0f, 8.0f );
	}

	private void BerettaFire( float flCycleTime, float flAimPunch, bool m_fHasHEV )
	{
		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.2f;
			return;
		}

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		pev.effects |= EF_MUZZLEFLASH;

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		{
			float x, y;
			g_Utility.GetCircularGaussianSpread( x, y );

			Vector vecDir = vecAiming + x * CONE.x * g_Engine.v_right + y * CONE.y * g_Engine.v_up;
			Vector vecEnd = vecSrc + vecDir * 8192.0f;

			TraceResult tr;
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
			self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, DAMAGE, m_pPlayer.pev );

			if( tr.flFraction < 1.0f && tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if( pHit !is null && pHit.IsBSPModel() && !pHit.pev.ClassNameIs( "worldspawn" ) )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
			}
		}

		self.SendWeaponAnim( self.m_iClip != 0 ? SHOOT : SHOOT_EMPTY, 0, GetBodygroup() );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SHOOT_SND, Math.RandomFloat( 0.92f, 1.0f ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
		m_pPlayer.pev.punchangle.x = flAimPunch;

		Vector vecForward, vecRight, vecUp;
		g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
		Vector vecOrigin = m_pPlayer.GetGunPosition() + vecForward * SHELL.x + vecRight * SHELL.y + vecUp * SHELL.z;
		Vector vecVelocity = m_pPlayer.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
		g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, m_pPlayer.pev.v_angle.y, m_iShell, TE_BOUNCE_SHELL );

		if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && m_fHasHEV )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flCycleTime;
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
	}
}

class ammo_bts_beretta : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, A_MODEL );
		BaseClass.Spawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel( A_MODEL );
		g_SoundSystem.PrecacheSound( "hlclassic/items/9mmclip1.wav" );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		if( pOther.GiveAmmo( pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? AMMO_GIVE : Math.RandomLong( 2, 15 ), AMMO_TYPE, MAX_CARRY ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1.0f, ATTN_NORM );
			return true;
		}
		return false;
	}
}

string GetName()
{
	return "weapon_bts_beretta";
}

string GetAmmoName()
{
	return "ammo_bts_beretta";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_BERETTA::weapon_bts_beretta", GetName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_BERETTA::ammo_bts_beretta", GetAmmoName() );
	g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", AMMO_TYPE, AMMO_TYPE2, GetAmmoName(), "" );
}

}
