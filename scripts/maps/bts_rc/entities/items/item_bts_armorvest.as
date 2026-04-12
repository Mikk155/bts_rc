namespace items
{
    class item_bts_armorvest : CItem
    {
        protected const string& GetModel() override {
            return "models/bshift/barney_vest.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) || other.pev.armorvalue >= other.pev.armortype )
                return false;

            CBasePlayer@ player = cast<CBasePlayer@>( other );
            auto character = GetCharacter(player);

            if( player is null || character is null || character.IsHEV || character.IsHazard || !player.TakeArmor( Math.RandomFloat( 20, 30 ), DMG_GENERIC ) )
                return false;

            PickupObject( player, "item_battery", "bts_rc/items/armor_pickup1.wav" );

            return true;
        }
    }
}
