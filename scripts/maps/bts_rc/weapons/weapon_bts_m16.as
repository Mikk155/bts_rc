/*  
* M16A3 Full Auto
*/

#include "../hl_utils"

namespace BTS_M16A3
{

enum M16A3Animation
{
	M16A3_DRAW = 0,
	M16A3_HOLSTER,
	M16A3_IDLE,
	M16A3_FIDGET,
	M16A3_SHOOT_1,
	M16A3_SHOOT_2,
	M16A3_RELOAD_M16,
	M16A3_LAUNCH,
	M16A3_RELOAD_M203
};

array<string> HEV =
{
	"bts_helmet"
};

const int M16A3_DEFAULT_GIVE 	= Math.RandomLong( 15, 30 );
const int M16A3_MAX_AMMO		= 150;
const int M16A3_MAX_AMMO2 	= 10;
const int M16A3_MAX_CLIP 		= 30;
const int M16A3_MAX_DROP		= 14;
const int M16A3_WEIGHT 		= 5;
//const int M16A3_DAMAGE        = 15;
const int M16A3_GL_GIVE		= Math.RandomLong( 0, 1 ); //1

const string MODEL_AMMO		= "models/bts_rc/weapons/w_9mmarclip.mdl";
const string V_MODEL = "models/bts_rc/weapons/v_m16a2.mdl";

class weapon_bts_m16 : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{
	private CBasePlayer@ m_pPlayer = null;
	
	float m_flNextAnimTime;
	int m_iShell;
	int	m_iSecondaryAmmo;

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
		string modelName = g_EngineFuncs.GetInfoKeyBuffer(m_pPlayer.edict()).GetValue( "model" );

    	switch( int(g_Models[ modelName ]) )
    	{
        	case 0:
            	m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 2, 0 );
            	break;
        	case 1:
            	m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 2, 1 );
            	break;
        	case 2:
            	m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 2, 2 );
            	break;
			case 3:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 2, 3 );
            	break;
			case 4:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 2, 4 );
            	break;
    	}

    return m_iCurBodyConfig;
}
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/w_m16.mdl" );

		self.m_iDefaultAmmo = M16A3_DEFAULT_GIVE;
		self.m_iDefaultSecAmmo = M16A3_GL_GIVE;

		self.m_iSecondaryAmmoType = 0;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/bts_rc/weapons/v_m16a2.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/weapons/w_m16.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/weapons/p_m16.mdl" );
		g_Game.PrecacheModel( MODEL_AMMO );

		m_iShell = g_Game.PrecacheModel( "models/bts_rc/weapons/saw_shell.mdl" );

		g_Game.PrecacheModel( "models/grenade.mdl" );

		g_Game.PrecacheModel( "models/w_saw_clip.mdl" );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );              

		//These are played by the model, needs changing there
		g_SoundSystem.PrecacheSound( "hl/items/clipinsert1.wav" );
		g_SoundSystem.PrecacheSound( "hl/items/cliprelease1.wav" );
		g_SoundSystem.PrecacheSound( "hl/items/guncock1.wav" );

		g_SoundSystem.PrecacheSound( "bts_rc/weapons/m16_fire1.wav" );

		g_SoundSystem.PrecacheSound( "hl/weapons/glauncher.wav" );
		g_SoundSystem.PrecacheSound( "hl/weapons/glauncher2.wav" );

		g_SoundSystem.PrecacheSound( "hl/weapons/357_cock1.wav" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= M16A3_MAX_AMMO;
		info.iMaxAmmo2 	= M16A3_MAX_AMMO2;
		info.iMaxClip 	= M16A3_MAX_CLIP;
		info.iSlot 		= 2;
		info.iPosition 	= 10;
		info.iFlags 	= 0;
		info.iWeight 	= M16A3_WEIGHT;

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
		return self.DefaultDeploy( self.GetV_Model( "models/bts_rc/weapons/v_m16a2.mdl" ), self.GetP_Model( "models/bts_rc/weapons/p_m16.mdl" ), M16A3_DRAW, "m16", 0, GetBodygroup() );
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

	void PrimaryAttack()
	{
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound( );
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.13;
			return;
		}

		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.13;
			return;
		}

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;
		
		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
		{
		case 0: self.SendWeaponAnim( M16A3_SHOOT_1, 0, GetBodygroup() ); break;
		case 1: self.SendWeaponAnim( M16A3_SHOOT_2, 0, GetBodygroup() ); break;
		case 2: self.SendWeaponAnim( M16A3_SHOOT_1, 0, GetBodygroup() ); break;
		}
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/m16_fire1.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		g_EngineFuncs.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		
		Vector vecShellVelocity = m_pPlayer.pev.velocity + g_Engine.v_right * Math.RandomFloat( 50.0, 70.0 ) + g_Engine.v_up * Math.RandomFloat( 100.0, 150.0 ) + g_Engine.v_forward * 25;
		g_EntityFuncs.EjectBrass( self.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_up * -12 + g_Engine.v_forward * 32 + g_Engine.v_right * 6, vecShellVelocity, self.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		// Weapon spread
		Vector vecSpread;

		if( !(m_pPlayer.pev.flags & FL_DUCKING != 0 ) )
		{
			vecSpread = VECTOR_CONE_3DEGREES; //spread when standing
		}
		else
		{
			vecSpread = Vector( 0.01, 0.01, 0.01 ); //spread when crouching
		}

		vecSpread = vecSpread * 1.0f;
		
		// optimized multiplayer. Widened to make it easier to hit a moving player
		self.FireBullets( 1, vecSrc, vecAiming, vecSpread, 8192, BULLET_PLAYER_SAW, 4, 0, m_pPlayer.pev );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			// HEV suit - indicate out of ammo condition
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			
		// model difference
		string modelName = g_EngineFuncs.GetInfoKeyBuffer(m_pPlayer.edict()).GetValue( "model" );

		if ( HEV.find(modelName) >= 0 )
		{
			m_pPlayer.pev.punchangle.x = -3.0;

			self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.142;
			if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
				self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.142; // Fire rate
		}
		else
		{
			// crouching recoil logic
			if( m_pPlayer.pev.flags & FL_DUCKING != 0 )
			{
				m_pPlayer.pev.punchangle.x = Math.RandomLong( -3, 2 ); //recoil when crouching
			}
			else
			{
				m_pPlayer.pev.punchangle.x = Math.RandomLong( -8, 3 ); //recoil when stand
			}

			self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.145;
			if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
				self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.145; // Fire rate
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * vecSpread.x * g_Engine.v_right 
						+ y * vecSpread.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
			}
		}
	}

	void SecondaryAttack()
	{
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
			return;
		}
		
		if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
		{
			self.PlayEmptySound();
			return;
		}


		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
		m_pPlayer.m_flStopExtraSoundTime = WeaponTimeBase() + 0.2;

		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );

		m_pPlayer.pev.punchangle.x = -11.0;

		self.SendWeaponAnim( M16A3_LAUNCH, 0, GetBodygroup() );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		if ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) != 0 )
		{
			// play this sound through BODY channel so we can hear it if player didn't stop firing MP3
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl/weapons/glauncher.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		else
		{
			// play this sound through BODY channel so we can hear it if player didn't stop firing MP3
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl/weapons/glauncher2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
	
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		// we don't add in player velocity anymore.
		if( ( m_pPlayer.pev.button & IN_DUCK ) != 0 )
		{
			g_EntityFuncs.ShootContact( m_pPlayer.pev, 
								m_pPlayer.pev.origin + g_Engine.v_forward * 16 + g_Engine.v_right * 6, 
								g_Engine.v_forward * 900 ); //800
		}
		else
		{
			g_EntityFuncs.ShootContact( m_pPlayer.pev, 
								m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs * 0.5 + g_Engine.v_forward * 16 + g_Engine.v_right * 6, 
								g_Engine.v_forward * 900 ); //800
		}
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.25;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 1.25;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 5;// idle pretty soon after shooting.

		if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
			// HEV suit - indicate out of ammo condition
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
	}

	void Reload()
	{
		self.DefaultReload( M16A3_MAX_CLIP, M16A3_RELOAD_M16, 3.25, GetBodygroup() );

		//Set 3rd person reloading animation -Sniper
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
			iAnim = M16A3_IDLE;	
			break;
		
		case 1:
			iAnim = M16A3_FIDGET;
			break;
			
		default:
			iAnim = M16A3_FIDGET;
			break;
		}

		self.SendWeaponAnim( iAnim, 0, GetBodygroup() );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );// how long till we do this again.
	}
}

class ammo_bts_m16 : ScriptBasePlayerAmmoEntity
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

		iGive = M16A3_MAX_CLIP;

		if( pOther.GiveAmmo( iGive, "556", M16A3_MAX_AMMO ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

//Ammo Drop
class ammo_bts_556round : ScriptBasePlayerAmmoEntity
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

		iGive = Math.RandomLong( 9, 23 );

		if( pOther.GiveAmmo( iGive, "556", M16A3_MAX_AMMO ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1, ATTN_NORM );
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

string GetAmmoDropName()
{
	return "ammo_bts_556round";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M16A3::weapon_bts_m16", GetName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M16A3::ammo_bts_m16", GetAmmoName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M16A3::ammo_bts_556round", GetAmmoDropName() );
	g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", "556", "ARgrenades", GetAmmoName() );
}

}
