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

        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_armorvest", "item_bts_armorvest" );
        g_Game.PrecacheOther( "item_bts_armorvest" );
        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_clsuit", "item_bts_clsuit" );
        g_Game.PrecacheOther( "item_bts_clsuit" );
        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_helmet", "item_bts_helmet" );
        g_Game.PrecacheOther( "item_bts_helmet" );
        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_hevbattery", "item_bts_hevbattery" );
        g_Game.PrecacheOther( "item_bts_hevbattery" );
        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_hevsuit", "item_bts_hevsuit" );
        g_Game.PrecacheOther( "item_bts_hevsuit" );
        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_skeleton", "item_bts_skeleton" );
        g_Game.PrecacheOther( "item_bts_skeleton" );
        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_sprayaid", "item_bts_sprayaid" );
        g_Game.PrecacheOther( "item_bts_sprayaid" );
    }

    class CItem : ScriptBasePlayerAmmoEntity
    {
        /// Get entity model. if pev.model is empty set to this.GetModel()
        string model {
            get {
                string mdl = string( self.pev.model );
                if( mdl.IsEmpty() )
                {
                    mdl = this.GetModel();
                    self.pev.model = string_t(mdl);
                }
                return mdl;
            }
            set {
                self.pev.model = string_t( value );
            }
        }

        /// Override method to set a defaul model for this.model
        protected const string& GetModel() {
            return String::EMPTY_STRING;
        }

        void Precache()
        {
            g_Game.PrecacheModel( self, this.model );
        }

        void Spawn()
        {
            Precache();

            g_EntityFuncs.SetModel( self, this.model );

            BaseClass.Spawn();

            g_EntityFuncs.SetSize( self.pev, Vector( -8, -8, -8 ), Vector( 8, 8, 8 ) );
        }

        // Whatever player is not null, is a player and is alive
        bool IsValid( CBaseEntity@ player )
        {
            return( player !is null && player.IsPlayer() && player.IsAlive() );
        }

        void PickupObject( CBasePlayer@ player, const string&in name = String::EMPTY_STRING, const string&in sound = String::EMPTY_STRING )
        {
            g_EntityFuncs.FireTargets( self.pev.target, player, self, USE_TOGGLE, 0, 0 );

            if( !name.IsEmpty() )
            {
                NetworkMessage message( MSG_ONE, NetworkMessages::ItemPickup, player.edict() );
                    message.WriteString( name );
                message.End();
            }

            if( !sound.IsEmpty() )
            {
                g_SoundSystem.EmitSound( player.edict(), CHAN_ITEM, sound, 1, ATTN_NORM );
            }

            if( ( self.pev.spawnflags & 1 ) == 0 )
            {
                self.UpdateOnRemove();
                self.pev.flags |= FL_KILLME;
                self.pev.targetname = String::EMPTY_STRING;
            }
        }
    }
}