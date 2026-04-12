namespace items
{
    class item_bts_hevsuit : BTS_Item
    {
        protected const string& GetModel() override {
            return "models/hlclassic/w_suit.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) )
                return false;

            CBasePlayer@ player = cast<CBasePlayer@>( other );

            auto character = GetCharacter(player);

            if( player is null || character is null || character.IsHEV || character.IsHazard )
                return false;

            SetClass( player, Classification::HEV );

            PickupObject( player );

            g_SoundSystem.EmitSoundSuit( player.edict(), "!HEV_A0" );

            return true; 
        }
    }
}
