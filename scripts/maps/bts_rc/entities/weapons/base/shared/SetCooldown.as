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
    // Set weapon cooldown, returns an absolute value with g_Engine.time added
    float SetCooldown( CBasePlayerWeapon@ weapon, CBasePlayer@ player, float cooldown = 1.0f )
    {
        float gCooldown = g_Engine.time + cooldown;

        player.m_flNextAttack = cooldown;

        weapon.m_flNextPrimaryAttack =
        weapon.m_flNextSecondaryAttack =
        weapon.m_flNextTertiaryAttack = gCooldown;

        if( weapon.m_flTimeWeaponIdle < gCooldown )
            weapon.m_flTimeWeaponIdle = gCooldown;

        return gCooldown;
    }
}
