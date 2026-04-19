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

abstract class BTS_MeleeWeapon : BTS_Weapon
{
    ASMeleeWeaponConfig@ get_configMelee() {
        return cast<ASMeleeWeaponConfig@>( this.config );
    }

    // Amount of swings in a raw
    int m_iSwing = 0;

    bool m_IsSecondary = false;

    // Set weapon cooldown
    void SetCooldown( bool is_trained_personal, bool miss, AttackType type ) {
        weapons::SetCooldown( self, configMelee.GetCooldown( is_trained_personal, type, miss ) );
    }

    // Hit ahead. return whatever it was a hit or a miss. automatically damages the target with config data
    bool Hit( TraceResult&out tr, AttackType type, CBaseEntity@&out hit ) {
        return weapons::Hit( self, this.owner, tr, type, hit, configMelee );
    }
}
