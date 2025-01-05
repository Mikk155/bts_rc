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
        #endif

        // Do not update the class here, Only weapons should do that so we assume the game hasn't started yet.
        const PM player_class = g_PlayerClass[ player, true ];

        // Clases not yet set? Then there's nothing to do here.
        if( player_class == PM::UNSET )
        {
            return HOOK_CONTINUE;
        }

        dictionary@ user_data = player.GetUserData();

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
                        g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, CONST_HEV_NIGHTVISION_OFF, 1.0, ATTN_NORM, 0, PITCH_NORM );
                        g_PlayerFuncs.ScreenFade( player, Vector( 250, 200, 20 ), 1.0f, 0.5f, 255.0f, 2 );
                    }
                    else if( player.pev.impulse == 100 )
                    {
                        g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, CONST_HEV_NIGHTVISION_NO_POWER, 1.0, ATTN_NORM, 0, PITCH_NORM );
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
                        ( state == 1 ? CONST_HEV_NIGHTVISION_OFF : CONST_HEV_NIGHTVISION_ON ),
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
                            // -TODO Find a nice drain time
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

                player.m_iFlashBattery = int(Math.max( 1, player.pev.armorvalue ));

                // Update HUD
                NetworkMessage m( MSG_ONE, NetworkMessages::Flashlight, player.edict() );
                    m.WriteByte( state );
                    m.WriteByte(player.m_iFlashBattery);
                m.End();

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
