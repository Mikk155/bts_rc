class ammo_bts_beretta : BTS_Ammo
{
    const string& get_m_PlaySound() override {
        return "hlclassic/items/9mmclip1.wav";
    }

    const string& get_m_Model() override {
        return "models/hlclassic/w_9mmclip.mdl";
    }

    bool AddAmmo( CBaseEntity@ other )
    {
        return PickupObject( other, 12, "9mm", 12 );
    }
}
