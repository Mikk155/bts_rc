namespace items
{
    const bool Register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_armorvest", "item_bts_armorvest" );
        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_helmet", "item_bts_helmet" );
        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_hevbattery", "item_bts_hevbattery" );
        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_hevsuit", "item_bts_hevsuit" );
        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_clsuit", "item_bts_clsuit" );
        g_CustomEntityFuncs.RegisterCustomEntity( "items::item_bts_sprayaid", "item_bts_sprayaid" );
        return true;
    }

    const bool IsRegistered = Register();

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

        void Spawn()
        {
            string pModel = this.model;
            g_Game.PrecacheModel( self, pModel );
            g_EntityFuncs.SetModel( self, pModel );

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

            if( player is null || player_models::HasHazardSuit(player) || !player.TakeArmor( Math.RandomFloat( 20, 30 ), DMG_GENERIC ) )
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

            if( player is null || player_models::HasHazardSuit(player) || !player.TakeArmor( Math.RandomFloat( 7, 10 ), DMG_GENERIC ) )
                return false;

            PickupObject( player, "item_battery", "bts_rc/items/armor_pickup1.wav" );

            return true;
        }
    }

    class item_bts_hevbattery : CItem
    {
        CSprite@ m_Sprite;

        protected const string& GetModel() override {
            return "models/bts_rc/weapons/w_battery.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) || other.pev.armorvalue >= other.pev.armortype )
                return false;

            CBasePlayer@ player = cast<CBasePlayer@>( other );

            if( player is null || !player_models::HasHazardSuit(player) || !player.TakeArmor( Math.RandomFloat( 10, 25 ), DMG_GENERIC ) )
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

            g_EntityFuncs.Remove( m_Sprite );

            PickupObject( player, "item_battery", "items/gunpickup2.wav" );

            return true;
        }

        void UpdateOnRemove()
        {
            g_EntityFuncs.Remove( m_Sprite );
        }

        void Think()
        {
            self.pev.nextthink = g_Engine.time + 0.1f;

            if( m_Sprite is null )
            {
                @m_Sprite = g_EntityFuncs.CreateSprite( "sprites/glow01.spr", g_vecZero, true );
                m_Sprite.pev.rendermode = kRenderGlow;
                m_Sprite.pev.renderamt = 255;
                m_Sprite.pev.rendercolor.x = 50;
                m_Sprite.pev.rendercolor.y = 100;
                m_Sprite.pev.rendercolor.z = 255;
            }

            m_Sprite.pev.origin = self.pev.origin;
            m_Sprite.pev.origin.z += 4;

            // Unreliable, PVS
            NetworkMessage message( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
                message.WriteByte( TE_DLIGHT );
                message.WriteCoord( m_Sprite.pev.origin.x );
                message.WriteCoord( m_Sprite.pev.origin.y );
                message.WriteCoord( m_Sprite.pev.origin.z );
                message.WriteByte( 4 );   // radius
                message.WriteByte( 50 ); // R
                message.WriteByte( 100 );   // G
                message.WriteByte( 255 );   // B
                message.WriteByte( 30 );   // life in 0.1's
                message.WriteByte( 1 );   // decay in 0.1's
            message.End();
        }
    }

    class item_bts_sprayaid : CItem
    {
        protected const string& GetModel() override {
            return "models/bts_rc/items/w_medkits.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) || other.pev.health >= other.pev.max_health || !other.TakeHealth( Math.RandomFloat( 10, 20 ), DMG_GENERIC ))
                return false;

            PickupObject( cast<CBasePlayer@>(other), "item_healthkit", "items/medshot4.wav" );

            return true;
        }
    }

    class item_bts_hevsuit : CItem
    {
        protected const string& GetModel() override {
            return "models/hlclassic/w_suit.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) )
                return false;

            CBasePlayer@ player = cast<CBasePlayer@>( other );

            if( player is null || player_models::HasHazardSuit(player) )
                return false;

            if( player_models::IsTrainedPersonal(player) )
                player_models::SetClass( player, PM::HELMET );
            else
                player_models::SetClass( player, PM::HELMET_CIVIL );

            PickupObject( player );

            g_SoundSystem.EmitSoundSuit( player.edict(), "!HEV_A0" );

            return true; 
        }
    }

    class item_bts_clsuit : CItem
    {
        protected const string& GetModel() override {
            return "models/w_hazmat.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) )
                return false;

            CBasePlayer@ player = cast<CBasePlayer@>( other );

            if( player is null || player_models::HasHazardSuit(player) )
                return false;

            if( player_models::IsTrainedPersonal(player) )
                player_models::SetClass( player, PM::CLSUIT );
            else
                player_models::SetClass( player, PM::CLSUIT_CIVIL );

            PickupObject( player );

            return true;
        }
    }
}
