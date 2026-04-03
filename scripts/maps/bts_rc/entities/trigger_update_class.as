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
                for( int i = 0; i < int( kvObj[keys[ui]] ); i++ )
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
                        m_class = PM::OPERATIVE;
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
            if( pActivator is null )
            {
                return;
            }

            CBasePlayer@ player = null;

            if( !pActivator.IsPlayer() )
            {
                return;
            }

            @player = cast<CBasePlayer@>( pActivator );

            if( player is null )
            {
                return;
            }

            string playerName = string( player.pev.netname );

            player_models::SetClass( player, m_class );

            Vector fadeColor;

            switch( m_loadout )
            {
                case LoadOut::Nothing:
                {
                    return; // Exit.
                }
                case LoadOut::Solo:
                {
                    fadeColor = Vector( 255, 0, 0 );

                    switch( Math.RandomLong( 1, 33 ) )
                    {
                        case 1:
                        {
                            AddItems( player, { { "weapon_bts_glock", 1 }, { "weapon_bts_flashlight", 1 }, { "item_bts_armorvest", 2 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: BLUE-SHIFT" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: BLUE-SHIFT.\n" );
                            player.GetUserData()["pm"] = "bts_op";
                            break;
                        }
                        case 2:
                        {
                            AddItems( player, { { "weapon_bts_flaregun", 1 } } );
                            player.GiveNamedItem( "weapon_bts_flaregun", SF_GIVENITEM );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: IGNITION" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: IGNITION.\n" );
                            player.GetUserData()["pm"] = "bts_op5";
                            break;
                        }
                        case 3:
                        {
                            AddItems( player, { { "weapon_bts_sbshotgun", 1 }, { "weapon_bts_flashlight", 1 }, { "item_bts_helmet", 1 }, { "item_bts_armorvest", 1 }, { "ammo_buckshot", 1 }, { "ammo_bts_eagle", 3 }, { "ammo_mp5clip", 1 } } );
                            AddKeyCard( player, { { "skin", "2" }, { "description", "Blackmesa Research Clearance Level 1" }, { "display_name", "Research Keycard lvl 1" }, { "item_name", "Blackmesa_Research_Clearance_1" }, { "item_icon", "bts_rc/inv_card_research.spr" } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: THE BEST ROLL" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: THE BEST ROLL.\n" );
                            player.GetUserData()["pm"] = "bts_op2";
                            break;
                        }
                        case 4:
                        {
                            AddItems( player, { { "weapon_bts_glock17f", 2 }, { "weapon_bts_flashlight", 1 } } );
                            AddKeyCard( player, { { "skin", "3" }, { "description", "Blackmesa Security Clearance Level 1" }, { "display_name", "Security Keycard lvl 1" }, { "item_name", "Blackmesa_Security_Clearance_1" }, { "item_icon", "bts_rc/inv_card_security.spr" }, { "item_group", "security" } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: LEVEL 1 SECURITY" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: LEVEL 1 SECURITY.\n" );
                            player.GetUserData()["pm"] = "bts_op3";
                            break;
                        }
                        case 5:
                        {
                            AddItems( player, { { "weapon_bts_handgrenade", 1 }, { "weapon_bts_screwdriver", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: FINAL SOLUTION" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: FINAL SOLUTION.\n" );
                            player.GetUserData()["pm"] = "bts_op_hurt";
                            break;
                        }
                        case 6:
                        {
                            AddItems( player, { { "weapon_bts_flashlight", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: OLD TIMES" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: OLD TIMES.\n" );
                            player.GetUserData()["pm"] = "bts_op";
                            break;
                        }
                        case 7:
                        {
                            AddItems( player, { { "weapon_bts_knife", 1 }, { "weapon_bts_flashlight", 1 }, { "item_bts_helmet", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: PERSONAL" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: THE BRITISH.\n" );
                            player.GetUserData()["pm"] = "bts_op4";
                            break;
                        }
                        case 8:
                        {
                            AddItems( player, { { "weapon_bts_flare", 3 }, { "weapon_bts_flaregun", 1 }, { "weapon_bts_flashlight", 1 }, { "ammo_bts_flarebox", 3 }, { "item_bts_helmet", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: FIRESTARTER" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: PYROMANIAC.\n" );
                            player.GetUserData()["pm"] = "bts_op6";
                            break;
                        }
                        case 9:
                        {
                            AddItems( player, { { "weapon_bts_python", 1 }, { "ammo_bts_eagle", 4 }, { "item_bts_helmet", 1 } } );
                            AddKeyCard( player, { { "skin", "4" }, { "description", "Blackmesa Maintenance Clearance" }, { "display_name", "Maintenance Keycard" }, { "item_name", "Blackmesa_Maintenance_Clearance" }, { "item_icon", "bts_rc/inv_card_maint.spr" }, { "item_group", "repair" } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: HAND CANNON" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: HAND CANNON.\n" );
                            player.GetUserData()["pm"] = "bts_op2";
                            break;
                        }
                        case 10:
                        {
                            AddItems( player, { { "weapon_bts_flashlight", 1 }, { "item_bts_armorvest", 1 }, { "weapon_bts_crowbar", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: THE ONE FREEMAN" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: THE ONE FREEMAN.\n" );
                            player.GetUserData()["pm"] = "bts_op_free";
                            break;
                        }
                        case 11:
                        {
                            AddItems( player, { { "weapon_bts_medkit", 1 }, { "weapon_bts_eagle", 1 }, { "item_bts_helmet", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: POOR MAN'S MEDIC" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: POOR MAN'S MEDIC.\n" );
                            player_models::SetClass( player, PM::VETERAN );
                            player.GetUserData()["pm"] = "bts_op_band";
                            break;
                        }
                        case 12:
                        {
                            AddItems( player, { { "weapon_bts_flashlight", 1 }, { "ammo_bts_m16_grenade", 1 }, { "weapon_bts_flare", 1 }, { "item_bts_helmet", 2 }, { "weapon_bts_handgrenade", 4 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: LOCKSMITh" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: LOCKSMITH.\n" );
                            player_models::SetClass( player, PM::VETERAN );
                            player.GetUserData()["pm"] = "bts_op5";
                            break;
                        }
                        case 13:
                        {
                            AddItems( player, { { "weapon_bts_crowbar", 1 }, { "weapon_bts_flashlight", 1 }, { "weapon_bts_knife", Math.RandomLong( -1, 1 ) }, { "weapon_bts_pipe", Math.RandomLong( -1, 1 ) }, { "weapon_bts_screwdriver", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: BLACKMESA SURVIVOR" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: BLACKMESA SURVIVOR.\n" );
                            player.GetUserData()["pm"] = "bts_op2";
                            break;
                        }
                        case 14:
                        {
                            AddItems( player, { { "item_bts_helmet", 1 }, { "weapon_bts_glock17f", 1 }, { "weapon_bts_flashlight", 1 }, { "weapon_bts_beretta", 1 }, { "ammo_9mmclip", 3 }, { "weapon_bts_glock", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: WEAPON COLLECTOR" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: WEAPON COLLECTOR.\n" );
                            player.GetUserData()["pm"] = "bts_op_dual";
                            break;
                        }
                        case 15:
                        {
                            AddItems( player, { { "item_bts_armorvest", 2 }, { "weapon_bts_beretta", 1 }, { "ammo_9mmclip", Math.RandomLong( 3, 4 ) }, { "weapon_bts_flashlight", 1 } } );
                            AddKeyCard( player, { { "skin", "3" }, { "description", "Blackmesa Security Clearance Level 1" }, { "display_name", "Security Keycard lvl 1" }, { "item_name", "Blackmesa_Security_Clearance_1" }, { "item_icon", "bts_rc/inv_card_security.spr" }, { "item_group", "security" } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: LEVEL 1 SECURITY +" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: LEVEL 1 SECURITY +.\n" );
                            player.GetUserData()["pm"] = "bts_op";
                            break;
                        }
                        case 16:
                        {
                            AddItems( player, { { "weapon_bts_poolstick", 1 }, { "item_bts_helmet", 1 }, { "weapon_bts_flashlight", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: SNOOKERED" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: SNOOKERED.\n" );
                            player.GetUserData()["pm"] = "bts_op6";
                            break;
                        }
                        case 17:
                        {
                            AddItems( player, { { "item_bts_armorvest", Math.RandomLong( 1, 2 ) }, { "weapon_bts_beretta", 1 }, { "ammo_9mmclip", Math.RandomLong( 2, 4 ) }, { "weapon_bts_knife", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: TACTICAL" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: TACTICAL.\n" );
                            player.GetUserData()["pm"] = "bts_op4";
                            break;
                        }
                        case 18:
                        {
                            AddItems( player, { { "weapon_bts_screwdriver", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: SCREWED" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: SCREWED.\n" );
                            player.GetUserData()["pm"] = "bts_op2";
                            break;
                        }
                        case 19:
                        {
                            AddItems( player, { { "weapon_bts_flashlight", 1 }, { "item_bts_helmet", 2 }, { "weapon_bts_eagle", 1 }, { "ammo_bts_python", Math.RandomLong( 1, 4 ) } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: TACTICAL HAND CANNON" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: TACTICAL HAND CANNON.\n" );
                            player.GetUserData()["pm"] = "bts_op";
                            break;
                        }
                        case 20:
                        {
                            AddItems( player, { { "weapon_bts_python", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: ROULETTE" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: ROULETTE.\n" );
                            player.GetUserData()["pm"] = "bts_op5";
                            break;
                        }
                        case 25:
                        {
                            AddItems( player, { { "weapon_bts_medkit", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: DOCTOR" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: DOCTOR.\n" );
                            player_models::SetClass( player, PM::VETERAN );
                            player.GetUserData()["pm"] = "bts_op4";
                            break;
                        }
                        case 26:
                        {
                            AddItems( player, { { "item_bts_helmet", 2 }, { "weapon_bts_glock17f", 1 }, { "weapon_bts_eagle", 1 }, { "ammo_bts_eagle", 3 }, { "ammo_9mmclip", 1 }, { "weapon_bts_flashlight", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: 9MM EAGLE" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: 9MM EAGLE.\n" );
                            player.GetUserData()["pm"] = "bts_op6";
                            break;
                        }
                        case 27:
                        {
                            AddItems( player, { { "item_bts_helmet", 2 }, { "weapon_bts_screwdriver", 1 }, { "weapon_bts_medkit", 1 } } );
                            AddItemInventory( player, { { "item_name", "CLEANSUIT_ID" }, { "item_group", "IMMUNE" }, { "target_on_collect", "GAMEMODE_ITEM_TXT" }, { "description", "Suit used for protection while going into highly toxic locations." }, { "display_name", "Blackmesa Cleansuit" }, { "target_cant_collect", "GAMEMODE_FULL_TXT" }, { "weight", "1.0" }, { "carried_hidden", "1" }, { "return_timelimit", "120" }, { "holder_timelimit_wait_until_activated", "0" }, { "holder_can_drop", "0" }, { "holder_keep_on_death", "1" }, { "holder_keep_on_respawn", "1" }, { "model", "models/w_security.mdl" } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: CLEANSUIT TEAM" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: CLEANSUIT TEAM.\n" );
                            player_models::SetClass( player, PM::CLSUIT );
                            break;
                        }
                        case 28:
                        {
                            AddItems( player, { { "weapon_bts_shotgun", 1 }, { "ammo_bts_shotshell", Math.RandomLong( 0, 5 ) }, { "weapon_bts_poolstick", 1 }, { "item_bts_helmet", Math.RandomLong( 0, 3 ) } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: HEAVY SECURITY" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: HEAVY SECURITY\n" );
                            player_models::SetClass( player, PM::VETERAN );
                            player.GetUserData()["pm"] = "bts_op";
                            break;
                        }
                        case 29:
                        {
                            AddItems( player, { { "weapon_bts_glock18", 1 }, { "item_bts_helmet", 2 }, { "ammo_9mmclip", Math.RandomLong( 2, 4 ) }, { "weapon_bts_flashlight", 1 } } );
                            AddKeyCard( player, { { "skin", "3" }, { "description", "Blackmesa Security Clearance Level 1" }, { "display_name", "Security Keycard lvl 1" }, { "item_name", "Blackmesa_Security_Clearance_1" }, { "item_icon", "bts_rc/inv_card_security.spr" }, { "item_group", "security" } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: ILLEGAL SIDEARM" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: ILLEGAL SIDEARM.\n" );
                            player.GetUserData()["pm"] = "bts_op3";
                            break;
                        }
                        case 30:
                        {
                            AddItems( player, { { "item_bts_helmet", 1 }, { "weapon_bts_crowbar", 1 }, { "ammo_9mmclip", Math.RandomLong( 3, 4 ) }, { "weapon_bts_uzi", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: ILLEGAL FIREARM" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: ILLEGAL FIREARM.\n" );
                            player_models::SetClass( player, PM::VETERAN );
                            player.GetUserData()["pm"] = "bts_op2";
                            break;
                        }
                        case 31:
                        {
                            AddItems( player, { { "weapon_bts_sbshotgun", 1 }, { "ammo_bts_battery", 2 }, { "ammo_bts_shotshell", 4 }, { "weapon_bts_flashlight", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: MEDIUM ENLIGHTENMENT" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled: MEDIUM ENLIGHTENMENT.\n" );
                            player.GetUserData()["pm"] = "bts_op3";
                            break;
                        }
                        case 32:
                        {
                            AddItems( player, { { "item_bts_helmet", 3 }, { "weapon_bts_axe", 1 }, { "weapon_bts_flashlight", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: FIRE MARSHAL" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled 48th Loadout: FIRE MARSHAL.\n" );
                            player.GetUserData()["pm"] = "bts_op5";
                            break;
                        }
                        case 33:
                        {
                            switch( Math.RandomLong( 1, 3 ) )
                            {
                                case 1:
                                {
                                    AddItems( player, { { "weapon_bts_screwdriver", 1 }, { "weapon_bts_flashlight", 1 }, { "weapon_medkit", 1 } } );
                                    break;
                                }
                                case 2:
                                {
                                    AddItems( player, { { "weapon_bts_flashlight", 1 }, { "weapon_medkit", 1 } } );
                                    break;
                                }
                                case 3:
                                {
                                    AddItems( player, { { "weapon_bts_screwdriver", 1 }, { "weapon_bts_flashlight", 1 }, { "weapon_medkit", 1 }, { "ammo_medkit", 5 } } );
                                    break;
                                }
                            }
                            AddKeyCard( player, { { "skin", "2" }, { "description", "Blackmesa Research Clearance level 1" }, { "display_name", "Research Keycard lvl 1" }, { "item_name", "Blackmesa_Research_Clearance_1" }, { "item_icon", "bts_rc/inv_card_research.spr" } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: NON TRAINED PERSONNEL" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled 49th Loadout: NON TRAINED PERSONNEL.\n" );
                            player_models::SetClass( player, PM::SCIENTIST );
                            break;
                        }
                        case 34:
                        {
                            AddItems( player, { { "item_bts_helmet", 3 }, { "item_bts_armorvest", 1 }, { "weapon_bts_pipe", 1 }, { "weapon_bts_flare", 2 }, { "weapon_bts_flashlight", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: SURVIVOR" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " rolled 54th Loadout: PIPE\n" );
                            player.GetUserData()["pm"] = "bts_op_hurt";
                            break;
                        }
                    }
                    break;
                }
                case LoadOut::Security:
                {
                    fadeColor = Vector( 0, 170, 255 );

                    string barney_ammo_type = "ammo_9mmclip";
                    string barney_wpn_type = "weapon_bts_glock17f";

                    switch( Math.RandomLong( 1, 5 ) )
                    {
                        case 1:
                            barney_ammo_type = "ammo_bts_eagle";
                            AddItems( player, { { barney_ammo_type, 4 } } );
                            barney_wpn_type = "weapon_bts_eagle";
                            g_PlayerFuncs.SayTextAll( player, playerName + " enrolled as a Security Guard with a Desert Eagle.\n" );
                            switch( Math.RandomLong( 1, 4 ) )
                            {
                                case 1:
                                    player_models::SetClass( player, PM::BOTIS );
                                    player.GetUserData()["pm"] = "bts_otis_blk";
                                    break;
                                case 2:
                                    player_models::SetClass( player, PM::BARNEY );
                                    player.GetUserData()["pm"] = "bts_otis";
                                    break;
                                case 3:
                                    player_models::SetClass( player, PM::BARNEY );
                                    player.GetUserData()["pm"] = "bts_otis2";
                                    break;
                                case 4:
                                    player_models::SetClass( player, PM::BOTIS );
                                    player.GetUserData()["pm"] = "bts_otis_blk";
                                    break;
                            }
                            break;
                        case 2:
                            barney_wpn_type = "weapon_bts_beretta";
                            g_PlayerFuncs.SayTextAll( player, playerName + " enrolled as a Security Guard, with a M9 Beretta.\n" );
                            break;
                        case 3:
                            barney_wpn_type = "weapon_bts_glock";
                            g_PlayerFuncs.SayTextAll( player, playerName + " enrolled as a Security Guard, with a Glock 17.\n" );
                            break;
                        case 4:
                            barney_wpn_type = "weapon_bts_glock17f";
                            g_PlayerFuncs.SayTextAll( player, playerName + " enrolled as a Security Guard, with a Glock 17 (w/ flashlight).\n" );
                            break;
                        case 5:
                            barney_ammo_type = "ammo_bts_sw637";
                            barney_wpn_type = "weapon_bts_sw637";
                            g_PlayerFuncs.SayTextAll( player, playerName + " enrolled as a Security Guard, with a Smith & Wesson 637.\n" );
                            break;
                    }

                    AddItems( player, { { "item_bts_helmet", 1 }, { barney_wpn_type, 1 }, { barney_ammo_type, 2 }, { "weapon_bts_flashlight", 1 }, { "item_bts_armorvest", 1 } } );
                    AddKeyCard( player, { { "skin", "3" }, { "description", "Blackmesa Security Clearance level 1" }, { "display_name", "Security Keycard lvl 1" }, { "item_name", "Blackmesa_Security_Clearance_1" }, { "item_icon", "bts_rc/inv_card_security.spr" }, { "item_group", "security" } } );
                    g_PlayerFuncs.HudMessage( player, msgParams, "Blackmesa Security Force" );
                    break;
                }
                case LoadOut::Scientist:
                {
                    fadeColor = Vector( 0, 255, 93 );
                    switch( Math.RandomLong( 1, 3 ) )
                    {
                        case 1:
                        {
                            AddItems( player, { { "weapon_bts_screwdriver", 1 }, { "weapon_bts_flashlight", 1 }, { "weapon_medkit", 1 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "Blackmesa Science Team" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " enrolled as a Scientist, with a Screwdriver.\n" );
                            break;
                        }
                        case 2:
                        {
                            AddItems( player, { { "weapon_bts_flashlight", 1 }, { "weapon_medkit", 1 }, { "ammo_medkit", 3 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "Blackmesa Science Team" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " enrolled as a Scientist, with a Flashlight.\n" );
                            break;
                        }
                        case 3:
                        {
                            AddItems( player, { { "weapon_bts_screwdriver", 1 }, { "weapon_bts_flashlight", 1 }, { "weapon_medkit", 1 }, { "ammo_medkit", 5 } } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "Blackmesa Science Team" );
                            g_PlayerFuncs.SayTextAll( player, playerName + " enrolled as a Scientist, with Extra medkit ammo.\n" );
                            break;
                        }
                    }

                    AddKeyCard( player, { { "skin", "2" }, { "description", "Blackmesa Research Clearance level 1" }, { "display_name", "Research Keycard lvl 1" }, { "item_name", "Blackmesa_Research_Clearance_1" }, { "item_icon", "bts_rc/inv_card_research.spr" } } );
                    break;
                }
                case LoadOut::Constructor:
                {
                    fadeColor = Vector( 255, 255, 127 );

                    switch( Math.RandomLong( 1, 4 ) ) // sorry
                    {
                        case 1:
                            AddItems( player, { { "weapon_bts_pipewrench", 1 }, { "item_bts_helmet", 3 }, { "weapon_bts_flashlight", 1 } } );
                            g_PlayerFuncs.SayTextAll( player, playerName + " enrolled as a Maintenance, with a Pipewrench.\n" );
                            break;
                        case 2:
                            AddItems( player, { { "weapon_bts_crowbar", 1 }, { "item_bts_helmet", 3 }, { "weapon_bts_flashlight", 1 } } );
                            g_PlayerFuncs.SayTextAll( player, playerName + " enrolled as a Maintenance, with a Crowbar.\n" );
                            break;
                        case 3:
                            AddItems( player, { { "weapon_bts_pipe", 1 }, { "item_bts_helmet", 3 }, { "weapon_bts_flashlight", 1 } } );
                            g_PlayerFuncs.SayTextAll( player, playerName + " enrolled as a Maintenance, with a Spanner.\n" );
                            break;
                        case 4:
                            AddItems( player, { { "weapon_bts_screwdriver", 1 }, { "item_bts_helmet", 6 }, { "weapon_bts_flashlight", 1 } } );
                            g_PlayerFuncs.SayTextAll( player, playerName + " enrolled as a Maintenance, with extra Armor.\n" );
                            break;
                    }

                    AddKeyCard( player, { { "skin", "4" }, { "description", "Blackmesa Maintenance Clearance" }, { "display_name", "Maintenance Keycard" }, { "item_name", "Blackmesa_Maintenance_Clearance" }, { "item_icon", "bts_rc/inv_card_maint.spr" }, { "item_group", "repair" } } );
                    AddItemInventory( player, { { "model", "models/bts_rc/items/tool_box.mdl" }, { "skin", "1" }, { "delay", "0" }, { "holder_timelimit_wait_until_activated", "0" }, { "m_flCustomRespawnTime", "0" }, { "holder_keep_on_death", "0" }, { "holder_keep_on_respawn", "0" }, { "weight", "10" }, { "carried_hidden", "0" }, { "carried_body", "1" }, { "holder_can_drop", "1" }, { "return_timelimit", "-1" }, { "scale", "0.8" }, { "item_icon", "bts_rc/inv_card_maint.spr" }, { "item_name", "GM_TOOLBOX_SPECIAL" }, { "item_group", "TOOLBOX" }, { "description", "This Toolbox can be used for yellow and orange repair markers,(10 SLOTS)" }, { "display_name", "Engineers Toolbox" } } );
                    g_PlayerFuncs.HudMessage( player, msgParams, "Blackmesa Maintenance" );
                    break;
                }
            }
            g_PlayerFuncs.ScreenFade( player, fadeColor, 0.25f, 1.0f, 255.0f, FFADE_OUT );
            g_Scheduler.SetTimeout( this, "PlayerFade", 1.0f, @player, fadeColor );
        }
    }
}
