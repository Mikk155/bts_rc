namespace Hooks
{
bool PlayerThink = g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink,
PlayerPostThinkHook( function( CBasePlayer@ player )
{
    if( player is null || !player.IsConnected() )
        return HOOK_CONTINUE;

    auto character = GetCharacter(player);

    dictionary@ data = player.GetUserData();

    if( character is null )
    {
        if( gpGameStarted )
        {
            auto observer = player.GetObserver();

            if( !observer.IsObserver() )
            {
                observer.StartObserver( player.pev.origin, player.pev.angles, false );
            }
        }

        // Let late joined players join a role
        if( float( data[ "pm_selectcd" ] ) <= g_Engine.time )
        {
            string name;
            int current = int( data[ "pm_select" ] );
            data[ "pm_select" ] = current = ( current < 0 ? 3 : 0 );

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
        return HOOK_CONTINUE;
    }

    player.SetOverriddenPlayerModel( character.Name );

    // Are we trying to use a flashlight without suit or with suit but no battery? Then try to use a weapon with attached flashlight
    if( player.pev.impulse == 100 && ( !character.IsHEV || player.pev.armorvalue <= 0 ))
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
        //player_models::hev_nightvision::Think( player );
    }

    return HOOK_CONTINUE;
} ) );
}
