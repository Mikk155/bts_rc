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

namespace item_tracker
{
    dictionary Items;

    // Array of EHandle to track item_inventory entities from MapActivate
    array<EHandle> gpItems;

    // String containing all the information.
    string gpBuffer;

    // Global integer (version/revision count of the global buffer)
    int gpBufferVersion = 0;

    // Flag indicating if gpBuffer needs to be rebuilt
    bool gpBufferDirty = true;

    // List containing all the item_inventory names
    const array<string>@ ValidItemNames =
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

    void OnPlayerDisconnect( CBasePlayer@ player )
    {
        if( player !is null )
        {
            dictionary@ data = player.GetUserData();
            data[ "tracked_items" ] = "";
        }
        gpBufferVersion++;
        gpBufferDirty = true;
    }

    void UpdateGlobalBuffer()
    {
        dictionary bufferList;

        for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
        {
            CBasePlayer@ players = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

            if( players is null || !players.IsConnected() )
                continue;

            dictionary@ data = players.GetUserData();
            string trackedStr = data.exists( "tracked_items" ) ? string( data[ "tracked_items" ] ) : "";
            if( trackedStr.IsEmpty() )
                continue;

            array<string>@ storedItems = trackedStr.Split( ";" );

            foreach( auto name : storedItems )
            {
                if( name.IsEmpty() )
                    continue;

                string buffer;

                if( !bufferList.get( name, buffer ) )
                {
                    array<string>@ KeyvaluePairData;

                    if( Items.get( name, @KeyvaluePairData ) )
                    {
                        snprintf( buffer, "Item: %1\nDetails: %2\nHolders:", KeyvaluePairData[0], KeyvaluePairData[1] );
                    }
                    else
                    {
                        snprintf( buffer, "Item: %1\nHolders:", name );
                    }
                }

                snprintf( buffer, "%1\n - %2\n", buffer, string( players.pev.netname ) );
                bufferList[ name ] = buffer;
            }
        }

        array<string> item_names = bufferList.getKeys();

        if( item_names.length() == 0 )
        {
            gpBuffer = "There is no player that has currently any item.";
        }
        else
        {
            gpBuffer = "List of players and inventory information\n";

            foreach( auto name : item_names )
            {
                snprintf( gpBuffer, "%1\n%2", gpBuffer, string( bufferList[ name ] ) );
            }
        }
    }

    void UpdatePlayerInventory( CBasePlayer@ player )
    {
        dictionary@ data = player.GetUserData();
        string trackedStr = data.exists( "tracked_items" ) ? string( data[ "tracked_items" ] ) : "";
        array<string>@ storedItems = null;
        if( !trackedStr.IsEmpty() )
            @storedItems = trackedStr.Split( ";" );

        array<string> temp;

        // Clean up invalid handles from gpItems to prevent memory/handle leak
        for( int i = int( gpItems.length() ) - 1; i >= 0; i-- )
        {
            if( !gpItems[i].IsValid() )
            {
                gpItems.removeAt( i );
            }
        }

        array<string> currentItems;
        InventoryList@ inventory = player.m_pInventory;
        while( inventory !is null )
        {
            CItemInventory@ item = cast<CItemInventory@>( inventory.hItem.GetEntity() );
            @inventory = inventory.pNext;

            if( item is null )
                continue;

            // Validate that this item is in the tracked map items (gpItems)
            bool isTracked = false;
            foreach( auto entity : gpItems )
            {
                if( cast<CBaseEntity@>( entity.GetEntity() ) is cast<CBaseEntity@>( item ) )
                {
                    isTracked = true;
                    break;
                }
            }

            if( !isTracked )
                continue;

            string name = item.m_szItemName;
            if( name.IsEmpty() )
                continue;

            if( currentItems.find( name ) < 0 )
            {
                currentItems.insertLast( name );
            }
        }

        bool changed = false;

        // Check if item was not stored (newly collected)
        foreach( auto name : currentItems )
        {
            if( storedItems is null || storedItems.find( name ) < 0 )
            {
                g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, string( player.pev.netname ) + " collected " + name + "\n" );
                if( storedItems is null )
                {
                    @storedItems = @temp;
                }
                storedItems.insertLast( name );
                changed = true;
            }
        }

        // Check if there are items in userdata that are no longer in the inventory (dropped/lost)
        if( storedItems !is null )
        {
            for( int i = int( storedItems.length() ) - 1; i >= 0; i-- )
            {
                string name = storedItems[i];
                if( currentItems.find( name ) < 0 )
                {
                    storedItems.removeAt( i );
                    changed = true;
                }
            }
        }

        if( changed )
        {
            // Serialize back to userdata
            string newTrackedStr = "";
            foreach( auto name : storedItems )
            {
                if( name.IsEmpty() )
                    continue;
                if( !newTrackedStr.IsEmpty() )
                    newTrackedStr += ";";
                newTrackedStr += name;
            }
            data[ "tracked_items" ] = newTrackedStr;

            gpBufferVersion++;
            gpBufferDirty = true;
        }
    }

    void Think( CBasePlayer@ player )
    {
        if( player is null || !player.IsConnected() )
            return;

        // Run inventory checks per-player per-frame
        UpdatePlayerInventory( player );

        // Key down check: only trigger when pressing USE and RELOAD (one-shot transition check)
        dictionary@ data = player.GetUserData();
        bool isHolding = ( player.pev.button & IN_USE ) != 0 && ( player.pev.button & IN_RELOAD ) != 0;
        bool wasHolding = data.exists( "motd_holding" ) ? bool( data[ "motd_holding" ] ) : false;
        data[ "motd_holding" ] = isHolding;

        if( !isHolding || wasHolding )
            return;

        player.pev.button &= ~IN_RELOAD;
        player.pev.button &= ~IN_USE;

        int playerMOTDVersion = data.exists( "motd_update" ) ? int( data[ "motd_update" ] ) : -1;

        if( playerMOTDVersion != gpBufferVersion )
        {
            if( gpBufferDirty )
            {
                UpdateGlobalBuffer();
                gpBufferDirty = false;
            }

            data[ "motd_update" ] = gpBufferVersion;

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
        else
        {
            NetworkMessage msg( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, player.edict() );
                msg.WriteString( "motd\n" );
            msg.End();
        }
    }
}
