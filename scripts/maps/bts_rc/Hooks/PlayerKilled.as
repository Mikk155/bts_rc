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
    HookReturnCode PlayerKilled( CBasePlayer@ player, CBaseEntity@ attacker, int gib )
    {
        if( player is null )
            return HOOK_CONTINUE;

        LaserSpot::Hide( player );

        auto character = GetCharacter(player);

        if( character is null )
            return HOOK_CONTINUE;

        if( gib != GIB_ALWAYS )
        {
            CVoices@ voices = g_VoiceResponse[player];

            if( voices !is null && voices.killed !is null )
                voices.killed.PlaySound( player );
        }

        return HOOK_CONTINUE;
    }
}
