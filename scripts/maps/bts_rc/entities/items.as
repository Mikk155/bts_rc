namespace items
{
    const bool Register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_armorvest", "item_bts_armorvest" );
        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_helmet", "item_bts_helmet" );
        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_hevbattery", "item_bts_hevbattery" );
        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_sprayaid", "item_bts_sprayaid" );
        return true;
    }

    const bool IsRegistered = Register();

    class CItem : ScriptBasePlayerAmmoEntity
    {
        /// Get entity model. if pev.model is empty set to this.GetModel()
        string_t model {
            get {
                if( self.pev.model == "" )
                    self.pev.model = string_t( GetModel() );
                return self.pev.model;
            }
            set {
                self.pev.model = value;
            }
        }

        /// Override method to set a defaul model for this.model
        protected const string& GetModel() {
            return String::EMPTY_STRING;
        }

        void Spawn()
        {
            string pModel = this.GetModel();
            g_Game.PrecacheModel( self, pModel );
            g_EntityFuncs.SetModel( self, pModel );

            BaseClass.Spawn();
        }

        // Whatever player is not null, is a player and is alive
        bool IsValid( CBaseEntity@ player )
        {
            return( player !is null && player.IsPlayer() && player.IsAlive() );
        }

        void PickupObject( CBasePlayer@ player, const string&in name, const string&in sound )
        {
            g_EntityFuncs.FireTargets( self.pev.target, player, self, USE_TOGGLE, 0, 0 );

            NetworkMessage message( MSG_ONE, NetworkMessages::ItemPickup, player.edict() );
                message.WriteString( name );
            message.End();

            g_SoundSystem.EmitSound( player.edict(), CHAN_ITEM, sound, 1, ATTN_NORM );

            if( ( self.pev.spawnflags & 1 ) == 0 )
            {
                self.UpdateOnRemove();
                self.pev.flags |= FL_KILLME;
                self.pev.targetname = String::EMPTY_STRING;
            }
        }
    }

    class item_bts_armorvest : CItem
    {
        protected const string& GetModel() override {
            return "models/bshift/barney_vest.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) || other.pev.armorvalue >= other.pev.armortype )
                return false;

            CBasePlayer@ player = cast<CBasePlayer@>( other );

            if( player is null || player_models::CanPickBattery(player) || !player.TakeArmor( Math.RandomFloat( 20, 30 ), DMG_GENERIC ) )
                return false;

            PickupObject( player, "item_battery", "bts_rc/items/armor_pickup1.wav" );

            return true;
        }
    }

    class item_bts_helmet : CItem
    {
        protected const string& GetModel() override {
            return "models/bshift/barney_helmet.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) || other.pev.armorvalue >= other.pev.armortype )
                return false;

            CBasePlayer@ player = cast<CBasePlayer@>( other );

            if( player is null || player_models::CanPickBattery(player) || !player.TakeArmor( Math.RandomFloat( 7, 10 ), DMG_GENERIC ) )
                return false;

            PickupObject( player, "item_battery", "bts_rc/items/armor_pickup1.wav" );

            return true;
        }
    }

    class item_bts_hevbattery : CItem
    {
        protected const string& GetModel() override {
            return "models/bts_rc/weapons/w_battery.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) || other.pev.armorvalue >= other.pev.armortype )
                return false;

            CBasePlayer@ player = cast<CBasePlayer@>( other );

            if( player is null || !player_models::CanPickBattery(player) || !player.TakeArmor( Math.RandomFloat( 10, 25 ), DMG_GENERIC ) )
                return false;

            if( player_models::IsHEV( player ) )
            {
                int pct = int( float( player.pev.armorvalue * 100.0 ) * ( 1.0 / 100 ) + 0.5 );

                pct = ( pct / 5 );

                if( pct > 0 )
                    pct--;

                string szcharge;
                snprintf( szcharge, "!HEV_%1P", pct );

                player.SetSuitUpdate( szcharge, false, 30 );
            }

            PickupObject( player, "item_battery", "items/gunpickup2.wav" );

            return true;
        }
    }

    class item_bts_sprayaid : CItem
    {
        protected const string& GetModel() override {
            return "models/bts_rc/weapons/w_medkits.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) || other.pev.health >= other.pev.max_health || !other.TakeHealth( Math.RandomFloat( 10, 20 ), DMG_GENERIC ))
                return false;

            PickupObject( cast<CBasePlayer@>(other), "item_healthkit", "items/medshot4.wav" );

            return true;
        }
    }
}
