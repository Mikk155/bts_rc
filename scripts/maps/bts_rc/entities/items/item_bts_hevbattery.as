namespace bts_items
{
    class item_bts_hevbattery : ScriptBasePlayerItemEntity
    {
        void Precache()
        {
            pev.model = ( pev.model != "" ? pev.model : string_t( "models/hlclassic/w_battery.mdl" ) );

            g_Game.PrecacheModel( self, string( pev.model ) );

            g_SoundSystem.PrecacheSound( "items/gunpickup2.wav" );

            BaseClass.Precache();
        }

        void Spawn()
        {
            Precache();

            g_EntityFuncs.SetModel( self, string( pev.model ) );

            BaseClass.Spawn();
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( other is null || !other.IsPlayer() || !other.IsAlive() )
                return false;

            CBasePlayer@ player = cast<CBasePlayer@>( other );

            if( player is null )
                return false;

            if( PM::HELMET != g_PlayerClass[ player, true ] )
                return false;

            if( player.pev.armorvalue >= player.pev.armortype )
                return false;

            player.pev.armorvalue += Math.RandomFloat( 10, 25 );

            if( player.pev.armorvalue > player.pev.armortype )
                player.pev.armorvalue = player.pev.armortype;

            // From CItemBattery at items.cpp
            NetworkMessage m( MSG_ONE, NetworkMessages::ItemPickup, player.edict() );
                m.WriteString( "item_battery" );
            m.End();

            if( PM::HELMET == g_PlayerClass[ player, true ] )
            {
                int pct = int( float( player.pev.armorvalue * 100.0 ) * ( 1.0 / 100 ) + 0.5 );

                pct = ( pct / 5 );

                if( pct > 0 )
                {
                    pct--;
                }

                string szcharge;
                snprintf( szcharge, "!HEV_%1P", pct );

                player.SetSuitUpdate( szcharge, false, 30 );
            }

            g_SoundSystem.EmitSound( player.edict(), CHAN_ITEM, "items/gunpickup2.wav", 1, ATTN_NORM );

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