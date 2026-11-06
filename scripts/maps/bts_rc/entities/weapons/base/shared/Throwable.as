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

mixin class MThrowable
{
    void Throw()
    {
        CBasePlayer@ player = this.owner;
        AttackType type = ( m_bRoll ? AttackType::Secondary : AttackType::Primary );

        float maximumVelocity = type == AttackType::Secondary ? config.secondary_distance : config.primary_distance;
        if( maximumVelocity <= 0.0f )
            maximumVelocity = this.m_bRoll ? 250.0f : 500.0f;

        Vector throwAngles = player.pev.v_angle + player.pev.punchangle;
        float velocity;

        if( this.m_bRoll )
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

        if( this.m_bRoll )
        {
            source = player.pev.origin + g_Engine.v_forward * 16.0f + g_Engine.v_up * 4.0f;
        }

        Vector throwVelocity = g_Engine.v_forward * velocity + player.pev.velocity;
        float damage = type == AttackType::Secondary && config.secondary_damage > 0.0f ? config.secondary_damage : config.primary_damage;
        SpawnThrowable( source, throwVelocity, damage );

        int ammo = player.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1;
        player.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );

        if( --ammo <= 0 )
        {
            self.DestroyItem();
            return;
        }

        m_fAttackStart = 0.0f;

        weapons::SetCooldown( self, player, config.GetCooldown( util::IsTrainedPersonal( player ), type ) );
    }
}
