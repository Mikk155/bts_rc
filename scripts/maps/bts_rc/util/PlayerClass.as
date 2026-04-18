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

namespace util
{
    /// Is the player wearing a Hazard suit?
    bool IsHazard( CBaseEntity@ player )
    {
        auto character = GetCharacter(player);
        return ( character !is null && character.IsHazard );
    }

    /// Is the player wearing a HEV suit?
    bool IsHEV( CBaseEntity@ player )
    {
        auto character = GetCharacter(player);
        return ( character !is null && character.IsHEV );
    }

    /// Is the player a weapon-trained personal?
    bool IsTrainedPersonal( CBaseEntity@ player )
    {
        if( player !is null )
        {
            dictionary@ data = player.GetUserData();

            if( data !is null )
            {
                bool isTrained;

                if( data.get( "security", isTrained ) )
                    return isTrained;
            }
        }

        return false;
    }

    /// Get the player class
    const Classification GetClass( CBasePlayer@ player )
    {
        if( player !is null )
        {
            auto character = GetCharacter(player);

            if( character !is null )
            {
                return character.Classify;
            }
        }

        return Classification::Unset;
    }

    /// Get the player class
    const Classification GetClass( CBaseEntity@ player )
    {
        return GetClass( cast<CBasePlayer@>(player) );
    }
}
