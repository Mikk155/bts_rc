/**
>>>Credits<<<

->Model: Hellspike
->Textures: klla_syc3/flamshmizer
->Animations: Michael65
->Compile, Edits: Norman the Loli Pirate
->Colored Model: D.N.I.O. 071
->Sprites: Der Graue Fuchs
->Script author: KernCore, Nero0 ( CSO Grenade Projectile )
->Sounds: Resident Evil Cold Blood Team

* This script is a sample to be used in: https://github.com/baso88/SC_AngelScript/
* You're free to use this sample in any way you would like to
* Just remember to credit the people who worked to provide you this

**/
namespace HL_M79
{

enum HL_M79_Animations
{
	M79_IDLE = 0,
	M79_SHOOT,
	M79_RELOAD,
	M79_DEPLOY,
	M79_HOLSTER
};

//Models
const string M79_W_MODEL = "models/bts_rc/weapons/w_m79.mdl"; //World
const string M79_V_MODEL = "models/bts_rc/weapons/v_m79.mdl"; //View
const string M79_P_MODEL = "models/bts_rc/weapons/p_m79.mdl"; //Player
const string M79_G_MODEL = "models/grenade.mdl"; //Grenade
const string M79_A_MODEL = "models/w_argrenade.mdl"; //Ammo
//Sounds
const string M79_S_SHOOT = "bts_rc/weapons/m79_fire.wav";
//Sprites
const string SPRITE_MUZZLE_GRENADE	= "sprites/bts_rc/muzzleflash12.spr";
const string SPRITE_BEAM			= "sprites/laserbeam.spr";
const string SPRITE_EXPLOSION1		= "sprites/bts_rc/zerogxplode.spr";
const string SPRITE_SMOKE			= "sprites/steam1.spr";
//Information
const int M79_DEFAULT_GIVE 	= Math.RandomLong( 0, 3 );
const int M79_MAX_CLIP  	= 1;
const int M79_MAX_CARRY 	= 10;
const int M79_WEIGHT		= 20;
const int M79_AMMO_GIVE 	= 2;
const float GRENADE_DAMAGE	 	= 125.0;
const float GRENADE_RADIUS	  = 240.0;
const float GRENADE_VELOCITY	= 1200.0;
const Vector SHELL_ORIGIN		= Vector( 20.0, 10.0, -4.0 ); //forward, right, up
const Vector MUZZLE_ORIGIN		= Vector( 16.0, 4.0, -4.0 ); //forward, right, up

class weapon_bts_m79 : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set	   	{ self.m_hPlayer = EHandle( @value ); }
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
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( M79_V_MODEL ), m_iCurBodyConfig, 1, 0 );
				break;
			case 1:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( M79_V_MODEL ), m_iCurBodyConfig, 1, 1 );
				break;
			case 2:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( M79_V_MODEL ), m_iCurBodyConfig, 1, 2 );
				break;
			case 3:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( M79_V_MODEL ), m_iCurBodyConfig, 1, 3 );
				break;
			case 4:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( M79_V_MODEL ), m_iCurBodyConfig, 1, 4 );
				break;
		}

		return m_iCurBodyConfig;
	}
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( M79_W_MODEL ) );

		self.m_iDefaultAmmo = M79_DEFAULT_GIVE;

		self.FallInit(); //get ready to fall
	}

	//Always precache the stuff you're going to use
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( M79_W_MODEL );
		g_Game.PrecacheModel( M79_V_MODEL );
		g_Game.PrecacheModel( M79_P_MODEL );
		g_Game.PrecacheModel( M79_G_MODEL );

		//Precache here, because there's no late precache
		g_Game.PrecacheModel( M79_A_MODEL );
		g_Game.PrecacheModel( "sprites/bts_rc/weapon_M79.spr" );

		//Precaches the sound for the engine to use
		g_SoundSystem.PrecacheSound( M79_S_SHOOT );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );

		//Precaches the stuff for download
		g_Game.PrecacheGeneric( "sprites/" + "bts_rc/M79_crosshair.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "bts_rc/weapon_M79.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "bts_rc/weapons/weapon_bts_m79.txt" );
		g_Game.PrecacheModel( SPRITE_BEAM );
		g_Game.PrecacheModel( SPRITE_EXPLOSION1 );
		g_Game.PrecacheModel( SPRITE_SMOKE );
		g_Game.PrecacheModel( SPRITE_MUZZLE_GRENADE );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= M79_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= M79_MAX_CLIP;
		info.iAmmo1Drop	= 2; 
		info.iAmmo2Drop	= -1; 
		info.iSlot   	= 3; 
		info.iPosition 	= 4; 
		info.iFlags  	= 0; 
		info.iWeight 	= M79_WEIGHT; 
		return true;
	}

	float WeaponTimeBase()
	{
		return g_Engine.time;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;

		NetworkMessage m79( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m79.WriteLong( g_ItemRegistry.GetIdForName("weapon_bts_m79") ); //A better way than using self.m_iId
		m79.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( M79_V_MODEL ), self.GetP_Model( M79_P_MODEL ), M79_DEPLOY, "bow", 0, GetBodygroup() );
		
			float deployTime = 1.03;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		self.SendWeaponAnim( M79_HOLSTER, 0, GetBodygroup() );
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		//don't fire underwater/without having ammo loaded
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.0f;
			return;
		}

		m_pPlayer.m_iWeaponVolume 	= NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash 	= BRIGHT_GUN_FLASH;

		//Notify the monsters about the grenade
		m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
		m_pPlayer.m_flStopExtraSoundTime = WeaponTimeBase() + 0.2;

		--self.m_iClip;
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH; //Add muzzleflash

		m_pPlayer.pev.punchangle.x = -10.0; //Recoil

		//player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		//Custom Volume and Pitch
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, M79_S_SHOOT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		//Handles the grenade as custom entity, and changes their model
		ProjectileAttack();

		//View model animation
		self.SendWeaponAnim( M79_SHOOT, 0, GetBodygroup() );

		self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 1;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 1;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + 5; //Idle pretty soon after shooting.

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
	}

	void ProjectileAttack()
	{
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		m_pPlayer.pev.punchangle.x = Math.RandomFloat(-2.0, -3.0 );

		Vector vecOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 8 + g_Engine.v_right * 4 + g_Engine.v_up * -2;
		Vector vecAngles = m_pPlayer.pev.v_angle;

		vecAngles.x = 180.0 - vecAngles.x; //vecAngles.x = 360.0 - vecAngles.x

		CBaseEntity@ cbeGrenade = g_EntityFuncs.Create( "m79_rocket", vecOrigin, vecAngles, false, m_pPlayer.edict() ); 
		m79_rocket@ pGrenade = cast<m79_rocket@>( CastToScriptClass( cbeGrenade ) );
		pGrenade.pev.velocity = g_Engine.v_forward * GRENADE_VELOCITY;

		CreateMuzzleflash( SPRITE_MUZZLE_GRENADE, MUZZLE_ORIGIN.x, MUZZLE_ORIGIN.y, MUZZLE_ORIGIN.z, 0.05, 128, 20.0 );
	}

	void Reload()
	{
		//if the mag = the max mag, return
		if( self.m_iClip == M79_MAX_CLIP )
			return;

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
			return;

		self.DefaultReload( M79_MAX_CLIP, M79_RELOAD, 3.88, GetBodygroup() );

		//Set 3rd person reloading animation -Sniper
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		self.SendWeaponAnim( M79_IDLE, 0, GetBodygroup() );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 6 ); //How much time to idle again
	}
}

class m79_rocket : ScriptBaseEntity
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, M79_G_MODEL );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.movetype = MOVETYPE_TOSS;
		pev.solid = SOLID_BBOX;

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_BEAMFOLLOW );
			m1.WriteShort( self.entindex() );
			m1.WriteShort( g_EngineFuncs.ModelIndex( SPRITE_BEAM ) );
			m1.WriteByte( 20 ); //life
			m1.WriteByte( 4 );  //width
			m1.WriteByte( 190 ); //r
			m1.WriteByte( 190 ); //g
			m1.WriteByte( 190 ); //b
			m1.WriteByte( 200 ); //brightness
		m1.End();

		SetThink( ThinkFunction( this.GrenadeThink ) );
		SetTouch( TouchFunction( this.GrenadeTouch ) );

		pev.nextthink = g_Engine.time + 0.01;
	}

	void Precache()
	{
		g_Game.PrecacheModel( M79_G_MODEL );
		g_Game.PrecacheModel( SPRITE_BEAM );
	}

	void GrenadeThink()
	{
		pev.angles = Math.VecToAngles( pev.velocity.Normalize() );

		pev.nextthink = g_Engine.time + 0.1;
	}

	void GrenadeTouch( CBaseEntity@ pOther )
	{
		if( pOther.pev.classname == "m79_rocket" )
			return;

		if( g_EngineFuncs.PointContents( pev.origin) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		Explode();
	}

	void Explode()
	{
		TraceResult tr;
		Vector vecSpot = pev.origin - pev.velocity.Normalize() * 32;
		Vector vecEnd = pev.origin + pev.velocity.Normalize() * 64;
		g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, self.edict(), tr );

		g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong( 0, 1) );

		int sparkCount = Math.RandomLong( 0, 3 );
		for( int i = 0; i < sparkCount; i++ )
			g_EntityFuncs.Create( "spark_shower", pev.origin, tr.vecPlaneNormal, false );

		tr = g_Utility.GetGlobalTrace();

		//Pull out of the wall a bit
		if( tr.flFraction != 1.0f )
			pev.origin = tr.vecEndPos + ( tr.vecPlaneNormal * 24.0f );

		Vector vecOrigin = pev.origin;

		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_EngineFuncs.ModelIndex( SPRITE_EXPLOSION1) );
			m1.WriteByte( 15 ); //scale * 10
			m1.WriteByte( 30 ); //framerate
			m1.WriteByte( TE_EXPLFLAG_NONE );
		m1.End();

		float flDamage = GRENADE_DAMAGE;
		float flRadius = GRENADE_RADIUS;

		g_WeaponFuncs.RadiusDamage( pev.origin, self.pev, pev.owner.vars, flDamage, flRadius, CLASS_NONE, DMG_MORTAR );

		pev.effects |= EF_NODRAW;
		pev.velocity = g_vecZero;
		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_NOT;

		SetTouch( null );

		SetThink( ThinkFunction( this.Smoke ) );
		pev.nextthink = g_Engine.time + 0.5;
	}

	void Smoke()
	{
		NetworkMessage msg1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			msg1.WriteByte( TE_SMOKE );
			msg1.WriteCoord( pev.origin.x );
			msg1.WriteCoord( pev.origin.y );
			msg1.WriteCoord( pev.origin.z );
			msg1.WriteShort( g_EngineFuncs.ModelIndex( SPRITE_SMOKE ) );
			msg1.WriteByte( 40 ); //scale * 10
			msg1.WriteByte( 6 ); //framerate
		msg1.End();

		g_EntityFuncs.Remove( self );
	}
}

//Ammo class
class ammo_bts_m79 : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, M79_A_MODEL );
		BaseClass.Spawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel( M79_A_MODEL );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		int iGive;

		iGive = M79_AMMO_GIVE;

		if( pOther.GiveAmmo( iGive, "ARgrenades", M79_MAX_CARRY ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}
		return false;
	}
}

string GetM79WName()
{
	return "weapon_bts_m79";
}

string GetM79AName()
{
	return "ammo_bts_m79";
}

void RegisterM79()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_M79::m79_rocket", "m79_rocket" );
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_M79::weapon_bts_m79", GetM79WName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_M79::ammo_bts_m79", GetM79AName() );
	g_ItemRegistry.RegisterWeapon( GetM79WName(), "bts_rc/weapons", "ARgrenades", "", GetM79AName() );
}

} //Namespace end