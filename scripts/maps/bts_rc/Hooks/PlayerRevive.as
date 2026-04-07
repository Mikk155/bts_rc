namespace Hooks
{
bool PlayerRevive = g_Hooks.RegisterHook( Hooks::Player::PlayerRevived,
PlayerRevivedHook( function( CBasePlayer@ player )
{
    if( player is null )
        return HOOK_CONTINUE;

    player_models::UpdatePlayerArmor(player);

    return HOOK_CONTINUE;
} ) );
}
