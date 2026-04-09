namespace Hooks
{
bool PlayerTakeDamage = g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage,
PlayerTakeDamageHook( function( DamageInfo@ info )
{
    if( info.pVictim is null )
        return HOOK_CONTINUE;

    auto player = cast<CBasePlayer@>( info.pVictim );

    if( player is null )
        return HOOK_CONTINUE;

    auto character = GetCharacter(player);

    if( character is null )
        return HOOK_CONTINUE;

    character.TakeDamage( player, @info );

    return HOOK_CONTINUE;
} ) );
}
