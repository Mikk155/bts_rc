// Suppressed Glock 17
// Models: Valve Software, Gearbox Software
// Scripts: Giegue, Rizulix, Valve Software
// Sound: Valve Software
// Sprites: Valve Software, TurtleRock Studios, SV BOY
// Rewrited by Rizulix for bts_rc (december 2024)

#include "../utils/player_class"

namespace HL_GLOCKSD
{

enum hlglocksd_e
{
	IDLE1 = 0,
	IDLE2,
	IDLE3,
	SHOOT,
	SHOOT_EMPTY,
	RELOAD_EMPTY,
	RELOAD,
	DRAW,
	HOLSTER,
	ADD_SILENCER
};

enum bodygroups_e
{
	STUDIO0 = 0,
	STUDIO1,
	HANDS
};

// Models
string W_MODEL = "models/bts_rc/weapons/w_9mmhandgunsd.mdl";
string V_MODEL = "models/bts_rc/weapons/v_9mmhandgunsd.mdl";
string P_MODEL = "models/bts_rc/weapons/p_9mmhandgunsd.mdl";
string A_MODEL = "models/hlclassic/w_9mmclip.mdl";
// Sounds
string SHOOT_SND1 = "bts_rc/weapons/glocksd_fire1.wav";
string SHOOT_SND2 = "bts_rc/weapons/glocksd_fire2.wav";
string EMPTY_SND = "hlclassic/weapons/357_cock1.wav";
array<string> SOUNDS = {
	"hlclassic/items/9mmclip1.wav",
	"hlclassic/items/9mmclip2.wav"
};
// Weapon info
int MAX_CARRY = 120;
int MAX_CLIP = 17;
// int DEFAULT_GIVE = Math.RandomLong( 8, 17 );
int AMMO_GIVE = MAX_CLIP;
int AMMO_DROP = AMMO_GIVE;
int WEIGHT = 10;
int FLAGS = 0;
string AMMO_TYPE = "9mm";
// Weapon HUD
int SLOT = 1;
int POSITION = 5;
// Vars
int DAMAGE = 12;
Vector SEMI_CONE( 0.01f, 0.01f, 0.01f );
Vector RAPID_CONE( 0.1f, 0.1f, 0.1f );
Vector SHELL( 32.0f, 6.0f, -12.0f );
// weapon id
const int ID = Register();

class weapon_bts_glocksd : ScriptBasePlayerWeaponEntity
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
		self.m_iDefaultAmmo = Math.RandomLong( 8, MAX_CLIP );
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

		g_Game.PrecacheOther( GetAmmoName() );
		g_Game.PrecacheOther( GetDAmmoName() );

		g_SoundSystem.PrecacheSound( SHOOT_SND );
		g_SoundSystem.PrecacheSound( SHOOT2_SND );
		g_SoundSystem.PrecacheSound( EMPTY_SND );

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
		self.DefaultDeploy( self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), DRAW, "onehanded", 0, GetBodygroup() );
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
		Fire( SEMI_CONE, m_fHasHEV ? 0.3f : 0.325f );
	}

	void SecondaryAttack()
	{
		Fire( RAPID_CONE, m_fHasHEV ? 0.2f : 0.225f );
	}

	void Reload()
	{
		if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return;

		self.DefaultReload( MAX_CLIP, self.m_iClip != 0 ? RELOAD : RELOAD_EMPTY, 1.5f, GetBodygroup() );
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
			case 0: self.SendWeaponAnim( IDLE1, 0, GetBodygroup() ); break; 
			case 1: self.SendWeaponAnim( IDLE2, 0, GetBodygroup() ); break; 
			default: self.SendWeaponAnim( IDLE3, 0, GetBodygroup() ); break;
		}

		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 6.0f, 8.0f );
	}

	private void Fire( const Vector& in vecSpread, float flCycleTime )
	{
		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.2f;
			return;
		}

		m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;

		--self.m_iClip;

		m_pPlayer.pev.effects &= ~EF_MUZZLEFLASH;
		pev.effects &= ~EF_MUZZLEFLASH;

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		{
			float x, y;
			g_Utility.GetCircularGaussianSpread( x, y );

			Vector vecDir = vecAiming + x * vecSpread.x * g_Engine.v_right + y * vecSpread.y * g_Engine.v_up;
			Vector vecEnd = vecSrc + vecDir * 8192.0f;

			TraceResult tr;
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
			self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, DAMAGE, m_pPlayer.pev );

			if( tr.flFraction < 1.0f && tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if( ( pHit is null || pHit.IsBSPModel() ) && !pHit.pev.FlagBitSet( FL_WORLDBRUSH ) )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
			}
		}

		self.SendWeaponAnim( self.m_iClip != 0 ? SHOOT : SHOOT_EMPTY, 0, GetBodygroup() );
		switch( Math.RandomLong( 0, 1 ) )
		{
			case 0: g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, SHOOT_SND1, Math.RandomFloat( 0.9f, 1.0f ), ATTN_NORM ); break;
			case 1: g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, SHOOT_SND2, Math.RandomFloat( 0.9f, 1.0f ), ATTN_NORM ); break;
		}
		m_pPlayer.pev.punchangle.x = m_fHasHEV ? -2.0f : -2.65f;

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

class ammo_bts_glocksd : ScriptBasePlayerAmmoEntity
{
	private int m_iAmount = AMMO_GIVE;

	void Spawn()
	{
		if( pev.ClassNameIs( GetDAmmoName() ) )
			m_iAmount = Math.RandomLong( 8, 13 );

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

string GetName()
{
	return "weapon_bts_glocksd";
}

string GetAmmoName()
{
	return "ammo_bts_glocksd";
}

string GetDAmmoName()
{
	return "ammo_bts_dglocksd";
}

int Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_GLOCKSD::weapon_bts_glocksd", GetName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_GLOCKSD::ammo_bts_glocksd", GetAmmoName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_GLOCKSD::ammo_bts_glocksd", GetDAmmoName() ); // ammo drop case
	return g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", AMMO_TYPE, "", GetAmmoName(), "" );
}

}
