class item_bts_sprayaid : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/bts_rc/items/w_medkits.mdl" );
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
}
