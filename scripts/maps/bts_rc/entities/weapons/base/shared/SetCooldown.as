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
    // Set weapon cooldown
    void SetCooldown( CBasePlayerWeapon@ weapon, CBasePlayer@ player, float cooldown = 1.0f )
    {
        player.m_flNextAttack = cooldown;

        weapon.m_flNextPrimaryAttack = weapon.m_flNextSecondaryAttack = weapon.m_flNextTertiaryAttack =
            g_Engine.time + cooldown;

        if( weapon.m_flTimeWeaponIdle < weapon.m_flNextPrimaryAttack )
            weapon.m_flTimeWeaponIdle = weapon.m_flNextPrimaryAttack;
    }
}
