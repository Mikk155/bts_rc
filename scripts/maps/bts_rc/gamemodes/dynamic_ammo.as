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

class ASDynamicAmmoConfig : IConfigurableContext
{
    // Maps ammo type name -> array<int>{ min_give, max_give }
    // min_give = ammo given at max players, max_give = ammo given solo
    dictionary m_AmmoRanges;

    const string& GetName() const override {
        return "ammo";
    }

    private meta_api::json::v2::json@ GetDefaults( uint min, uint max )
    {
        auto@ obj = meta_api::json::v2::json();
        obj.Set( "type", "array" );
        obj.Set( "minItems", 2 );
        obj.Set( "maxItems", 2 );
        obj.Set( "description", "List of [min, max] where min is given at full server and max is given solo." );
            auto@ items = meta_api::json::v2::json();
            items.Set( "type", "integer" );
            items.Set( "minimum", 1 );
        obj.Set( "items", items );
            auto@ arr = meta_api::json::v2::json();
            arr.SetType( meta_api::json::Type::Array );
            arr.Append(min);
            arr.Append(max);
        obj.Set( "default", arr );
/**
"prefixItems":
[
    { "description": "Minimum ammo given (at max players)" },
    { "description": "Maximum ammo given (solo play)" }
]
**/
        return obj;
    }

    meta_api::json::v2::json@ GetSchema() const override {
        auto@ schema = meta_api::json::v2::json();
        schema.Set( "type", "object" );
        schema.Set( "unevaluatedProperties", "false" );
        schema.Set( "description", "Scales ammo pickup amounts based on connected player count." );
            auto@ properties = meta_api::json::v2::json();
                auto@ active = meta_api::json::v2::json();
                active.Set( "type", "boolean" );
                active.Set( "default", true );
                active.Set( "description", "Should ammo be given to players dynamically based on player count?" );
            properties.Set( "active", active );
            properties.Set( "9mm", GetDefaults( 8, 17 ) );
            properties.Set( "357", GetDefaults( 1, 6 ) );
            properties.Set( "556", GetDefaults( 6, 30 ) );
            properties.Set( "buckshot", GetDefaults( 3, 8 ) );
            properties.Set( "ARgrenades", GetDefaults( 1, 2 ) );
            properties.Set( "38", GetDefaults( 3, 6 ) );
            properties.Set( "bts:flare", GetDefaults( 1, 3 ) );
            properties.Set( "bts:battery", GetDefaults( 1, 3 ) );
        schema.Set( "properties", properties );
        return schema;
    }

    private RegisterCommand@ m_command;

    bool Register( meta_api::json::v2::json@ config ) override
    {
        if( !bool( config[ "active" ] ) )
            return false;

        @gpDynamicAmmo = this;

        const auto@ ammoTypes = config.Keys;
        uint size = ammoTypes.length();

        for( uint ui = 0; ui < size; ui++ )
        {
            string ammoType = ammoTypes[ui];

            array<int>@ range;

            if( meta_api::json::v2::fmt::ToArray( config[ ammoType ], range, true, false ) )
            {
                m_AmmoRanges[ ammoType ] = range;

                if( range[0] > range[1] )
                {
                    g_Logger.error.print( "Dynamic ammo \"%1\" has inverted values! first number should be lesser than the second!" );
                    int temp = range[0];
                    range[0] = range[1];
                    range[0] = temp;
                }

                if( g_Logger.debug.active )
                    g_Logger.debug.print( snprintf( glog, "Dynamic ammo \"%1\": min=%2 max=%3", ammoType, range[0], range[1] ) );
            }
        }

        if( g_Logger.info.active )
            g_Logger.info.print( snprintf( glog, "Registered %1 dynamic ammo types.", m_AmmoRanges.getSize() ) );

#if SERVER
        @m_command = RegisterCommand(
            "test_ammo",
            "[simulated_players]",
            "Print dynamic ammo values for all configured types. Pass a number to simulate that many players connected.",
            function( CBasePlayer@ player, array<string>@ arguments )
            {
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
#endif
        return true;
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

ASDynamicAmmoConfig@ gpDynamicAmmo = null;
