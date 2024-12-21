// Spray Aid with Bandages
// Author: Mikk

namespace BTS_SPRAYAID
{

//model
const string W_SPRAYAID = "models/bts_rc/items/w_medkits.mdl";
//sound
const string SPRAYAID_PICKUP_SND = "bts_rc/items/sprayaid1.wav";

class item_bts_sprayaid : ScriptBasePlayerItemEntity
{
	private bool Activated = true;
	dictionary g_MaxPlayers;

	void Spawn()
	{ 
		Precache();

		if( self.SetupModel() == false )
			g_EntityFuncs.SetModel( self, W_SPRAYAID );
		else //Custom model
			g_EntityFuncs.SetModel( self, self.pev.model );

        if( self.pev.SpawnFlagBitSet( 384 )  )
		{	
            Activated = false;
		}

		BaseClass.Spawn();
	}

	void Precache()
	{
		BaseClass.Precache();

		if( string( self.pev.model ).IsEmpty() )
			g_Game.PrecacheModel( W_SPRAYAID );
		else //Custom model
			g_Game.PrecacheModel( self.pev.model );

		g_SoundSystem.PrecacheSound( SPRAYAID_PICKUP_SND );
	}
		
	void AddHealth( CBasePlayer@ pPlayer )
	{	
        string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

		if( pPlayer is null || pPlayer.pev.health == pPlayer.pev.max_health || g_MaxPlayers.exists(steamId)  )
			return;
			
		pPlayer.TakeHealth( Math.RandomFloat( 10, 12 ), DMG_GENERIC ); //pPlayer.TakeHealth( g_EngineFuncs.CVarGetFloat( "sk_healthkit" ), DMG_GENERIC );

        g_MaxPlayers[steamId] = @pPlayer;

		NetworkMessage message( MSG_ONE, NetworkMessages::ItemPickup, pPlayer.edict() );
			message.WriteString( self.m_iId );
		message.End();

		g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_ITEM, SPRAYAID_PICKUP_SND, 1, ATTN_NORM );

        // Trigger targets
        self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0 );

		g_EntityFuncs.Remove( self );
	}

	void Touch( CBaseEntity@ pOther )
	{
		if( pOther is null || !pOther.IsPlayer() || !pOther.IsAlive() || !Activated || self.pev.SpawnFlagBitSet( 256 ) )
			return;
				
		AddHealth( cast<CBasePlayer@>( pOther ) );
	}
		
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
        if( self.pev.SpawnFlagBitSet( 384 ) && !Activated )
		{	
            Activated = !Activated;
		}

		if( pActivator.IsPlayer() && Activated )
		{
			AddHealth( cast<CBasePlayer@>( pActivator ) );
		}
	}		
}

string GetItemName()
{
    return "item_bts_sprayaid";
}

void Register()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_SPRAYAID::item_bts_sprayaid", GetItemName() ); // register class entity
	g_ItemRegistry.RegisterItem( GetItemName(), "bts_rc/items" );
}

}