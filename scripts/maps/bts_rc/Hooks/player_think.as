/*
    Author: Mikk
*/

HookReturnCode player_think( CBasePlayer@ player )
{
    if( player !is null && player.IsConnected() )
    {
        dictionary@ user_data = player.GetUserData();

        // New *feature* "No pressing E while shooting" xD
        if( ( player.pev.button & IN_USE ) != 0 && ( player.pev.button & IN_RELOAD ) != 0 )
        {
            // Don't call Reload.
            player.pev.button &= ~IN_RELOAD;

            if( g_Engine.time > float( user_data["motd_update"] ) )
            {
                // Individual cooldown players to not spam UserMessages
                user_data["motd_update"] = g_Engine.time + 1.0f;

                // The buffer may be old, update it.
                if( g_Engine.time > item_tracker::time )
                {
                    dictionary items = {
                        { "GEAR_1", "Area 3 - Gear 1 - Tutorial" },
                        { "GEAR_2", "Area 3 - Gear 2 - Warehouse 2" },
                        { "GEAR_3", "Area 3 - Gear 3 - Basement" },
                        { "GEAR_4", "Area 3 - Gear 4 - Warehouse 1" },
                        { "RETINA_COMPONENT", "Area 1 - Retina component" },
                        { "VALVE_1", "Area 1 - Override Valve 1" },
                        { "VALVE_1_2", "Area 1 - Override Valve 2" },
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
                        { "TORTURED_ARMORY_KEYCARD", "Area 4 Armory Keycard - Level 5" },
                        { "Blackmesa_Security_Clearance_3", "Blackmesa Security Clearance level 3" } };

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

                                if( item !is null && items.exists( item.m_szItemName ) )
                                {
                                    string format;

                                    CustomKeyvalues@ doubles = item.GetCustomKeyvalues();

                                    // These are duplicated "item_name" So to identify to which "Display name" it belongs we use a custom keyvalue.
                                    if( doubles !is null && doubles.HasKeyvalue( "$i_secondary" ) )
                                    {
                                        string name;
                                        snprintf( name, "%1_%2", item.m_szItemName, doubles.GetKeyvalue( "$i_secondary" ).GetInteger() );
                                        snprintf( format, "%1\n - %2", string( items[name] ), players.pev.netname );
                                        items[name] = format;
                                    }
                                    else
                                    {
                                        snprintf( format, "%1\n - %2", string( items[string( item.m_szItemName )] ), players.pev.netname );
                                        items[string( item.m_szItemName )] = format;
                                    }
                                }
                                @inventory = inventory.pNext;
                            }
                        }
                    }

                    array<string> item_names = items.getKeys();

                    item_tracker::buffer = "Who has what?\n";

                    for( uint ui = 0; ui < item_names.length(); ui++ )
                    {
                        snprintf( item_tracker::buffer, "%1\n%2", item_tracker::buffer, string( items[item_names[ui]] ) );
                    }

                    item_tracker::time = g_Engine.time + 5.0; // Cooldown time for refreshing.
                }

                motd::open( player, item_tracker::buffer );
            }
        }
    }

    return HOOK_CONTINUE;
}
