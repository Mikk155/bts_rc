/*
    Author: Mikk
*/

HookReturnCode player_takedamage( DamageInfo@ pDamageInfo )
{
    if( pDamageInfo.flDamage <= 0 )
        return HOOK_CONTINUE;

    CBaseEntity@ victim = pDamageInfo.pVictim;

    if( victim !is null )
    {
        CBasePlayer@ player = cast<CBasePlayer@>( victim );

        if( player !is null )
        {
            if( cvar_player_voices.GetInt() == 0 )
            {
                CVoices@ voices = g_VoiceResponse[ player ];

                if( voices !is null )
                {
                    /*if( player.pev.waterlevel == WATERLEVEL_HEAD )
                    {
                        if( voices.drowndamage !is null )
                        {
                            voices.drowndamage.PlaySound( player );
                        }
                    }
                    else
                    {*/
                        // Player will be dead
                        if( player.pev.health - pDamageInfo.flDamage <= 0 )
                        {
                            if( voices.killed !is null )
                            {
                                voices.killed.PlaySound( player );
                            }
                        }
                        else
                        {
                            if( voices.takedamage !is null )
                            {
                                voices.takedamage.PlaySound( player );
                            }
                        }
                    //}
                }
            }
        }
    }
    return HOOK_CONTINUE;
}
