//HEV Battery Power (Custom)
//Taken from ammo_individual code created by Mikk & Gaftherman
//Author: Mikk & Gaftherman

namespace BTS_HEVBATTERY
{

array<string> IsNotHEVUser =
{
	"bts_scientist",
	"bts_scientist2",
	"bts_scientist3",
	"bts_scientist4",
	"bts_scientist5",
	"bts_scientist6",
	"bts_barney",
	"bts_barney2",
	"bts_otis",
	"bts_construction"
};

const string W_HEVBATTERY = "models/hlclassic/w_battery.mdl";
const string PICKUP_SND   = "items/gunpickup2.wav";

class item_bts_hevbattery : ScriptBasePlayerItemEntity
{
	private bool Activated = true;
	dictionary g_MaxPlayers;

	void Spawn()
	{
		Precache();

		if( self.SetupModel() == false )
			g_EntityFuncs.SetModel( self, W_HEVBATTERY );
		else //Custom model
			g_EntityFuncs.SetModel( self, self.pev.model );

		if( self.pev.SpawnFlagBitSet( 384 ) )
		{
			Activated = false;
		}

		BaseClass.Spawn();
	}

	void Precache()
	{
		BaseClass.Precache();

		if( string( self.pev.model ).IsEmpty() )
			g_Game.PrecacheModel( W_HEVBATTERY );
		else //Custom model
			g_Game.PrecacheModel( self.pev.model );

		g_SoundSystem.PrecacheSound( PICKUP_SND );
	}

	void AddArmor( CBasePlayer@ pPlayer )
	{
		string steamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
		int pct;
		string modelName = g_EngineFuncs.GetInfoKeyBuffer( pPlayer.edict() ).GetValue( "model" );

		//non-HEV user won't get this battery as their armor
		if( IsNotHEVUser.find( modelName ) >= 0 )
			return;

		//player that has 100 AP, doesn't have suit ( in general ) and they existed, won't get the battery anymore
		if( pPlayer is null || pPlayer.pev.armorvalue >= 100 && pPlayer.HasSuit() || !pPlayer.HasSuit() || g_MaxPlayers.exists( steamId ) )
			return;

		g_MaxPlayers[ steamId ] = @pPlayer;

		pPlayer.pev.armorvalue += Math.RandomFloat( 10, 25 ); //int( g_EngineFuncs.CVarGetFloat( "sk_battery" ) );
		pPlayer.pev.armorvalue = Math.min( pPlayer.pev.armorvalue, 100 );

		//Battery sound
		g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_ITEM, PICKUP_SND, 1, ATTN_NORM );

		NetworkMessage msg( MSG_ONE, NetworkMessages::ItemPickup, pPlayer.edict() );
			msg.WriteString( "item_battery" );
		msg.End();

		//Suit reports new power level
		//For some reason this wasn't working in release build -- round it.
		pct = int( float( pPlayer.pev.armorvalue * 100.0 ) * ( 1.0 / 100 ) + 0.5 );
		pct = ( pct / 5 );
		if( pct > 0 )
			pct--;

		//EMIT_SOUND_SUIT( ENT( pev), szcharge );
		pPlayer.SetSuitUpdate( "!HEV_" + pct + "P", false, 30 );

		//Trigger targets
		self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0 );

		g_EntityFuncs.Remove( self );
	}

	void Touch( CBaseEntity@ pOther )
	{
		if( pOther is null || !pOther.IsPlayer() || !pOther.IsAlive() || !Activated || self.pev.SpawnFlagBitSet( 256 ) )
			return;

		AddArmor( cast<CBasePlayer@>( pOther ) );
	}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		if( self.pev.SpawnFlagBitSet( 384 ) && !Activated )
		{
			Activated = !Activated;
		}

		if( pActivator.IsPlayer() && Activated )
		{
			AddArmor( cast<CBasePlayer@>( pActivator ) );
		}
	}
}

string GetName()
{
	return "item_bts_hevbattery";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "BTS_HEVBATTERY::item_bts_hevbattery", GetName() ); //register class entity
	g_ItemRegistry.RegisterItem( GetName(), "bts_rc/items" );
}

}