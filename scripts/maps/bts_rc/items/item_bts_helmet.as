namespace items
{
    class item_bts_helmet : CItem
    {
        protected const string& GetModel() override {
            return "models/bshift/barney_helmet.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) || other.pev.armorvalue >= other.pev.armortype )
                return false;

            CBasePlayer@ player = cast<CBasePlayer@>( other );

            if( player is null || player_models::HasHazardSuit(player) || !player.TakeArmor( Math.RandomFloat( 7, 10 ), DMG_GENERIC ) )
                return false;

            PickupObject( player, "item_battery", "bts_rc/items/armor_pickup1.wav" );

            return true;
        }
    }
}
