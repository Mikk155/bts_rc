#include "item_bts_armorvest"
#include "item_bts_clsuit"
#include "item_bts_helmet"
#include "item_bts_hevbattery"
#include "item_bts_hevsuit"
#include "item_bts_skeleton"
#include "item_bts_sprayaid"

namespace items
{
    bool gpBatteryLighting;

    void Register( dictionary@ data )
    {
        data.get( "battery_lighting", gpBatteryLighting );

        CustomEntity( "item_bts_armorvest", true );
        CustomEntity( "item_bts_clsuit", true );
        CustomEntity( "item_bts_helmet", true );
        CustomEntity( "item_bts_hevbattery", true );
        CustomEntity( "item_bts_hevsuit", true );
        CustomEntity( "item_bts_skeleton", true );
        CustomEntity( "item_bts_sprayaid", true );
    }
}

class BTS_Item : ScriptBasePlayerAmmoEntity
{
    /// Override method to play the given sound on pickup
    const string& get_m_PlaySound() {
        return String::EMPTY_STRING;
    }

    /// Override method to set a defaul model for this.model
    const string& get_m_Model() {
        return String::EMPTY_STRING;
    }

    /// Get entity model. if pev.model is empty set to this.GetModel()
    string model {
        get {
            string mdl = string( self.pev.model );
            if( mdl.IsEmpty() )
            {
                mdl = this.m_Model;
                self.pev.model = string_t(mdl);
            }
            return mdl;
        }
        set {
            self.pev.model = string_t( value );
        }
    }

    const array<Vector>@ get_m_Size() {
        return { Vector( -8, -8, -8 ), Vector( 8, 8, 8 ) };
    }

    void Precache()
    {
        const string pickupSound = m_PlaySound;

        if( !pickupSound.IsEmpty() )
        {
            string buffer;
            snprintf( buffer, "sound/%1", pickupSound );
            g_Game.PrecacheGeneric( buffer );
            g_SoundSystem.PrecacheSound( pickupSound );
        }

        g_Game.PrecacheModel( self, this.model );
    }

    void Spawn()
    {
        Precache();

        g_EntityFuncs.SetModel( self, this.model );

        auto entitySize = this.m_Size;

        g_EntityFuncs.SetSize( self.pev, entitySize[0], entitySize[1] );

        BaseClass.Spawn();

        g_EntityFuncs.SetSize( self.pev, entitySize[0], entitySize[1] );
    }

    // Whatever player is not null, is a player and is alive
    bool IsValid( CBaseEntity@ player )
    {
        return( player !is null && player.IsPlayer() && player.IsAlive() );
    }

    void PickupObject( CBasePlayer@ player, const string&in name = String::EMPTY_STRING )
    {
        g_EntityFuncs.FireTargets( self.pev.target, player, self, USE_TOGGLE, 0, 0 );

        if( !name.IsEmpty() )
        {
            NetworkMessage message( MSG_ONE, NetworkMessages::ItemPickup, player.edict() );
                message.WriteString( name );
            message.End();
        }

        const string pickupSound = m_PlaySound;

        if( !pickupSound.IsEmpty() )
        {
            g_SoundSystem.EmitSound( player.edict(), CHAN_ITEM, pickupSound, 1, ATTN_NORM );
        }

        if( ( self.pev.spawnflags & 1 ) == 0 )
        {
            self.UpdateOnRemove();
            self.pev.flags |= FL_KILLME;
            self.pev.targetname = String::EMPTY_STRING;
        }
    }
}
