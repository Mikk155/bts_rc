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

namespace weapons
{
    void Given( CBasePlayer@ player, CBasePlayerWeapon@ weapon, ASWeaponConfig@ config = null, bool callGive = true )
    {
        if( player is null || weapon is null )
            return;

        if( config is null && ( @config = cast<ASWeaponConfig@>( g_WeaponsConfig.Interfaces[ weapon.GetClassname() ] ) ) is null )
            return;

        if( !config.IsCustomWeapon() )
        {
            int primaryAmmo = g_PlayerFuncs.GetAmmoIndex( weapon.pszAmmo1() );
            if( primaryAmmo != WEAPON_NOCLIP )
                player.SetMaxAmmo( primaryAmmo, config.primary_maxammo );

            int secondaryAmmo = g_PlayerFuncs.GetAmmoIndex( weapon.pszAmmo2() );
            if( secondaryAmmo != WEAPON_NOCLIP )
                player.SetMaxAmmo( secondaryAmmo, config.secondary_maxammo );

            NetworkMessage message( MSG_ONE, NetworkMessages::WeaponList, player.edict() );
                message.WriteString( config.GetName() );
                message.WriteByte( weapon.m_iPrimaryAmmoType );
                message.WriteLong( config.primary_maxammo );
                message.WriteByte( weapon.m_iSecondaryAmmoType );
                message.WriteLong( config.secondary_maxammo );
                message.WriteByte( config.slot );
                message.WriteByte( config.position );
                message.WriteShort( weapon.m_iId );
                message.WriteByte( weapon.iFlags() );
            message.End();
        }

        if( callGive )
        {
            CCharacter@ character = GetCharacter( player );

            if( character !is null )
            {
                config.WeaponGiven( player, weapon, character );
            }
        }
    }
}
