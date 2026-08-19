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

namespace Hooks
{
    dictionary __JoinedPlayers__;

    // Called when a player changes class
    void PlayerSetClass( CBasePlayer@ player, CCharacter@ character )
    {
        dictionary@ data = player.GetUserData();

        switch( character.Classify )
        {
            case Classification::Security:
            case Classification::Operative:
                data[ "security" ] = true; // Set "Is trained personal"
            break;
        }

        if( player.IsAlive() )
        {
            // Re-Deploy weapon to update view model hands
            if( player.m_hActiveItem.IsValid() )
            {
                CBaseEntity@ active_item = player.m_hActiveItem.GetEntity();

                if( active_item !is null )
                {
                    CBasePlayerItem@ weapon = cast<CBasePlayerItem@>( active_item );

                    if( weapon !is null )
                    {
                        weapon.Deploy();
                    }
                }
            }
        }
        else if( !__JoinedPlayers__.exists( g_EngineFuncs.GetPlayerAuthId( player.edict() ) ) )
        {
            g_PlayerFuncs.RespawnPlayer( player, false, true );
        }

        __JoinedPlayers__[ g_EngineFuncs.GetPlayerAuthId( player.edict() ) ] = true;

        ASEquipmentCharacter@ equipmentCharacter = gpEquipment.Characters[ character.Classify ];
        equipmentCharacter.Equip( player );
    }
}
