namespace items
{
    class item_bts_sprayaid : BTS_Item
    {
        const string& get_m_PlaySound() override {
            return "items/medshot4.wav";
        }

        const string& get_m_Model() override {
            return "models/bts_rc/items/w_medkits.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) || other.pev.health >= other.pev.max_health || !other.TakeHealth( Math.RandomFloat( 10, 20 ), DMG_GENERIC ))
                return false;

            PickupObject( cast<CBasePlayer@>(other), "item_healthkit" );

            return true;
        }
    }
}
