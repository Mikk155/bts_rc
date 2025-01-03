// Idk what gun is this lmao
// Author: Nevermore2790, Nero0
// Rewrited by Rizulix for bts_rc (december 2024)

#include "../proj/dart"
#include "../utils/player_class"

namespace BTS_DARTGUN
{

enum btsdartgun_e
{
	LONGIDLE = 0,
	IDLE1,
	LAUNCH,
	RELOAD,
	DRAW,
	SHOOT1,
	SHOOT2,
	SHOOT3,
};

enum bodygroups_e
{
	BODY = 0
};

enum spinspeed_e
{
	STOP = 0,
	START,
	SLOW,
	MED,
	FAST
	// FIRE?
};

// Models
string P_MODEL = "models/bts_rc/weapons/p_dartgun.mdl";
string V_MODEL = "models/bts_rc/weapons/v_dartgun.mdl";
string W_MODEL = "models/bts_rc/weapons/w_dartgun.mdl";
string A_MODEL = "models/bts_rc/weapons/w_dartgun_clip.mdl";
string PRJ_MDL = "models/bts_rc/weapons/dart.mdl";
// Sounds
string SHOOT_SND = "bts_rc/weapons/dartgun_fire1.wav";
string EMPTY_SND = "hlclassic/weapons/357_cock1.wav";
// array<string> SOUNDS = { }; // no viewmodel sounds ¯\_(ツ)_/¯
string SPINUP_SND = "bts_rc/weapons/dartgun_chargeup.wav";
string SPINDOWN_SND = "bts_rc/weapons/dartgun_chargedown.wav";
// string SPINLOOP_SND = "bts_rc/weapons/dartgun_chargeloop.wav";
string RELOAD_SND1 = "hlclassic/weapons/reload1.wav";
string RELOAD_SND2 = "hlclassic/weapons/reload2.wav";
string RELOAD_SND3 = "hlclassic/weapons/reload3.wav";
// Weapon info
int MAX_CARRY	= 60;
int MAX_CLIP = 20;
int DEFAULT_GIVE = MAX_CLIP * 2;
int AMMO_GIVE = MAX_CLIP;
int AMMO_DROP = AMMO_GIVE;
int WEIGHT = 20;
int FLAGS = 0;
int ID; // assigned on register
string AMMO_TYPE = "bts:darts";
// Weapon HUD
uint SLOT = 3;
uint POSITION = 5;
// Vars
float DAMAGE = 1.0f;
float AIR_VELOCITY = 2000.0f;
float WATER_VELOCITY = 1000.0f;
Vector OFFSET( 0.0f, 2.0f, -2.0f ); // for projectile

class weapon_bts_dartgun : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{
	private CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer>( self.m_hPlayer.GetEntity() ); }
		set       { self.m_hPlayer = EHandle( @value ); }
	}
	private bool m_fHasHEV
	{
		get const { return g_PlayerClass[m_pPlayer] == HELMET; }
	}
	private int m_iSpinSpeed;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( W_MODEL ) );
		self.m_iDefaultAmmo = DEFAULT_GIVE;
		self.FallInit();

		m_iSpinSpeed = STOP;
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( V_MODEL );
		g_Game.PrecacheModel( W_MODEL );
		g_Game.PrecacheModel( P_MODEL );
		g_Game.PrecacheModel( A_MODEL );
		g_Game.PrecacheModel( PRJ_MDL );

		g_SoundSystem.PrecacheSound( SHOOT_SND );
		g_SoundSystem.PrecacheSound( EMPTY_SND );

		// for( uint i = 0; i < SOUNDS.length(); i++ )
		// 	g_SoundSystem.PrecacheSound( SOUNDS[i] );

		g_SoundSystem.PrecacheSound( SPINUP_SND );
		g_SoundSystem.PrecacheSound( SPINDOWN_SND );
		// g_SoundSystem.PrecacheSound( SPINLOOP_SND );
		g_SoundSystem.PrecacheSound( RELOAD_SND1 );
		g_SoundSystem.PrecacheSound( RELOAD_SND2 );
		g_SoundSystem.PrecacheSound( RELOAD_SND3 );

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
		info.iMaxAmmo2 = -1;
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
		self.DefaultDeploy( self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), DRAW, "mp5"/*, 0, GetBodygroup()*/ );	//Third person Player won't be having any reload animations. Expect them to see go doing Idle No-Weapon animation when it happens.
		self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
		return true;
	}

	void Holster( int skiplocal = 0 )
	{
		SpinDown();
		SetThink( null );
		BaseClass.Holster( skiplocal );
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
		// don't fire underwater, or if the clip is empty.
		// if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		// {
		// 	if( m_iSpinSpeed != STOP )
		// 		SpinDown();

		// 	self.PlayEmptySound();
		// 	self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
		// 	return;
		// }

		// SpinUp();

		// don't fire underwater, or if the clip is empty.
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			if( m_iSpinSpeed != STOP )
				self.m_flTimeWeaponIdle = g_Engine.time + 0.1f;

			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
			return;
		}

		SpinUp();

		if( m_iSpinSpeed > FAST )
			Fire();
	}

	void SecondaryAttack()
	{
		// don't fire underwater, or if the clip is empty.
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			if( m_iSpinSpeed != STOP )
				self.m_flTimeWeaponIdle = g_Engine.time + 0.1f;

			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
			return;
		}

		SpinUp();
	}

	void Reload()
	{
		if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return;

		if( self.m_flNextPrimaryAttack > g_Engine.time )
			return;

		self.DefaultReload( MAX_CLIP, RELOAD, 3.0f/*, GetBodygroup()*/ );
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 2.75f;
		SetThink( ThinkFunction( this.FinishAnim ) );
		pev.nextthink = g_Engine.time + 1.5f;
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_iSpinSpeed != STOP )
		{
			SpinDown();
			self.m_flTimeWeaponIdle = g_Engine.time + 3.0f;
			return;
		}

		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) )
		{
			case 0: self.SendWeaponAnim( LONGIDLE/*, 0, GetBodygroup()*/ ); break;
			case 1: self.SendWeaponAnim( IDLE1/*, 0, GetBodygroup()*/ ); break;
		}

		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0f, 15.0f ); // how long till we do this again.
	}

	private void FinishAnim()
	{
		SetThink( null );
		self.SendWeaponAnim( LONGIDLE/*, 0, GetBodygroup()*/ );
		BaseClass.Reload();

		float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0.0f, 1.0f );
		if( flRand >= 0.75 )
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, RELOAD_SND1, 1.0f, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
		else if( flRand >= 0.5 )
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, RELOAD_SND2, 1.0f, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
		else
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, RELOAD_SND3, 1.0f, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
	}

	private void SpinUp()
	{
		// spin up
		m_pPlayer.SetMaxSpeedOverride( 150 );
		m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;

		switch( m_iSpinSpeed )
		{
			case STOP:
				self.SendWeaponAnim( LONGIDLE/*, 0, GetBodygroup()*/ );
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, SPINUP_SND, 1.0f, ATTN_NORM );
			case START: case SLOW: case MED: case FAST:
				m_iSpinSpeed += 1;
				// g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, SPINLOOP_SND, 1.0f, ATTN_NORM ); // here?
				break;
		}

		self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.1f;
		self.m_flNextSecondaryAttack = 0.0f/*g_Engine.time + 0.0f*/;
	}

	private void SpinDown()
	{
		// Spin down
		m_pPlayer.SetMaxSpeedOverride( -1 );
		m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;

		self.SendWeaponAnim( IDLE1/*, 0, GetBodygroup()*/ );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SPINDOWN_SND, 1.0f, ATTN_NORM, 0, 80 + Math.RandomLong( 0, 0x3f ) );
		m_iSpinSpeed = STOP;

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
		self.m_flTimeWeaponIdle = g_Engine.time + 0.5f;
	}

	private void Fire()
	{
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		pev.effects |= EF_MUZZLEFLASH;

		//player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition() + g_Engine.v_forward * OFFSET.x + g_Engine.v_right * OFFSET.y + g_Engine.v_up * OFFSET.z;
		Vector vecVelocity = g_Engine.v_forward * ( ( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD ) ? WATER_VELOCITY : AIR_VELOCITY );

		float flSpread = 32.0f;
		if( m_pPlayer.pev.FlagBitSet( FL_DUCKING ) )
			flSpread = 16.0f;
		// if( self.m_fInZoom )
		// 	flSpread = 8.0f;

		vecVelocity = vecVelocity + g_Engine.v_right * Math.RandomFloat( -flSpread, flSpread ) + g_Engine.v_up * Math.RandomFloat( -flSpread, flSpread );

		// float flDamage = DAMAGE;
		// if( self.m_flCustomDmg > 0 )
		// 	flDamage = self.m_flCustomDmg;

		DART::Shoot( m_pPlayer.pev, vecSrc, vecVelocity, DAMAGE, PRJ_MDL );

		self.SendWeaponAnim( SHOOT1/*, 0, GetBodygroup()*/ );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SHOOT_SND, 1.0f, ATTN_NORM, 0, 100 );
		m_pPlayer.pev.punchangle.x = -2.0f;
		m_pPlayer.pev.punchangle.y = -1.0f;

		if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && m_fHasHEV )
			m_pPlayer.SetSuitUpdate( '!HEV_AMO0', false, 0 );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.1f;
		self.m_flTimeWeaponIdle = g_Engine.time + 0.1f;
	}
}

class ammo_bts_dartgun : ScriptBasePlayerAmmoEntity
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
		if( pOther.GiveAmmo( AMMO_GIVE, AMMO_TYPE, MAX_CARRY ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1.0f, ATTN_NORM );
			return true;
		}
		return false;
	}
}

string GetName()
{
	return "weapon_bts_dartgun";
}

string GetAmmoName()
{
	return "ammo_bts_dartgun";
}

void Register()
{
	DART::Register();
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_DARTGUN::weapon_bts_dartgun", GetName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_DARTGUN::ammo_bts_dartgun", GetAmmoName() );
	ID = g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", AMMO_TYPE, "", GetAmmoName(), "" );
}

} //End of namespace
