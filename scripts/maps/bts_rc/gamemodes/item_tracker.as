namespace item_tracker
{
    dictionary m_Items;

    // Last frame we did an operation.
    float gptime;
    // String containing all the information.
    string gpBuffer;

    // List containing all the item_inventory names
    array<string> m_ValidItemNames =
    {
        "GEAR_1",
        "GEAR_2",
        "GEAR_3",
        "GEAR_4",
        "RETINA_COMPONENT",
        "VALVE_1",
        "WAREHOUSE_YARDKEY",
        "DORMS_CARD_101",
        "DORMS_CARD_106",
        "DORMS_CARD_201",
        "CODES_1",
        "Blackmesa_Maintenance_Clearance_2",
        "d5_officekey",
        "d5_doctorkey",
        "TORTURED_ARMORY_KEYCARD",
        "Blackmesa_Security_Clearance_3"
    };

    void Initialize()
    {
        CItemInventory@ item = null;

        while( ( @item = cast<CItemInventory@>( g_EntityFuncs.FindEntityByClassname( item, "item_inventory" ) ) ) !is null )
        {
            if( m_ValidItemNames.find( item.m_szItemName ) >= 0 )
            {
                array<string> list = { item.m_szDisplayName, item.m_szDescription };
                m_Items[ item.m_szItemName ] = list;
            }
        }
    }

    void Think( CBasePlayer@ player )
    {
        if( player is null )
            return;

        if( ( player.pev.button & IN_USE ) == 0 || ( player.pev.button & IN_RELOAD ) == 0 )
            return;

        // The buffer may be old, update it.
        if( g_Engine.time > gptime )
        {
            dictionary bufferList;

            for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
            {
                CBasePlayer@ players = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

                if( players is null || !players.IsConnected() )
                    continue;

                InventoryList@ inventory = players.m_pInventory;
                array<string> duplicatedItems(0);

                while( inventory !is null )
                {
                    CItemInventory@ item = cast<CItemInventory@>( inventory.hItem.GetEntity() );
                    @inventory = inventory.pNext;

                    string buffer, name = item.m_szItemName;

                    if( item is null || m_ValidItemNames.find( name ) <= -1 || duplicatedItems.find( name ) >= 0 )
                        continue;

                    duplicatedItems.insertLast( name );

                    if( !bufferList.get( name, buffer ) )
                    {
                        array<string>@ KeyvaluePairData;

                        if( m_Items.get( name, @KeyvaluePairData ) )
                        {
                            snprintf( buffer, "Item: %1\nDetails: %2\nPlayers holding this item:", KeyvaluePairData[0], KeyvaluePairData[1] );
                        }
                    }

                    snprintf( buffer, "%1\n - %2\n", buffer, string( player.pev.netname ) );
                    bufferList[ name ] = buffer;
                }
            }

            array<string> item_names = bufferList.getKeys();
            uint length = item_names.length();

            if( length == 0 )
            {
                gpBuffer = "There is no player that has currently any item.";
            }
            else
            {
                gpBuffer = "List of players and inventory information\n";

                for( uint ui = 0; ui < length; ui++ )
                {
                    snprintf( gpBuffer, "%1\n%2", gpBuffer, string( bufferList[ item_names[ui] ] ) );
                }
            }

            gptime = g_Engine.time + 1.0; // Cooldown time for refreshing.
        }

        player.pev.button &= ~IN_RELOAD;
        player.pev.button &= ~IN_USE;

        dictionary@ data = player.GetUserData();

        if( g_Engine.time > float( data["motd_update"] ) )
        {
            // Individual cooldown players to not spam UserMessages
            data["motd_update"] = g_Engine.time + 1.0f;

            auto edict = player.edict();

            {
                NetworkMessage msg( MSG_ONE, NetworkMessages::ServerName, edict );
                    msg.WriteString( "Item holders list" );
                msg.End();
            }

            uint length = gpBuffer.Length();
            string buffer;
            uint cur = 0;

            while( length > cur )
            {
                buffer = gpBuffer.SubString( cur, cur + 45 > length ? length - cur : 45 );
                cur += 45;

                NetworkMessage msg( MSG_ONE, NetworkMessages::MOTD, edict );
                    msg.WriteByte( buffer.Length() == 45 ? 0 : 1 );
                    msg.WriteString( buffer );
                msg.End();  
            }

            // Restore the hostname
            {
                NetworkMessage msg( MSG_ONE, NetworkMessages::ServerName, edict );
                    msg.WriteString( g_EngineFuncs.CVarGetString( "hostname" ) );
                msg.End();
            }
        }
    }
}
