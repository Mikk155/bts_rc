/**
*   Copyright (c) 2026 Mikk155 and contributors of bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software to use, copy, modify, merge, publish, distribute, sublicense,
*   and/or sell copies of the Software under the following conditions:
*   
*   A reference to the original project must be included in all copies or substantial
*   portions of the Software. This must include, at minimum, a URL to:
*   https://github.com/Mikk155/bts_rc
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies of the Software when distributed as a whole.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
**/

#include "ammo_bts_beretta"
#include "ammo_bts_flashlight"

class BTS_Ammo : BTS_Item
{
    bool PickupObject( CBaseEntity@ player, const int give, const string&in ammoName, const int max )
    {
        int finalGive = gpDynamicAmmo.GetAmmoGive( ammoName, give );

        if( IsValid( player ) && player.GiveAmmo( finalGive, ammoName, max ) != -1 )
        {
            g_EntityFuncs.FireTargets( self.pev.target, player, self, USE_TOGGLE, 0, 0 );

            {
                NetworkMessage msg( MSG_ONE, NetworkMessages::AmmoPickup, player.edict() );
                    msg.WriteByte( g_PlayerFuncs.GetAmmoIndex( ammoName ) );
                    msg.WriteByte( finalGive );
                msg.End();
            }

            const string pickupSound = m_PlaySound;

            if( !pickupSound.IsEmpty() )
            {
                g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, pickupSound, 1.0f, ATTN_NORM );
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
