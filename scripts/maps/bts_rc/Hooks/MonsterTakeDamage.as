namespace Hooks
{
    HookReturnCode MonsterTakeDamage( DamageInfo@ info )
    {
        if( info.pVictim is null )
            return HOOK_CONTINUE;

        CBaseMonster@ victim = cast<CBaseMonster@>( info.pVictim );

        if( victim is null )
            return HOOK_CONTINUE;

        dictionary@ data = info.pVictim.GetUserData();

        zombie_uncrab::MonsterTakeDamage( info, victim, data );

        return HOOK_CONTINUE;
    }
}