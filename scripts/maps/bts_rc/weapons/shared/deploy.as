namespace weapons
{
    /**
    *   @brief Deploy a weapon for the given player
    *   @param hands_group: group for the view model weapon hands
    *   @param time: next think time
    **/
    bool deploy( CBasePlayer@ player,
        CBasePlayerWeapon@ weapon,
        const string&in viewmodel,
        const string&in playermodel,
        int animation,
        const string&in animation_ext,
        int hands_group,
        float time = 1.0f
    )
    {
        weapon.DefaultDeploy( viewmodel, playermodel, animation, animation_ext, 0, hands_group );

        player.pev.viewmodel = viewmodel;
        player.pev.weaponmodel = playermodel;

        player.set_m_szAnimExtension( animation_ext );

        // Set the correct bodygroup for character hands in the given hands_group, most of the weapons has it in the bodygroup 1s
        weapon.pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex(viewmodel), weapon.pev.body, hands_group, g_PlayerClass[player] );

        weapon.SendWeaponAnim( animation, 0, weapon.pev.body);

        player.m_flNextAttack = time;
        time += g_Engine.time;

        if( weapon.m_flNextPrimaryAttack < time )
            weapon.m_flNextPrimaryAttack = time;

        if( weapon.m_flTimeWeaponIdle < time )
            weapon.m_flTimeWeaponIdle = time;

        if( weapon.m_flNextSecondaryAttack < time )
            weapon.m_flNextSecondaryAttack = time;

        return true;
    }
}
