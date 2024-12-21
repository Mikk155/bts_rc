//Black Mesa Emergency Flare
/* Model Credits
/ Model: Valve
/ Textures: Valve
/ Animations: Valve
/ Sounds: Valve
/ Sprites: Valve
/ Misc: Valve, D.N.I.O. 071 (Player Model Fix)
/ Script: Solokiller, KernCore, original base from Nero
*/

#include "../proj/proj_flare"

namespace BTS_FLARE
{

// Animations
enum BTS_Flare_Animations 
{
	IDLE = 0,
	PULLPIN,
	THROW,
	DRAW
};

// Models
string W_MODEL  	= "models/bts_rc/weapons/w_flare.mdl";
string V_MODEL  	= "models/bts_rc/weapons/v_flare.mdl";
string P_MODEL  	= "models/bts_rc/weapons/p_flare.mdl";
string TOSS_MODEL   = "models/bts_rc/weapons/flare.mdl";
// Sounds
array<string> 		WeaponSoundEvents = {
					"bts_rc/weapons/flare_pin.wav"
};
// Information
int MAX_CARRY   	= 5;
int MAX_CLIP    	= WEAPON_NOCLIP;
int DEFAULT_GIVE 	= 1;
int WEIGHT      	= 5;
int FLAGS       	= ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE;
uint DAMAGE     	= 0;
uint SLOT       	= 4;
uint POSITION   	= 5;
string AMMO_TYPE 	= GetFlareName();
float TIMER      	= 1.5;

class weapon_bts_flare : ScriptBasePlayerWeaponEntity, HLWeaponUtils, FlareWeaponExplode
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	private bool m_bInAttack, m_bThrown;
	private float m_fAttackStart, m_flStartThrow;
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
            	m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 0, 0 );
            	break;
        	case 1:
            	m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 0, 1 );
            	break;
        	case 2:
            	m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 0, 2 );
            	break;
			case 3:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 0, 3 );
            	break;
			case 4:
				m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), m_iCurBodyConfig, 0, 4 );
            	break;
    	}

    	return m_iCurBodyConfig;
	}

	void Spawn()
	{
		Precache();

		self.pev.dmg = DAMAGE;
		CommonSpawn( W_MODEL, DEFAULT_GIVE );
		self.pev.scale = 1;
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		//Models
		g_Game.PrecacheModel( W_MODEL );
		g_Game.PrecacheModel( V_MODEL );
		g_Game.PrecacheModel( P_MODEL );
		g_Game.PrecacheModel( TOSS_MODEL );
		//Entities
		g_Game.PrecacheOther( FLARE_PROJ::DEFAULT_PROJ_NAME );
		//Sounds
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/flare_pin.wav" );
		//Sprites
//		CommonSpritePrecache();
        g_Game.PrecacheGeneric('sprites/bts_rc/weapons/' + pev.classname + '.txt');
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= MAX_CARRY;
		info.iMaxAmmo2 	= WEAPON_NOCLIP;
		info.iMaxClip 	= MAX_CLIP;
		info.iSlot  	= SLOT;
		info.iPosition 	= POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= FLAGS;
		info.iWeight 	= WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		return CommonAddToPlayer( pPlayer );
	}

	// Better ammo extraction --- Anggara_nothing
	bool CanHaveDuplicates()
	{
		return true;
	}

	private int m_iAmmoSave;
	bool Deploy()
	{
		m_iAmmoSave = 0; // Zero out the ammo save
		return Deploy( V_MODEL, P_MODEL, DRAW, "gren", GetBodygroup(), (20.0/30.0) );
	}

	bool CanHolster()
	{
		if( m_fAttackStart != 0 )
			return false;

		return true;
	}

	bool CanDeploy()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType) == 0 )
			return false;

		return true;
	}

	private CBasePlayerItem@ DropItem()
	{
		m_iAmmoSave = m_pPlayer.AmmoInventory( self.m_iPrimaryAmmoType ); //Save the player's ammo pool in case it has any in DropItem

		return self;
	}

	void Holster( int skipLocal = 0 )
	{
		m_bThrown = false;
		m_bInAttack = false;
		m_fAttackStart = 0;
		m_flStartThrow = 0;

		CommonHolster();

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 ) //Save the player's ammo pool in case it has any in Holster
		{
			m_iAmmoSave = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		}

		if( m_iAmmoSave <= 0 )
		{
			SetThink( ThinkFunction( DestroyThink ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0  )
			return;

		if( m_fAttackStart < 0 || m_fAttackStart > 0 )
			return;

		self.m_flNextPrimaryAttack = WeaponTimeBase() + (40.0/41.0);
		self.SendWeaponAnim( PULLPIN, 0, GetBodygroup() );

		m_bInAttack = true;
		m_fAttackStart = g_Engine.time + (40.0/41.0);

		self.m_flTimeWeaponIdle = g_Engine.time + (40.0/41.0) + (23.0/30.0);
	}

	void LaunchThink()
	{
		//g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_VOICE, SHOOT_S, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		Vector angThrow = m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle;

		if ( angThrow.x < 0 )
			angThrow.x = -10 + angThrow.x * ( (90 - 10) / 90.0 );
		else
			angThrow.x = -10 + angThrow.x * ( (90 + 10) / 90.0 );

		float flVel = (90.0f - angThrow.x) * 6;

		if ( flVel > 750.0f )
			flVel = 750.0f;

		Math.MakeVectors( angThrow );

		Vector vecSrc = m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * 16;
		Vector vecThrow = g_Engine.v_forward * flVel + m_pPlayer.pev.velocity;

		FLARE_PROJ::CFlare@ Flare = FLARE_PROJ::TossGrenade( m_pPlayer.pev, vecSrc, vecThrow, TIMER, DAMAGE, TOSS_MODEL );

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
		m_fAttackStart = 0;
	}

	void ItemPreFrame()
	{
		if( m_fAttackStart == 0 && m_bThrown == true && m_bInAttack == false && self.m_flTimeWeaponIdle - 0.1 < g_Engine.time )
		{
			if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
			{
				self.Holster();
			}
			else
			{
				self.Deploy();
				m_bThrown = false;
				m_bInAttack = false;
				m_fAttackStart = 0;
				m_flStartThrow = 0;
			}
		}

		if( !m_bInAttack || CheckButton() || g_Engine.time < m_fAttackStart )
			return;

		self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = WeaponTimeBase() + (22.0/30.0);
		self.SendWeaponAnim( THROW, 0, GetBodygroup() );
		m_bThrown = true;
		m_bInAttack = false;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		SetThink( ThinkFunction( this.LaunchThink ) );
		self.pev.nextthink = g_Engine.time + 0.2;

		BaseClass.ItemPreFrame();
	}

/*	void SecondaryAttack()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0  )
			return;

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + (40.0/41.0);
		self.SendWeaponAnim( PULLPIN, 0, GetBodygroup() );

		m_fAttackStart = g_Engine.time + (40.0/41.0);

		self.m_flTimeWeaponIdle = g_Engine.time + (40.0/41.0) + (23.0/30.0);

		@SelfFlareLightSchedule = @g_Scheduler.SetInterval( @this, "FlareSelfThink", 0.099f, 1200.0f ); // How much time the flare will last long
	}
*/

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		self.SendWeaponAnim( IDLE, 0, GetBodygroup() );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 7 );
	}
}

string GetFlareName()
{
	return "weapon_bts_flare";
}

void RegisterFLARE()
{
	FLARE_PROJ::Register();
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLARE::weapon_bts_flare", GetFlareName() );
	g_ItemRegistry.RegisterWeapon( GetFlareName(), "bts_rc/weapons", AMMO_TYPE, "", GetFlareName() );
}

}