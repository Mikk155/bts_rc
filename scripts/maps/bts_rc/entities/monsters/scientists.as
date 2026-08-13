/**
*   Copyright (c) 2026 Mikk155 and contributors of bts_rc
*
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software to use, copy, modify, merge, publish, distribute, sublicense,
*   and/or sell copies of the Software under the following conditions:
*
*   A reference to the original project must be included in all copies or substantial
*   portions of the Software. This must include, at minimum, a URL to:
*   https://github.com/Mikk155/bts_rc
*
*   The above copyright notice and this permission notice shall be included in all
*   copies of the Software when distributed as a whole.
*
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
**/

/*
    Author: Nero
*/

namespace btscm
{

void ScientistThink()
{
    CBaseEntity@ entity = null;

    while( ( @entity = g_EntityFuncs.FindEntityByClassname( entity, "monster_scientist" ) ) !is null )
    {
        CBaseMonster@ monster = entity.MyMonsterPointer();

        if( IgnoreThisScientist( monster ) || monster.m_MonsterState == MONSTERSTATE_NONE )
            continue;

        CustomKeyvalues@ custom = entity.GetCustomKeyvalues();

        if( custom.GetKeyvalue( KVN_MONSTERTHINK ).GetFloat() > g_Engine.time )
            continue;

        if( entity.pev.deadflag == DEAD_NO )
            CheckForRevive( monster );

        custom.SetKeyvalue( KVN_MONSTERTHINK, g_Engine.time + THINKRATE_OTHER );
    }
}

bool IgnoreThisScientist( CBaseMonster@ monster )
{
    return monster is null || monster.pev.SpawnFlagBitSet( 256 ); // Pre-Disaster
}

CBaseEntity@ FindPlayerCorpse( CBasePlayer@ player )
{
    CBaseEntity@ corpse = null;

    while( ( @corpse = g_EntityFuncs.FindEntityByClassname( corpse, "deadplayer" ) ) !is null )
    {
        if( corpse.pev.renderfx != kRenderFxDeadPlayer || corpse.pev.renderamt < 0 )
            continue;

        CBaseEntity@ corpsePlayer = g_EntityFuncs.Instance( int( corpse.pev.renderamt ) );

        if( corpsePlayer is player )
            return corpse;
    }

    return null;
}

void SetPlayerReviveVisibility( CBasePlayer@ player, bool visible )
{
    if( visible )
    {
        player.pev.effects &= ~EF_NODRAW;
        player.pev.rendermode = kRenderTransColor;
        player.pev.renderamt = 0;
        return;
    }

    player.pev.effects |= EF_NODRAW;
    player.pev.rendermode = kRenderNormal;
}

void CheckForRevive( CBaseMonster@ monster )
{
    if( monster is null )
        return;

    CBaseEntity@ target = monster.m_hTargetEnt.GetEntity();

    if( target is null || target.GetClassname() != "player" )
        return;

    CBasePlayer@ player = cast<CBasePlayer@>( target );

    if( player is null || player.IsAlive() || player.pev.iuser1 == OBS_NONE )
        return;

    CBaseEntity@ corpse = FindPlayerCorpse( player );

    if( corpse is null )
        return;

    float corpseDistance = ( monster.pev.origin - corpse.pev.origin ).Length();

    if( corpseDistance > 128.0 )
        monster.m_hTargetEnt = EHandle( corpse );
    else
        monster.m_hTargetEnt = EHandle( player );

    if( corpseDistance > 128.0 || ( player.pev.origin - corpse.pev.origin ).Length() <= 16.0 )
        return;

    if( player.pev.iuser1 != OBS_ROAMING )
    {
        player.GetObserver().SetMode( OBS_ROAMING );
        player.GetObserver().SetObserverModeControlEnabled( false );
    }

    SetPlayerReviveVisibility( player, true );
    g_EntityFuncs.SetOrigin( player, corpse.pev.origin );
}

void ScientistMapInit()
{
    g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @PlayerPreThink );
}

HookReturnCode PlayerPreThink( CBasePlayer@ player, uint& out uiFlags )
{
    if( player.pev.iuser1 == OBS_NONE )
        return HOOK_CONTINUE;

    CustomKeyvalues@ custom = player.GetCustomKeyvalues();

    if( custom.GetKeyvalue( KVN_PLAYERTHINK ).GetFloat() > g_Engine.time )
        return HOOK_CONTINUE;

    CBaseEntity@ corpse = FindPlayerCorpse( player );

    if( corpse !is null )
        SetPlayerReviveVisibility( player, ( player.pev.origin - corpse.pev.origin ).Length() <= 128.0 );

    custom.SetKeyvalue( KVN_PLAYERTHINK, g_Engine.time + THINKRATE_PLAYER );
    return HOOK_CONTINUE;
}

} // namespace btscm END
