/**   MIT License
*   
*   Copyright (c) 2025 Mikk155 https://github.com/Mikk155/bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies or substantial portions of the Software.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*   SOFTWARE.
*/

/*
    Author: Nero
*/

namespace btscm
{

//SETTINGS
const string SENTRY_CLASSNAME           = "monster_sentry";
const uint SENTRY_DROP_AMOUNT           = 1; //how many to spawn at a time
const uint SENTRY_MAX                           = 5; //number of sentries that can be dropped per engy
const float SENTRY_RADIUS                   = 128.0; //distance from the engy
const float SENTRY_ARCDEG                   = 120.0; //sentries are spawned in an arc in front of the engineer, they will be spawned within this number of degrees (360 = full circle)
const float SENTRY_CD_INITIAL               = 6.0; //time until engineer can place a sentry after spawning
const float SENTRY_CD_COMBAT                = 6.0; //how often to try to drop a sentry in combat, in seconds
const float SENTRY_CD_IDLE                  = 30.0; //how often to try to drop a sentry while idle/roaming, in seconds
const float SENTRY_RANDOM_RNG           = 15.0; //SENTRY_CD_IDLE plus/minus this
const float SENTRY_RANDOM_CHANCE    = 75.0; //Chance to drop a sentry while idle/roaming, in percentage 0-100


const string KVN_SENTRYCD                   = "$f_engysentrycd";
const string KVN_SENTRYDROP             = "$f_engysentrydrop";
const string KVN_SENTRYLEFT             = "$f_engysentryleft";

void EngineerThink()
{
    CBaseEntity@ pEntity = null;
    while( (@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "monster_human_torch_ally")) !is null )
    {
        if( ShouldIgnoreThisEntity(pEntity) ) continue;

        CBaseMonster@ pMonster = pEntity.MyMonsterPointer();
        if( pMonster is null ) continue;

        CustomKeyvalues@ pCustom = pMonster.GetCustomKeyvalues();

        if( !pCustom.GetKeyvalue(KVN_SENTRYLEFT).Exists() )
            pCustom.SetKeyvalue( KVN_SENTRYLEFT, SENTRY_MAX );

        if( !pCustom.GetKeyvalue(KVN_SENTRYCD).Exists() )
            pCustom.SetKeyvalue( KVN_SENTRYCD, g_Engine.time + SENTRY_CD_INITIAL + Math.RandomFloat(-SENTRY_RANDOM_RNG, SENTRY_RANDOM_RNG) );

        if( pCustom.GetKeyvalue(KVN_SENTRYLEFT).GetInteger() <= 0 )
            continue;

        CheckForSentryDrop( pMonster );
        DoSentryDrop( pMonster );
    }
}

bool ShouldIgnoreThisEntity( CBaseEntity@ pEntity )
{
    if( pEntity.pev.deadflag != DEAD_NO ) return true;

    return false;
}

void CheckForSentryDrop( CBaseMonster@ pMonster )
{
    CustomKeyvalues@ pCustom = pMonster.GetCustomKeyvalues();
    float flSentryCD = pCustom.GetKeyvalue(KVN_SENTRYCD).GetFloat();
    if( flSentryCD > g_Engine.time )
        return;

    if( pMonster.m_MonsterState == MONSTERSTATE_COMBAT )
    {
        if( pMonster.HasConditions(bits_COND_CAN_RANGE_ATTACK1) )
        {
            pMonster.ChangeSchedule( pMonster.GetScheduleOfType(SCHED_ARM_WEAPON) );
            pCustom.SetKeyvalue( KVN_SENTRYCD, g_Engine.time + SENTRY_CD_COMBAT );
            pCustom.SetKeyvalue( KVN_SENTRYDROP, g_Engine.time + 1.0 );
        }
    }
    else if( pMonster.m_MonsterState == MONSTERSTATE_IDLE or pMonster.m_MonsterState == MONSTERSTATE_ALERT )
    {
        if( btscm::RandomChance(SENTRY_RANDOM_CHANCE) )
        {
            pMonster.ChangeSchedule( pMonster.GetScheduleOfType(SCHED_ARM_WEAPON) );
            pCustom.SetKeyvalue( KVN_SENTRYCD, g_Engine.time + SENTRY_CD_IDLE + Math.RandomFloat(-SENTRY_RANDOM_RNG, SENTRY_RANDOM_RNG) );
            pCustom.SetKeyvalue( KVN_SENTRYDROP, g_Engine.time + 1.0 );
        }
    }
}

void DoSentryDrop( CBaseMonster@ pMonster )
{
    if( pMonster is null ) return;

    CustomKeyvalues@ pCustom = pMonster.GetCustomKeyvalues();
    float flSentryDrop = pCustom.GetKeyvalue(KVN_SENTRYDROP).GetFloat();

    if( flSentryDrop > 0 and flSentryDrop <= g_Engine.time )
    {
        if( pMonster.pev.sequence == pMonster.LookupSequence("open_floor_grate") )
        {
            int iSentriesLeft = pCustom.GetKeyvalue(KVN_SENTRYLEFT).GetInteger();
            //g_Game.AlertMessage( at_notice, "iSentriesLeft before dropping: %1\n", iSentriesLeft );

            //SpawnTurretRing( pMonster.pev.origin, 2 );
            int iSentriesSpawned = SpawnTurretArc( pMonster, SENTRY_DROP_AMOUNT, SENTRY_RADIUS, SENTRY_ARCDEG );
            //( CBaseEntity@ pOwner, uint uiCount = 3, float flRadius = 128.0, float flArcDeg = 120.0, bool bCheckSpace = true, bool bSpawnIfBlocked = false )

            if( iSentriesSpawned > 0 )
                pCustom.SetKeyvalue( KVN_SENTRYLEFT, iSentriesLeft - iSentriesSpawned );

            //g_Game.AlertMessage( at_notice, "iSentriesLeft after dropping: %1\n", iSentriesLeft - iSentriesSpawned );

            pCustom.SetKeyvalue( KVN_SENTRYDROP, 0 );
        }
    }
}

// =====================================================
// Spawns SENTRY_CLASSNAME in a forward arc in front of the engineer
//
// uiCount = how many turrets
// flRadius = distance from owner
// flArcDeg = total arc width (<= 180 recommended)
//
// Examples:
// count 1 -> center
// count 2 -> left/right
// count 3 -> left/center/right
// count 5 -> far left / left / center / right / far right
// =====================================================

bool IsHullFree( const Vector &in vecPos )
{
    TraceResult tr;
    g_Utility.TraceHull( vecPos, vecPos, dont_ignore_monsters, head_hull, null, tr );

    return ( tr.fStartSolid == 0 ) and ( tr.fAllSolid == 0 );
}

bool FindFreeArcSpot( const Vector &in vecStartPos, const Vector& in vecOutwardDir, Vector &out vecResult )
{
    for( int up = 0; up <= 4; up++ )
    {
        for( int step = 0; step <= 6; step++ )
        {
            Vector vecTest = vecStartPos + vecOutwardDir * float(step * 24) + Vector( 0.0, 0.0, float(up * 16) );

            if( IsHullFree(vecTest) )
            {
                vecResult = vecTest;
                return true;
            }
        }
    }

    return false;
}

int SpawnTurretArc( CBaseEntity@ pOwner, uint uiCount = 3, float flRadius = 128.0, float flArcDeg = 120.0, bool bCheckSpace = true, bool bSpawnIfBlocked = false )
{
    if( pOwner is null or uiCount == 0 )
        return 0;

    Vector vecOrigin = pOwner.pev.origin;
    float flYaw = pOwner.pev.angles.y;
    int iSentriesSpawned = 0;

    array<float> arrflOffsets;

    if( uiCount == 1 )
        arrflOffsets.insertLast( 0.0 );
    else
    {
        float flHalf = flArcDeg * 0.5;
        float flStep = flArcDeg / float( uiCount - 1 );

        for( uint i = 0; i < uiCount; i++ )
            arrflOffsets.insertLast( -flHalf + flStep * i );
    }

    for( uint i = 0; i < arrflOffsets.length(); i++ )
    {
        float flAngDeg = flYaw + arrflOffsets[i];
        float flAngRad = flAngDeg * Math.PI / 180.0;

        Vector vecDir( cos(flAngRad), sin(flAngRad), 0.0 );

        Vector vecPos = vecOrigin + vecDir * flRadius;

        bool bCanSpawn = true;

        if( bCheckSpace )
        {
            if( !IsHullFree(vecPos) )
            {
                Vector vecNudged;

                if( FindFreeArcSpot(vecPos, vecDir, vecNudged) )
                    vecPos = vecNudged;
                else
                    bCanSpawn = bSpawnIfBlocked;
            }
        }

        if( !bCanSpawn )
            continue;

        // Face same direction as engineer
        Vector vecAngles( 0.0, flYaw, 0.0 );

        CBaseEntity@ pSentry = g_EntityFuncs.Create( SENTRY_CLASSNAME, vecPos, vecAngles, true, pOwner.edict() );

        if( pSentry !is null )
        {
            if( pOwner.IsPlayerAlly() )
                g_EntityFuncs.DispatchKeyValue( pSentry.edict(), "is_player_ally", "1" ); 

            g_EntityFuncs.DispatchSpawn( pSentry.edict() );
            iSentriesSpawned++;
        }
    }

    //g_Game.AlertMessage( at_notice, "SpawnTurretArc iSentriesSpawned: %1\n", iSentriesSpawned );
    return iSentriesSpawned;
}

/*bool IsHumanEngineer( CBaseEntity@ pMonster )
{
    if( pMonster.GetClassname() == "monster_human_torch_ally" ) // and pMonster.pev.model == "models/bts_rc/monsters/hgrunt_torch.mdl"
        return true;

    return false;
}*/

void EngineerMapInit()
{
    //g_Game.PrecacheMonster( "monster_miniturret", true );
    //g_Game.PrecacheMonster( "monster_miniturret", false );
    //g_Game.PrecacheMonster( "monster_turret", true );
    //g_Game.PrecacheMonster( "monster_turret", false );
    g_Game.PrecacheMonster( SENTRY_CLASSNAME, true );
    g_Game.PrecacheMonster( SENTRY_CLASSNAME, false );
}

} //namespace btscm END