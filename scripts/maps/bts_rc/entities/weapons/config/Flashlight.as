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

namespace Flashlight
{
    void Holster( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character )
    {
        g_SoundSystem.StopSound( player.edict(), CHAN_WEAPON, "bts_rc/items/battery_reload.wav" );

        if( player.FlashlightIsOn() )
            player.FlashlightTurnOff();
    }

    void Think( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character, ASWeaponConfig@ config, const string&in flashlight_model )
    {
        if( ( player.pev.effects & EF_DIMLIGHT ) != 0 )
        {
            player.pev.weaponmodel = flashlight_model;
        }
        else
        {
            player.pev.weaponmodel = config.player_model;
        }

        player.m_iHideHUD &= ~HIDEHUD_FLASHLIGHT;
    }
}
