namespace ammo
{
    void Register( dictionary@ data )
    {
        CustomEntity( "", true );
    }
}

class BTS_Ammo : BTS_Item
{
    protected string m_PickupSound;

    void Spawn()
    {
        if( !m_PickupSound.IsEmpty() )
        {
        }
    }

    bool PickupObject( CBasePlayer@ player, const int give, const string&in ammoName, const int max )
    {
        if( IsValid(player) && player.GiveAmmo( give, ammoName, max ) != -1 )
        {
            g_EntityFuncs.FireTargets( self.pev.target, player, self, USE_TOGGLE, 0, 0 );

            {
                NetworkMessage msg( MSG_ONE, NetworkMessages::AmmoPickup, player.edict() );
                    msg.WriteByte( g_PlayerFuncs.GetAmmoIndex( ammoName ) );
                    msg.WriteByte( give );
                msg.End();
            }

            if( !m_PickupSound.IsEmpty() )
            {
                g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, m_PickupSound, 1.0f, ATTN_NORM );
            }

            if( ( self.pev.spawnflags & 1 ) == 0 )
            {
                self.UpdateOnRemove();
                self.pev.flags |= FL_KILLME;
                self.pev.targetname = String::EMPTY_STRING;
            }
            return true;
        }
        return false;
    }
}
