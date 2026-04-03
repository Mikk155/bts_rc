/*
*   Author: Mikk
*/

const bool __HEV_NightVision__ = g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink,
PlayerPostThinkHook( function( CBasePlayer@ player )
{
    if( player is null || player_models::GetClass(player, true) == PM::UNSET )
        return HOOK_CONTINUE;

    if( !player_models::IsHEV( player ) )
    {
        // Deny flashlight in other than hev
        if( player.pev.impulse == 100 )
        {
            // Try to use the lantern in the equiped weapon
            if( player.m_hActiveItem.IsValid() )
            {
                CBaseEntity@ active_item = player.m_hActiveItem.GetEntity();

                if( active_item !is null )
                {
                    CBasePlayerWeapon@ weapon = cast<CBasePlayerWeapon@>( active_item );

                    
                    if( weapon !is null && weapon.pszAmmo2() == "bts:battery" || weapon.pszAmmo1() == "bts:battery" )
                    {
                        weapon.SecondaryAttack();
                    }
                }
            }
            player.pev.impulse = 0;
        }
        return HOOK_CONTINUE;
    }

    dictionary@ user_data = player.GetUserData();

    int state = int( user_data["helmet_nv_state"] );

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

        user_data["helmet_nv_state"] = state = 0;
    }
    // Catch impulse command and toggle night vision state
    else if( player.pev.impulse == 100 )
    {
        user_data["helmet_nv_state"] = ( state == 1 ? 0 : 1 );

        if( state == 1 )
            user_data["helmet_nv_startup"] = 0;

        g_PlayerFuncs.ScreenFade( player, Vector( 250, 200, 20 ), 1.0f, 0.5f, 255.0f, state == 0 ? 6 : 2 );

        g_SoundSystem.EmitSoundDyn(
            player.edict(),
            CHAN_WEAPON,
            ( state == 1 ? "bts_rc/items/nvg_off.wav" : "bts_rc/items/nvg_on.wav" ),
            1.0,
            ATTN_NORM,
            0,
            PITCH_NORM );
    }

    // Night vision ON, drain and light.
    if( state == 1 )
    {
        // Show even when dead lying.
        if( !player.GetObserver().IsObserver() )
        {
            if( float( user_data["helmet_nv_drain"] ) <= g_Engine.time )
            {
                player.pev.armorvalue--;
                user_data["helmet_nv_drain"] = 12 + g_Engine.time;
            }

            int nv_radius = int( user_data["helmet_nv_startup"] );

            if( nv_radius <= 40 )
            {
                nv_radius++;
                user_data["helmet_nv_startup"] = nv_radius;
            }

            NetworkMessage m( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, player.edict() );
            m.WriteByte( TE_DLIGHT );
            m.WriteCoord( player.pev.origin.x );
            m.WriteCoord( player.pev.origin.y );
            m.WriteCoord( player.pev.origin.z );
            m.WriteByte( nv_radius );
            m.WriteByte( 255 );
            m.WriteByte( 255 );
            m.WriteByte( 255 );
            m.WriteByte( 2 );
            m.WriteByte( 1 );
            m.End();
        }
        else
        {
            g_PlayerFuncs.ScreenFade( player, g_vecZero, 0.0f, 0.0f, 0.0f, ( FFADE_OUT | FFADE_STAYOUT ) );
            user_data["helmet_nv_state"] = 0;
        }
    }

    // Deny flashlight as we use our own.
    if( player.pev.impulse == 100 ) {
        player.pev.impulse = 0;
    }

    return HOOK_CONTINUE;
} ) );
