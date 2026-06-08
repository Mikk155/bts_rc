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

namespace item_tracker
{
    array<ASItemData@> Items(0);

    class ASItemData
    {
        private
            CItemInventory@ m_Item;

        bool IsValid() const
        {
            if( m_Item is null )
            {
                int index = Items.findByRef( this );

                if( g_Logger.info.active )
                    g_Logger.info.print( snprintf( glog, "Invalid CItemInventory removing from item tracking", m_Item.m_szItemName ) );

                Items.removeAt( index );
                return false;
            }
            return true;
        }

        string Content( int current, int max ) const
        {
            string players;

            string itemName = m_Item.m_szItemName;

            for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
            {
                CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

                if( player !is null && player.IsConnected() )
                {
                    InventoryList@ inventory = player.m_pInventory;

                    while( inventory !is null )
                    {
                        if( inventory.hItem.IsValid() )
                        {
                            CItemInventory@ item = cast<CItemInventory@>( inventory.hItem.GetEntity() );

                            if( item !is null && string( item.m_szItemName ) == itemName )
                            {
                                snprintf( players, "%1\n%2", players, string( player.pev.netname ) );
                                break;
                            }
                        }
                        @inventory = inventory.pNext;
                    }
                }
            }
            string buffer;
            snprintf( buffer, "%1/%2\nName: %3\nDetails: %4\nPlayers holding this item:%5", current, max, m_Item.m_szDisplayName, m_Item.m_szDescription, players );
            return buffer;
        }

        ASItemData( CItemInventory@ item )
        {
            @m_Item = item;
        }
    }

    void RegisterItem( CItemInventory@ item )
    {
        if( item is null )
            return;

        string name = item.m_szItemName;

        if( name != "GEAR_1"
        && name != "GEAR_1"
        && name != "GEAR_2"
        && name != "GEAR_3"
        && name != "GEAR_4"
        && name != "RETINA_COMPONENT"
        && name != "VALVE_1"
        && name != "WAREHOUSE_YARDKEY"
        && name != "DORMS_CARD_101"
        && name != "DORMS_CARD_106"
        && name != "DORMS_CARD_201"
        && name != "CODES_1"
        && name != "Blackmesa_Maintenance_Clearance_2"
        && name != "d5_officekey"
        && name != "d5_doctorkey"
        && name != "TORTURED_ARMORY_KEYCARD"
        && name != "Blackmesa_Security_Clearance_3"
        ) {
            return;
        }

        if( g_Logger.info.active )
            g_Logger.info.print( snprintf( glog, "Registering item \"%1\" for item tracking", item.m_szItemName ) );

        ASItemData@ data = ASItemData( item );

        Items.insertLast( data );
    }

    HUDTextParams params;

    void Think( CBasePlayer@ player )
    {
        if( player is null )
            return;

        dictionary@ data = player.GetUserData();

        float nextthink = float( data[ "item_tracker.time" ] );

        const int length = Items.length();

        int menuIndex;

        if( !data.get( "item_tracker.index", menuIndex ) )
        {
            if( ( player.pev.button & IN_USE ) != 0 && ( player.pev.button & IN_RELOAD ) != 0 )
            {
                player.pev.button &= ~IN_USE;
                player.pev.button &= ~IN_RELOAD;

                if( nextthink > g_Engine.time ) { return; }

                data[ "item_tracker.index" ] = menuIndex = 0;
            }
            else
            {
                data[ "item_tracker.time" ] = g_Engine.time + 0.3f;
                return;
            }
        }
        else if( ( player.pev.button & IN_USE ) != 0 && ( player.pev.button & IN_RELOAD ) != 0 )
        {
            player.pev.button &= ~IN_USE;
            player.pev.button &= ~IN_RELOAD;

            if( nextthink > g_Engine.time ) { return; }

            data.delete( "item_tracker.index" );
            data[ "item_tracker.time" ] = g_Engine.time + 0.3f;
            return;
        }
        else if( ( player.pev.button & IN_ATTACK ) != 0 )
        {
            player.pev.button &= ~IN_ATTACK;

            if( nextthink > g_Engine.time ) { return; }

            if( menuIndex == 0 )
                menuIndex = length;
            menuIndex--;
        }
        else if( ( player.pev.button & IN_ATTACK2 ) != 0 )
        {
            player.pev.button &= ~IN_ATTACK2;

            if( nextthink > g_Engine.time ) { return; }

            menuIndex++;
            if( menuIndex >= length )
                menuIndex = 0;
        }

        if( nextthink > g_Engine.time ) { return; }

        data[ "item_tracker.time" ] = g_Engine.time + 0.3f;
        data[ "item_tracker.index" ] = menuIndex;

        auto itemData = Items[menuIndex];

        if( !itemData.IsValid() )
            return;

        params.r1 = 150;
        params.g1 = 150;
        params.b1 = 150;
        params.a1 = 255;
        params.fadeinTime = 0.0;
        params.holdTime = 1.0;
        params.fadeoutTime = 1.0;
        params.effect = 0;
        params.channel = 4;
        params.x = 0.01f;
        params.y = 0.30f;

        g_PlayerFuncs.HudMessage( player, params, itemData.Content( menuIndex, length ) );
    }
}
