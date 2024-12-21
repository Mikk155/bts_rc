// Selective nightvision
// Author: Mikk, Nero

CScheduledFunction@ g_pNVThinkFunc = null;
dictionary g_PlayerNV;
const Vector NV_COLOR( 250, 200, 20 );
const int g_iRadius = 40;
const int iDecay = 1;
const int iLife	= 2;
const int iBrightness = 64;

void BTSRC_NightVision()
{
	//Sounds precache
	nvg_Precache();

	//nightvision Hook
	g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @BTS_NIGHTVISION::PlayerPreThink );

	if( g_pNVThinkFunc !is null )
		g_Scheduler.RemoveTimer( g_pNVThinkFunc );

	@g_pNVThinkFunc = g_Scheduler.SetInterval( "nvThink", 0.005f );
}

void nvg_Precache()
{
	g_SoundSystem.PrecacheSound( "player/hud_nightvision.wav" );
	g_SoundSystem.PrecacheSound( "items/flashlight2.wav" );
}

namespace BTS_NIGHTVISION
{
	array<string> HEV =
	{
		"bts_helmet"
	};

	HookReturnCode PlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags )
	{
		if( pPlayer is null || HEV.find( g_EngineFuncs.GetInfoKeyBuffer( pPlayer.edict() ).GetValue( "model" ).ToLowercase() ) < 0 )
			return HOOK_CONTINUE;

		if( pPlayer.pev.impulse == 100 )
		{
			g_NightVision.ToggleNV( pPlayer );
		}

		g_NightVision.nvThink( pPlayer );

		return HOOK_CONTINUE;
	}

	enum NV_STATE
	{
		NV_NONE = -1,
		NV_OFF,
		NV_ON
	}

	class PlayerNVData
	{
  		Vector nvColor;
	}

	CNightVision g_NightVision;

	final class CNightVision
	{
		int State( CBasePlayer@ pPlayer, const NV_STATE mode = NV_NONE )
		{
			if( pPlayer !is null )
			{
				string kv = "$i_btsrc_nightvision";

				int state = pPlayer.GetCustomKeyvalues().GetKeyvalue( kv ).GetInteger();

				if( mode != NV_NONE )
				{
					state = mode;
            		g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), kv, string( state ) );
				}
				return state;
			}
			return NV_OFF;
        }

		void ToggleNV( CBasePlayer@ pPlayer )
		{
			if( pPlayer.IsAlive() )	
			{
				if ( pPlayer.pev.impulse == 100 )
				{
					string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );

					if ( g_PlayerNV.exists( szSteamId ) )
					{
						removeNV( pPlayer );
					}
					else
					{
						PlayerNVData data;
						data.nvColor = Vector(250, 200, 20);
						g_PlayerNV[szSteamId] = data;
						g_PlayerFuncs.ScreenFade( pPlayer, NV_COLOR, 0.01, 0.01, iBrightness, FFADE_OUT | FFADE_STAYOUT);
						g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_WEAPON, "player/hud_nightvision.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
					}
				}
			
			}
		}

		void nvMsg( CBasePlayer@ pPlayer, const string szSteamId )
		{
			PlayerNVData@ data = cast<PlayerNVData@>( g_PlayerNV[szSteamId] );

			Vector vecSrc = pPlayer.EyePosition();

			NetworkMessage nvon( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, pPlayer.edict() );
				nvon.WriteByte( TE_DLIGHT );
				nvon.WriteCoord( vecSrc.x );
				nvon.WriteCoord( vecSrc.y );
				nvon.WriteCoord( vecSrc.z );
				nvon.WriteByte( g_iRadius );
				nvon.WriteByte( int(NV_COLOR.x) );
				nvon.WriteByte( int(NV_COLOR.y) );
				nvon.WriteByte( int(NV_COLOR.z) );
				nvon.WriteByte( iLife );
				nvon.WriteByte( iDecay );
			nvon.End();
		}

		void removeNV( CBasePlayer@ pPlayer )
		{
			string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
			
			g_PlayerFuncs.ScreenFade( pPlayer, NV_COLOR, 0.01, 0.01, iBrightness, FFADE_IN);
			g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_WEAPON, "items/flashlight2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
			
			if ( g_PlayerNV.exists(szSteamId) )
				g_PlayerNV.delete(szSteamId);
		}

		HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
		{
			string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
			
			if ( g_PlayerNV.exists(szSteamId) )
				removeNV( pPlayer );
		
			return HOOK_CONTINUE;
		}

		HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
		{
			string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
			
			if ( g_PlayerNV.exists(szSteamId) )
				removeNV( pPlayer );
		
			return HOOK_CONTINUE;
		}

		HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
		{
			string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
			
			if ( g_PlayerNV.exists(szSteamId) )
				removeNV( pPlayer );
		
			return HOOK_CONTINUE;
		}

		void nvThink( CBasePlayer@ pPlayer )
		{
			for ( int i = 1; i <= g_Engine.maxClients; ++i )
			{
				CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);

				if ( pPlayer !is null && pPlayer.IsConnected() )
				{
					string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );

					if ( g_PlayerNV.exists(szSteamId) )
						nvMsg( pPlayer, szSteamId );
				}
			}
		}

	}

}