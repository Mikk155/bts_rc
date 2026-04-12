namespace Hellbound
{
    void Startup( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
    {
        auto pSetAttributes = PlayerSpawnHook( function( CBasePlayer@ player ) {
            if( player !is null )
            {
                player.pev.health = player.pev.armortype = player.pev.max_health = 1;
            }

            return HOOK_CONTINUE;
        } );

        g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @pSetAttributes );
        g_Hooks.RegisterHook( Hooks::Player::PlayerRevived, @pSetAttributes );

        for( int i = 0; i <= g_Engine.maxClients; i++ )
        {
            pSetAttributes( g_PlayerFuncs.FindPlayerByIndex( i ) );
        }
    }
}
