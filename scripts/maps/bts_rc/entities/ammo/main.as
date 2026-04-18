/**   MIT License
*   
*   Copyright (c) 2025 Mikk155 https://github.com/Mikk155/bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies or substantial portions of the Software.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*   SOFTWARE.
*/

#include "ammo_bts_beretta"

namespace ammo
{
    void Register( dictionary@ data )
    {
        CustomEntity( "ammo_bts_beretta", true );
    }
}

class BTS_Ammo : BTS_Item
{
    bool PickupObject( CBaseEntity@ player, const int give, const string&in ammoName, const int max )
    {
        if( IsValid( player ) && player.GiveAmmo( give, ammoName, max ) != -1 )
        {
            g_EntityFuncs.FireTargets( self.pev.target, player, self, USE_TOGGLE, 0, 0 );

            {
                NetworkMessage msg( MSG_ONE, NetworkMessages::AmmoPickup, player.edict() );
                    msg.WriteByte( g_PlayerFuncs.GetAmmoIndex( ammoName ) );
                    msg.WriteByte( give );
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
