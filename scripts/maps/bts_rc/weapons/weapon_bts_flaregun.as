/*
 * Emergency Flare Gun
 * Credits: Nero0, KernCore, Mikk, RaptorSKA
*/

#include '../hl_utils'

namespace BTS_FLAREGUN
{

enum flaregun_e
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

//Weapon information
const int MAX_CARRY	= 6;
const int MAX_CLIP	 = 1;
const int AMMO_GIVE	= 3;
const int DEFAULT_GIVE = 3;
const int WEIGHT	   = 15;
const int FLARE_DAMAGE1 = 20;
const float TIME_FLARE_LIFE		= 1200.0;
const float FLARE_VELOCITY	  = 1500.0;
const Vector SHELL_ORIGIN		= Vector( 16.0, 4.0, -4.0 ); //forward, right, up
const Vector MUZZLE_ORIGIN		= Vector( 16.0, 4.0, -4.0 ); //forward, right, up
//Sounds
const string FLAREGUN_S_SHOOT = "bts_rc/weapons/flaregun_shot1.wav";
const string FLAREGUN_S_HIT1 = "bts_rc/weapons/flaregun_hit1.wav";
const string FLAREGUN_S_HITBOD1 = "bts_rc/weapons/flaregun_hitbod1.wav";
const string FLAREGUN_S_RELOAD1 = "bts_rc/weapons/flaregun_reload1.wav";
const string FLAREGUN_S_RELOAD2 = "bts_rc/weapons/flaregun_reload2.wav";
const string FLARE_SOUND	= "bts_rc/weapons/flare_on.wav";
//Models
const string FLAREGUN_A_MODEL  = "models/bts_rc/weapons/w_flaregun_clip.mdl";
const string FLARE_MODEL	= "models/hlclassic/shotgunshell.mdl";
const string V_MODEL = "models/bts_rc/weapons/v_flaregun.mdl";
//Sprites
const string SPRITE_MUZZLE_GRENADE	= "sprites/bts_rc/muzzleflash12.spr";
const string SPRITE_BEAM			= "sprites/laserbeam.spr";
const string SPRITE_SMOKE			= "sprites/steam1.spr";

class weapon_bts_flaregun : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{
	private CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer>( self.m_hPlayer.GetEntity() ); }
		set	   { self.m_hPlayer = EHandle(@value); }
	}
	private int m_iSpecialReload;
	private int m_fInAttack;
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

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( 'models/bts_rc/weapons/w_flaregun.mdl' ) );
		self.m_iDefaultAmmo = DEFAULT_GIVE;
		m_iSpecialReload = 0;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( 'models/bts_rc/weapons/v_flaregun.mdl' );
		g_Game.PrecacheModel( 'models/bts_rc/weapons/w_flaregun.mdl' );
		g_Game.PrecacheModel( 'models/bts_rc/weapons/p_flaregun.mdl' );
		g_Game.PrecacheModel( FLAREGUN_A_MODEL );
		g_Game.PrecacheModel( FLARE_MODEL );

		g_SoundSystem.PrecacheSound( 'bts_rc/weapons/flaregun_reload1.wav' ); //default viewmodel; sequence: 3; frame: 70; event 5004
		g_SoundSystem.PrecacheSound( 'hlclassic/weapons/357_cock1.wav' );
		g_SoundSystem.PrecacheSound( 'bts_rc/weapons/flaregun_shot1.wav' );
		g_SoundSystem.PrecacheSound( 'bts_rc/weapons/flaregun_shot2.wav' );
		g_SoundSystem.PrecacheSound( 'bts_rc/weapons/flaregun_hit1.wav' );
		g_SoundSystem.PrecacheSound( 'bts_rc/weapons/flaregun_hit2.wav' );
		g_SoundSystem.PrecacheSound( 'bts_rc/weapons/flaregun_hitbod1.wav' );
		g_SoundSystem.PrecacheSound( 'bts_rc/weapons/flaregun_hitbod2.wav' );
		g_SoundSystem.PrecacheSound( 'bts_rc/items/flare_pickup1.wav' );

		g_Game.PrecacheModel( SPRITE_BEAM );
		g_Game.PrecacheModel( SPRITE_SMOKE );
		g_Game.PrecacheModel( SPRITE_MUZZLE_GRENADE );

		g_Game.PrecacheGeneric( 'sprites/bts_rc/weapons/' + pev.classname + '.txt' );
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
		info.iPosition = 13;
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
		bool bResult = self.DefaultDeploy( self.GetV_Model('models/bts_rc/weapons/v_flaregun.mdl'), self.GetP_Model('models/bts_rc/weapons/p_flaregun.mdl'), DRAW, 'python', 0, GetBodygroup() );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0;
		return bResult;
	}

	void Holster( int skiplocal = 0 )
	{
		self.m_fInReload = false;
		m_iSpecialReload = 0;

		BaseClass.Holster( skiplocal );
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

		m_pPlayer.pev.punchangle.x = -10.0; //Recoil

		//player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		//Custom Volume and Pitch
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, FLAREGUN_S_SHOOT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		//Handles the grenade as custom entity, and changes their model
		FireFlare();

		//View model animation
		self.SendWeaponAnim( FIRE1, 0, GetBodygroup() );

		self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 1;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 1;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + 5; //Idle pretty soon after shooting.

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
	}

	void FireFlare()
	{
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		m_pPlayer.pev.punchangle.x = Math.RandomFloat(-2.0, -3.0 );

		Vector vecOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 8 + g_Engine.v_right * 4 + g_Engine.v_up * -2;
		Vector vecAngles = m_pPlayer.pev.v_angle;

		vecAngles.x = 480.0; //vecAngles.x = 360.0 - vecAngles.x

		CBaseEntity@ cbeFlare = g_EntityFuncs.Create( "flare_rocket", vecOrigin, vecAngles, false, m_pPlayer.edict() );
		flare_rocket@ pGrenade = cast<flare_rocket@>( CastToScriptClass( cbeFlare ) );
		pGrenade.pev.velocity = g_Engine.v_forward * FLARE_VELOCITY;

		CreateMuzzleflash( SPRITE_MUZZLE_GRENADE, MUZZLE_ORIGIN.x, MUZZLE_ORIGIN.y, MUZZLE_ORIGIN.z, 0.05, 128, 20.0 );
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip >= MAX_CLIP )
			return;

		if( self.m_flNextPrimaryAttack > WeaponTimeBase() )
			return;

		if( m_fInAttack != 0 )
			return;

		if( m_iSpecialReload == 0 )
		{
			self.SendWeaponAnim( HOLSTER, 0, GetBodygroup() );
			m_iSpecialReload = 1;
			m_pPlayer.m_flNextAttack = 0.5;
			self.m_flTimeWeaponIdle = g_Engine.time + 1.5;
			self.m_flNextPrimaryAttack = g_Engine.time + 1.5;
			self.m_flNextSecondaryAttack = g_Engine.time + 1.5;
			return;
		}
		else if( m_iSpecialReload == 1 )
		{
			if( self.m_flTimeWeaponIdle > g_Engine.time )
				return;

			m_iSpecialReload = 2;

			float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0, 1 );
			if( flRand >= 0.75 )
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, FLAREGUN_S_RELOAD1, 1.0, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
			else if( flRand >= 0.5 )
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, FLAREGUN_S_RELOAD1, 1.0, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
			else
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, FLAREGUN_S_RELOAD1, 1.0, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );

			self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
		}
		else if( m_iSpecialReload == 2 )
		{
			self.DefaultReload( MAX_CLIP, DRAW, 1.0, GetBodygroup() );

			m_iSpecialReload = 0;

			m_pPlayer.m_flNextAttack = 0.6;

			self.m_flTimeWeaponIdle = 1.25;

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = 1.25;
		}

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

//flare projectile
class flare_rocket : ScriptBaseEntity
{
	private CScheduledFunction@ SelfFlareLightSchedule = null; //dynamic lighting schedule
	private CScheduledFunction@ SelfFlareSparkSchedule = null; //env_sparks schedule

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, FLARE_MODEL );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.movetype = MOVETYPE_TOSS;
		pev.solid = SOLID_BBOX;

		NetworkMessage flare1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			flare1.WriteByte( TE_BEAMFOLLOW );
			flare1.WriteShort( self.entindex() );
			flare1.WriteShort( g_EngineFuncs.ModelIndex( SPRITE_BEAM ) );
			flare1.WriteByte( 20 ); //life
			flare1.WriteByte( 4 );  //width
			flare1.WriteByte( 180 ); //r
			flare1.WriteByte( 10 ); //g
			flare1.WriteByte( 10 ); //b
			flare1.WriteByte( 200 ); //brightness
		flare1.End();

		SetThink( ThinkFunction( this.FlareThink ) );
		SetTouch( TouchFunction( this.FlareTouch ) );

		pev.nextthink = g_Engine.time + 0.1;
	}

	void Precache()
	{
		g_Game.PrecacheModel( FLARE_MODEL );
		g_Game.PrecacheModel( SPRITE_BEAM );
	}

	void FlareSelfThink()
	{
		CreateLight( Vector( self.GetOrigin().x, self.GetOrigin().y, self.GetOrigin().z + 20.0f ) ); //flare lighting start appearing after detonate
	}

	void FlareSparkSelfThink()
	{
		CreateSparks( Vector( self.GetOrigin().x, self.GetOrigin().y, self.GetOrigin().z + -20.0f ) ); //env_sparks appear on the flare
	}

	void FlareThink()
	{
		pev.angles = Math.VecToAngles( pev.velocity.Normalize() );

		pev.nextthink = g_Engine.time + 0.1;
	}

	void FlareTouch( CBaseEntity@ pOther )
	{
		if( g_EngineFuncs.PointContents( pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		if( pOther.pev.takedamage != DAMAGE_NO )
		{
			TraceResult tr = g_Utility.GetGlobalTrace();
			entvars_t@ pevOwner = pev.owner.vars;

			g_WeaponFuncs.ClearMultiDamage();

			if( pOther.IsPlayer() )
				pOther.TraceAttack( pevOwner, FLARE_DAMAGE1, pev.velocity.Normalize(), tr, DMG_NEVERGIB );
			else
				pOther.TraceAttack( pevOwner, FLARE_DAMAGE1, pev.velocity.Normalize(), tr, DMG_POISON | DMG_NEVERGIB );

			g_WeaponFuncs.ApplyMultiDamage( pev, pevOwner );

			pev.velocity = g_vecZero;

			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, FLAREGUN_S_HITBOD1, VOL_NORM, ATTN_NORM );

			self.Killed( pev, GIB_NEVER );
		}
		else
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, FLAREGUN_S_HIT1, Math.RandomFloat( 0.95, 1.0), ATTN_NORM, 0, 98 + Math.RandomLong(0, 7) );

			SetThink( ThinkFunction( this.RemoveThink ) );
			pev.nextthink = g_Engine.time;

			if( pOther.pev.ClassNameIs("worldspawn") )
			{
				Vector vecDir = pev.velocity.Normalize();
				g_EntityFuncs.SetOrigin( self, pev.origin - vecDir * 6 ); //Pull out of the wall a bit
				pev.angles = Math.VecToAngles( vecDir );
				pev.solid = SOLID_NOT;
				pev.movetype = MOVETYPE_FLY;
				pev.velocity = g_vecZero;
				pev.avelocity.z = 0;
				pev.angles.z = Math.RandomLong( 0, 360 );
				pev.nextthink = g_Engine.time + TIME_FLARE_LIFE;
			}

			FlareDetonate();
		}
	}

	void CreateLight( Vector& in origin )
	{
		NetworkMessage flare1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
				flare1.WriteByte( TE_DLIGHT ); //temp entity you want to implement
				flare1.WriteCoord( origin.x ); //vector x
				flare1.WriteCoord( origin.y ); //vector y
				flare1.WriteCoord( origin.z ); //vector z
				flare1.WriteByte( 18 ); //Radius
				flare1.WriteByte( int( 255) ); //R
				flare1.WriteByte( int( 21) ); //G
				flare1.WriteByte( int( 18) ); //B
				flare1.WriteByte( 1 ); //Life
				flare1.WriteByte( 1 ); //Decay
			flare1.End();
	}

	void CreateSparks( Vector& in origin )
	{
		NetworkMessage flarespark( MSG_ALL, NetworkMessages::SVC_TEMPENTITY, null );
				flarespark.WriteByte( TE_SPARKS );
				flarespark.WriteCoord( origin.x );
				flarespark.WriteCoord( origin.y );
				flarespark.WriteCoord( origin.z );
			flarespark.End();
	}

	void FlareDetonate()
	{
		TraceResult tr;
		Vector vecSpot = pev.origin - pev.velocity.Normalize() * 32;
		Vector vecEnd = pev.origin + pev.velocity.Normalize() * 64;
		g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, self.edict(), tr );

		tr = g_Utility.GetGlobalTrace();

		//Pull out of the wall a bit
		if( tr.flFraction != 1.0f )
			pev.origin = tr.vecEndPos + ( tr.vecPlaneNormal * 24.0f );

		Vector vecOrigin = pev.origin;

		self.pev.flags &= ~EF_BRIGHTLIGHT;
		CreateLight( Vector( self.GetOrigin().x, self.GetOrigin().y, self.GetOrigin().z + 20.0f ) ); //Dynamic lighting implemented around the flare entity

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, FLARE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM ); //Flare sound play when detonate

		@SelfFlareLightSchedule = @g_Scheduler.SetInterval( @this, "FlareSelfThink", 0.0125f, 3300.0f ); //How much time the flare will last long

		@SelfFlareSparkSchedule = @g_Scheduler.SetInterval( @this, "FlareSparkSelfThink", 0.099, 590.0f ); //How long the env_sparks appear on the flare

		pev.effects |= EF_NODRAW;
		pev.velocity = g_vecZero;
		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_NOT;

		SetTouch( null );
	}

	void RemoveThink()
	{
		g_EntityFuncs.Remove( self );
	}
}

//Ammo class
class ammo_bts_flarebox : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, FLAREGUN_A_MODEL );
		BaseClass.Spawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel( FLAREGUN_A_MODEL );
		g_SoundSystem.PrecacheSound( "bts_rc/items/flare_pickup1.wav" );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		int iGive;

		iGive = AMMO_GIVE;

		if( pOther.GiveAmmo( iGive, "flare", MAX_CARRY ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "bts_rc/items/flare_pickup1.wav", 1, ATTN_NORM );
			return true;
		}
		return false;
	}
}

string GetName()
{
	return 'weapon_bts_flaregun';
}

string GetAmmoName()
{
	return 'ammo_bts_flarebox';
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLAREGUN::flare_rocket", "flare_rocket" );
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLAREGUN::weapon_bts_flaregun", GetName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLAREGUN::ammo_bts_flarebox", GetAmmoName() );
	g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", "flare", "", GetAmmoName() );
}

}
