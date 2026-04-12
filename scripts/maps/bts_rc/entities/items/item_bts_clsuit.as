namespace items
{
    class item_bts_clsuit : BTS_Item
    {
        protected const string& GetModel() override {
            return "models/w_hazmat.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) )
                return false;

            CBasePlayer@ player = cast<CBasePlayer@>( other );

            auto character = GetCharacter(player);

            if( player is null || character is null || character.IsHEV || character.IsHazard )
                return false;

            SetClass( player, Classification::Hazard );

            PickupObject( player );

            return true;
        }
    }
}
