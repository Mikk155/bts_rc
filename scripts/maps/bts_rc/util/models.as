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

// Contain models/sprites ID
namespace models
{
    // sprites/WXplo1.spr
    uint WXplo1;
    // sprites/zerogxplode.spr
    uint zerogxplode;
    // sprites/steam1.spr
    uint steam1;
    // sprites/laserbeam.spr
    uint laserbeam;
    // models/hlclassic/shell.mdl
    uint shell;
    // models/bts_rc/weapons/saw_shell.mdl
    uint saw_shell;
    // models/hlclassic/shotgunshell.mdl
    uint shotgunshell;

    void Precache()
    {
        WXplo1 = g_Game.PrecacheModel( "sprites/WXplo1.spr" );
        zerogxplode = g_Game.PrecacheModel( "sprites/zerogxplode.spr" );
        steam1 = g_Game.PrecacheModel( "sprites/steam1.spr" );
        laserbeam = g_Game.PrecacheModel( "sprites/laserbeam.spr" );
        shell = g_Game.PrecacheModel( "models/hlclassic/shell.mdl" );
        saw_shell = g_Game.PrecacheModel( "models/bts_rc/weapons/saw_shell.mdl" );
        shotgunshell = g_Game.PrecacheModel( "models/hlclassic/shotgunshell.mdl" );

        g_Game.PrecacheModel( "sprites/bts_rc/gametitle.spr" );
    }
}
