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

#include "MonsterKilled"
#include "MonsterTakeDamage"
#include "PlayerCanCollect"
#include "PlayerCollect"
#include "PlayerInitialized"
#include "PlayerKilled"
#include "PlayerRevive"
#include "PlayerSpawn"
#include "PlayerTakeDamage"
#include "PlayerThink"
#include "PlayerDisconnect"
#include "SquadmakerSpawn"
#include "StartFrame"

namespace Hooks
{
    void Register()
    {
        g_Hooks.RegisterHook( Hooks::Monster::MonsterKilled, @MonsterKilled );
        g_Hooks.RegisterHook( Hooks::Monster::MonsterTakeDamage, @MonsterTakeDamage );

        g_Hooks.RegisterHook( Hooks::PickupObject::CanCollect, @PlayerCanCollect );
        g_Hooks.RegisterHook( Hooks::PickupObject::Collected, @PlayerCollect );

        g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @PlayerKilled );
        g_Hooks.RegisterHook( Hooks::Player::PlayerRevived, @PlayerRevive );
        g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawn );
        g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage );
        g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @PlayerThink );
        g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @PlayerDisconnect );

        g_CustomEntityFuncs.RegisterCustomEntity( "Hooks::CASStartFrame", "bts_startframe" );
        g_EntityFuncs.Create( "bts_startframe", g_vecZero, g_vecZero, false, null );
    }
}
