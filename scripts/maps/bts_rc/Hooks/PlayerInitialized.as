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
    // Called once per player after gpGameStarted is true and the player presses any key
    void PlayerInitialized( CBasePlayer@ player, dictionary@ data )
    {
        if( !g_IsMainMap )
            return;

        if( gpGameVersion == 526 )
        {
            g_PlayerFuncs.ClientPrint( player, HUD_PRINTTALK, "NOTICE: If you have played older versions of this map previously\n" );
            g_PlayerFuncs.ClientPrint( player, HUD_PRINTTALK, "\t\tPlease consider updating manually to the latest version as many assets has been modified\n" );
            g_PlayerFuncs.ClientPrint( player, HUD_PRINTTALK, "\t\tAnd your gameplay most likely will be affected. Open the console to get the download link.\n" );
            g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "https://github.com/Mikk155/bts_rc/releases/tag/" + g_ScriptsVersion.ToString() + "\n" );
        }

        // Nero ADDED 2026-01-10
        HUDSpriteParams hudParamsTitle;
        hudParamsTitle.fadeinTime = 1.0;
        hudParamsTitle.holdTime = 4.0;
        hudParamsTitle.fadeoutTime = 1.5;
        hudParamsTitle.effect = 0;
        hudParamsTitle.channel = 2; // 0-15 (1 is used by snapbug)
        hudParamsTitle.spritename = "bts_rc/gametitle.spr";
        hudParamsTitle.x = 0.0;
        hudParamsTitle.y = 0.0;
        hudParamsTitle.flags = HUD_ELEM_SCR_CENTER_X | HUD_ELEM_SCR_CENTER_Y;
        hudParamsTitle.color1 = RGBA( 180, 180, 180, 255 );
        g_PlayerFuncs.HudCustomSprite( player, hudParamsTitle );
    }
}