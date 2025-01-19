namespace bts_items
{
    class item_bts_helmet : ScriptBasePlayerAmmoEntity
    {
        void Spawn()
        {
            g_EntityFuncs.SetModel( self, "models/bshift/barney_helmet.mdl" );
            BaseClass.Spawn();
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( other is null || !other.IsPlayer() || !other.IsAlive() )
                return false;

            CBasePlayer@ player = cast<CBasePlayer@>( other );

            if( player is null )
                return false;

            if( PM::HELMET == g_PlayerClass[ player, true ] )
                return false;

            if( player.pev.armorvalue >= player.pev.armortype )
                return false;

            player.pev.armorvalue += Math.RandomFloat( 7, 10 );

            if( player.pev.armorvalue > player.pev.armortype )
                player.pev.armorvalue = player.pev.armortype;

            // From CItemBattery at items.cpp
            NetworkMessage m( MSG_ONE, NetworkMessages::ItemPickup, player.edict() );
                m.WriteString( "item_battery" );
            m.End();

            g_SoundSystem.EmitSound( player.edict(), CHAN_ITEM, "bts_rc/items/armor_pickup1.wav", 1, ATTN_NORM );

            self.UpdateOnRemove();
            pev.flags |= FL_KILLME;
            pev.targetname = String::EMPTY_STRING;

            return true;
        }
    }
}
