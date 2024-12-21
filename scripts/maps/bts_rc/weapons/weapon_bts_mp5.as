/*  
* H&K MP5
*/

namespace HL_MP5
{

enum Mp5Animation
{
	MP5_LONGIDLE = 0,
	MP5_IDLE1,
	MP5_LAUNCH,
	MP5_RELOAD,
	MP5_DEPLOY,
	MP5_FIRE1,
	MP5_FIRE2,
	MP5_FIRE3,
};

array<string> HEV =
{
	"bts_helmet"
};

const int MP5_DEFAULT_GIVE 	= Math.RandomLong( 5, 30 );
const int MP5_MAX_AMMO		= 120;
const int MP5_MAX_CLIP 		= 30;
const int MP5_MAX_DROP		= Math.RandomLong( 9, 21 ); //14
const int MP5_WEIGHT 		= 5;

const string MODEL_AMMO		= "models/hlclassic/w_9mmarclip.mdl";
const string V_MODEL = "models/bts_rc/weapons/v_9mmAR.mdl";

class weapon_bts_mp5 : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{
	private CBasePlayer@ m_pPlayer = null;
	
	float m_flNextAnimTime;
	int m_iShell;
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
		g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/w_9mmAR.mdl" );

		self.m_iDefaultAmmo = MP5_DEFAULT_GIVE;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/bts_rc/weapons/v_9mmAR.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/weapons/w_9mmAR.mdl" );
		g_Game.PrecacheModel( "models/bts_rc/weapons/p_9mmAR.mdl" );
		g_Game.PrecacheModel( MODEL_AMMO );

		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );

		g_Game.PrecacheModel( "models/grenade.mdl" );

		g_Game.PrecacheModel( "models/w_9mmARclip.mdl" );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );              

		//These are played by the model, needs changing there
		g_SoundSystem.PrecacheSound( "hl/items/clipinsert1.wav" );
		g_SoundSystem.PrecacheSound( "hl/items/cliprelease1.wav" );
		g_SoundSystem.PrecacheSound( "hl/items/guncock1.wav" );

		g_SoundSystem.PrecacheSound( "bts_rc/weapons/mp5_fire1.wav" );

		g_SoundSystem.PrecacheSound( "hl/weapons/357_cock1.wav" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= MP5_MAX_AMMO;
		info.iMaxClip 	= MP5_MAX_CLIP;
		info.iSlot 		= 2;
		info.iPosition 	= 4;
		info.iFlags 	= 0;
		info.iWeight 	= MP5_WEIGHT;

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
		return self.DefaultDeploy( self.GetV_Model( "models/bts_rc/weapons/v_9mmAR.mdl" ), self.GetP_Model( "models/bts_rc/weapons/p_9mmAR.mdl" ), MP5_DEPLOY, "mp5", 0, GetBodygroup() );
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
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.12;
			return;
		}

		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.12;
			return;
		}

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;
		
		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
		{
		case 0: self.SendWeaponAnim( MP5_FIRE1, 0, GetBodygroup() ); break;
		case 1: self.SendWeaponAnim( MP5_FIRE2, 0, GetBodygroup() ); break;
		case 2: self.SendWeaponAnim( MP5_FIRE3, 0, GetBodygroup() ); break;
		}
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/mp5_fire1.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

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
			vecSpread = VECTOR_CONE_1DEGREES; //spread when standing
		}
		else
		{
			vecSpread = Vector( 0.01, 0.01, 0.01 ); //spread when crouching
		}

		vecSpread = vecSpread * 1.0f;
		
		// optimized multiplayer. Widened to make it easier to hit a moving player
		self.FireBullets( 1, vecSrc, vecAiming, vecSpread, 8192, BULLET_PLAYER_MP5, 4, 0, m_pPlayer.pev );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			// HEV suit - indicate out of ammo condition
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			
		// model difference
		string modelName = g_EngineFuncs.GetInfoKeyBuffer(m_pPlayer.edict()).GetValue( "model" );

		if ( HEV.find(modelName) >= 0 )
		{
			m_pPlayer.pev.punchangle.x = -2.0;

			self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.116;
			if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
				self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.116;
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
				m_pPlayer.pev.punchangle.x = Math.RandomLong( -5, 3 ); //recoil when stand
			}

			self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.124;
			if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
				self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.124;
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming + x * vecSpread.x * g_Engine.v_right + y * vecSpread.y * g_Engine.v_up;
		Vector vecEnd = vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );
			}
		}
	}

	void Reload()
	{
		string modelName = g_EngineFuncs.GetInfoKeyBuffer(m_pPlayer.edict()).GetValue( "model" );

		if ( HEV.find(modelName) >= 0 )
		{
			self.DefaultReload( MP5_MAX_CLIP, MP5_RELOAD, 1.5, GetBodygroup() );
		}
		else
		{
			self.DefaultReload( MP5_MAX_CLIP, MP5_RELOAD, 1.75, GetBodygroup() );
		}

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
			iAnim = MP5_LONGIDLE;	
			break;
		
		case 1:
			iAnim = MP5_IDLE1;
			break;
			
		default:
			iAnim = MP5_IDLE1;
			break;
		}

		self.SendWeaponAnim( iAnim, 0, GetBodygroup() );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );// how long till we do this again.
	}
}

class ammo_bts_mp5 : ScriptBasePlayerAmmoEntity
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

		iGive = MP5_MAX_CLIP;

		if( pOther.GiveAmmo( iGive, "9mm", MP5_MAX_AMMO ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

class ammo_bts_dmp5 : ScriptBasePlayerAmmoEntity
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

		iGive = MP5_MAX_DROP;

		if( pOther.GiveAmmo( iGive, "9mm", MP5_MAX_AMMO ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

string GetHLMP5Name()
{
	return "weapon_bts_mp5";
}

string GetHLMP5AmmoName()
{
	return "ammo_bts_mp5";
}

string GetHLMP5DAmmoName()
{
	return "ammo_bts_dmp5";
}

void RegisterHLMP5()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5::weapon_bts_mp5", GetHLMP5Name() );
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5::ammo_bts_mp5", GetHLMP5AmmoName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5::ammo_bts_dmp5", GetHLMP5DAmmoName() );
	g_ItemRegistry.RegisterWeapon( GetHLMP5Name(), "bts_rc/weapons", "9mm", "", GetHLMP5AmmoName(), GetHLMP5DAmmoName() );
}

}