/*
    as_command bts_rc_disable_bloodpuddles (value)

    values:
        1 = Disables blood puddles entirely
        0 = Generate blood puddles when possible. Default.
*/
CCVar@ cvar_bloodpuddles = CCVar( "bts_rc_disable_bloodpuddles", 0 );

/*
    as_command bts_rc_disable_bloodpuddles (value)

    values:
        1 = Disables player voices entirely
        0 = Player does voice responses to game events. Default.
*/
CCVar@ cvar_player_voices = CCVar( "bts_rc_disable_player_voices", 0 );
