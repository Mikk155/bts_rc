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
    bool Deploy( CBasePlayerWeapon@ weapon, CBasePlayer@ player, ASWeaponConfig@ config )
    {
        if( weapon is null || player is null || config is null )
            return false;

        player.pev.viewmodel = config.view_model;
        player.pev.weaponmodel = config.player_model;

        player.set_m_szAnimExtension( config.animation_extension );

        auto character = GetCharacter(player);
        Hands handGroup = ( character !is null ? character.HandsGroup : Hands::Gray );

        // Set the correct bodygroup for character hands in the given hands_group, most of the weapons has it in the bodygroup 1s
        weapon.pev.body = g_ModelFuncs.SetBodygroup( config.view_model_index, weapon.pev.body, config.hands_group, handGroup );

        weapon.SendWeaponAnim( config.animation_draw, 0, weapon.pev.body );

        player.m_flNextAttack = config.deploy_time;
        float globalized_deploy = config.deploy_time + g_Engine.time;

        if( weapon.m_flNextPrimaryAttack < globalized_deploy )
            weapon.m_flNextPrimaryAttack = globalized_deploy;

        if( weapon.m_flTimeWeaponIdle < globalized_deploy )
            weapon.m_flTimeWeaponIdle = globalized_deploy;

        if( weapon.m_flNextSecondaryAttack < globalized_deploy )
            weapon.m_flNextSecondaryAttack = globalized_deploy;

        return true;
    }
}
