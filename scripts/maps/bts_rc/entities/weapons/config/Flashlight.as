namespace Flashlight
{
    void Holster( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character )
    {
        g_SoundSystem.StopSound( player.edict(), CHAN_WEAPON, "bts_rc/items/battery_reload.wav" );

        if( player.FlashlightIsOn() )
            player.FlashlightTurnOff();
    }

    void Think( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character, ASWeaponConfig@ config, const string&in flashlight_model )
    {
        if( ( player.pev.effects & EF_DIMLIGHT ) != 0 )
        {
            player.pev.weaponmodel = flashlight_model;
        }
        else
        {
            player.pev.weaponmodel = config.player_model;
        }

        player.m_iHideHUD &= ~HIDEHUD_FLASHLIGHT;
    }
}
