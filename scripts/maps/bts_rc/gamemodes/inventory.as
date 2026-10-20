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

namespace InventoryItem
{
    void Activate( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE useType, float value )
    {
        CBasePlayer@ player;
        CItemInventory@ itemInventory;

        if( activator is null
        || caller is null
        || !activator.IsPlayer()
        || ( @player = cast<CBasePlayer@>( activator ) ) is null
        || ( @itemInventory = cast<CItemInventory@>( caller ) ) is null )
            return;

        string equipItemName = string( itemInventory.pev.netname );

        if( equipItemName.IsEmpty() )
            return;

        CBasePlayerItem@ equipedItem = player.HasNamedPlayerItem( equipItemName );

        if( equipedItem !is null )
        {
            string message;
            ASWeaponConfig@ weaponConfig;

            if( g_WeaponsConfig.Interfaces.get( equipItemName, @weaponConfig ) && weaponConfig !is null )
            {
                snprintf( message, "You've already equiped %1", weaponConfig.name );
            }
            else
            {
                message = "You've already equiped this item";
            }

            ChatColor::Say( player, ChatColor::Red, message, player, true );
        }
        else
        {
            player.GiveNamedItem( equipItemName );
            itemInventory.Destroy();
        }
    }
}
