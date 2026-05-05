namespace Hooks
{
    HookReturnCode MonsterKilled( CBaseMonster@ monster, CBaseEntity@ attacker, int gib )
    {
        if( monster is null )
            return HOOK_CONTINUE;

        dictionary@ data = monster.GetUserData();

        gpDeathDrop.Create( monster );
        gpBloodPuddle.Create( monster, gib );
        gpZombieUncrab.Create( monster, attacker, gib, data );

        return HOOK_CONTINUE;
    }
}
