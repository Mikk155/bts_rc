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

namespace Hooks
{
    HookReturnCode MonsterTakeDamage( DamageInfo@ info )
    {
        if( info.pVictim is null )
            return HOOK_CONTINUE;

        CBaseMonster@ victim = cast<CBaseMonster@>( info.pVictim );

        if( victim is null )
            return HOOK_CONTINUE;

        dictionary@ data = info.pVictim.GetUserData();

        if( info.flDamage > 0 && victim.m_LastHitGroup == 1 && gpZombieUncrab.IsActive() && gpZombieUncrab.track_health && gpZombieUncrab.IsValid( info.pVictim ) )
            data["headcrab_damage"] = float( data["headcrab_damage"] ) + info.flDamage;

        string classname = victim.GetClassname();
        string model = string( victim.pev.model );

        if( gpZombieEngineer.IsValid( classname, model ) )
            gpZombieEngineer.TakeDamage( victim, info );

        return HOOK_CONTINUE;
    }
}