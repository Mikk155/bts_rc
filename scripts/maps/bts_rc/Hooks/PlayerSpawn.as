namespace Hooks
{
bool PlayerSpawn = g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn,
PlayerSpawnHook( function( CBasePlayer@ player )
{
    if( player is null )
        return HOOK_CONTINUE;

    player_models::UpdatePlayerArmor(player);

    return HOOK_CONTINUE;
} ) );
}
