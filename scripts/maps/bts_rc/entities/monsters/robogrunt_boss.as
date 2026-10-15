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

final class ASRoboGruntBoss : ASRoboGrunt
{
    const string& GetName() const override {
        return "robo_grunt_boss";
    }

    bool AddEntity( CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( monster is null || string( entity.pev.model ) != "models/bts_rc/monsters/robothwgrunt.mdl" )
            return false;

        if( !g_IsMainMap )
            SetDebugName( entity, "Robo grunt boss" );

        BurningMonster::SetInmune( entity );

        return EntityOverriden::AddEntity( entity, monster );
    }

    uint TakeDamage( uint index, CBaseMonster@ monster, DamageInfo@ info ) override
    {
        if( ( info.bitsDamageType & DMG_BLAST ) != 0 && monster.pev.health > 10.0 )
        {
            info.bitsDamageType &= ~DMG_BLAST | DMG_LAUNCH;
            info.flDamage *= this.m_fDmgMultiplierBlast;
        }

        return ASRoboGrunt::TakeDamage( index, monster, info );
    }
}
