/*
    Author: Mikk
*/

const array<string>@ geiger_snds = {
    "player/geiger1.wav",
    "player/geiger2.wav",
    "player/geiger3.wav",
    "player/geiger4.wav",
    "player/geiger5.wav",
    "player/geiger6.wav" };

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
        uint uisize = geiger_snds.length();

        if( uisize > 0 )
        {
            const string sound = geiger_snds[Math.RandomLong( 0, uisize - 1 )];
            g_SoundSystem.PlaySound( player.edict(), CHAN_VOICE, sound, 0.5, ATTN_NORM, 0, PITCH_NORM, 0, true, player.GetOrigin() );
        }

        switch( g_PlayerClass[player, true] )
        {
            case PM::CLSUIT:
            {
                float dmg = pDamageInfo.flDamage * 0.3;
                if( dmg > 1.0 )
                    pDamageInfo.flDamage = dmg;
                break;
            }
            case PM::HELMET:
            {
                pDamageInfo.flDamage = 0;
                return HOOK_CONTINUE;
            }
        }
    }

    return HOOK_CONTINUE;
}
