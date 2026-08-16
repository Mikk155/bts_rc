namespace Hooks
{
    dictionary __JoinedPlayers__;

    // Called when a player changes class
    void PlayerSetClass( CBasePlayer@ player, CCharacter@ character )
    {
        dictionary@ data = player.GetUserData();

        switch( character.Classify )
        {
            case Classification::Security:
            case Classification::Operative:
                data[ "security" ] = true; // Set "Is trained personal"
            break;
        }

        if( player.IsAlive() )
        {
            // Re-Deploy weapon to update view model hands
            if( player.m_hActiveItem.IsValid() )
            {
                CBaseEntity@ active_item = player.m_hActiveItem.GetEntity();

                if( active_item !is null )
                {
                    CBasePlayerItem@ weapon = cast<CBasePlayerItem@>( active_item );

                    if( weapon !is null )
                    {
                        weapon.Deploy();
                    }
                }
            }
        }
        else if( !__JoinedPlayers__.exists( g_EngineFuncs.GetPlayerAuthId( player.edict() ) ) )
        {
            g_PlayerFuncs.RespawnPlayer( player, false, true );
        }

        __JoinedPlayers__[ g_EngineFuncs.GetPlayerAuthId( player.edict() ) ] = true;

        ASEquipmentCharacter@ equipmentCharacter = gpEquipment.Characters[ character.Classify ];
        equipmentCharacter.Equip( player );
    }
}
