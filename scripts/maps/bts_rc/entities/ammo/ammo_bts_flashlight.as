class ammo_bts_flashlight : BTS_Ammo
{
    const string& get_m_PlaySound() override {
        return "bts_rc/items/battery_pickup1.wav";
    }

    const string& get_m_Model() override {
        return "models/bts_rc/furniture/w_flashlightbattery.mdl";
    }

    bool AddAmmo( CBaseEntity@ other )
    {
        return PickupObject( other, 1, "bts:battery", gpWeaponFlashlight.primary_maxammo );
    }
}
