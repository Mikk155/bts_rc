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
