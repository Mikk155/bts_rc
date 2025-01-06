/*
    Author: Mikk
*/

HookReturnCode monster_takedamage( DamageInfo@ pDamageInfo )
{
    if( pDamageInfo.flDamage <= 0 )
        return HOOK_CONTINUE;

    if( pDamageInfo.pVictim !is null )
    {
        CBaseMonster@ monster = cast<CBaseMonster@>( pDamageInfo.pVictim );

        if( monster !is null )
        {
            dictionary@ user_data = monster.GetUserData();

            if( monster.pev.classname == "monster_zombie" )
            {
                // Got hit on the headcrab. store damage
                if( monster.m_LastHitGroup == 1 )
                {
                    user_data[ "headcrab_damage" ] = int(user_data[ "headcrab_damage" ]) + pDamageInfo.flDamage;
                }
            }
        }
    }

    return HOOK_CONTINUE;
}
