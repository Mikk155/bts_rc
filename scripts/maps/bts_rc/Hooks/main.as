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

#include "MonsterKilled"
#include "MonsterTakeDamage"
#include "PlayerCollect"
#include "PlayerInitialized"
#include "PlayerRevive"
#include "PlayerSpawn"
#include "PlayerTakeDamage"
#include "PlayerThink"
#include "SquadmakerSpawn"
#include "StartFrame"

namespace Hooks
{
    void Register()
    {
        g_Hooks.RegisterHook( Hooks::Monster::MonsterKilled, @MonsterKilled );
        g_Hooks.RegisterHook( Hooks::Monster::MonsterTakeDamage, @MonsterTakeDamage );
        g_Hooks.RegisterHook( Hooks::PickupObject::Collected, @PlayerCollect );
        g_Hooks.RegisterHook( Hooks::Player::PlayerRevived, @PlayerRevive );
        g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawn );
        g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage );
        g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @PlayerThink );

        g_CustomEntityFuncs.RegisterCustomEntity( "Hooks::CASStartFrame", "bts_startframe" );
        g_EntityFuncs.Create( "bts_startframe", g_vecZero, g_vecZero, false, null );
    }
}