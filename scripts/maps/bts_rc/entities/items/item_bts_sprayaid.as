namespace items
{
    class item_bts_sprayaid : CItem
    {
        protected const string& GetModel() override {
            return "models/bts_rc/items/w_medkits.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) || other.pev.health >= other.pev.max_health || !other.TakeHealth( Math.RandomFloat( 10, 20 ), DMG_GENERIC ))
                return false;

            PickupObject( cast<CBasePlayer@>(other), "item_healthkit", "items/medshot4.wav" );

            return true;
        }
    }
}
