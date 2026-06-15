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
