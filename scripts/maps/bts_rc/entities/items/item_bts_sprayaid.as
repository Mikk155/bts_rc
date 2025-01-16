namespace bts_items
{
    class item_bts_sprayaid : ScriptBasePlayerItemEntity
    {
        void Precache()
        {
            pev.model = ( pev.model != "" ? pev.model : string_t( "models/bts_rc/items/w_medkits.mdl" ) );

            g_Game.PrecacheModel( self, string( pev.model ) );

            g_SoundSystem.PrecacheSound( "bts_rc/items/sprayaid1.wav" );

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

            if( player.pev.health >= player.pev.max_health )
                return false;

            player.TakeHealth( Math.RandomFloat( 10, 12 ), DMG_GENERIC );

            NetworkMessage m( MSG_ONE, NetworkMessages::ItemPickup, player.edict() );
                m.WriteString( "item_healthkit" );
            m.End();

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
