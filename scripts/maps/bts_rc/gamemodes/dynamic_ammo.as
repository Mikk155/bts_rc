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

class ASDynamicAmmoConfig : IConfigurable
{
    // Maps ammo type name -> array<int>{ min_give, max_give }
    // min_give = ammo given at max players, max_give = ammo given solo
    dictionary m_AmmoRanges;

    const string& get_Name() override
    {
        return "ammo";
    }

    void Register( meta_api::json::v2::json@ json ) override
    {
        if( !this.IsActive() )
            return;

        const auto ammoTypes = json.Keys;
        uint size = ammoTypes.length();

        for( uint ui = 0; ui < size; ui++ )
        {
            string ammoType = ammoTypes[ui];

            array<int>@ range;

            if( meta_api::json::v2::fmt::ToArray( json[ ammoType ], range ) && range.length() == 2 )
            {
                m_AmmoRanges[ ammoType ] = range;

                if( g_Logger.debug.active )
                    g_Logger.debug.print( snprintf( glog, "Dynamic ammo \"%1\": min=%2 max=%3", ammoType, range[0], range[1] ) );
            }
        }

        if( g_Logger.info.active )
            g_Logger.info.print( snprintf( glog, "Registered %1 dynamic ammo types.", m_AmmoRanges.getSize() ) );
    }

    /**
    *   @brief Count the number of connected players
    **/
    int CountConnectedPlayers()
    {
        int count = 0;

        for( int i = 1; i <= g_Engine.maxClients; i++ )
        {
            CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex( i );

            if( player !is null && player.IsConnected() )
                ++count;
        }

        return count < 1 ? 1 : count;
    }

    /**
    *   @brief Get the scaled ammo give amount for the given ammo type.
    *   @param ammoType The ammo type name (e.g. "9mm", "357", "buckshot")
    *   @param defaultGive The default give amount if no config exists for this type
    *   @return The scaled ammo amount based on connected player count
    **/
    int GetAmmoGive( const string&in ammoType, int defaultGive )
    {
        if( !this.IsActive() )
            return defaultGive;

        array<int>@ range;

        if( !m_AmmoRanges.get( ammoType, @range ) )
            return defaultGive;

        int minGive = range[0]; // ammo at max players
        int maxGive = range[1]; // ammo at solo

        int maxClients = g_Engine.maxClients;
        int players = CountConnectedPlayers();

        if( maxClients <= 1 )
            return maxGive;

        // t = 0.0 when solo (1 player), 1.0 when full (maxClients players)
        float t = float( players - 1 ) / float( maxClients - 1 );

        // Lerp from maxGive (solo) to minGive (full)
        float result = float( maxGive ) + t * float( minGive - maxGive );

        int give = int( Math.Ceil( result ) );

        if( give < 1 )
            give = 1;

        if( g_Logger.trace.active )
            g_Logger.trace.print( snprintf( glog, "Dynamic ammo \"%1\": players=%2/%3 t=%4 give=%5 (default=%6)", ammoType, players, maxClients, t, give, defaultGive ) );

        return give;
    }
}

ASDynamicAmmoConfig gpDynamicAmmo;

RegisterCommand __gpDynamicAmmoTestCmd__(
    "ammo_test",
    "[simulated_players]",
    "Print dynamic ammo values for all configured types. Pass a number to simulate that many players connected.",
    function( CBasePlayer@ player, array<string>@ arguments )
    {
        if( !gpDynamicAmmo.IsActive() )
        {
            g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "[Dynamic Ammo] Feature is disabled (active=false).\n" );
            return;
        }

        int maxClients = g_Engine.maxClients;
        int realPlayers = gpDynamicAmmo.CountConnectedPlayers();
        int simPlayers = realPlayers;

        if( arguments !is null && arguments.length() > 0 )
        {
            simPlayers = atoi( arguments[0] );
            if( simPlayers < 1 ) simPlayers = 1;
            if( simPlayers > maxClients ) simPlayers = maxClients;
        }

        string buffer;
        snprintf( buffer, "[Dynamic Ammo] maxClients=%1 connected=%2 simulated=%3\n", maxClients, realPlayers, simPlayers );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );

        float t = 0.0f;
        if( maxClients > 1 )
            t = float( simPlayers - 1 ) / float( maxClients - 1 );

        snprintf( buffer, "[Dynamic Ammo] t=%1 (0=solo, 1=full)\n", t );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );

        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "--- Ammo Type ---   --- Give ---\n" );

        auto keys = gpDynamicAmmo.m_AmmoRanges.getKeys();

        for( uint i = 0; i < keys.length(); i++ )
        {
            array<int>@ range;
            gpDynamicAmmo.m_AmmoRanges.get( keys[i], @range );

            int minGive = range[0];
            int maxGive = range[1];

            float result = float( maxGive ) + t * float( minGive - maxGive );
            int give = int( Math.Ceil( result ) );
            if( give < 1 ) give = 1;

            snprintf( buffer, "  %1: %2  (range: %3-%4)\n", keys[i], give, minGive, maxGive );
            g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );
        }

        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "--- End ---\n" );
    },
    false
);
