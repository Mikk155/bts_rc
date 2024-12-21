// Idk what gun is this lmao
// Author: Nevermore2790, Nero0

#include "../hl_utils"

namespace BTS_DARTGUN
{

enum BTS_DARTGUN_ANIM_E
{
	DARTGUN_LONGIDLE = 0,
	DARTGUN_IDLE1,
	DARTGUN_LAUNCH,
	DARTGUN_RELOAD,
	DARTGUN_DEPLOY,
	DARTGUN_FIRE1,
	DARTGUN_FIRE2,
	DARTGUN_FIRE3,
};

enum DARTGUN_SPIN_SPEED
{
	SPIN_STOP,
	SPIN_SLOW,
	SPIN_MED,
	SPIN_FAST
};

// Models
string P_MODEL		= "models/bts_rc/weapons/p_dartgun.mdl";
string V_MODEL		= "models/bts_rc/weapons/v_dartgun.mdl";
string W_MODEL		= "models/bts_rc/weapons/w_dartgun.mdl";

string MODEL_AMMO	= "models/bts_rc/weapons/w_dartgun_clip.mdl";
string MODEL_DART	= "models/bts_rc/weapons/dart.mdl";

// Sprites
string SPR_DIR		= "bts_rc/weapons/";
string SPRITE_BEAM	= "sprites/laserbeam.spr";

// Sounds
array<string> DartgunSoundEvents = { 
		"bts_rc/weapons/dartgun_chargeup.wav",
		"bts_rc/weapons/dartgun_fire1.wav",
		"bts_rc/weapons/dartgun_chargedown.wav",
		"bts_rc/weapons/dartgun_chargedown.wav",
		"hlclassic/weapons/reload1.wav",
		"hlclassic/weapons/reload2.wav",
		"hlclassic/weapons/reload3.wav",
		"weapons/357_cock1.wav"
};

string DARTGUN_SOUND_SPIN		= "bts_rc/weapons/dartgun_chargeloop.wav";
string DARTGUN_SOUND_SPIN_UP	= "bts_rc/weapons/dartgun_chargeup.wav";
string DARTGUN_SOUND_SPIN_DOWN	= "bts_rc/weapons/dartgun_chargedown.wav";
string DARTGUN_SOUND_SPIN_STOP	= "bts_rc/weapons/dartgun_chargestop.wav";

// Physics
const int DART_AIR_VELOCITY		= 2000;
const int DART_WATER_VELOCITY	= 1000;

// Weapon information
int MAX_CARRY    = 60;
int MAX_CLIP     = 20;
int DEFAULT_GIVE = MAX_CLIP * 2;
int WEIGHT       = 20;
int DAMAGE		= 1;
int FLAGS		= 0; // WeaponIdle() will take care of this.
uint SLOT		= 3;	// Moved to Slot 6 - Same slots for M249, Displacer, etc.
uint POSITION		= 5;
string AMMO_TYPE 	= "bts_darts";

const CCVar@ g_BtsDartgun = CCVar("bts_dartgun_mp", 0, "", ConCommandFlag::AdminOnly); // as_command bts_dartgun_mp 0. 1 - MP Spread. 0 - SP Spread.

class weapon_bts_dartgun : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{
	private CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer>(self.m_hPlayer.GetEntity()); }
		set       { self.m_hPlayer = EHandle(@value); }
	}
	
	private int DARTGUN_BULLETS_PER_SHOT = 1;
	private int m_fInAttack;
	private int m_iSpecialReload;
	int iSpinSpeed = 0;
	float fSpinTime = 0.0f;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( W_MODEL ) );
		self.m_iDefaultAmmo = DEFAULT_GIVE;
		m_iSpecialReload = 0;
		m_fInAttack = 0;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( V_MODEL );
		g_Game.PrecacheModel( W_MODEL );
		g_Game.PrecacheModel( P_MODEL );
		g_Game.PrecacheModel( MODEL_AMMO );
		g_Game.PrecacheModel( MODEL_DART );

		g_Game.PrecacheModel( SPRITE_BEAM );

		for( uint i = 0; i < DartgunSoundEvents.length(); i++ )
		{
			g_SoundSystem.PrecacheSound( DartgunSoundEvents[i] );
			g_Game.PrecacheGeneric( "sound/" + DartgunSoundEvents[i] );
		}

		g_SoundSystem.PrecacheSound( DARTGUN_SOUND_SPIN_STOP );
		g_SoundSystem.PrecacheSound( DARTGUN_SOUND_SPIN	 );
		g_SoundSystem.PrecacheSound( DARTGUN_SOUND_SPIN_UP );
		g_SoundSystem.PrecacheSound( DARTGUN_SOUND_SPIN_DOWN );	
		
		g_Game.PrecacheGeneric( "sound/" + DARTGUN_SOUND_SPIN_STOP );
		g_Game.PrecacheGeneric( "sound/" + DARTGUN_SOUND_SPIN );
		g_Game.PrecacheGeneric( "sound/" + DARTGUN_SOUND_SPIN_UP );
		g_Game.PrecacheGeneric( "sound/" + DARTGUN_SOUND_SPIN_DOWN );
	
		g_Game.PrecacheGeneric( "sprites/" + SPR_DIR + self.pev.classname + ".txt" );
	}
	
	bool GetItemInfo(ItemInfo& out info)
	{
		info.iMaxAmmo1 = MAX_CARRY;
		info.iMaxAmmo2 = -1;
		info.iAmmo1Drop = MAX_CLIP;
		info.iAmmo2Drop = -1;
		info.iMaxClip = MAX_CLIP;
		info.iFlags = FLAGS;
		info.iSlot = SLOT;
		info.iPosition = POSITION;
		info.iWeight = WEIGHT;
		info.iId = g_ItemRegistry.GetIdForName(pev.classname);

		return true;
	}
	
	bool AddToPlayer(CBasePlayer@ pPlayer)
	{
		if (!BaseClass.AddToPlayer(pPlayer))
			return false;

		NetworkMessage message(MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict());
			message.WriteLong(g_ItemRegistry.GetIdForName(pev.classname));
		message.End();

		return true;
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, DartgunSoundEvents[7], 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}
	
	bool Deploy()
	{
		bool bResult = self.DefaultDeploy(self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), DARTGUN_DEPLOY, "mp5" );	// Third person Player won't be having any reload animations. Expect them to see go doing Idle No-Weapon animation when it happens.
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0;
		return bResult;
	}
	
	void Holster(int skiplocal )
	{
		self.m_fInReload = false;
	    m_iSpecialReload = 0;
		m_pPlayer.m_flNextAttack = WeaponTimeBase() + 1.0f;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat(m_pPlayer.random_seed, 10, 15);
		self.SendWeaponAnim( DARTGUN_DEPLOY );

		// Stop dartgun sounds.
		StopSounds();

		// Restore player speed.
		SetPlayerSlow( false );

		m_fInAttack = 0;
	}

	void PrimaryAttack()
	{
		// don't fire underwater, or if the clip is empty.
		if ( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			if ( m_fInAttack != 0 )
			{
				// spin down
				SpinDown();
			}
			else if ( self.m_bFireOnEmpty )
			{
				self.PlayEmptySound();
				self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5f;
			}
			return;
		}

		if ( m_fInAttack == 0 )
		{
			// Spin up
			SpinUp();
		}
		else
		{
			// Spin
			Spin();
		}
	}

	void SecondaryAttack()
	{	
		CBasePlayer@ pPlayer = m_pPlayer;
		int iClip = pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || iClip <= 0 )
		{
			self.PlayEmptySound( );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}
		
		if (iSpinSpeed == SPIN_FAST)
			{
				self.SendWeaponAnim( DARTGUN_LONGIDLE, 0, 0 );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.5f;
				self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5f;
				fSpinTime = 1.01f;
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, DARTGUN_SOUND_SPIN, 1.0f, ATTN_NORM );
				return;
			}
		
		if (iSpinSpeed == SPIN_MED)
			{
				self.SendWeaponAnim( DARTGUN_IDLE1, 0, 0 );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.5f;
				self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5f;
				fSpinTime = fSpinTime + 0.5f;
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, DARTGUN_SOUND_SPIN, 1.0f, ATTN_NORM );
				iSpinSpeed = SPIN_FAST;
				return;
			}
		
		if (iSpinSpeed == SPIN_SLOW)
			{
				self.SendWeaponAnim( DARTGUN_LONGIDLE, 0, 0 );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.5f;
				self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5f;
				fSpinTime = fSpinTime + 0.5f;
				//g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, M134_SOUND_SPIN, 1.0f, ATTN_NORM );
				iSpinSpeed = SPIN_MED;
				return;
			}
			
		if (iSpinSpeed == SPIN_STOP)
			{
				self.SendWeaponAnim( DARTGUN_IDLE1, 0, 0 );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.5f;
				self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5f;
				fSpinTime = fSpinTime + 0.5f;
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, DARTGUN_SOUND_SPIN_UP, 1.0f, ATTN_NORM );
				iSpinSpeed = SPIN_SLOW;
				return;
			}
	}

	void Reload()
	{
		if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip >= MAX_CLIP )
			return;

		// don't reload until recoil is done
		if ( self.m_flNextPrimaryAttack > WeaponTimeBase() )
			return;

		if ( m_fInAttack != 0 )
			return;
		
		// check to see if we're ready to reload
		if ( m_iSpecialReload == 0 )
		{
			self.SendWeaponAnim( DARTGUN_RELOAD );
			m_iSpecialReload = 1;
			m_pPlayer.m_flNextAttack = 0.5;
			self.m_flTimeWeaponIdle = g_Engine.time + 1.75;
			self.m_flNextPrimaryAttack = g_Engine.time + 1.75;
			self.m_flNextSecondaryAttack = g_Engine.time + 1.75;
			return;
		}
		else if ( m_iSpecialReload == 1 )
		{
			if ( self.m_flTimeWeaponIdle > g_Engine.time )
				return;
			// was waiting for gun to move to side
			m_iSpecialReload = 2;

			float flRand = g_PlayerFuncs.SharedRandomFloat(m_pPlayer.random_seed, 0, 1);
			if ( flRand >= 0.75 )
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, DartgunSoundEvents[4], 1.0, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
			else if ( flRand >= 0.5 )
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, DartgunSoundEvents[5], 1.0, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
			else
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, DartgunSoundEvents[6], 1.0, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );

			self.m_flTimeWeaponIdle = g_Engine.time + 0.8;
		}
		else if ( m_iSpecialReload == 2 )
		{
			self.DefaultReload( MAX_CLIP, DARTGUN_LONGIDLE, 1.25 );

			m_iSpecialReload = 0;

			// Used to immediatly complete the reload.
			//m_pPlayer.m_flNextAttack = g_Engine.time - 0.1;
			m_pPlayer.m_flNextAttack = 0.6;
			
			//self.m_flTimeWeaponIdle = g_Engine.time + CHAINGUN_REDRAW_DURATION;
			self.m_flTimeWeaponIdle = 1.25;
			
			// Delay next attack times to allow the draw sequence to complete.
			//self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CHAINGUN_REDRAW_DURATION;
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = 1.25;
		}
		
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		int iAnim;
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 1 ) )
		{
		case 0:	
			iAnim = DARTGUN_LONGIDLE;	
			break;
		
		case 1:
			iAnim = DARTGUN_IDLE1;
			break;
			
		default:
			iAnim = DARTGUN_IDLE1;
			break;
		}

		self.SendWeaponAnim( iAnim );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );// how long till we do this again.
	}

	bool ShouldWeaponIdle()
	{
		return true;
	}

	void SpinUp()
	{
		// spin up
		m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;

		self.SendWeaponAnim( DARTGUN_LONGIDLE );

		// Slowdown player.
		SetPlayerSlow( false );

		m_fInAttack = 1;
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5f;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.5f;
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, DartgunSoundEvents[0], 1.0, ATTN_NORM, 0, 80 + Math.RandomLong( 0, 0x3f ) );
	}

	void SpinDown()
	{	
		// Spin down
		m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;

		self.SendWeaponAnim( DARTGUN_IDLE1 );

		// Restore player speed.
		SetPlayerSlow( false );
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, DartgunSoundEvents[2], 1.0, ATTN_NORM, 0, 80 + Math.RandomLong( 0, 0x3f ) );

		m_fInAttack = 0;
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 1.0f;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;
	}

	void Spin()
	{	
		m_fInAttack = 1;

		// Spin sound.
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, DartgunSoundEvents[3], 0.8, ATTN_NORM );
		
		if ( g_BtsDartgun.GetBool() )
			Fire( 0.1, false);
		else
			Fire( 0.1, false);
	}

	void Fire( float flCycleTime, bool bUseAutoAim )
	{
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		// The mp5 fires 2 bullets at a time, so we need to ensure it only shoot one bullet m_iClip is 1. 
		//int nShot = std::min( self.m_iClip, DARTGUN_BULLETS_PER_SHOT );
		self.m_iClip -= DARTGUN_BULLETS_PER_SHOT;

		m_pPlayer.pev.effects = ( int (m_pPlayer.pev.effects) ) | EF_MUZZLEFLASH;

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Math.MakeVectors(m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
		
		Vector vecSrc = m_pPlayer.GetGunPosition() - g_Engine.v_up * 2 + g_Engine.v_right * 2;
		Vector vecDir = g_Engine.v_forward;
		
		// dart entity physics logic
		float flDamage = DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		CBaseEntity@ pBolt = g_EntityFuncs.Create( "gun_dart", vecSrc, vecDir, false, m_pPlayer.edict() );

		Vector vecVelocity;
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
			vecVelocity = vecDir * DART_WATER_VELOCITY;
		else
			vecVelocity = vecDir * DART_AIR_VELOCITY;

		float flSpread = 32.0;

		if( m_pPlayer.pev.FlagBitSet(FL_DUCKING) )
			flSpread = 16.0;

		if( m_pPlayer.m_iFOV != 0 )
			flSpread = 8.0;

		vecVelocity = vecVelocity + g_Engine.v_right * Math.RandomFloat(-flSpread, flSpread) + g_Engine.v_up * Math.RandomFloat(-flSpread, flSpread);

		pBolt.pev.velocity = vecVelocity;
		pBolt.pev.angles = Math.VecToAngles( pBolt.pev.velocity.Normalize() );
		pBolt.pev.avelocity.z = 10;
		pBolt.pev.dmg = flDamage;

		pev.effects |= EF_MUZZLEFLASH;
		
		self.SendWeaponAnim( DARTGUN_FIRE1 );
		m_pPlayer.pev.punchangle.x = -2.0;
		m_pPlayer.pev.punchangle.y = -1.0;

		Vector ShellVelocity, ShellOrigin;
		GetDefaultShellInfo(ShellVelocity, ShellOrigin, 14.0, -10.0, 8.0);
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, DartgunSoundEvents[1], 1.0, ATTN_NORM, 0, 100 );
		
		if (self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0)
			m_pPlayer.SetSuitUpdate('!HEV_AMO0', false, 0);

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + flCycleTime;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + flCycleTime;
	}

	void StopSounds()
	{
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, DartgunSoundEvents[0] );
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, DartgunSoundEvents[1] );
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, DartgunSoundEvents[2] );
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_ITEM, DartgunSoundEvents[3] );
	}

	void SetPlayerSlow( bool bSlowDown )
	{
		if ( !bSlowDown )
			m_pPlayer.SetMaxSpeedOverride( -1 );
		else
			m_pPlayer.SetMaxSpeedOverride( 150 );
	}

}

class gun_dart : ScriptBaseEntity
{
	void Spawn()
	{
		pev.movetype = MOVETYPE_FLY;
		pev.solid    = SOLID_BBOX;
		pev.gravity = 0.5;
		self.SetClassification( CLASS_NONE );

		NetworkMessage darttrail( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			darttrail.WriteByte( TE_BEAMFOLLOW );
			darttrail.WriteShort( self.entindex() );
			darttrail.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_BEAM) );
			darttrail.WriteByte( 2 ); // life
			darttrail.WriteByte( 1 );  // width
			darttrail.WriteByte( 160 ); // r
			darttrail.WriteByte( 32 ); // g
			darttrail.WriteByte( 240 ); // b
			darttrail.WriteByte( 100 ); // brightness
		darttrail.End();

		g_EntityFuncs.SetModel( self, MODEL_DART );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );

		SetTouch( TouchFunction(this.BoltTouch) );
		SetThink( ThinkFunction(this.BubbleThink) );
		pev.nextthink = g_Engine.time + 0.2;
	}

	void BoltTouch( CBaseEntity@ pOther )
	{
		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		SetTouch(null);
		SetThink(null);

		if( pOther.pev.takedamage != DAMAGE_NO )
		{
			TraceResult tr = g_Utility.GetGlobalTrace();
			entvars_t@ pevOwner = pev.owner.vars;

			g_WeaponFuncs.ClearMultiDamage();

			if( pOther.IsPlayer() )
				pOther.TraceAttack( pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_NEVERGIB ); 
			else
				pOther.TraceAttack( pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_BULLET | DMG_NEVERGIB ); 

			g_WeaponFuncs.ApplyMultiDamage( pev, pevOwner );

			pev.velocity = g_vecZero;

			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "weapons/xbow_hitbod1", 1, ATTN_NORM );

			self.Killed( pev, GIB_NEVER );
		}
		else
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "weapons/xbow_hitwall2", Math.RandomFloat(0.95, 1.0), ATTN_NORM, 0, 98 + Math.RandomLong(0, 7) );

			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;

			if( pOther.pev.ClassNameIs("worldspawn") )
			{
				Vector vecDir = pev.velocity.Normalize();
				g_EntityFuncs.SetOrigin( self, pev.origin - vecDir ); //Pull out of the wall a bit
				pev.angles = Math.VecToAngles( vecDir );
				pev.solid = SOLID_NOT;
				pev.movetype = MOVETYPE_FLY;
				pev.velocity = Vector(0, 0, 0);
				pev.avelocity.z = 0;
				pev.angles.z = Math.RandomLong(0, 360);
				pev.nextthink = g_Engine.time + 10.0;

				TraceResult tr = g_Utility.GetGlobalTrace();
				g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_9MM );
			}

			if( g_EngineFuncs.PointContents(pev.origin) != CONTENTS_WATER )
				g_Utility.Sparks( pev.origin );
		}

		GetAmmoName();
	}

	void BubbleThink()
	{
		pev.nextthink = g_Engine.time + 0.1;

		if( pev.waterlevel == WATERLEVEL_DRY )
			return;

		g_Utility.BubbleTrail( pev.origin - pev.velocity * 0.1, pev.origin, 1 );
	}

	void SUB_Remove()
	{
		self.SUB_Remove();
	}
}

class ammo_bts_dartgun : ScriptBasePlayerAmmoEntity
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

		if( pOther.GiveAmmo( iGive, "bts_darts", MAX_CARRY ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

string GetAmmoName()
{
	return "ammo_bts_dartgun";
}

string GetName()
{
	return "weapon_bts_dartgun";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_DARTGUN::gun_dart", "gun_dart" );
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_DARTGUN::weapon_bts_dartgun", GetName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_DARTGUN::ammo_bts_dartgun", GetAmmoName() );
	g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", AMMO_TYPE, "", GetAmmoName() );
}

} // End of namespace
