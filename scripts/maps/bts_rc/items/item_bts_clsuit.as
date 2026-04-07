namespace items
{
    class item_bts_clsuit : CItem
    {
        protected const string& GetModel() override {
            return "models/w_hazmat.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) )
                return false;

            CBasePlayer@ player = cast<CBasePlayer@>( other );

            if( player is null || player_models::HasHazardSuit(player) )
                return false;

            if( player_models::IsTrainedPersonal(player) )
                player_models::SetClass( player, PM::CLSUIT );
            else
                player_models::SetClass( player, PM::CLSUIT_CIVIL );

            PickupObject( player );

            return true;
        }
    }
}
