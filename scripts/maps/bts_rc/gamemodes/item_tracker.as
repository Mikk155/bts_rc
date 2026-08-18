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
    const float INVENTORY_UPDATE_INTERVAL = 0.5f;
    const uint MOTD_CHUNK_SIZE = 45;

    const string TRACKED_ITEMS_KEY = "tracked_items";
    const string INVENTORY_COOLDOWN_KEY = "it_inventorycd";
    const string MOTD_HOLDING_KEY = "motd_holding";
    const string MOTD_VERSION_KEY = "motd_update";

    dictionary Items;
    dictionary gpItemEntities;

    string gpBuffer;
    int gpBufferVersion = 0;
    bool gpBufferDirty = true;

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

    string EntityKey( CBaseEntity@ entity )
    {
        string key;
        snprintf( key, "%1", entity.entindex() );
        return key;
    }

    void MarkDirty()
    {
        gpBufferVersion++;
        gpBufferDirty = true;
    }

    void Reset()
    {
        Items.deleteAll();
        gpItemEntities.deleteAll();
        gpBuffer = String::EMPTY_STRING;
        MarkDirty();
    }

    void RegisterItem( CItemInventory@ item )
    {
        if( item is null )
            return;

        gpItemEntities[ EntityKey( item ) ] = @item;

        string itemName = item.m_szItemName;
        array<string> details = { item.m_szDisplayName, item.m_szDescription };
        Items[ itemName ] = details;
    }

    bool IsTrackedItem( CItemInventory@ item )
    {
        if( item is null )
            return false;

        CItemInventory@ trackedItem;
        return gpItemEntities.get( EntityKey( item ), @trackedItem ) && trackedItem is item;
    }

    void OnPlayerDisconnect( CBasePlayer@ player )
    {
        if( player !is null )
        {
            dictionary@ data = player.GetUserData();
            data[ TRACKED_ITEMS_KEY ] = String::EMPTY_STRING;
        }

        MarkDirty();
    }

    void UpdateGlobalBuffer()
    {
        dictionary bufferList;

        for( int playerIndex = 1; playerIndex <= g_Engine.maxClients; playerIndex++ )
        {
            CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex( playerIndex );

            if( player is null || !player.IsConnected() )
                continue;

            dictionary@ data = player.GetUserData();
            string trackedItems = data.exists( TRACKED_ITEMS_KEY ) ? string( data[ TRACKED_ITEMS_KEY ] ) : String::EMPTY_STRING;

            if( trackedItems.IsEmpty() )
                continue;

            array<string>@ storedItems = trackedItems.Split( ";" );

            for( uint itemIndex = 0; itemIndex < storedItems.length(); itemIndex++ )
            {
                string name = storedItems[itemIndex];

                if( name.IsEmpty() )
                    continue;

                string buffer;

                if( !bufferList.get( name, buffer ) )
                {
                    array<string>@ details;

                    if( Items.get( name, @details ) && details !is null && details.length() >= 2 )
                        snprintf( buffer, "Item: %1\nDetails: %2\nHolders:", details[0], details[1] );
                    else
                        snprintf( buffer, "Item: %1\nHolders:", name );
                }

                buffer += "\n - " + string( player.pev.netname ) + "\n";
                bufferList[ name ] = buffer;
            }
        }

        array<string> itemNames = bufferList.getKeys();

        if( itemNames.length() == 0 )
        {
            gpBuffer = "There is no player that has currently any item.";
            return;
        }

        gpBuffer = "List of players and inventory information\n";

        for( uint itemIndex = 0; itemIndex < itemNames.length(); itemIndex++ )
            gpBuffer += "\n" + string( bufferList[ itemNames[itemIndex] ] );
    }

    string SerializeItems( const array<string>@ items )
    {
        string serialized;

        for( uint itemIndex = 0; itemIndex < items.length(); itemIndex++ )
        {
            if( items[itemIndex].IsEmpty() )
                continue;

            if( !serialized.IsEmpty() )
                serialized += ";";

            serialized += items[itemIndex];
        }

        return serialized;
    }

    void UpdatePlayerInventory( CBasePlayer@ player )
    {
        dictionary@ data = player.GetUserData();
        string trackedItems = data.exists( TRACKED_ITEMS_KEY ) ? string( data[ TRACKED_ITEMS_KEY ] ) : String::EMPTY_STRING;

        array<string> emptyItems;
        array<string>@ storedItems = @emptyItems;

        if( !trackedItems.IsEmpty() )
            @storedItems = trackedItems.Split( ";" );

        array<string> currentItems;
        InventoryList@ inventory = player.m_pInventory;

        while( inventory !is null )
        {
            CItemInventory@ item = cast<CItemInventory@>( inventory.hItem.GetEntity() );
            @inventory = inventory.pNext;

            if( !IsTrackedItem( item ) )
                continue;

            string itemName = item.m_szItemName;

            if( itemName.IsEmpty() || currentItems.find( itemName ) >= 0 )
                continue;

            currentItems.insertLast( itemName );
        }

        bool changed = false;

        for( uint itemIndex = 0; itemIndex < currentItems.length(); itemIndex++ )
        {
            string name = currentItems[itemIndex];

            if( storedItems.find( name ) >= 0 )
                continue;

            g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, string( player.pev.netname ) + " collected " + name + "\n" );
            storedItems.insertLast( name );
            changed = true;
        }

        for( int itemIndex = int( storedItems.length() ) - 1; itemIndex >= 0; itemIndex-- )
        {
            if( currentItems.find( storedItems[itemIndex] ) >= 0 )
                continue;

            storedItems.removeAt( itemIndex );
            changed = true;
        }

        if( !changed )
            return;

        data[ TRACKED_ITEMS_KEY ] = SerializeItems( storedItems );
        MarkDirty();
    }

    void SendBuffer( edict_t@ edict )
    {
        uint length = gpBuffer.Length();
        uint offset = 0;

        while( offset < length )
        {
            uint chunkLength = offset + MOTD_CHUNK_SIZE > length ? length - offset : MOTD_CHUNK_SIZE;
            string chunk = gpBuffer.SubString( offset, chunkLength );
            offset += chunkLength;

            NetworkMessage msg( MSG_ONE, NetworkMessages::MOTD, edict );
                msg.WriteByte( offset >= length ? 1 : 0 );
                msg.WriteString( chunk );
            msg.End();
        }
    }

    void Think( CBasePlayer@ player )
    {
        if( player is null || !player.IsConnected() )
            return;

        dictionary@ data = player.GetUserData();
        float nextInventoryUpdate = data.exists( INVENTORY_COOLDOWN_KEY ) ? float( data[ INVENTORY_COOLDOWN_KEY ] ) : 0.0f;

        if( g_Engine.time >= nextInventoryUpdate )
        {
            UpdatePlayerInventory( player );
            data[ INVENTORY_COOLDOWN_KEY ] = g_Engine.time + INVENTORY_UPDATE_INTERVAL;
        }

        bool isHolding = ( player.pev.button & IN_USE ) != 0 && ( player.pev.button & IN_RELOAD ) != 0;
        bool wasHolding = data.exists( MOTD_HOLDING_KEY ) ? bool( data[ MOTD_HOLDING_KEY ] ) : false;

        if( isHolding == wasHolding )
            return;

        data[ MOTD_HOLDING_KEY ] = isHolding;

        if( !isHolding )
            return;

        player.pev.button &= ~IN_RELOAD;
        player.pev.button &= ~IN_USE;

        int playerMOTDVersion = data.exists( MOTD_VERSION_KEY ) ? int( data[ MOTD_VERSION_KEY ] ) : -1;
        edict_t@ edict = player.edict();

        {
            NetworkMessage msg( MSG_ONE, NetworkMessages::ServerName, edict );
                msg.WriteString( "Item holders list" );
            msg.End();
        }

        if( playerMOTDVersion != gpBufferVersion )
        {
            if( gpBufferDirty )
            {
                UpdateGlobalBuffer();
                gpBufferDirty = false;
            }

            data[ MOTD_VERSION_KEY ] = gpBufferVersion;
            SendBuffer( edict );
        }
        else
        {
            NetworkMessage msg( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, edict );
                msg.WriteString( "servermotd\n" );
            msg.End();
        }

        {
            NetworkMessage msg( MSG_ONE, NetworkMessages::ServerName, edict );
                msg.WriteString( g_EngineFuncs.CVarGetString( "hostname" ) );
            msg.End();
        }
    }
}
