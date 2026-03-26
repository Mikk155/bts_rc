/*
	Author: Nero
*/

#include "customMonsterSettings"
#include "hwrgboss"
#include "robogrunts"
#include "zombies"
#include "monster_zombie_grenadier"
#include "monster_snapbug"
#include "monster_zombie_gunner"

namespace btscm
{

CScheduledFunction@ g_monsterThink = null;

void CustomMonsterMapInit()
{
	RobogruntMapInit();
	HWRGMapInit();
	ZombiesMapInit();

	monster_zombie_grenadier::Register();
	monster_snapbug::Register();
	monster_zombie_gunner::Register();

	//handles robots dying
	g_Hooks.RegisterHook( Hooks::Monster::MonsterKilled, @MonsterKilled );

	//handles snapbugs attached to players
	g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage);

	//handles effects and attacks
	if( g_monsterThink !is null )
		g_Scheduler.RemoveTimer( g_monsterThink );

	@g_monsterThink = g_Scheduler.SetInterval( "MonsterThink", THINKRATE_MAIN );
}

void MonsterThink()
{
	RoboThink();
	HWRGThink();
	ZombieThink();
}

HookReturnCode MonsterKilled( CBaseMonster@ pMonster, CBaseEntity@ pAttacker, int iGib )
{
	if( (IsRobot(pMonster) or IsRobotBoss(pMonster)) and pMonster.pev.deadflag == DEAD_NO )
	{
		if( (pMonster.pev.health < -40 and iGib != GIB_NEVER) or iGib == GIB_ALWAYS )
		{
			DoRobotDeath( EHandle(pMonster), true, IsRobotBoss(pMonster) );
			return HOOK_CONTINUE;
		}

		DoRobotDeath( EHandle(pMonster), false, IsRobotBoss(pMonster) );
	}

	return HOOK_CONTINUE;
}

HookReturnCode PlayerTakeDamage( DamageInfo@ pDamageInfo )
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );

	if( pPlayer.m_LastHitGroup != HITGROUP_CHEST or pPlayer.FInViewCone(pDamageInfo.pAttacker) )
		return HOOK_CONTINUE;

	RemoveSnapbug( pPlayer, pDamageInfo.flDamage );

	return HOOK_CONTINUE;
}

void RemoveSnapbug( CBasePlayer@ pPlayer, float flDamage = 0.0 )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	if( pCustom.GetKeyvalue(monster_snapbug::KVN_SNAPBUGGED).GetInteger() != 1 )
		return;

	CBaseEntity@ pSnapbug = null;
	while( (@pSnapbug = g_EntityFuncs.FindEntityByClassname(pSnapbug, monster_snapbug::NPC_CLASSNAME2)) !is null )
	{
		if( pSnapbug.pev.owner !is null and pSnapbug.pev.owner is pPlayer.edict() )
		{
			g_PlayerFuncs.HudToggleElement( pPlayer, monster_snapbug::HUD_SPRITE_SNAPBUG, false );
			pCustom.SetKeyvalue( monster_snapbug::KVN_SNAPBUGGED, 0 );
			g_SoundSystem.EmitSound( pSnapbug.edict(), CHAN_VOICE, monster_snapbug::arrsSounds[Math.RandomLong(monster_snapbug::SND_DEATH1, monster_snapbug::SND_DEATH2)], VOL_NORM, ATTN_IDLE );

			g_WeaponFuncs.SpawnBlood( pSnapbug.pev.origin, BLOOD_COLOR_GREEN, flDamage );
			//TraceBleed( flDamage, vecDir, ptr, bitsDamageType );

			g_EntityFuncs.Remove( pSnapbug );
		}
	}
}

void SpawnExplosion( Vector center, float randomRange, float time, int magnitude )
{
	center.x += Math.RandomFloat( -randomRange, randomRange );
	center.y += Math.RandomFloat( -randomRange, randomRange ); 

	CBaseEntity@ pExplosion = g_EntityFuncs.Create( "env_explosion", center, g_vecZero, false );
	pExplosion.KeyValue( "iMagnitude", string(magnitude) );

	g_EntityFuncs.DispatchSpawn( pExplosion.edict() );

	pExplosion.Use( null, null, USE_ON );

	pExplosion.pev.nextthink = g_Engine.time + time;
}

//GetGlobalTrace doesn't actually get the point of impact on the monster, it just looks that way to the player shooting
//slightly hacky way of getting the actual impact origin
/*TraceResult GetPlayerTrace( CBaseEntity@ pAttacker )
{
	if( pAttacker.pev.FlagBitSet(FL_CLIENT) )
	{
		Math.MakeVectors( pAttacker.pev.v_angle + pAttacker.pev.punchangle ); 
		Vector vecSrc = pAttacker.pev.origin + pAttacker.pev.view_ofs;
		Vector vecAiming = g_Engine.v_forward;
		Vector vecEnd = vecSrc + vecAiming * 8192;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pAttacker.edict(), tr );
		return tr;
	}
}*/

bool HasFlags( int iFlagVariable, int iFlags )
{
	return (iFlagVariable & iFlags) != 0;
}

float ptof( int iPercentage )
{
	return float( iPercentage ) / 100.0;
}

} //namespace btscm END


class bts_rc_base_monster : ScriptBaseMonsterEntity
{
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "is_player_ally" )
		{
			if( atoi(szValue) >= 1 )
				self.SetPlayerAllyDirect( true );

			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
}

/* FIXME
*/

/* TODO
	Use a map entity to "think" for the monsters instead of using the scheduler ??

	Use RadiusDamage etc for explosions, instead of env_explosion ??
*/