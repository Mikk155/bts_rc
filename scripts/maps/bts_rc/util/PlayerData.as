class CPlayerData
{
    private string m_SteamID;

    const string& SteamID {
        get {
            return this.m_SteamID;
        }
    }

    CPlayerData( const string&in steamID )
    {
        this.m_SteamID = steamID;
    }

    bool HasStartedPlaying;
}

dictionary g_PlayerData;

namespace util
{
    CPlayerData@ GetPlayerData( const string&in steamID )
    {
        if( !g_PlayerData.exists( steamID ) )
        {
            CPlayerData@ data = CPlayerData( steamID );
            @g_PlayerData[ steamID ] = data;
            return @data;
        }
        return cast<CPlayerData@>( g_PlayerData[ steamID ] );
    }

    CPlayerData@ GetPlayerData( CBasePlayer@ player )
    {
        return ( player !is null ? GetPlayerData( g_EngineFuncs.GetPlayerAuthId( player.edict() ) ) : null );
    }

    CPlayerData@ GetPlayerData( CBaseEntity@ player )
    {
        return ( player !is null ? GetPlayerData( g_EngineFuncs.GetPlayerAuthId( player.edict() ) ) : null );
    }
}
