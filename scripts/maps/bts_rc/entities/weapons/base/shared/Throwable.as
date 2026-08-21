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

interface IThrowable
{
    CBasePlayer@ get_Thrower();
    CBasePlayerWeapon@ get_ThrowableWeapon();
    ASWeaponConfig@ get_ThrowableConfig();
    AttackType get_ThrowAttackType();
    bool get_Rolling();
    void SpawnThrowable( const Vector&in source, const Vector&in velocity, float damage );
}

namespace weapons
{
    void Throw( IThrowable@ throwable )
    {
        if( throwable is null || throwable.Thrower is null || throwable.ThrowableWeapon is null || throwable.ThrowableConfig is null )
            return;

        CBasePlayer@ player = throwable.Thrower;
        ASWeaponConfig@ config = throwable.ThrowableConfig;
        AttackType type = throwable.ThrowAttackType;

        float maximumVelocity = type == AttackType::Secondary ? config.secondary_distance : config.primary_distance;
        if( maximumVelocity <= 0.0f )
            maximumVelocity = throwable.Rolling ? 250.0f : 500.0f;

        Vector throwAngles = player.pev.v_angle + player.pev.punchangle;
        float velocity;

        if( throwable.Rolling )
        {
            throwAngles.x = 0.0f;
            velocity = maximumVelocity;
        }
        else
        {
            throwAngles.x = -10.0f + throwAngles.x * ( throwAngles.x < 0.0f ? 0.888889f : 1.11111f );
            velocity = Math.min( ( 90.0f - throwAngles.x ) * 4.0f, maximumVelocity );
        }

        Math.MakeVectors( throwAngles );
        Vector source = player.GetGunPosition() + g_Engine.v_forward * 16.0f;

        if( throwable.Rolling )
            source = player.pev.origin + g_Engine.v_forward * 16.0f + g_Engine.v_up * 4.0f;

        Vector throwVelocity = g_Engine.v_forward * velocity + player.pev.velocity;
        float damage = type == AttackType::Secondary && config.secondary_damage > 0.0f ? config.secondary_damage : config.primary_damage;
        throwable.SpawnThrowable( source, throwVelocity, damage );

        weapons::SetCooldown( throwable.ThrowableWeapon, player, config.GetCooldown( util::IsTrainedPersonal( player ), type ) );
    }
}
