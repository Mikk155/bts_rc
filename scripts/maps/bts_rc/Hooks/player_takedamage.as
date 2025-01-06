/*
    Author: Mikk
*/

HookReturnCode player_takedamage( DamageInfo@ pDamageInfo )
{
    if( pDamageInfo.flDamage <= 0 )
        return HOOK_CONTINUE;

    CBaseEntity@ victim = pDamageInfo.pVictim;

    if( victim is null )
        return HOOK_CONTINUE;

    CBasePlayer@ player = cast<CBasePlayer@>( victim );

    if( player is null )
        return HOOK_CONTINUE;

    if( ( pDamageInfo.bitsDamageType & DMG_RADIATION ) != 0 )
    {
        uint uisize = CONST_GEIGER_SND.length();

        if( uisize > 0 )
        {
            const string sound = CONST_GEIGER_SND[ Math.RandomLong( 0, uisize - 1 ) ];
            g_SoundSystem.PlaySound( player.edict(), CHAN_VOICE, sound, 0.5, ATTN_NORM, 0, PITCH_NORM, 0, true, player.GetOrigin() );
        }

        switch( g_PlayerClass[ player, true ] )
        {
            case PM::HELMET:
            {
                pDamageInfo.flDamage *= CONST_HELMET_RADIATION_MULTIPLIER;
                break;
            }
            case PM::CLSUIT:
            {
                pDamageInfo.flDamage *= CONST_CLSUIT_RADIATION_MULTIPLIER;
                break;
            }
        }
    }

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

    return HOOK_CONTINUE;
}
