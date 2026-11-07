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

// Base class for handgrenades / flares throwing
abstract class BTS_ThrowableWeapon : BTS_Weapon
{
    bool m_ThrowStarted;
    float m_ThrowDelay;
    AttackType m_ThrowType;

    bool CanHolster() // disable-line W119
    {
        return !m_ThrowStarted;
    }

    bool CanHaveDuplicates() // disable-line W119
    {
        return true;
    }

    void Holster( int skiplocal = 0 ) override
    {
        CBasePlayer@ player = this.owner;

        if( player.pev.deadflag != DEAD_NO && this.m_ThrowStarted )
        {
            Vector vecHandPos, vecVelocity;
            g_EngineFuncs.GetBonePosition( player.edict(), 28, vecHandPos, void );

            vecVelocity = Vector( Math.RandomFloat( -20.0, 20.0 ), Math.RandomFloat( -20.0, 20.0 ), 40.0 );

            ThrowCreate( vecHandPos, vecVelocity );
        }

        this.m_ThrowStarted = false;
        this.m_ThrowDelay = 0;

        BTS_Weapon::Holster( skiplocal );
    }

    void ThrowCreate( const Vector&in source, const Vector&in velocity )
    {
    }

    float ThrowEnd( AttackType&in type, const Vector&in source, const Vector&in velocity )
    {
        return 0.1f;
    }

    void ItemPreFrame()
    {
        BaseClass.ItemPreFrame();

        if( !this.m_ThrowStarted )
            return;

        CBasePlayer@ player = this.owner;

        if( ( player.pev.button & ( IN_ATTACK | IN_ATTACK2 | IN_ALT1 ) ) != 0 || this.m_ThrowDelay >= g_Engine.time )
        {
            self.m_flTimeWeaponIdle = g_Engine.time + 0.5f;
            return;
        }

        this.m_ThrowStarted = false;

        bool rolling = ( this.m_ThrowType == AttackType::Secondary );

        float maximumVelocity = rolling ? config.secondary_distance : config.primary_distance;

        if( maximumVelocity <= 0.0f )
        {
            maximumVelocity = rolling ? 250.0f : 500.0f;
        }

        Vector throwAngles = player.pev.v_angle + player.pev.punchangle;
        float velocity;

        if( rolling )
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

        if( rolling )
        {
            source = player.pev.origin + g_Engine.v_forward * 16.0f + g_Engine.v_up * 4.0f;
        }

        Vector throwVelocity = g_Engine.v_forward * velocity + player.pev.velocity;

        float delay = this.ThrowEnd( this.m_ThrowType, source, throwVelocity );

        this.StartSchedule( g_Scheduler.SetTimeout( @this, "Deploy", delay ) );

        int ammo = player.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1;
        player.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );

        if( --ammo <= 0 )
        {
            self.DestroyItem();
            return;
        }

        weapons::SetCooldown( self, player, config.GetCooldown( util::IsTrainedPersonal( player ), this.m_ThrowType ) );

        self.m_flTimeWeaponIdle += delay;
    }

    bool ThrowStart( AttackType&in type, float delay )
    {
        this.m_ThrowType = type;

        if( this.m_ThrowStarted )
        {
            return false;
        }

        if( this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return false;

        this.m_ThrowStarted = true;
        this.m_ThrowDelay = g_Engine.time + delay;

        return true;
    }
}
