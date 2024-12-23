/*
* Custom Player Sound (Experiment)
* Code Author: Nero0 & Mikk
*/

namespace PLAYER_VOICES
{

array<string> Sci =
{
	"bts_scientist",
	"bts_scientist2",
	"bts_scientist3",
	"bts_scientist4",
	"bts_scientist5",
	"bts_scientist6"
};

array<string> Barn =
{
	"bts_barney",
	"bts_barney2",
	"bts_barney3",
	"bts_otis"
};

array<string> Constr =
{
	"bts_construction",
	"HL_Construction",
	"HL_Gus"
};

array<string> HEV =
{
	"bts_helmet"
};

HookReturnCode BTSRC_PlayerSpawn( CBasePlayer@ pPlayer )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.SetKeyvalue( "$fl_lastHealth", pPlayer.pev.health );
	pCustom.SetKeyvalue( "$fl_lastPain", 0.0f );

	return HOOK_CONTINUE;
}

HookReturnCode BTSRC_PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
{
	//Get the player model
	string modelName = g_EngineFuncs.GetInfoKeyBuffer( pPlayer.edict() ).GetValue( "model" );

	if( Sci.find( modelName ) >= 0 ) //scientist death sound
	{
		if( pPlayer.pev.health > -60 )
		{
			if( pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
			{
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, "bts_rc/player/pl_drown1.wav", 1, ATTN_NORM );
			}
			else
			{
				int iNum = Math.RandomLong( 1, 3 );
				string sName = "scientist/sci_die" + string( iNum ) + ".wav"; //its the other way around idek why lmao
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, sName, 1, ATTN_NORM );
			}
		}
	}
	else if( Barn.find( modelName ) >= 0 ) //barney death sound
	{
		if( pPlayer.pev.health > -60 )
		{
			if( pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
			{
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, "bts_rc/player/pl_drown1.wav", 1, ATTN_NORM );
			}
			else
			{
				int iNum = Math.RandomLong( 1, 4 );
				string sName = "barney/ba_die" + string( iNum ) + ".wav"; //ditto
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, sName, 1, ATTN_NORM );
			}
		}
	}
	else if( Constr.find( modelName ) >= 0 ) //construction death sounds
	{
		if( pPlayer.pev.health > -60 )
		{
			if( pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
			{
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, "bts_rc/player/pl_drown1.wav", 1, ATTN_NORM );
			}
			else
			{
				int iNum = Math.RandomLong( 1, 4 );
				string sName = "bts_rc/player/construction/co_die" + string( iNum ) + ".wav"; //ditto
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, sName, 1, ATTN_NORM );
			}
		}
	}
	else if( HEV.find( modelName ) >= 0 ) //HEV user death sound
	{
		if( pPlayer.pev.health > -60 )
		{
			if( pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
			{
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, "bts_rc/player/pl_drown1.wav", 1, ATTN_NORM );
			}
			else
			{
				int iNum = Math.RandomLong( 1, 4 );
				string sName = "bts_rc/player/helmet/hm_death" + string( iNum ) + ".wav"; //ditto
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, sName, 1, ATTN_NORM );
			}
		}
	}
	else //generic playermodel death sound ( can be modified )
	{
		if( pPlayer.pev.health > -60 )
		{
			if( pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
			{
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, "bts_rc/player/generic/pl_drown1.wav", 1, ATTN_NORM );
			}
			else
			{
				int iNum = Math.RandomLong( 1, 4 );
				string sName = "bts_rc/player/generic/pl_death" + string( iNum ) + ".wav";
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, sName, 1, ATTN_NORM );
			}
		}
	}

	return HOOK_CONTINUE;
}

HookReturnCode BTSRC_PlayerPostThink( CBasePlayer@ pPlayer )
{
	BTSRC_PlayPlayerPainSounds( EHandle( pPlayer ) );

	return HOOK_CONTINUE;
}

void BTSRC_PlayPlayerPainSounds( EHandle& in ePlayer )
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );
	if( pPlayer is null ) return;

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	float flLastHealth = pCustom.GetKeyvalue( "$fl_lastHealth" ).GetFloat();
	float flLastPain = pCustom.GetKeyvalue( "$fl_lastPain" ).GetFloat();

	//Update last health value
	pCustom.SetKeyvalue( "$fl_lastHealth", pPlayer.pev.health );

	if( flLastPain > g_Engine.time ) return;
	if( pPlayer.pev.health <= 0 ) return;

	float flDmg = pPlayer.m_lastPlayerDamageAmount;
	if( flDmg < 1.0f || ( flLastHealth - pPlayer.pev.health < 1.0f ) ) return; //1.0f = every 1 HP damage will cause player to emit pain sound

	//Get the player model
	string modelName = g_EngineFuncs.GetInfoKeyBuffer( pPlayer.edict() ).GetValue( "model" );

	//Determine sound to play based on the model
	int iDmgType = pPlayer.m_bitsDamageType;
	string sName;
	if( Sci.find( modelName ) >= 0 )
	{
		//barney pain sounds
		sName = "scientist/sci_pain" + string( Math.RandomLong( 1, 10 ) ) + ".wav";
	}
	else if( Barn.find( modelName ) >= 0 )
	{
		//scientist pain sounds
		sName = "barney/ba_pain" + string( Math.RandomLong( 1, 3 ) ) + ".wav";
	}
	else if( Constr.find( modelName ) >= 0 )
	{
		//construction pain sounds
		sName = "bts_rc/player/construction/co_pain" + string( Math.RandomLong( 1, 4 ) ) + ".wav";
	}
	else if( HEV.find( modelName ) >= 0 )
	{
		//barney pain sounds
		sName = "bts_rc/player/helmet/hm_pain" + string( Math.RandomLong( 1, 5 ) ) + ".wav";
	}
	else
	{
		//generic playermodel pain sounds ( can be modified )
		sName = "bts_rc/player/generic/pl_pain" + string( Math.RandomLong(1, 5)) + ".wav";
	}

	//Update last pain time
	pCustom.SetKeyvalue( "$fl_lastPain", g_Engine.time + 0.7f );

	//Emit the sound
	g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, sName, 1, ATTN_NORM );
}

void BTSRC_PrecachePlayerSounds()
{
	//generic playermodel
	g_SoundSystem.PrecacheSound( "bts_rc/player/generic/pl_burn1.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/generic/pl_burn2.wav" );

	g_SoundSystem.PrecacheSound( "bts_rc/player/generic/pl_death1.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/generic/pl_death2.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/generic/pl_death3.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/generic/pl_death4.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/generic/pl_drown1.wav" );

	g_SoundSystem.PrecacheSound( "bts_rc/player/generic/pl_pain1.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/generic/pl_pain2.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/generic/pl_pain3.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/generic/pl_pain4.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/generic/pl_pain5.wav" );

	//HEV user
	g_SoundSystem.PrecacheSound( "bts_rc/player/helmet/hm_death1.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/helmet/hm_death2.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/helmet/hm_death3.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/helmet/hm_death4.wav" );

	g_SoundSystem.PrecacheSound( "bts_rc/player/helmet/hm_pain1.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/helmet/hm_pain2.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/helmet/hm_pain3.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/helmet/hm_pain4.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/helmet/hm_pain5.wav" );

	//scientist
	g_SoundSystem.PrecacheSound( "scientist/sci_pain6.wav" );
	g_SoundSystem.PrecacheSound( "scientist/sci_pain7.wav" );
	g_SoundSystem.PrecacheSound( "scientist/sci_pain8.wav" );
	g_SoundSystem.PrecacheSound( "scientist/sci_pain9.wav" );
	g_SoundSystem.PrecacheSound( "scientist/sci_pain10.wav" );

	g_SoundSystem.PrecacheSound( "scientist/sci_die1.wav" );
	g_SoundSystem.PrecacheSound( "scientist/sci_die2.wav" );
	g_SoundSystem.PrecacheSound( "scientist/sci_die3.wav" );
	g_SoundSystem.PrecacheSound( "scientist/sci_die4.wav" );

	//construction
	g_SoundSystem.PrecacheSound( "bts_rc/player/construction/co_pain1.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/construction/co_pain2.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/construction/co_pain3.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/construction/co_pain4.wav" );

	g_SoundSystem.PrecacheSound( "bts_rc/player/construction/co_die1.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/construction/co_die2.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/construction/co_die3.wav" );
	g_SoundSystem.PrecacheSound( "bts_rc/player/construction/co_die4.wav" );
}

}