/*
* M16A3 Full Auto
*/
// Rewrited by Rizulix for bts_rc (december 2024)

#include "../utils/player_class"

namespace BTS_M16A3
{

enum m16a3_e
{
	DRAW = 0,
	HOLSTER,
	IDLE,
	FIDGET,
	SHOOT1,
	SHOOT2,
	RELOAD,
	LAUNCH,
	RELOAD2 // m203 reload
};

enum bodygroups_e
{
	STUDIO0 = 0,
	STUDIO1,
	HANDS
};

// Models
string W_MODEL = "models/bts_rc/weapons/w_m16.mdl";
string V_MODEL = "models/bts_rc/weapons/v_m16a2.mdl";
string P_MODEL = "models/bts_rc/weapons/p_m16.mdl";
string A_MODEL = "models/bts_rc/weapons/w_9mmarclip.mdl";
string G_MODEL = "models/hlclassic/w_argrenade.mdl";
string PRJ_MDL = "models/hlclassic/grenade.mdl";
// Sounds
string SHOOT_SND = "bts_rc/weapons/m16_fire1.wav";
string SHOOT2_SND = "hlclassic/weapons/glauncher.wav";
string SHOOT2_SND2 = "hlclassic/weapons/glauncher2.wav";
string EMPTY_SND = "hlclassic/weapons/357_cock1.wav";
array<string> SOUNDS = {
	"weapons/m16_draw.wav",
	"weapons/m16_magout_metallic.wav",
	"weapons/m16_magin_metallic.wav",
	"weapons/m16_charge.wav"
};
// Weapon info
int MAX_CARRY = 150;
int MAX_CLIP = 30;
int MAX_CARRY2 = 10;
int MAX_CLIP2 = WEAPON_NOCLIP;
// int DEFAULT_GIVE = Math.RandomLong( 15, 30 );
// int DEFAULT_GIVE2 = Math.RandomLong( 0, 1 );
int AMMO_GIVE = MAX_CLIP;
int AMMO_DROP = AMMO_GIVE;
int AMMO_GIVE2 = 2;
int AMMO_DROP2 = 1;
int WEIGHT = 5;
int FLAGS = 0;
int ID; // assigned on register
string AMMO_TYPE = "556";
string AMMO_TYPE2 = "ARgrenades";
// Weapon HUD
int SLOT = 2;
int POSITION = 10;
// Vars
int DAMAGE = 15;
float DAMAGE2 = 100.0f;
Vector CROUCH_CONE( 0.01f, 0.01f, 0.01f );
Vector SHELL( 32.0f, 6.0f, -12.0f );

class weapon_bts_m16 : ScriptBasePlayerWeaponEntity
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
	private int m_iTracerCount;
	private int m_iShell;

	int GetBodygroup()
	{
		pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), pev.body, HANDS, Math.min( 0, g_PlayerClass[m_pPlayer] ) );
		return pev.body;
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( W_MODEL ) );
		self.m_iDefaultAmmo = Math.RandomLong( 15, MAX_CLIP );
		self.m_iDefaultSecAmmo = Math.RandomLong( 0, 1 );
		self.FallInit();

		m_iTracerCount = 0;
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( W_MODEL );
		g_Game.PrecacheModel( V_MODEL );
		g_Game.PrecacheModel( P_MODEL );
		g_Game.PrecacheModel( A_MODEL );
		g_Game.PrecacheModel( G_MODEL );
		g_Game.PrecacheModel( PRJ_MDL );

		m_iShell = g_Game.PrecacheModel( "models/bts_rc/weapons/saw_shell.mdl" );

		g_Game.PrecacheOther( "grenade" );
		g_Game.PrecacheOther( GetAmmoName() );
		g_Game.PrecacheOther( GetGLAmmoName() );

		g_SoundSystem.PrecacheSound( SHOOT_SND );
		g_SoundSystem.PrecacheSound( SHOOT2_SND );
		g_SoundSystem.PrecacheSound( SHOOT2_SND2 );
		g_SoundSystem.PrecacheSound( EMPTY_SND );

		for( uint i = 0; i < SOUNDS.length(); i++ )
			g_SoundSystem.PrecacheSound( SOUNDS[i] );

		g_Game.PrecacheGeneric( "sprites/SAWFlash.spr" );
		g_Game.PrecacheGeneric( "events/muzzle_saw.txt" );
		g_Game.PrecacheGeneric( "sprites/bts_rc/wepspr.spr" );
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
		info.iAmmo2Drop = AMMO_DROP2;
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
		self.DefaultDeploy( self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), DRAW, "m16", 0, GetBodygroup() );
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
		return true;
	}

	void Holster( int skiplocal = 0 )
	{
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
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.13f;
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
		Vector vecSpread = m_pPlayer.pev.FlagBitSet( FL_DUCKING ) ? CROUCH_CONE : VECTOR_CONE_3DEGREES;

		{
			float x, y;
			g_Utility.GetCircularGaussianSpread( x, y );

			Vector vecDir = vecAiming + x * vecSpread.x * g_Engine.v_right + y * vecSpread.y * g_Engine.v_up;
			Vector vecEnd = vecSrc + vecDir * 8192.0f;

			TraceResult tr;
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
			self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, DAMAGE, m_pPlayer.pev );

			// each 4 bullets
			if( ( m_iTracerCount++ % 4 ) == 0 )
			{
				Vector vecTracerSrc = vecSrc + Vector( 0.0f, 0.0f, -4.0f ) + g_Engine.v_right * 2.0f + g_Engine.v_forward * 16.0f;
				NetworkMessage tracer( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecTracerSrc );
					tracer.WriteByte( TE_TRACER );
					tracer.WriteCoord( vecTracerSrc.x );
					tracer.WriteCoord( vecTracerSrc.y );
					tracer.WriteCoord( vecTracerSrc.z );
					tracer.WriteCoord( tr.vecEndPos.x );
					tracer.WriteCoord( tr.vecEndPos.y );
					tracer.WriteCoord( tr.vecEndPos.z );
				tracer.End();
			}

			if( tr.flFraction < 1.0f && tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if( ( pHit is null || pHit.IsBSPModel() ) && !pHit.pev.FlagBitSet( FL_WORLDBRUSH ) )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
			}
		}

		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
		{
			case 0: self.SendWeaponAnim( SHOOT1, 0, GetBodygroup() ); break;
			case 1: self.SendWeaponAnim( SHOOT2, 0, GetBodygroup() ); break;
			case 2: self.SendWeaponAnim( SHOOT1, 0, GetBodygroup() ); break;
		}

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SHOOT_SND, 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

		if( m_fHasHEV )
			m_pPlayer.pev.punchangle.x = -3.0f;
		else
			m_pPlayer.pev.punchangle.x = m_pPlayer.pev.FlagBitSet( FL_DUCKING ) ? float( Math.RandomLong( -3, 2 )) : float( Math.RandomLong( -8, 3 ) );

		Vector vecForward, vecRight, vecUp;
		g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
		Vector vecOrigin = m_pPlayer.GetGunPosition() + vecForward * SHELL.x + vecRight * SHELL.y + vecUp * SHELL.z;
		Vector vecVelocity = m_pPlayer.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
		g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, m_pPlayer.pev.v_angle.y, m_iShell, TE_BOUNCE_SHELL );

		if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && m_fHasHEV )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_flNextPrimaryAttack = g_Engine.time + ( m_fHasHEV ? 0.142f : 0.145f );
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0f, 15.0f );
	}

	void SecondaryAttack()
	{
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextSecondaryAttack = g_Engine.time + 0.15f;
			return;
		}

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
		m_pPlayer.m_flStopExtraSoundTime = g_Engine.time + 0.2f;

		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.pev.origin + g_Engine.v_forward * 16.0f + g_Engine.v_right * 6.0f;
		vecSrc = vecSrc + ( ( ( m_pPlayer.pev.button & IN_DUCK ) != 0 ) ? g_vecZero : ( m_pPlayer.pev.view_ofs * 0.5f ) );

		// we don't add in player velocity anymore.
		CGrenade@ pGrenade = g_EntityFuncs.ShootContact( m_pPlayer.pev, vecSrc, g_Engine.v_forward * 900.0f );
		if( pGrenade !is null )
		{
			g_EntityFuncs.SetModel( pGrenade, PRJ_MDL );
			pGrenade.pev.dmg = DAMAGE2;
		}

		self.SendWeaponAnim( LAUNCH, 0, GetBodygroup() );

		if( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) != 0 )
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SHOOT2_SND, 0.8f, ATTN_NORM, 0, PITCH_NORM );
		else
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SHOOT2_SND2, 0.8f, ATTN_NORM, 0, PITCH_NORM );

		m_pPlayer.pev.punchangle.x = -11.0f;

		if( m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0 && m_fHasHEV )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.25f;
		self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;
	}

	void Reload()
	{
		if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return;

		self.DefaultReload( MAX_CLIP, RELOAD, 3.25f, GetBodygroup() );
		self.m_flTimeWeaponIdle = g_Engine.time + 3.25f;
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) )
		{
			case 0: self.SendWeaponAnim( IDLE, 0, GetBodygroup() ); break;
			case 1: self.SendWeaponAnim( FIDGET, 0, GetBodygroup() ); break;
		}

		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0f, 15.0f );
	}
}

class ammo_bts_m16 : ScriptBasePlayerAmmoEntity
{
	private int m_iAmount = AMMO_GIVE;

	void Spawn()
	{
		if( pev.ClassNameIs( GetDAmmoName() ) )
			m_iAmount = Math.RandomLong( 9, 23 );

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
		if( pOther.GiveAmmo( m_iAmount, AMMO_TYPE, MAX_CARRY ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1.0f, ATTN_NORM );
			return true;
		}
		return false;
	}
}

class ammo_bts_m16_grenade : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, G_MODEL );
		BaseClass.Spawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel( G_MODEL );
		g_SoundSystem.PrecacheSound( "hlclassic/items/9mmclip1.wav" );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		if( pOther.GiveAmmo( pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? AMMO_DROP2 : AMMO_GIVE2, AMMO_TYPE2, MAX_CARRY2 ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1.0f, ATTN_NORM );
			return true;
		}
		return false;
	}
}

string GetName()
{
	return "weapon_bts_m16";
}

string GetAmmoName()
{
	return "ammo_bts_m16";
}

string GetDAmmoName()
{
	return "ammo_bts_556round";
}

string GetGLAmmoName()
{
	return "ammo_bts_m16_grenade";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M16A3::weapon_bts_m16", GetName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M16A3::ammo_bts_m16", GetAmmoName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M16A3::ammo_bts_m16", GetDAmmoName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M16A3::ammo_bts_m16_grenade", GetGLAmmoName() );
	ID = g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", AMMO_TYPE, AMMO_TYPE2, GetAmmoName(), GetGLAmmoName() );
}

}
