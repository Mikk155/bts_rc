namespace Hooks
{
bool WeaponPrimaryAttack = g_Hooks.RegisterHook( Hooks::Weapon::WeaponPrimaryAttack,
WeaponPrimaryAttackHook( function( CBasePlayer@ player, CBasePlayerWeapon@ weapon )
{
    if( weapon is null || player is null )
        return HOOK_CONTINUE;

    WeaponOverrider@ wpnOverride = null;

    if( gpWeaponsOverride.get( weapon.GetClassname(), @wpnOverride ) && wpnOverride !is null && wpnOverride.WeaponPrimaryAttack !is null )
        wpnOverride.WeaponPrimaryAttack( player, weapon, GetCharacter(player) );

    return HOOK_CONTINUE;
} ) );
}
