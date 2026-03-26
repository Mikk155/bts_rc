/*
	Author: Nero
*/

namespace btscm
{

HookReturnCode ZombieTakeDamage( DamageInfo@ pDamageInfo )
{
	if( IsZombieEngineer(pDamageInfo.pVictim) )
	{
		if( pDamageInfo.flDamage <= 0.0 or pDamageInfo.pVictim.pev.takedamage == DAMAGE_NO )
			return HOOK_CONTINUE;

		HandleZombieDamage( pDamageInfo );
	}

	return HOOK_CONTINUE;
}

void HandleZombieDamage( DamageInfo@ pDamageInfo )
{
	int iHitGroup = pDamageInfo.pVictim.MyMonsterPointer().m_LastHitGroup;

	if( iHitGroup == HITGROUP_CANISTER )
	{
		HandleCanisterDamage( EHandle(pDamageInfo.pVictim), EHandle(pDamageInfo.pAttacker), pDamageInfo.flDamage );

		TraceResult tr = g_Utility.GetGlobalTrace();

		if( pDamageInfo.pAttacker !is null and pDamageInfo.pAttacker.pev.FlagBitSet(FL_CLIENT) )
		{
			NetworkMessage ricochet( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, pDamageInfo.pAttacker.edict() );
				ricochet.WriteByte( TE_ARMOR_RICOCHET );
				ricochet.WriteCoord( tr.vecEndPos.x );
				ricochet.WriteCoord( tr.vecEndPos.y );
				ricochet.WriteCoord( tr.vecEndPos.z );
				ricochet.WriteByte( 10 ); //scale in 0.1's
			ricochet.End();
		}

		pDamageInfo.flDamage *= 0.1;
	}
	else if( iHitGroup == HITGROUP_CHEST or iHitGroup == HITGROUP_STOMACH )
	{
		if( Math.RandomLong(1, 100) <= CANISTER_STRAY_CHANCE )
			HandleCanisterDamage( EHandle(pDamageInfo.pVictim), EHandle(pDamageInfo.pAttacker), pDamageInfo.flDamage );
	}
}

void HandleCanisterDamage( EHandle hVictim, EHandle hAttacker, float flDamage )
{
	CBaseEntity@ pVictim = hVictim.GetEntity();
	if( pVictim is null ) return;

	CBaseEntity@ pAttacker = hAttacker.GetEntity();

	CustomKeyvalues@ pCustom = pVictim.GetCustomKeyvalues();

	float flCanisterHealth = pCustom.GetKeyvalue(KVN_ZOMBIECANHP).GetFloat();
	flCanisterHealth -= flDamage;

	if( flCanisterHealth > 0 )
		pCustom.SetKeyvalue( KVN_ZOMBIECANHP, flCanisterHealth );
	else if( flCanisterHealth != -1337 )
	{
		pCustom.SetKeyvalue( KVN_ZOMBIECANHP, -1337 );

		SpawnExplosion( pVictim.pev.origin, 0.0, 0.0, CANISTER_DAMAGE );
		entvars_t@ pevAttacker = null;

		if( pAttacker !is null )
			@pevAttacker = pAttacker.pev;

		pVictim.Killed( pevAttacker, GIB_ALWAYS );
	}
}

void ZombieThink()
{
	CBaseEntity@ pEntity = null;
	while( (@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "monster_zombie_soldier")) !is null )
	{
		if( pEntity.pev.model != "models/bts_rc/monsters/zombie_engineer.mdl" )
			continue;

		HandleZombieEngineer( EHandle(pEntity) );
	}

	@pEntity = null;

	while( (@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "monster_gonome")) !is null )
	{
		if( pEntity.pev.model != "models/bts_rc/monsters/zombie_engineer2.mdl" )
			continue;

		HandleZombieEngineer( EHandle(pEntity) );
	}

	while( (@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "monster_zombie_soldier")) !is null )
	{
		if( pEntity.pev.model != "models/bts_rc/monsters/zombie_construction_welder.mdl" )
			continue;

		HandleZombieEngineer( EHandle(pEntity) );
	}
}

void HandleZombieEngineer( EHandle hEntity )
{
	CBaseEntity@ pEntity = hEntity.GetEntity();
	if( pEntity is null ) return;

	CustomKeyvalues@ pCustom = pEntity.GetCustomKeyvalues();
	float flNextThink = pCustom.GetKeyvalue(KVN_MONSTERTHINK).GetFloat();

	if( flNextThink <= g_Engine.time )
	{
		DoCanisterSmoke( pEntity );

		if( !pCustom.GetKeyvalue(KVN_ZOMBIECANHP).Exists() )
			pCustom.SetKeyvalue( KVN_ZOMBIECANHP, CANISTER_HEALTH );

		if( pEntity.pev.deadflag == DEAD_DEAD )
		{
			float flCanisterHealth = pCustom.GetKeyvalue(KVN_ZOMBIECANHP).GetFloat();

			if( flCanisterHealth <= 0 )
			{
				Vector vecOrigin;
				pEntity.MyMonsterPointer().GetAttachment( 0, vecOrigin, void );
				SpawnExplosion( vecOrigin, 0.0, 0.0, CANISTER_DAMAGE );
			}
			else if( flCanisterHealth < CANISTER_HEALTH )
				pCustom.SetKeyvalue( KVN_ZOMBIECANHP, flCanisterHealth - CANISTER_DEGRADE );
		}

		pCustom.SetKeyvalue( KVN_MONSTERTHINK, g_Engine.time + THINKRATE_OTHER );
	}
}

void DoCanisterSmoke( CBaseEntity@ pMonster )
{
	if( !freeedicts(1) )
		return;

	if( pMonster is null ) return;

	CustomKeyvalues@ pCustom = pMonster.GetCustomKeyvalues();
	float flCanisterHealth = pCustom.GetKeyvalue(KVN_ZOMBIECANHP).GetFloat();

	if( flCanisterHealth > 0 and Math.RandomLong(0, CANISTER_HEALTH) > flCanisterHealth )
	{
		Vector vecOrigin;
		pMonster.MyMonsterPointer().GetAttachment( 0, vecOrigin, void );

		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m1.WriteByte( TE_SPRITE );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );

			if( pMonster.pev.deadflag == DEAD_DEAD )
				m1.WriteCoord( vecOrigin.z + 16.0 );
			else
				m1.WriteCoord( vecOrigin.z + 8.0 );

			m1.WriteShort( g_Game.PrecacheModel(SPRITE_CANISTER_GAS) );
			m1.WriteByte( 3 ); // scale * 10
			m1.WriteByte( 128 ); // brightness
		m1.End();
	}
}

bool IsZombieEngineer( CBaseEntity@ pMonster )
{
	if( pMonster.GetClassname() == "monster_zombie_soldier" and pMonster.pev.model == "models/bts_rc/monsters/zombie_engineer.mdl" )
		return true;
	else if( pMonster.GetClassname() == "monster_zombie_soldier" and pMonster.pev.model == "models/bts_rc/monsters/zombie_construction_welder.mdl" )
		return true;
	else if( pMonster.GetClassname() == "monster_gonome" and pMonster.pev.model == "models/bts_rc/monsters/zombie_engineer2.mdl" )
		return true;

	return false;
}

void ZombiesMapInit()
{
	g_Game.PrecacheModel( SPRITE_CANISTER_GAS );

	g_Hooks.RegisterHook( Hooks::Monster::MonsterTakeDamage, @ZombieTakeDamage );
}

} //namespace btscm END