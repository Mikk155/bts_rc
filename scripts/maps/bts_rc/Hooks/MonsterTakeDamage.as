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

        if( info.flDamage > 0 && victim.m_LastHitGroup == 1 && gpZombieUncrab.IsActive() && gpZombieUncrab.track_health && gpZombieUncrab.IsValid( info.pVictim ) )
            data["headcrab_damage"] = float( data["headcrab_damage"] ) + info.flDamage;

        return HOOK_CONTINUE;
    }
}