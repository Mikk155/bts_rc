mixin class CBaseFlashLight
{
    float m_battery = 100;

    void fl_Holster()
    {
        if( m_pPlayer.FlashlightIsOn() )
            m_pPlayer.FlashlightTurnOff();

        m_pPlayer.m_iHideHUD |= HIDEHUD_FLASHLIGHT;
    }

    bool fl_ShouldToggle()
    {
        if( m_battery > 0 )
        {
            if( m_pPlayer.FlashlightIsOn() )
            {
                m_pPlayer.FlashlightTurnOff();
            }
            else
            {
                m_pPlayer.FlashlightTurnOn();
            }
            return true;
        }
        return false;
    }

    void fl_Deploy()
    {
        m_pPlayer.m_iHideHUD &= ~HIDEHUD_FLASHLIGHT;
    }

    void fl_ItemPostFrame()
    {
        m_pPlayer.m_iFlashBattery = int(m_battery);

        if( m_pPlayer.FlashlightIsOn() )
        {
            // -TODO Do a proper deduction time.
            m_battery -= 0.1f;

            if( m_battery <= 0 )
            {
                m_pPlayer.FlashlightTurnOff();
            }
        }
    }
}