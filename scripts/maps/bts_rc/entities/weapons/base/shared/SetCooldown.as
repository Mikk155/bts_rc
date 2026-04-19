namespace weapons
{
    // Set weapon cooldown
    void SetCooldown( CBasePlayerWeapon@ weapon, CBasePlayer@ player, float cooldown = 1.0f )
    {
        player.m_flNextAttack = cooldown;

        weapon.m_flNextPrimaryAttack = weapon.m_flNextSecondaryAttack = weapon.m_flNextTertiaryAttack =
            g_Engine.time + cooldown;

        if( weapon.m_flTimeWeaponIdle < weapon.m_flNextPrimaryAttack )
            weapon.m_flTimeWeaponIdle = weapon.m_flNextPrimaryAttack;
    }
}
