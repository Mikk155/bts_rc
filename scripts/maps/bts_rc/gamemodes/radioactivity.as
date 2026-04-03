/*
*   Author: Mikk
*/

const bool __HazardSuitRadioactivity__ = g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage,
PlayerTakeDamageHook( function( DamageInfo@ info )
{
    if( info.flDamage > 0 && info.pVictim !is null && ( info.bitsDamageType & DMG_RADIATION ) != 0 )
    {
        switch( player_models::GetClass( cast<CBasePlayer@>( info.pVictim ) ) )
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
