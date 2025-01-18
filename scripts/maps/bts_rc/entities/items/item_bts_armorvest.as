namespace bts_items
{
    class item_bts_armorvest : ScriptBasePlayerItemEntity
    {
        void Spawn()
        {
            g_EntityFuncs.SetModel( self, "models/bshift/barney_vest.mdl" );
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

            player.pev.armorvalue += Math.RandomFloat( 20, 30 );

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

        void Touch( CBaseEntity@ other )
        {
            if( ( pev.spawnflags & item_f::TouchOnly ) == 0 )
                AddAmmo(other);
        }

        void Use( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE usetype, float value )
        {
            if( ( pev.spawnflags & item_f::UseOnly ) == 0 )
                AddAmmo(activator);
        }
    }
}
