namespace player_models
{
    namespace class_selector
    {
        void Think( CBasePlayer@ player )
        {
            if( player is null )
                return;

            dictionary@ user_data = player.GetUserData();

            if( float( user_data[ "pm_selectcd" ] ) > g_Engine.time )
                return;

            int current = int( user_data[ "pm_select" ] );

            string name;

            if( current < 0 )
            {
                user_data[ "pm_select" ] = current = 3;
            }
            else if( current > 3 )
            {
                user_data[ "pm_select" ] = current = 0;
            }

            switch( current )
            {
                case 1:
                    name = "Security";
                break;
                case 2:
                    name = "Maintenance";
                break;
                case 3:
                    name = "Operator";
                break;
                case 0:
                    name = "Scientist";
                break;
            }

            string buffer;
            snprintf( buffer, "<- +moveleft | +moveright ->\n+use select %1\n", name );
            g_PlayerFuncs.PrintKeyBindingString( player, buffer );

            if( ( player.pev.button & IN_MOVELEFT ) != 0 )
            {
                user_data[ "pm_select" ] = current-1;
                user_data[ "pm_selectcd" ] = g_Engine.time + 0.5f;
            }
            else if( ( player.pev.button & IN_MOVERIGHT ) != 0 )
            {
                user_data[ "pm_select" ] = current+1;
                user_data[ "pm_selectcd" ] = g_Engine.time + 0.5f;
            }
            else if( ( player.pev.button & IN_USE ) != 0 )
            {
                switch( current )
                {
                    case 1:
                        player_models::SetClass( player, PM::BARNEY );
                    break;
                    case 2:
                        player_models::SetClass( player, PM::CONSTRUCTION );
                    break;
                    case 3:
                        player_models::SetClass( player, PM::OPERATIVE );
                    break;
                    case 0:
                        player_models::SetClass( player, PM::SCIENTIST );
                    break;
                }
            }
        }
    }
}