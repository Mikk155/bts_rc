/*
    Author: Mikk
*/

void PlayerFadeOutScreen( CBasePlayer@ player, Vector color )
{
    if( player !is null )
    {
        g_PlayerFuncs.ScreenFade(player, color, 1.0f, 0.0f, 255.0f, FFADE_IN );
    }
}

namespace trigger_update_class
{
    HUDTextParams msgParams;

    void AddItemInventory( CBasePlayer@ player, dictionary@ kvObj )
    {
        if( player !is null )
        {
            auto entity = g_EntityFuncs.CreateEntity( "item_inventory", kvObj );

            if( entity !is null )
            {
                entity.Touch( player );
            }
        }
    }

    void AddItems( CBasePlayer@ player, dictionary@ kvObj )
    {
        array<string> keys = kvObj.getKeys();

        for( uint ui = 0; ui < keys.length(); ui++ )
            for( int i = 0; i < int( kvObj[keys[ui]] ); i++ )
                player.GiveNamedItem( keys[ui], SF_GIVENITEM ); // Somehow the third argument is not working so we iterate
    }

    void AddKeyCard( CBasePlayer@ player, dictionary@ kvObj )
    {
        if( player !is null )
        {
            if( !kvObj.exists( "model" ) )
                kvObj["model"] = "models/w_security.mdl";
            if( !kvObj.exists( "delay" ) )
                kvObj["delay"] = "0";
            if( !kvObj.exists( "holder_timelimit_wait_until_activated" ) )
                kvObj["holder_timelimit_wait_until_activated"] = "0";
            if( !kvObj.exists( "m_flCustomRespawnTime" ) )
                kvObj["m_flCustomRespawnTime"] = "0";
            if( !kvObj.exists( "holder_keep_on_death" ) )
                kvObj["holder_keep_on_death"] = "0";
            if( !kvObj.exists( "holder_keep_on_respawn" ) )
                kvObj["holder_keep_on_respawn"] = "0";
            if( !kvObj.exists( "holder_can_drop" ) )
                kvObj["holder_can_drop"] = "1";
            if( !kvObj.exists( "carried_hidden" ) )
                kvObj["carried_hidden"] = "1";
            if( !kvObj.exists( "return_timelimit" ) )
                kvObj["return_timelimit"] = "-1";

            AddItemInventory( player, kvObj );
        }
    }

    void EquipPlayer( CBasePlayer@ player )
    {
        if( player is null )
            return;

        string buffer;
        string role;
        string title;
        Vector color;

        auto player_class = player_models::GetClass( player );

        switch( player_class )
        {
        case PM::BARNEY:
        {
            role = "Security";
            title = "Blackmesa Security Force";
            color = Vector( 0, 170, 255 );

            AddKeyCard( player, { { "skin", "3" }, { "description", "Blackmesa Security Clearance level 1" }, { "display_name", "Security Keycard lvl 1" }, { "item_name", "Blackmesa_Security_Clearance_1" }, { "item_icon", "bts_rc/inv_card_security.spr" }, { "item_group", "security" } } );

            // Otis
            if( string( player.GetUserData()[ "pm" ] ).StartsWith( "bts_otis" ) )
            {
                if( Math.RandomLong( 1, 3 ) == 2 )
                {
                    snprintf( buffer, "Shotgun (w/ Flashlight" );
                    AddItems( player, { { "weapon_bts_sbshotgun", 1 }, { "ammo_bts_sbshotgun", 4 }, { "item_bts_armorvest", 1 }, { "item_bts_helmet", 1 } } );
                    break;
                }

                snprintf( buffer, "Desert Eagle, Flashlight" );
                AddItems( player, { { "weapon_bts_eagle", 1 }, { "ammo_bts_eagle", 4 }, { "weapon_bts_flashlight", 1 }, { "item_bts_armorvest", 1 }, { "item_bts_helmet", 1 } } );
                break;
            }

            string barney_ammo_type = "ammo_9mmclip";
            string barney_wpn_type = "weapon_bts_glock17f";

            switch( Math.RandomLong( 0, 3 ) )
            {
                case 0:
                    barney_wpn_type = "weapon_bts_beretta";
                    snprintf( buffer, "M9 Beretta, Flashlight" );
                break;
                case 1:
                    barney_wpn_type = "weapon_bts_glock";
                    snprintf( buffer, "Glock 17, Flashlight" );
                break;
                case 2:
                    barney_wpn_type = "weapon_bts_glock17f";
                    snprintf( buffer, "Glock 17 (w/ flashlight), Flashlight" );
                break;
                case 3:
                    barney_wpn_type = "weapon_bts_sw637";
                    barney_ammo_type = "ammo_bts_sw637";
                    snprintf( buffer, "Smith & Wesson 637, Flashlight" );
                break;
            }

            AddItems( player, { { barney_wpn_type, 1 }, { barney_ammo_type, 2 }, { "weapon_bts_flashlight", 1 }, { "item_bts_helmet", 1 }, { "item_bts_armorvest", 1 } } );
            break;
        }
        case PM::SCIENTIST:
        {
            role = "Scientist";
            title = "Blackmesa Science team";
            color = Vector( 0, 255, 93 );

            AddKeyCard( player, { { "skin", "2" }, { "description", "Blackmesa Research Clearance level 1" }, { "display_name", "Research Keycard lvl 1" }, { "item_name", "Blackmesa_Research_Clearance_1" }, { "item_icon", "bts_rc/inv_card_research.spr" } } );

            switch( Math.RandomLong( 0, 4 ) )
            {
                case 0:
                    snprintf( buffer, "Screwdriver, Flashlight, Medkit" );
                    AddItems( player, { { "weapon_bts_screwdriver", 1 }, { "weapon_bts_flashlight", 1 }, { "weapon_medkit", 1 } } );
                break;
                case 1:
                    snprintf( buffer, "Flashlight, Medkit" );
                    AddItems( player, { { "weapon_bts_flashlight", 1 }, { "weapon_medkit", 1 }, { "ammo_medkit", 3 } } );
                break;
                case 2:
                    snprintf( buffer, "Pipe, Medkit" );
                    AddItems( player, { { "weapon_bts_pipe", 1 }, { "weapon_medkit", 1 }, { "ammo_medkit", 5 } } );
                break;
                case 3:
                    snprintf( buffer, "Pipe, Flashlight, Medkit" );
                    AddItems( player, { { "weapon_bts_pipe", 1 }, { "weapon_bts_flashlight", 1 }, { "weapon_medkit", 1 } } );
                break;
                case 4:
                default:
                    snprintf( buffer, "Poolstick, Medkit" );
                    AddItems( player, { { "weapon_bts_poolstick", 1 }, { "weapon_medkit", 1 }, { "ammo_medkit", 5 } } );
                break;
            }
            break;
        }
        case PM::CONSTRUCTION:
        {
            role = "Maintenance";
            title = "Blackmesa Maintenance";
            color = Vector( 255, 255, 127 );

            AddItemInventory( player, { { "model", "models/bts_rc/items/tool_box.mdl" }, { "skin", "1" }, { "delay", "0" }, { "holder_timelimit_wait_until_activated", "0" }, { "m_flCustomRespawnTime", "0" }, { "holder_keep_on_death", "0" }, { "holder_keep_on_respawn", "0" }, { "weight", "10" }, { "carried_hidden", "0" }, { "carried_body", "1" }, { "holder_can_drop", "1" }, { "return_timelimit", "-1" }, { "scale", "0.8" }, { "item_icon", "bts_rc/inv_card_maint.spr" }, { "item_name", "GM_TOOLBOX_SPECIAL" }, { "item_group", "TOOLBOX" }, { "description", "This Toolbox can be used for yellow and orange repair markers,(10 SLOTS)" }, { "display_name", "Engineers Toolbox" } } );

            switch( Math.RandomLong( 0, 8 ) )
            {
                case 0:
                    snprintf( buffer, "Pipewrench, Flashlight" );
                    AddItems( player, { { "weapon_bts_pipewrench", 1 }, { "item_bts_helmet", 3 }, { "weapon_bts_flashlight", 1 } } );
                break;
                case 1:
                    snprintf( buffer, "Crowbar, Flashlight" );
                    AddItems( player, { { "weapon_bts_crowbar", 1 }, { "item_bts_helmet", 3 }, { "weapon_bts_flashlight", 1 } } );
                break;
                case 2:
                    snprintf( buffer, "Crowbar, Flares" );
                    AddItems( player, { { "weapon_bts_crowbar", 1 }, { "item_bts_helmet", 3 }, { "weapon_bts_flare", 5 } } );
                break;
                case 3:
                    snprintf( buffer, "Pipe, Flares" );
                    AddItems( player, { { "weapon_bts_pipe", 1 }, { "item_bts_helmet", 3 }, { "weapon_bts_flare", 5 } } );
                break;
                case 4:
                    snprintf( buffer, "Pipe wrench, Flashlight" );
                    AddItems( player, { { "weapon_bts_pipe", 1 }, { "item_bts_helmet", 3 }, { "weapon_bts_flashlight", 1 } } );
                break;
                case 6:
                    snprintf( buffer, "Screwdriver, Flashlight" );
                    AddItems( player, { { "weapon_bts_screwdriver", 1 }, { "item_bts_helmet", 3 }, { "weapon_bts_flashlight", 1 } } );
                break;
                case 7:
                    snprintf( buffer, "Flares, Flashlight" );
                    AddItems( player, { { "weapon_bts_flare", 6 }, { "item_bts_helmet", 3 }, { "weapon_bts_flashlight", 1 } } );
                break;
                case 8:
                default:
                    snprintf( buffer, "Axe, Flashlight" );
                    AddItems( player, { { "weapon_bts_axe", 1 }, { "item_bts_helmet", 3 }, { "weapon_bts_flashlight", 1 } } );
                break;
            }
            break;
        }
        case PM::HELMET:
        case PM::HELMET_CIVIL:
        {
            return;
        }
        case PM::CLSUIT:
        case PM::CLSUIT_CIVIL:
        {
            return;
        }
        case PM::OPERATIVE:
        {
            break;
        }
        default:
        break;
        }

        snprintf( buffer, "%1\n%2 Enrolled as %3\nWith: %4", title, player.pev.netname, role, buffer );
        g_PlayerFuncs.HudMessageAll( msgParams, buffer );
        g_PlayerFuncs.ScreenFade( player, color, 0.25f, 1.0f, 255.0f, FFADE_OUT );
        g_Scheduler.SetTimeout( "PlayerFadeOutScreen", 1.0f, @player, color );
    }

    class trigger_update_class : ScriptBaseEntity
    {
        private PM m_class = PM::SCIENTIST;

        void Spawn()
        {
            msgParams.x = 0;
            msgParams.y = 0;
            msgParams.effect = 2;
            msgParams.r1 = 255;
            msgParams.g1 = 255;
            msgParams.b1 = 255;
            msgParams.a1 = 0;
            msgParams.r2 = 240;
            msgParams.g2 = 110;
            msgParams.b2 = 0;
            msgParams.a2 = 0;
            msgParams.fadeinTime = 0.05f;
            msgParams.fadeoutTime = 0.5f;
            msgParams.holdTime = 1.2f;
            msgParams.fxTime = 0.025f;
            msgParams.channel = 5;

            self.pev.movetype = MOVETYPE_NONE;
            self.pev.effects |= EF_NODRAW;
            self.pev.solid = SOLID_NOT;
        }

        bool KeyValue( const string& in szKeyName, const string& in szValue )
        {
            if( szKeyName == 'm_class' )
            {
                m_class = PM( atoi( szValue ) );
                return true;
            }
            return BaseClass.KeyValue( szKeyName, szValue );
        }

        void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
        {
            if( pActivator is null || !pActivator.IsPlayer() )
                return;

            auto player = cast<CBasePlayer@>( pActivator );

            if( player is null )
                return;

            string playerName = string( player.pev.netname );

            player_models::SetClass( player, m_class );

            EquipPlayer( player );
        }
    }
}
