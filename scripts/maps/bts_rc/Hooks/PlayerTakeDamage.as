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

    if( info.flDamage > 0 && info.pVictim !is null && ( info.bitsDamageType & DMG_RADIATION ) != 0 )
    {
        switch( player_models::GetClass( player ) )
        {
            case PM::CLSUIT:
            case PM::CLSUIT_CIVIL:
            {
                float dmg = info.flDamage * 0.3;
                if( dmg > 1.0 )
                    info.flDamage = dmg;
                break;
            }
            case PM::HELMET:
            case PM::HELMET_CIVIL:
            {
                info.flDamage = 0;
                return HOOK_CONTINUE;
            }
        }
    }

    return HOOK_CONTINUE;
} ) );
}
