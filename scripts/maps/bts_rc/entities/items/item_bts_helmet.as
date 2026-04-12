namespace items
{
    class item_bts_helmet : BTS_Item
    {
        const string& get_m_PlaySound() override {
            return "bts_rc/items/armor_pickup1.wav";
        }

        protected const string& GetModel() override {
            return "models/bshift/barney_helmet.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) || other.pev.armorvalue >= other.pev.armortype )
                return false;

            CBasePlayer@ player = cast<CBasePlayer@>( other );

            auto character = GetCharacter(player);

            if( player is null || character is null || character.IsHEV || character.IsHazard || !player.TakeArmor( Math.RandomFloat( 7, 10 ), DMG_GENERIC ) )
                return false;

            PickupObject( player, "item_battery" );

            return true;
        }
    }
}
