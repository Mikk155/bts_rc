/*
* The original Half-Life version of the hand grenade
*/
// Rewrited by Rizulix for bts_rc (january 2024)

#include "../utils/player_class"

namespace BTS_HANDGRENADE
{

enum handgrenade_e
{
	IDLE = 0,
	FIDGET,
	PULLPIN,
	THROW1,	//toss
	THROW2,	//medium
	THROW3,	//hard
	HOLSTER,
	DRAW
};

enum bodygroups_e
{
	BODY = 0,
	HANDS
};

// Models
string W_MODEL = "models/hlclassic/w_grenade.mdl";
string V_MODEL = "models/bts_rc/weapons/v_grenade.mdl";
string P_MODEL = "models/hlclassic/p_grenade.mdl";
string PRJ_MDL = "models/hlclassic/w_grenade.mdl";
// Sounds
array<string> SOUNDS = {
	"bts_rc/weapons/spas_idle4.wav",
	// "bts_rc/weapons/spas_foley.wav", // no found
	"bts_rc/weapons/grenade_pinpull.wav",
	"bts_rc/weapons/grenade_throw1.wav",
	"bts_rc/weapons/grenade_throw2.wav",
	"bts_rc/weapons/grenade_draw.wav"
};
// Weapon info
int MAX_CARRY = 10;
int MAX_CLIP = WEAPON_NOCLIP;
int DEFAULT_GIVE = 1;
int AMMO_GIVE = DEFAULT_GIVE;
int AMMO_DROP = AMMO_GIVE;
int WEIGHT = 20;
int FLAGS = ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE;
int ID; // assigned on register
string AMMO_TYPE = "Hand Grenade";
// Weapon HUD
uint SLOT = 4;
uint POSITION = 6;
// Vars
float TIMER = 3.0f;
float DAMAGE = 100.0f;
Vector OFFSET( 16.0f, 0.0f, 0.0f ); // for projectile

class weapon_bts_handgrenade : ScriptBasePlayerWeaponEntity, HLWeaponUtils
{
	private CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer>( self.m_hPlayer.GetEntity() ); }
		set       { self.m_hPlayer = EHandle( @value ); }
	}
	// private bool m_fHasHEV
	// {
	// 	get const { return g_PlayerClass[m_pPlayer] == HELMET; }
	// }
	private float m_flVel, m_fAttackStart, m_flStartThrow;
	private bool m_bInAttack, m_bThrown;
	private int m_iAmmoSave;

	int GetBodygroup()
	{
		pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), pev.body, HANDS, Math.min( 0, g_PlayerClass[m_pPlayer] ) );
		return pev.body;
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( W_MODEL ) );
		self.m_iDefaultAmmo = DEFAULT_GIVE;
		self.FallInit(); // get ready to fall
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( W_MODEL );
		g_Game.PrecacheModel( V_MODEL );
		g_Game.PrecacheModel( P_MODEL );
		g_Game.PrecacheModel( PRJ_MDL );

		g_Game.PrecacheOther( "grenade" );

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

	// Better ammo extraction --- Anggara_nothing
	bool CanHaveDuplicates()
	{
		return true;
	}

	bool Deploy()
	{
		m_iAmmoSave = 0; // Zero out the ammo save
		self.DefaultDeploy( self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), DRAW, "gren", 0, GetBodygroup() );
		self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + ( 20.0f / 30.0f );
		return true;
	}

	bool CanHolster()
	{
		return m_fAttackStart == 0.0f;
	}

	bool CanDeploy()
	{
		return m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0;
	}

	CBasePlayerItem@ DropItem()
	{
		m_iAmmoSave = m_pPlayer.AmmoInventory( self.m_iPrimaryAmmoType ); // Save the player"s ammo pool in case it has any in DropItem
		return self;
	}

	void Holster( int skiplocal = 0 )
	{
		m_bThrown = false;
		m_bInAttack = false;
		m_fAttackStart = 0.0f;
		m_flStartThrow = 0.0f;
		m_flVel = 0.0f;

		SetThink( null );

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 ) // Save the player"s ammo pool in case it has any in Holster
		{
			m_iAmmoSave = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		}

		if( m_iAmmoSave <= 0 )
		{
			SetThink( ThinkFunction( this.DestroyThink ) );
			pev.nextthink = g_Engine.time + 0.1f;
		}

		BaseClass.Holster( skiplocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return;

		if( m_fAttackStart < 0.0f || m_fAttackStart > 0.0f )
			return;

		self.m_flNextPrimaryAttack = g_Engine.time + ( 24.0f / 30.0f );
		self.SendWeaponAnim( PULLPIN, 0, GetBodygroup() );

		m_bInAttack = true;
		m_fAttackStart = g_Engine.time + ( 24.0f / 30.0f );
		m_flVel = 0.0f;

		self.m_flTimeWeaponIdle = g_Engine.time + ( 24.0f / 30.0f ) + ( 9.0f / 30.0f );
	}

	private void LaunchThink()
	{
		Vector angThrow = m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle;

		Math.MakeVectors( angThrow );
		Vector vecSrc = m_pPlayer.GetGunPosition() + g_Engine.v_forward * OFFSET.x + g_Engine.v_right * OFFSET.y + g_Engine.v_up * OFFSET.z;
		Vector vecThrow = g_Engine.v_forward * m_flVel + m_pPlayer.pev.velocity;

		// explode 3 seconds after launch
		CGrenade@ pGrenade = g_EntityFuncs.ShootTimed( m_pPlayer.pev, vecSrc, vecThrow, TIMER );
		if( pGrenade !is null )
		{
			g_EntityFuncs.SetModel( pGrenade, PRJ_MDL );
			pGrenade.pev.dmg = DAMAGE;
		}

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
		m_fAttackStart = 0.0f;
		m_flVel = 0.0f;
	}

	void ItemPreFrame()
	{
		if( m_fAttackStart == 0 && m_bThrown == true && m_bInAttack == false && self.m_flTimeWeaponIdle - 0.1f < g_Engine.time )
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
				m_fAttackStart = 0.0f;
				m_flStartThrow = 0.0f;
				m_flVel = 0.0f;
			}
		}

		if( !m_bInAttack || CheckButton() || g_Engine.time < m_fAttackStart )
			return;

		self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + ( 9.0f / 30.0f );

		Vector angThrow = m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle;

		if( angThrow.x < 0 )
			angThrow.x = -10.0f + angThrow.x * ( ( 90.0f - 10.0f ) / 90.0f );
		else
			angThrow.x = -10.0f + angThrow.x * ( ( 90.0f + 10.0f ) / 90.0f );

		m_flVel = ( 90.0f - angThrow.x ) * 4.0f;
		if( m_flVel > 500.0f )
			m_flVel = 500.0f;

		if( m_flVel < 500.0f )
			self.SendWeaponAnim( THROW1, 0, GetBodygroup() );
		else if( m_flVel < 1000.0f )
			self.SendWeaponAnim( THROW2, 0, GetBodygroup() );
		else
			self.SendWeaponAnim( THROW3, 0, GetBodygroup() );

		m_bThrown = true;
		m_bInAttack = false;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		SetThink( ThinkFunction( this.LaunchThink ) );
		pev.nextthink = g_Engine.time + 0.2f;

		BaseClass.ItemPreFrame();
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0.0f, 1.0f );
		if( flRand <= 0.75f )
		{
			self.SendWeaponAnim( IDLE, 0, GetBodygroup() );
			self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0f, 15.0f ); //how long till we do this again.
		}
		else
		{
			self.SendWeaponAnim( FIDGET, 0, GetBodygroup() );
			self.m_flTimeWeaponIdle = g_Engine.time + ( 70.0f / 30.0f );
		}
	}

	private bool CheckButton() // returns which key the player is pressing (that might interrupt the reload)
	{
		return m_pPlayer.pev.button & ( IN_ATTACK | IN_ATTACK2 | IN_ALT1 ) != 0;
	}

	private void DestroyThink() // destroys the item
	{
		SetThink( null );
		self.DestroyItem();
		//g_Game.AlertMessage( at_console, "Item Destroyed.\n" );
	}
}

string GetName()
{
	return "weapon_bts_handgrenade";
}
void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_HANDGRENADE::weapon_bts_handgrenade", GetName() );
	ID = g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", AMMO_TYPE, "", GetName(), "" );
}

}
