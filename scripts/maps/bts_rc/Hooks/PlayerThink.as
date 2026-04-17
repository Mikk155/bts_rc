namespace Hooks
{
bool PlayerThink = g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink,
PlayerPostThinkHook( function( CBasePlayer@ player )
{
    if( player is null || !player.IsConnected() )
        return HOOK_CONTINUE;

    auto character = GetCharacter(player);

    dictionary@ data = player.GetUserData();

    if( !data.exists( "connected" ) )
        ClientInitialized(player);

    // Change impulse 101 command with our own weapons.
    if( player.pev.impulse == 101 && g_EngineFuncs.CVarGetFloat( "sv_cheats" ) > 0 && g_PlayerFuncs.AdminLevel( player ) >= ADMIN_YES )
    {
        const array<string>@ weaponNames = g_WeaponsConfig.WeaponNames();
        uint length = weaponNames.length();

        for( uint ui = 0; ui < length; ui++ )
        {
            const string weapon_name = weaponNames[ui];

            player.GiveNamedItem( weapon_name );

            CBasePlayerItem@ item = player.HasNamedPlayerItem( weapon_name );

            if( item !is null )
            {
                CBasePlayerWeapon@ weapon = cast<CBasePlayerWeapon@>( item );

                if( weapon !is null )
                {
                    if( weapon.m_iPrimaryAmmoType > 0 )
                        player.m_rgAmmo( weapon.m_iPrimaryAmmoType, weapon.iMaxAmmo1() );
                    
                    weapon.m_iClip = weapon.iMaxClip();

                    if( weapon.m_iSecondaryAmmoType > 0 )
                        player.m_rgAmmo( weapon.m_iSecondaryAmmoType, weapon.iMaxAmmo2() );
                }
            }
        }
        player.pev.impulse = 0;
    }
#if METAMOD_DEBUG
    if( character is null )
        SetClass( player, Classification::Scientist );
#endif

    if( character is null )
    {
        if( gpGameStarted )
        {
            auto observer = player.GetObserver();

            if( !observer.IsObserver() )
            {
                observer.StartObserver( player.pev.origin, player.pev.angles, false );
            }

            // Let late joined players join a role
            if( float( data[ "pm_selectcd" ] ) <= g_Engine.time )
            {
                string name;
                int current = int( data[ "pm_select" ] );
                data[ "pm_select" ] = current = Math.clamp( 0, 3, current );

                data[ "pm_selectcd" ] = g_Engine.time + 0.5f;

                switch( current )
                {
                    case 1: name = "Security"; break;
                    case 2: name = "Maintenance"; break;
                    case 3: name = "Operator"; break;
                    case 0: name = "Scientist"; break;
                }

                string buffer;
                snprintf( buffer, "<- +moveleft | +moveright ->\n+use select %1\n", name );
                g_PlayerFuncs.PrintKeyBindingString( player, buffer );

                if( ( player.pev.button & IN_MOVELEFT ) != 0 )
                {
                    data[ "pm_select" ] = current-1;
                }
                else if( ( player.pev.button & IN_MOVERIGHT ) != 0 )
                {
                    data[ "pm_select" ] = current+1;
                }
                else if( ( player.pev.button & IN_USE ) != 0 )
                {
                    switch( current )
                    {
                        case 1: SetClass( player, Classification::Security ); break;
                        case 2: SetClass( player, Classification::Maintenance ); break;
                        case 3: SetClass( player, Classification::Operative ); break;
                        case 0: SetClass( player, Classification::Scientist ); break;
                    }
                }
            }
        }
        return HOOK_CONTINUE;
    }

    item_tracker::Think(player);

    player.SetOverriddenPlayerModel( character.Name );

    // Are we trying to use a flashlight without suit or with suit but no battery? Then try to use a weapon with attached flashlight
    if( player.pev.impulse == 100 && ( !character.IsHEV || player.pev.armorvalue <= 0 ) )
    {
        CBasePlayerWeapon@ weapon = cast<CBasePlayerWeapon@>( player.m_hActiveItem.GetEntity() );

        if( weapon !is null && ( weapon.pszAmmo2() != "bts:battery" && weapon.pszAmmo1() != "bts:battery" ) )
            @weapon = null;

        if( weapon is null )
        {
            for( uint ui = 0; ui < MAX_ITEM_TYPES; ui++ )
            {
                CBasePlayerItem@ item = player.m_rgpPlayerItems(ui);

                while( item !is null )
                {
                    @weapon = cast<CBasePlayerWeapon@>( item );

                    if( weapon !is null && weapon.pszAmmo2() == "bts:battery" || weapon.pszAmmo1() == "bts:battery" )
                    {
                        player.SelectItem( weapon.pev.classname );
                        weapon.Deploy();
                        ui = MAX_ITEM_TYPES; // Break for loop
                        break;
                    }

                    @weapon = null;
                    @item = cast<CBasePlayerWeapon@>( item.m_hNextItem.GetEntity() );
                }
            }
        }

        if( weapon !is null )
        {
            weapon.m_flNextSecondaryAttack = g_Engine.time;
            weapon.SecondaryAttack();
        }

        player.pev.impulse = 0;
    }

    if( character.IsHEV )
    {
        int state = int( data["helmet_nv_state"] );

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
                player.pev.impulse = 0;
            }

            data["helmet_nv_state"] = state = 0;
        }
        // Catch impulse command and toggle night vision state
        else if( player.pev.impulse == 100 )
        {
            data["helmet_nv_state"] = ( state == 1 ? 0 : 1 );

            if( state == 1 )
                data["helmet_nv_startup"] = 0;

            g_PlayerFuncs.ScreenFade( player, Vector( 250, 200, 20 ), 1.0f, 0.5f, 255.0f, state == 0 ? 6 : 2 );
            g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, ( state == 1 ? "bts_rc/items/nvg_off.wav" : "bts_rc/items/nvg_on.wav" ), 1.0, ATTN_NORM, 0, PITCH_NORM );
            player.pev.impulse = 0;
        }

        // Night vision ON, drain and light.
        if( state == 1 )
        {
            // Show even when dead lying.
            if( !player.GetObserver().IsObserver() )
            {
                if( float( data["helmet_nv_drain"] ) <= g_Engine.time )
                {
                    player.pev.armorvalue--;
                    data["helmet_nv_drain"] = 12 + g_Engine.time;
                }

                int nv_radius = int( data["helmet_nv_startup"] );

                if( nv_radius <= 40 )
                {
                    nv_radius++;
                    data["helmet_nv_startup"] = nv_radius;
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
                data["helmet_nv_state"] = 0;
            }
        }
    }

    return HOOK_CONTINUE;
} ) );
}
