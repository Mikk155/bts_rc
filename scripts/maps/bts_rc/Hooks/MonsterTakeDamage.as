/**
*   Copyright (c) 2026 Mikk155 and contributors of bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software to use, copy, modify, merge, publish, distribute, sublicense,
*   and/or sell copies of the Software under the following conditions:
*   
*   A reference to the original project must be included in all copies or substantial
*   portions of the Software. This must include, at minimum, a URL to:
*   https://github.com/Mikk155/bts_rc
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies of the Software when distributed as a whole.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
**/

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

        if( info.flDamage > 0 && victim.m_LastHitGroup == 1 )
        {
            if( gpZombieUncrab !is null && gpZombieUncrab.TrackHealth && gpZombieUncrab.IsValid( info.pVictim ) )
            {
                data["headcrab_damage"] = float( data["headcrab_damage"] ) + info.flDamage;
            }
        }

        string classname = victim.GetClassname();
        string model = string( victim.pev.model );

        if( gpZombieEngineer.IsValid( classname, model ) )
            gpZombieEngineer.TakeDamage( victim, info );
        else if( gpRoboGrunt.IsValid( classname, model ) )
            gpRoboGrunt.TakeDamage( victim, info );
        else if( gpRoboGruntBoss.IsValid( classname, model ) )
            gpRoboGruntBoss.TakeDamage( victim, info );

        return HOOK_CONTINUE;
    }
}
