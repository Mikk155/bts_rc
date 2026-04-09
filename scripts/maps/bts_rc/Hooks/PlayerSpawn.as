namespace Hooks
{
bool PlayerSpawn = g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn,
PlayerSpawnHook( function( CBasePlayer@ player )
{
    if( player is null )
        return HOOK_CONTINUE;

    // Hide flashlight icon.
    player.m_iHideHUD |= HIDEHUD_FLASHLIGHT;

    UpdateArmor(player);

    return HOOK_CONTINUE;
} ) );
}
