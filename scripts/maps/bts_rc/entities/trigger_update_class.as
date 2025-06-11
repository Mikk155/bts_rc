/*
    Author: Mikk
*/

namespace trigger_update_class
{
    HUDTextParams msgParams;

    enum LoadOut
    {
        Nothing = -1,
        Security = 0,
        Scientist = 1,
        Constructor = 2,
        Solo = 3
    };

    class trigger_update_class : ScriptBaseEntity
    {
        private PM m_class = PM::SCIENTIST;
        private LoadOut m_loadout = LoadOut::Nothing;

        void AddItems( CBasePlayer@ player, dictionary@ kvObj )
        {
            array<string> keys = kvObj.getKeys();

            for( uint ui = 0; ui < keys.length(); ui++ )
                for( int i = 0; i < int(kvObj[keys[ui]]); i++ )
                    player.GiveNamedItem( keys[ui], SF_GIVENITEM ); // Somehow the third argument is not working so we iterate
        }

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

        void AddKeyCard( CBasePlayer@ player, dictionary@ kvObj )
        {
            if( player !is null )
            {
                if( !kvObj.exists( "model" ) )
                    kvObj[ "model" ] = "models/w_security.mdl";
                if( !kvObj.exists( "delay" ) )
                    kvObj[ "delay" ] = "0";
                if( !kvObj.exists( "holder_timelimit_wait_until_activated" ) )
                    kvObj[ "holder_timelimit_wait_until_activated" ] = "0";
                if( !kvObj.exists( "m_flCustomRespawnTime" ) )
                    kvObj[ "m_flCustomRespawnTime" ] = "0";
                if( !kvObj.exists( "holder_keep_on_death" ) )
                    kvObj[ "holder_keep_on_death" ] = "0";
                if( !kvObj.exists( "holder_keep_on_respawn" ) )
                    kvObj[ "holder_keep_on_respawn" ] = "0";
                if( !kvObj.exists( "holder_can_drop" ) )
                    kvObj[ "holder_can_drop" ] = "1";
                if( !kvObj.exists( "carried_hidden" ) )
                    kvObj[ "carried_hidden" ] = "1";
                if( !kvObj.exists( "return_timelimit" ) )
                    kvObj[ "return_timelimit" ] = "-1";

                AddItemInventory( player, kvObj );
            }
        }

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
                int value = atoi( szValue );

                switch( value )
                {
                    case 6: // Solo
                    {
                        m_loadout = LoadOut::Solo;
                        m_class = PM::BARNEY;
                        break;
                    }
                    case PM::BARNEY:
                    {
                        m_loadout = LoadOut::Security;
                        m_class = PM::BARNEY;
                        break;
                    }
                    case PM::SCIENTIST:
                    {
                        m_loadout = LoadOut::Scientist;
                        m_class = PM::SCIENTIST;
                        break;
                    }
                    case PM::CONSTRUCTION:
                    {
                        m_loadout = LoadOut::Constructor;
                        m_class = PM::CONSTRUCTION;
                        break;
                    }
                    default:
                    {
                        m_class = PM( value );
                        break;
                    }
                }
                return true;
            }
            return BaseClass.KeyValue( szKeyName, szValue );
        }

        void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
        {
            if( pActivator is null ) {
                #if SERVER
                g_PlayerClass.m_Logger.error( "Entity \"{}\" origin {} got no !activator!", { self.GetTargetname(), self.GetOrigin().ToString() } );
                #endif
                return;
            }

            CBasePlayer@ player = null;

            if( !pActivator.IsPlayer() ) {
                #if SERVER
                g_PlayerClass.m_Logger.error( "Entity \"{}\" origin {} got an !activator that is not a player!", { self.GetTargetname(), self.GetOrigin().ToString() } );
                #endif
                return;
            }

            @player = cast<CBasePlayer@>( pActivator );

            if( player is null ) {
                return;
            }

            g_PlayerClass.set_class( player, m_class );

            Vector fadeColor;

            switch( m_loadout )
            {
                case LoadOut::Nothing:
                {
                    return; // Exit.
                }
                case LoadOut::Solo:
                {
                    fadeColor = Vector(255, 0, 0);

                    switch( Math.RandomLong( 1, 30 ) )
                    {
                        case 1:
                        {
                            AddItems( player, {
                                { "weapon_bts_glock", 3 },
                                { "weapon_bts_flashlight", 1 },
                                { "item_bts_armorvest", 2 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: BLUE-SHIFT" );
                            break;
                        }
                        case 2:
                        {
                            AddItems( player, {
                                { "weapon_bts_flaregun", 1 }
                            } );
                            player.GiveNamedItem( "weapon_bts_flaregun", SF_GIVENITEM );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: SIGNAL" );
                            break;
                        }
                        case 3:
                        {
                            AddItems( player, {
                                { "weapon_bts_sbshotgun", 1 },
                                { "weapon_bts_flashlight", 1 },
                                { "item_bts_helmet", 1 },
                                { "item_bts_armorvest", 1 },
                                { "ammo_buckshot", 1 },
                                { "ammo_bts_eagle", 1 },
                                { "ammo_mp5clip", 1 }
                            } );
                            AddKeyCard( player, {
                                { "skin", "2" },
                                { "description", "Blackmesa Research Clearance level 1" },
                                { "display_name", "Research Keycard lvl 1" },
                                { "item_name", "Blackmesa_Research_Clearance_1" },
                                { "item_icon", "bts_rc/inv_card_research.spr" }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: 99 PERCENT GAMBLERS QUIT" );
                            break;
                        }
                        case 4:
                        {
                            AddItems( player, {
                                { "weapon_bts_glock17f", 2 },
                                { "weapon_bts_flashlight", 1 }
                            } );
                            AddKeyCard( player, {
                                { "skin", "3" },
                                { "description", "Blackmesa Security Clearance level 1" },
                                { "display_name", "Security Keycard lvl 1" },
                                { "item_name", "Blackmesa_Security_Clearance_1" },
                                { "item_icon", "bts_rc/inv_card_security.spr" },
                                { "item_group", "security" }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: LEVEL 1 SECURITY" );
                            break;
                        }
                        case 5:
                        {
                            AddItems( player, {
                                { "weapon_bts_handgrenade", 1 },
                                { "weapon_bts_screwdriver", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: FINAL SOLUTION" );
                            break;
                        }
                        case 6:
                        {
                            AddItems( player, {
                                { "weapon_bts_flashlight", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: OLD TIMES" );
                            break;
                        }
                        case 7:
                        {
                            AddItems( player, {
                                { "weapon_bts_knife", 1 },
                                { "weapon_bts_flashlight", 1 },
                                { "item_bts_helmet", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: THE BRITISH" );
                            break;
                        }
                        case 8:
                        {
                            AddItems( player, {
                                { "weapon_bts_flare", 3 },
                                { "weapon_bts_flaregun", 1 },
                                { "weapon_bts_flashlight", 1 },
                                { "ammo_bts_flarebox", 3 },
                                { "item_bts_helmet", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: PYROMANIAC" );
                            break;
                        }
                        case 9:
                        {
                            AddItems( player, {
                                { "weapon_bts_python", 1 },
                                { "ammo_bts_eagle", 2 }
                            } );
                            AddKeyCard( player, {
                                { "skin", "2" },
                                { "description", "Blackmesa Maintenance Clearance" },
                                { "display_name", "Maintenance Keycard" },
                                { "item_name", "Blackmesa_Maintenance_Clearance" },
                                { "item_icon", "bts_rc/inv_card_maint.spr" },
                                { "item_group", "repair" }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: SIX PACK" );
                            break;
                        }
                        case 10:
                        {
                            AddItems( player, {
                                { "weapon_bts_flashlight", 1 },
                                { "item_bts_armorvest", 1 },
                                { "weapon_bts_crowbar", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: FREE MAN" );
                            break;
                        }
                        case 11:
                        {
                            AddItems( player, {
                                { "item_bts_armorvest", 1 },
                                { "item_bts_helmet", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: BETTER LUCK NEXT TIME BUCKAROO" );
                            break;
                        }
                        case 12:
                        {
                            AddItems( player, {
                                { "weapon_bts_medkit", 1 },
                                { "weapon_bts_eagle", 1 },
                                { "item_bts_helmet", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: POOR MAN'S MEDIC" );
                            break;
                        }
                        case 13:
                        {
                            AddItems( player, {
                                { "weapon_bts_screwdriver", 1 },
                                { "weapon_bts_flashlight", 1 },
                                { "item_bts_helmet", 1 },
                                { "ammo_mp5clip", 1 },
                                { "ammo_bts_battery", 1 },
                                { "ammo_buckshot", 1 },
                                { "ammo_bts_python", 2 },
                                { "weapon_bts_flare", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: HOARDER" );
                            break;
                        }
                        case 14:
                        {
                            AddItems( player, {
                                { "weapon_bts_flashlight", 1 },
                                { "ammo_bts_m16_grenade", 1 },
                                { "weapon_bts_flare", 1 },
                                { "item_bts_helmet", 2 },
                                { "weapon_bts_handgrenade", 4 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: DEMOLITION MAN" );
                            break;
                        }
                        case 15:
                        {
                            AddItems( player, {
                                { "weapon_bts_poolstick", 1 },
                                { "weapon_bts_crowbar", 1 },
                                { "weapon_bts_flashlight", 1 },
                                { "weapon_bts_knife", 1 },
                                { "weapon_bts_screwdriver", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: BLACKMESA REDEMPTION" );
                            break;
                        }
                        case 16:
                        {
                            AddItems( player, {
                                { "item_bts_helmet", 1 },
                                { "weapon_bts_glock17f", 1 },
                                { "weapon_bts_flashlight", 1 },
                                { "weapon_bts_beretta", 1 },
                                { "ammo_9mmclip", 3 },
                                { "weapon_bts_glock", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: WEAPON COLLECTOR" );
                            break;
                        }
                        case 17:
                        {
                            AddItems( player, {
                                { "item_bts_armorvest", 2 },
                                { "weapon_bts_beretta", 1 },
                                { "ammo_9mmclip", 3 },
                                { "weapon_bts_flashlight", 1 }
                            } );
                            AddKeyCard( player, {
                                { "skin", "3" },
                                { "description", "Blackmesa Security Clearance level 1" },
                                { "display_name", "Security Keycard lvl 1" },
                                { "item_name", "Blackmesa_Security_Clearance_1" },
                                { "item_icon", "bts_rc/inv_card_security.spr" },
                                { "item_group", "security" }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: TAX EVASION" );
                            break;
                        }
                        case 18:
                        {
                            AddItems( player, {
                                { "weapon_bts_poolstick", 1 },
                                { "item_bts_helmet", 1 },
                                { "weapon_bts_flashlight", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: SNOOKERED" );
                            break;
                        }
                        case 19:
                        {
                            AddItems( player, {
                                { "item_bts_armorvest", 1 },
                                { "weapon_bts_beretta", 1 },
                                { "ammo_9mmclip", 2 },
                                { "weapon_bts_knife", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: LUCKY DAY" );
                            break;
                        }
                        case 20:
                        {
                            AddItems( player, {
                                { "item_bts_armorvest", 1 },
                                { "weapon_bts_flashlight", 1 }
                            } );
                            AddItemInventory( player, {
                                { "model", "models/w_antidote.mdl" },
                                { "delay", "0" },
                                { "holder_timelimit_wait_until_activated", "0" },
                                { "m_flCustomRespawnTime", "0" },
                                { "holder_keep_on_death", "0" },
                                { "holder_keep_on_respawn", "0" },
                                { "weight", "25" },
                                { "carried_hidden", "1" },
                                { "holder_can_drop", "1" },
                                { "return_timelimit", "-1" },
                                { "scale", "1.3" },
                                { "item_name", "pickup" },
                                { "item_group", "Items" },
                                { "description", "Increased damage... at a cost. (25 SLOTS)" },
                                { "display_name", "Adrenaline" },
                                { "effect_damage", "115" }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: SPEED RUNNER" );
                            break;
                        }  
                        case 21:
                        {
                            AddItems( player, {
                                { "weapon_bts_screwdriver", 1 },
                                { "hornet", 2 }
                            } );
                            AddItemInventory( player, {
                                { "model", "models/w_antidote.mdl" },
                                { "delay", "0" },
                                { "holder_timelimit_wait_until_activated", "0" },
                                { "m_flCustomRespawnTime", "0" },
                                { "holder_keep_on_death", "0" },
                                { "holder_keep_on_respawn", "0" },
                                { "weight", "10" },
                                { "carried_hidden", "1" },
                                { "holder_can_drop", "1" },
                                { "return_timelimit", "-1" },
                                { "scale", "1.3" },
                                { "item_name", "pickup" },
                                { "item_group", "Items" },
                                { "description", "Increased movement speed (10 SLOTS)" },
                                { "display_name", "Morphine Can" },
                                { "effect_speed", "115" }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: JUNKY" );
                            break;
                        }
                        case 22:
                        {
                            AddItems( player, {
                                { "weapon_bts_screwdriver", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: SCREWED" );
                            break;
                        }
                        case 23:
                        {
                            AddItems( player, {
                                { "weapon_bts_flashlight", 1 },
                                { "item_bts_helmet", 2 },
                                { "weapon_bts_eagle", 1 },
                                { "weapon_bts_python", 1 },
                                { "ammo_bts_python", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: TOUGH CHOICE" );
                            break;
                        }
                        case 24:
                        {
                            AddItems( player, {
                                { "weapon_bts_python", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: ROULETTE" );
                            break;
                        }
                        case 25:
                        {
                            AddItems( player, {
                                { "weapon_bts_medkit", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: MEDIC" );
                            break;
                        }
                        case 26:
                        {
                            AddItems( player, {
                                { "item_bts_helmet", 2 },
                                { "weapon_bts_glock17f", 1 },
                                { "ammo_9mmclip", 1 },
                                { "weapon_bts_screwdriver", 1 },
                                { "ammo_bts_python", 1 },
                                { "ammo_bts_shotshell", 2 },
                                { "weapon_bts_flare", 1 },
                                { "weapon_bts_flashlight", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: ALL ROUNDER" );
                            break;
                        }
                        case 27:
                        {
                            AddItems( player, {
                                { "item_bts_helmet", 1 },
                                { "ammo_9mmclip", 1 },
                                { "ammo_bts_m16", 1 },
                                { "weapon_bts_flashlight", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: AND YET NO GUN" );
                            break;
                        }
                        case 28:
                        {
                            AddItems( player, {
                                { "item_bts_helmet", 1 },
                                { "ammo_bts_shotshell", 2 },
                                { "ammo_bts_python", 3 },
                                { "weapon_bts_flashlight", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: AND YET NO DAMN GUN" );
                            break;
                        }
                        case 29:
                        {
                            AddItems( player, {
                                { "item_bts_helmet", 2 },
                                { "weapon_bts_glock17f", 1 },
                                { "weapon_bts_eagle", 1 },
                                { "ammo_bts_python", 1 },
                                { "ammo_9mmclip", 1 },
                                { "weapon_bts_flashlight", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: DUAL WIELD" );
                            break;
                        }
                        case 30:
                        {
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: TORTURED PLUS" );
                            break;
                        }
                    } 
                    break;
                }
                case LoadOut::Security:
                {
                    fadeColor = Vector(0, 170, 255);

                    string barney_ammo_type = "ammo_9mmclip";
                    string barney_wpn_type = "weapon_bts_glock17f";

                    switch( Math.RandomLong( 1, 3 ) )
                    {
                        case 1:
                            barney_ammo_type = "ammo_bts_eagle";
                            barney_wpn_type = "weapon_bts_eagle";
                        break;
                        case 2:
                            barney_wpn_type = "weapon_bts_beretta";
                        break;
                        case 3:
                            barney_wpn_type = "weapon_bts_glock";
                        break;
                    }

                    AddItems( player, {
                        { "item_bts_helmet", 1 },
                        { barney_wpn_type, 1 },
                        { barney_ammo_type, 2 },
                        { "weapon_bts_flashlight", 1 },
                        { "item_bts_armorvest", 1 }
                    } );
                    AddKeyCard( player, {
                        { "skin", "3" },
                        { "description", "Blackmesa Security Clearance level 1" },
                        { "display_name", "Security Keycard lvl 1" },
                        { "item_name", "Blackmesa_Security_Clearance_1" },
                        { "item_icon", "bts_rc/inv_card_security.spr" },
                        { "item_group", "security" }
                    } );
                    g_PlayerFuncs.HudMessage( player, msgParams, "Blackmesa Security Force" );
                    break;
                }
                case LoadOut::Scientist:
                {
                    fadeColor = Vector(0, 255, 93);

                    AddItems( player, {
                        { "weapon_bts_screwdriver", 1 },
                        { "weapon_bts_flashlight", 1 },
                        { "weapon_medkit", 1 }
                    } );
                    AddKeyCard( player, {
                        { "skin", "2" },
                        { "description", "Blackmesa Research Clearance level 1" },
                        { "display_name", "Research Keycard lvl 1" },
                        { "item_name", "Blackmesa_Research_Clearance_1" },
                        { "item_icon", "bts_rc/inv_card_research.spr" }
                    } );
                    g_PlayerFuncs.HudMessage( player, msgParams, "Blackmesa Science Team" );
                    break;
                }
                case LoadOut::Constructor:
                {
                    fadeColor = Vector(255, 255, 127);

                    AddItems( player, {
                        { ( Math.RandomLong( 0, 1 ) == 1 ? "weapon_bts_pipewrench" : "weapon_bts_crowbar" ), 1 },
                        { "item_bts_helmet", 3 },
                        { "weapon_bts_flashlight", 1 }
                    } );
                    AddKeyCard( player, {
                        { "skin", "2" },
                        { "description", "Blackmesa Maintenance Clearance" },
                        { "display_name", "Maintenance Keycard" },
                        { "item_name", "Blackmesa_Maintenance_Clearance" },
                        { "item_icon", "bts_rc/inv_card_maint.spr" },
                        { "item_group", "repair" }
                    } );
                    AddItemInventory( player, {
                        { "model", "models/tool_box.mdl" },
                        { "delay", "0" },
                        { "holder_timelimit_wait_until_activated", "0" },
                        { "m_flCustomRespawnTime", "0" },
                        { "holder_keep_on_death", "0" },
                        { "holder_keep_on_respawn", "0" },
                        { "weight", "10" },
                        { "carried_hidden", "1" },
                        { "holder_can_drop", "1" },
                        { "return_timelimit", "-1" },
                        { "scale", "0.8" },
                        { "item_icon", "bts_rc/inv_card_maint.spr" },
                        { "item_name", "GM_TOOLBOX_SPECIAL" },
                        { "item_group", "TOOLBOX" },
                        { "description", "Blackmesa Maintenance Engineers Toolbox" },
                        { "display_name", "Maintenance Engineers Toolbox (10 SLOTS)" }
                    } );
                    g_PlayerFuncs.HudMessage( player, msgParams, "Blackmesa Maintenance" );
                    break;
                }
            }
            g_PlayerFuncs.ScreenFade( player, fadeColor, 0.25f, 1.0f, 255.0f, FFADE_OUT );
            g_Scheduler.SetTimeout( this, "PlayerFade", 1.0f, @player, fadeColor);
        }

        protected void PlayerFade(CBasePlayer@ player, Vector color)
        {
            if( player !is null )
            {
                g_PlayerFuncs.ScreenFade(player, color, 1.0f, 0.0f, 255.0f, FFADE_IN );
            }
        }
    }
}
