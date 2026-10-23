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

        CBasePlayerWeapon@ weapon = cast<CBasePlayerWeapon@>( player.HasNamedPlayerItem( equipItemName ) );

        string message;

        if( weapon !is null )
        {
            ASWeaponConfig@ weaponConfig = g_WeaponsConfig.GetContext( equipItemName );

            if( weaponConfig.primary_maxammo == WEAPON_NOCLIP )
            {
                snprintf( message, "You've already equiped %1\n", itemInventory.m_szDisplayName );
                ChatColor::Say( player, ChatColor::Color::Red, message, player, true );
                return;
            }
            else if( player.m_rgAmmo( weapon.m_iPrimaryAmmoType ) == weaponConfig.primary_maxammo )
            {
                snprintf( message, "You're full of ammo for %1\n", itemInventory.m_szDisplayName );
                ChatColor::Say( player, ChatColor::Color::Red, message, player, true );
                return;
            }
        }

        snprintf( message, "Equiped %1\n", itemInventory.m_szDisplayName );
        Player::GiveItem( player, equipItemName, null, false, true );
        itemInventory.Destroy();
        ChatColor::Say( player, ChatColor::Color::Green, message, player, true );
    }
}
