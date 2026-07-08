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
    HookReturnCode PlayerCollect( CBaseEntity@ pickup, CBaseEntity@ other )
    {
        if( pickup is null || other is null )
            return HOOK_CONTINUE;

        auto player = cast<CBasePlayer@>(other);

        CBasePlayerWeapon@ weapon = cast<CBasePlayerWeapon@>(pickup);

        if( player is null || weapon is null )
            return HOOK_CONTINUE;

        ASWeaponConfig@ weaponConfig = cast<ASWeaponConfig@>( g_WeaponsConfig.Interfaces[ weapon.GetClassname() ] );

        // We assume weaponConfig is not null.
        // If it is null then is a third party weapon.
        // the map is not designed to have other weapons than ours.
        // I don't have time to redesign this nor i care.
        if( weaponConfig is null )
        {
            if( true )
                return HOOK_CONTINUE;
            player.RemovePlayerItem( weapon );
            return HOOK_CONTINUE;
        }

        if( !weaponConfig.IsCustomWeapon() )
        {
            int primaryAmmo = g_PlayerFuncs.GetAmmoIndex( weapon.pszAmmo1() );
            if( primaryAmmo != WEAPON_NOCLIP )
                player.SetMaxAmmo( primaryAmmo, weaponConfig.primary_maxammo );

            int secondaryAmmo = g_PlayerFuncs.GetAmmoIndex( weapon.pszAmmo2() );
            if( secondaryAmmo != WEAPON_NOCLIP )
                player.SetMaxAmmo( secondaryAmmo, weaponConfig.secondary_maxammo );

            NetworkMessage m( MSG_ONE, NetworkMessages::WeaponList, player.edict() );
                m.WriteString( weaponConfig.GetName() );
                m.WriteByte( weapon.m_iPrimaryAmmoType );
                m.WriteLong( weaponConfig.primary_maxammo );
                m.WriteByte( weapon.m_iSecondaryAmmoType );
                m.WriteLong( weaponConfig.secondary_maxammo );
                m.WriteByte( weaponConfig.slot );
                m.WriteByte( weaponConfig.position );
                m.WriteShort( weapon.m_iId );
                m.WriteByte( weapon.iFlags() );
            m.End();
        }

        return HOOK_CONTINUE;
    }
}
