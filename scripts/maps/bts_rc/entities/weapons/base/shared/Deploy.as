namespace weapons
{
    bool Deploy( CBasePlayerWeapon@ weapon, CBasePlayer@ player, ASWeaponConfig@ config )
    {
        if( weapon is null || player is null || config is null )
            return false;

        player.pev.viewmodel = config.view_model;
        player.pev.weaponmodel = config.player_model;

        player.set_m_szAnimExtension( config.animation_extension );

        auto character = GetCharacter(player);
        Hands handGroup = ( character !is null ? character.HandsGroup : Hands::Gray );

        // Set the correct bodygroup for character hands in the given hands_group, most of the weapons has it in the bodygroup 1s
        weapon.pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( config.view_model ), weapon.pev.body, config.hands_group, handGroup );

        weapon.SendWeaponAnim( config.animation_draw, 0, weapon.pev.body );

        player.m_flNextAttack = config.deploy_time;
        float globalized_deploy = config.deploy_time + g_Engine.time;

        if( weapon.m_flNextPrimaryAttack < globalized_deploy )
            weapon.m_flNextPrimaryAttack = globalized_deploy;

        if( weapon.m_flTimeWeaponIdle < globalized_deploy )
            weapon.m_flTimeWeaponIdle = globalized_deploy;

        if( weapon.m_flNextSecondaryAttack < globalized_deploy )
            weapon.m_flNextSecondaryAttack = globalized_deploy;

        return true;
    }
}
