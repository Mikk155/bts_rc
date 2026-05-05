namespace Hooks
{
    HookReturnCode MonsterKilled( CBaseMonster@ monster, CBaseEntity@ attacker, int gib )
    {
        if( monster is null )
            return HOOK_CONTINUE;

        dictionary@ data = monster.GetUserData();

        gpBloodPuddle.Create( monster, gib );
        deathdrop::MonsterKilled( monster, attacker, gib );
        gpZombieUncrab.Create( monster, attacker, gib, data );

        return HOOK_CONTINUE;
    }
}