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
        return ( character !is null && character.IsHazard );
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
