/*
    Author: Mikk
*/

HookReturnCode player_think( CBasePlayer@ player )
{
    if( player !is null && player.IsConnected() )
    {
#if SERVER
        // Change impulse 101 command with our own weapons.
        check_impulse_101(player);
        whatsthat(player);
#endif

        // Do not update the class here, Only weapons should do that so we assume the game hasn't started yet.
        const PM player_class = g_PlayerClass[ player, true ];

        // Clases not yet set? Then there's nothing to do here.
        if( player_class == PM::UNSET )
        {
            return HOOK_CONTINUE;
        }

        dictionary@ user_data = player.GetUserData();

        // Prevent players switching models
        player.SetOverriddenPlayerModel( string(user_data[ "pm" ] ) );

        // New *feature* "No pressing E while shooting" xD
        if( ( player.pev.button & IN_USE ) != 0 && ( player.pev.button & IN_RELOAD ) != 0  )
        {
            // Don't call Reload.
            player.pev.button &= ~IN_RELOAD;

            if( g_Engine.time > float(user_data[ "motd_update" ] ) )
            {
                // Individual cooldown players to not spam UserMessages
                user_data[ "motd_update" ] = g_Engine.time + 1.0f;

                // The buffer may be old, update it.
                if( g_Engine.time > item_tracker::time )
                {
#if SERVER
                    item_tracker::m_Logger.info( "Updating global buffer." );
#endif
                    dictionary items = {
                        { "RETINA_COMPONENT", "Area 1 - Retina component" },
                        { "VALVE_1", "Area 1 - Override Valve 1" },
                        { "VALVE_1_2", "Area 1 - Override Valve 2" },
                        { "GEAR_1", "Area 3 - Gear 1" },
                        { "GEAR_2", "Area 3 - Gear 2" },
                        { "GEAR_3", "Area 3 - Gear 3" },
                        { "GEAR_4", "Area 3 - Gear" },
                        { "WAREHOUSE_YARDKEY", "Area 2 - Yard managers keycard" },
                        { "DORMS_CARD_101", "Area 1 - A-101 Dorms key 1" },
                        { "DORMS_CARD_101_2", "Area 1 - A-101 Dorms key 2" },
                        { "DORMS_CARD_106", "Area 1 - A-106 Dorms key 3" },
                        { "DORMS_CARD_201", "Area 1 - B-201 Dorms key 4" },
                        { "CODES_1", "Service Elevator codes" },
                        { "Blackmesa_Maintenance_Clearance_2", "Maintenance Access level 2 keycard" },
                        { "Blackmesa_Maintenance_Clearance_2_2", "Maintenance Access level 2 keycard Alt" },
                        { "Blackmesa_Maintenance_Clearance_2_1", "Maintenance Access level 2 keycard X" },
                        { "d5_officekey", "Reception key 1" },
                        { "d5_officekey_1", "Reception key 2" },
                        { "d5_doctorkey", "Doctors key" },
                        { "Blackmesa_Security_Clearance_3", "Blackmesa Security Clearance level 3" }
                    };

                    // Iterate over all clients, some player's indexes will be above GetNumPlayers, i have no proofs but neither doubts.
                    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
                    {
                        CBasePlayer@ players = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

                        if( players !is null && players.IsConnected() )
                        {
                            InventoryList@ inventory = players.m_pInventory;

                            while( inventory !is null )
                            {
                                CItemInventory@ item = cast<CItemInventory@>( inventory.hItem.GetEntity() );

                                if( item !is null && items.exists( item.m_szItemName ))
                                {
                                    string format;

                                    CustomKeyvalues@ doubles = item.GetCustomKeyvalues();

                                    // These are duplicated "item_name" So to identify to which "Display name" it belongs we use a custom keyvalue.
                                    if( doubles !is null && doubles.HasKeyvalue( "$i_secondary" ) )
                                    {
                                        string name;
                                        snprintf( name, "%1_%2", item.m_szItemName, doubles.GetKeyvalue( "$i_secondary" ).GetInteger() );
                                        snprintf( format, "%1\n - %2", string( items[ name ] ), players.pev.netname );
                                        items[ name ] = format;
                                    }
                                    else
                                    {
                                        snprintf( format, "%1\n - %2", string( items[ string( item.m_szItemName ) ] ), players.pev.netname );
                                        items[ string( item.m_szItemName ) ] = format;
                                    }
                                }
                                @inventory = inventory.pNext;
                            }
                        }
                    }

                    array<string> item_names = items.getKeys();

                    item_tracker::buffer = "Who has what?\n";

                    for( uint ui = 0; ui < item_names.length(); ui++ )
                    {
                        snprintf( item_tracker::buffer, "%1\n%2", item_tracker::buffer, string( items[ item_names[ui] ] ) );
                    }

                    item_tracker::time = g_Engine.time + 5.0; // Cooldown time for refreshing.
                }

                //================================================================================================
                //  Shows a MOTD message to the player
                //  Code by Giegue. Taken from: https://github.com/JulianR0/TPvP/blob/master/src/plugins/TPvP.as#L7375
                //================================================================================================
                uint iChars = 0;

                string szSplitMsg = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

                for( uint uChars = 0; uChars < item_tracker::buffer.Length(); uChars++ )
                {
                    szSplitMsg.SetCharAt( iChars, char( item_tracker::buffer[ uChars ] ) );
                    iChars++;

                    if( iChars == 32 )
                    {
                        NetworkMessage motd_append( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict() );
                            motd_append.WriteByte( 0 );
                            motd_append.WriteString( szSplitMsg );
                        motd_append.End();

                        iChars = 0;
                    }
                }

                // If we reached the end, send the last letters of the message
                if( iChars > 0 )
                {
                    szSplitMsg.Truncate( iChars );

                    NetworkMessage motd_fix( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict() );
                        motd_fix.WriteByte( 0 );
                        motd_fix.WriteString( szSplitMsg );
                    motd_fix.End();
                }

                NetworkMessage motd_open( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict() );
                    motd_open.WriteByte( 1 );
                    motd_open.WriteString( "\n" );
                motd_open.End(); 
            }
        }

        switch( player_class )
        {
            /*==========================================================================
            *   - Start of Helmet night vision
            ==========================================================================*/
            case PM::HELMET:
            {
                int state = int( user_data[ "helmet_nv_state" ] );

                // Not enough power, Shut down
                if( player.pev.armorvalue <= 0 )
                {
                    if( state == 1 )
                    {
                        g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "bts_rc/items/nvg_off.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
                        g_PlayerFuncs.ScreenFade( player, Vector( 250, 200, 20 ), 1.0f, 0.5f, 255.0f, 2 );
                    }
                    else if( player.pev.impulse == 100 )
                    {
                        g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "items/suitchargeno1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
                    }

                    user_data[ "helmet_nv_state" ] = state = 0;
                }
                // Catch impulse command and toggle night vision state
                else if( player.pev.impulse == 100 )
                {
                    user_data[ "helmet_nv_state" ] = ( state == 1 ? 0 : 1 );

                    g_PlayerFuncs.ScreenFade( player, Vector( 250, 200, 20 ), 1.0f, 0.5f, 255.0f, state == 0 ? 6 : 2 );

                    g_SoundSystem.EmitSoundDyn(
                        player.edict(),
                        CHAN_WEAPON,
                        ( state == 1 ? "bts_rc/items/nvg_off.wav" : "bts_rc/items/nvg_on.wav" ),
                        1.0,
                        ATTN_NORM,
                        0,
                        PITCH_NORM
                    );
                }

                // Night vision ON, drain and light.
                if( state == 1 )
                {
                    // Show even when dead lying.
                    if( !player.GetObserver().IsObserver() )
                    {
                        if( float( user_data[ "helmet_nv_drain" ] ) <= g_Engine.time )
                        {
                            player.pev.armorvalue--;
                            user_data[ "helmet_nv_drain" ] = 4.5 + g_Engine.time;

#if SERVER
                            g_Logger.debug( "HEV Battery of {} at {}", { player.pev.netname, player.pev.armorvalue } );
#endif
                        }

                        NetworkMessage m( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, player.edict() );
                            m.WriteByte( TE_DLIGHT );
                            m.WriteCoord(player.pev.origin.x);
                            m.WriteCoord(player.pev.origin.y);
                            m.WriteCoord(player.pev.origin.z);
                            m.WriteByte(40);
                            m.WriteByte(255);
                            m.WriteByte(255);
                            m.WriteByte(255);
                            m.WriteByte(2);
                            m.WriteByte(1);
                        m.End();
                    }
                    else
                    {
                        g_PlayerFuncs.ScreenFade( player, g_vecZero, 0.0f, 0.0f, 0.0f, ( FFADE_OUT | FFADE_STAYOUT ) );
                        user_data[ "helmet_nv_state" ] = 0;
                    }
                }
#if DISCARDED
                player.m_iFlashBattery = int(Math.max( 1, player.pev.armorvalue ));

                // Update HUD
                NetworkMessage m( MSG_ONE, NetworkMessages::Flashlight, player.edict() );
                    m.WriteByte( state );
                    m.WriteByte(player.m_iFlashBattery);
                m.End();
#endif
                break;
            }
            /*==========================================================================
            *   - End
            ==========================================================================*/
        }

        // Deny flashlight as we use our own.
        if( player.pev.impulse == 100 )
        {
            player.pev.impulse = 0;
        }
    }

    return HOOK_CONTINUE;
}
