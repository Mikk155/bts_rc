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

enum WhackState
{
    Idle,
    Holding,
    Released
};

// Inheriting from this class will make the Secondary attack be called twice when start holding right click and when releasing.
// ifm_WhackState is Holding then the attack wasn't released but started charging
abstract class BTS_MeleeCharge : BTS_MeleeWeapon
{
    WhackState m_WhackState = WhackState::Idle;

    void Holster( int skiplocal = 0 ) override
    {
        m_WhackState = WhackState::Idle;
        BTS_MeleeWeapon::Holster( skiplocal );
    }

    void SecondaryAttack() override
    {
        auto player = this.owner;

        player.pev.button |= IN_ATTACK2;

        self.m_flTimeWeaponIdle = Math.max( self.m_flTimeWeaponIdle, g_Engine.time + 0.5f );

        switch( m_WhackState )
        {
            case WhackState::Idle:
            {
                m_WhackState = WhackState::Holding;
                BTS_MeleeWeapon::SecondaryAttack();
                player.m_flNextAttack = 1.0f;
                ForcePlayerAnim( 25, 28 ); // ref_cock_wrench, crouch_cock_wrench
                break;
            }
            case WhackState::Holding:
            {
                ForcePlayerAnim( 26, 29 ); // ref_hold_wrench, crouch_hold_wrench
                break;
            }
        }
    }

    void ItemPostFrame()
    {
        if( m_WhackState == WhackState::Holding )
        {
            CBasePlayer@ player = this.owner;

            if( ( player.pev.button & IN_ATTACK2 ) == 0 )
            {
                player.m_flNextAttack = 0.5f;
                m_WhackState = WhackState::Released;
                BTS_MeleeWeapon::SecondaryAttack();
                ForcePlayerAnim( 27, 30 ); // ref_shoot_wrench, crouch_shoot_wrench
                m_WhackState = WhackState::Idle;
            }
        }

        BaseClass.ItemPostFrame();
    }
}
