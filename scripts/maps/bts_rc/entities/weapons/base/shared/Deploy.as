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
