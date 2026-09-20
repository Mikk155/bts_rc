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

namespace Hooks
{
    HookReturnCode PlayerSay( SayParameters@ params )
    {
        CBasePlayer@ player = params.GetPlayer();

        if( player is null )
            return HOOK_CONTINUE;

        if( params.ShouldHide )
            return HOOK_CONTINUE;

        string content = params.GetCommand();

        if( content.IsEmpty() )
            return HOOK_CONTINUE;

        params.ShouldHide = true;

        string message;

        auto character = GetCharacter(player);

        if( character is null )
        {
            snprintf( message, "[Spectator] %1: %2\n", player.pev.netname, content );
            ChatColor::Say( player, ChatColor::Color::Blue, message );
            return HOOK_HANDLED;
        }

        if( player.IsAlive() )
        {
            snprintf( message, "[%1] %2: %3\n", Classification::ToString( character.Classify ), player.pev.netname, content );
            ChatColor::Say( player, ChatColor::Color::Green, message );
        }
        else
        {
            snprintf( message, "[%1] (dead) %2: %3\n", Classification::ToString( character.Classify ), player.pev.netname, content );
            ChatColor::Say( player, ChatColor::Color::Red, message );
        }

        return HOOK_HANDLED;
    }
}
