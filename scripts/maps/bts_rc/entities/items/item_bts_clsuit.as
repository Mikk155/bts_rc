namespace items
{
    class item_bts_clsuit : BTS_Item
    {
        const string& get_m_Model() override {
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

            PickupObject( player, "suit_empty" );

            return true;
        }
    }
}
