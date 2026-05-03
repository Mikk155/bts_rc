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

#include "../../../mikk155/meta_api"
#include "../../../mikk155/meta_api/json"
#include "../../../mikk155/Server/chrono"

#include "CommandContext"
#include "ConfigContext"
#include "CustomEntity"
#include "EntityOverriden"
#include "json"
#include "Logger"
#include "models"
#include "PlayerClass"

// sven only has 8192 edicts at any given time
// so assume each player carries exactly 10 weapons, and then leave 100 slots free for various temporary things. -Zode
const int __freedicts_overgead__ = g_Engine.maxEntities - ( 10 * g_Engine.maxClients ) - 100;

// Return whatever there's space in the server to spawn "overhead" amount of entities
bool FreeEdicts( int overhead = 1 )
{
    return ( g_EngineFuncs.NumberOfEntities() < __freedicts_overgead__ - overhead );
}

// Get a random number between 0 and max. if RandomUint was called before the result will be stored in player data as "RandomUint" to avoid repeating the same number in a row
uint8 RandomUint( uint8 max, CBasePlayer@ player )
{
    if( player is null )
        return 0;

    if( max == 0 )
    {
        if( g_Logger.critical )
            g_Logger.critical = snprintf( glog, "RandomUint called with an argument of zero!" );
        return 0;
    }

    dictionary@ data = player.GetUserData();

    uint8 lastRand;
    data.get( "RandomUint", lastRand );
    uint8 rand;

    do{ rand = Math.RandomLong( 0, max ); }
    while( rand == lastRand );

    data[ "RandomUint" ]  = rand;

    return rand;
}
