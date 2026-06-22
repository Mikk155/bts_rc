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

#include "item_bts_armorvest"
#include "item_bts_clsuit"
#include "item_bts_helmet"
#include "item_bts_hevbattery"
#include "item_bts_hevsuit"
#include "item_bts_skeleton"
#include "item_bts_sprayaid"

final class ASItemsConfig : IConfigurableContext
{
    const string& GetName() const override
    {
        return "items";
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Items",
            "description": "Control items configuration",
            "properties":
            {
                "battery_lighting":
                {
                    "title": "Lighting battery",
                    "type": "boolean",
                    "description": "If enabled, HEV batteries will emit a blue dynamic light.",
                    "default": true
                }
            }
        }""";
    }

    private bool m_BatteryLighting;

    const bool get_BatteryLighting() const {
        return this.m_BatteryLighting;
    }

    bool Register( meta_api::json::v2::json@ config ) override
    {
        this.m_BatteryLighting = bool( config[ "battery_lighting" ] );

        CustomEntity( "item_bts_armorvest", true );
        CustomEntity( "item_bts_clsuit", true );
        CustomEntity( "item_bts_helmet", true );
        CustomEntity( "item_bts_hevbattery", true );
        CustomEntity( "item_bts_hevsuit", true );
        CustomEntity( "item_bts_skeleton", true );
        CustomEntity( "item_bts_sprayaid", true );

        return true;
    }
}

ASItemsConfig gpItemsConfig;

abstract class BTS_Item : ScriptBasePlayerAmmoEntity
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
        int seq = self.pev.sequence;

        Precache();

        g_EntityFuncs.SetModel( self, this.model );

        const auto entitySize = this.m_Size;

        g_EntityFuncs.SetSize( self.pev, entitySize[0], entitySize[1] );

        BaseClass.Spawn();

        g_EntityFuncs.SetSize( self.pev, entitySize[0], entitySize[1] );

        self.pev.sequence = seq;
    }

    // Whatever player is not null, is a player and is alive
    bool IsValid( CBaseEntity@ player )
    {
        return( player !is null && player.IsPlayer() && player.IsAlive() );
    }

    void PickupObject( CBasePlayer@ player, const string&in name = String::EMPTY_STRING )
    {
        g_EntityFuncs.FireTargets( self.pev.target, player, self, USE_TOGGLE, 0, 0 );

        if( g_Logger.trace.active )
            g_Logger.trace.print( "Added {} to player {}", { self.pev.classname, player.pev.netname } );

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
