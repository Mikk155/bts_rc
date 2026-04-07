namespace items
{
    class item_bts_hevsuit : CItem
    {
        protected const string& GetModel() override {
            return "models/hlclassic/w_suit.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) )
                return false;

            CBasePlayer@ player = cast<CBasePlayer@>( other );

            if( player is null || player_models::HasHazardSuit(player) )
                return false;

            if( player_models::IsTrainedPersonal(player) )
                player_models::SetClass( player, PM::HELMET );
            else
                player_models::SetClass( player, PM::HELMET_CIVIL );

            PickupObject( player );

            g_SoundSystem.EmitSoundSuit( player.edict(), "!HEV_A0" );

            return true; 
        }
    }
}
