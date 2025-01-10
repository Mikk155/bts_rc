/*
    Author: Mikk
    Original: Gaftherman & Rizulix
    Motd code: Giegue
*/

namespace item_tracker
{
#if DEVELOP
    CLogger@ m_Logger = CLogger( "Item Tracker" );
#endif

    dictionary items = {
        { "RETINA_COMPONENT", "Area 1 - Retina component" },
        { "VALVE_1", "Area 1 - Override Valve 1" },
        { "VALVE_1_2", "Area 1 - Override Valve 2" },
        { "GEAR_1", "Area 3 - Gear 1" },
        { "GEAR_2", "Area 3 - Gear 2" },
        { "GEAR_3", "Area 3 - Gear 3" },
        { "GEAR_4", "Area 3 - Gear" },
        { "WAREHOUSE_YARDKEY", "Area 2 - Yard managers keycard" },
        { "DORMS_CARD_101", "Area 1 - A-101 Dorms key 1" },
        { "DORMS_CARD_101_2", "Area 1 - A-101 Dorms key 2" },
        { "DORMS_CARD_106", "Area 1 - A-106 Dorms key 3" },
        { "DORMS_CARD_201", "Area 1 - B-201 Dorms key 4" },
        { "CODES_1", "Service Elevator codes" },
        { "Blackmesa_Maintenance_Clearance_2", "Maintenance Access level 2 keycard" },
        { "Blackmesa_Maintenance_Clearance_2_2", "Maintenance Access level 2 keycard Alt" },
        { "Blackmesa_Maintenance_Clearance_2_1", "Maintenance Access level 2 keycard X" },
        { "d5_officekey", "Reception key 1" },
        { "d5_officekey_1", "Reception key 2" },
        { "d5_doctorkey", "Doctors key" },
        { "Blackmesa_Security_Clearance_3", "Blackmesa Security Clearance level 3" }
    };

    // Last frame we did an operation.
    float time;

    // String containing all the information.
    string buffer;

    void open( CBasePlayer@ player, dictionary@ user_data )
    {
        if( player !is null )
        {
            // The buffer may be old, update it.
            if( g_Engine.time > time )
            {
#if DEVELOP
                m_Logger.info( "Updating global buffer." );
#endif

                dictionary item_copy = items;

                // Iterate over all clients, some player's indexes will be above GetNumPlayers, i have no proofs but neither doubts.
                for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
                {
                    CBasePlayer@ players = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

                    if( players !is null && players.IsConnected() )
                    {
                        InventoryList@ inventory = players.m_pInventory;

                        while( inventory !is null )
                        {
                            CItemInventory@ item = cast<CItemInventory@>( inventory.hItem.GetEntity() );

                            if( item !is null && item_copy.exists( item.m_szItemName ))
                            {
                                string format;

                                CustomKeyvalues@ doubles = item.GetCustomKeyvalues();

                                // These are duplicated "item_name" So to identify to which "Display name" it belongs we use a custom keyvalue.
                                if( doubles !is null && doubles.HasKeyvalue( "$i_secondary" ) )
                                {
                                    string name;
                                    snprintf( name, "%1_%2", item.m_szItemName, doubles.GetKeyvalue( "$i_secondary" ).GetInteger() );
                                    snprintf( format, "%1\n - %2", string( item_copy[ name ] ), players.pev.netname );
                                    item_copy[ name ] = format;
                                }
                                else
                                {
                                    snprintf( format, "%1\n - %2", string( item_copy[ string( item.m_szItemName ) ] ), players.pev.netname );
                                    item_copy[ string( item.m_szItemName ) ] = format;
                                }
                            }
                            @inventory = inventory.pNext;
                        }
                    }
                }

                array<string> item_names = item_copy.getKeys();

                buffer = CONST_WHO_HAS_WHAT_TITLE;

                for( uint ui = 0; ui < item_names.length(); ui++ )
                {
                    snprintf( buffer, "%1\n%2", buffer, string( item_copy[ item_names[ui] ] ) );
                }

                time = g_Engine.time + CONST_WHO_HAS_WHAT_TIME;
            }

            //================================================================================================
            //  Shows a MOTD message to the player
            //  Code by Giegue. Taken from: https://github.com/JulianR0/TPvP/blob/master/src/plugins/TPvP.as#L7375
            //================================================================================================
            uint iChars = 0;

            string szSplitMsg = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

            for( uint uChars = 0; uChars < buffer.Length(); uChars++ )
            {
                szSplitMsg.SetCharAt( iChars, char( buffer[ uChars ] ) );
                iChars++;

                if( iChars == 32 )
                {
                    NetworkMessage motd_append( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict() );
                        motd_append.WriteByte( 0 );
                        motd_append.WriteString( szSplitMsg );
                    motd_append.End();

                    iChars = 0;
                }
            }

            // If we reached the end, send the last letters of the message
            if( iChars > 0 )
            {
                szSplitMsg.Truncate( iChars );

                NetworkMessage motd_fix( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict() );
                    motd_fix.WriteByte( 0 );
                    motd_fix.WriteString( szSplitMsg );
                motd_fix.End();
            }

            NetworkMessage motd_open( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict() );
                motd_open.WriteByte( 1 );
                motd_open.WriteString( "\n" );
            motd_open.End(); 
        }
    }
}
