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

abstract class BTS_FireWeapon : BTS_Weapon
{
    float Accuracy( float tr, float def, float trd, float defd )
    {
        auto player = this.owner;

        if( util::IsTrainedPersonal( player ) )
        {
            if( ( player.pev.button & IN_DUCK ) != 0 )
            {
                return trd;
            }
            return tr;
        }
        else if( ( player.pev.button & IN_DUCK ) != 0 )
        {
            return defd;
        }
        return def;
    }

    void PlayEmptySound( AttackType type = AttackType::Primary )
    {
        self.pev.fuser4 = g_Engine.time + config.GetCooldown( util::IsTrainedPersonal( this.owner ), type, true );

        if( self.m_bPlayEmptySound )
        {
            self.m_bPlayEmptySound = false;
            PlaySound( "hlclassic/weapons/357_cock1.wav", 0.8f );
            CheckDepletedAmmo( type == AttackType::Secondary ? self.m_iSecondaryAmmoType : self.m_iPrimaryAmmoType );
        }
    }

    void ItemPostFrame()
    {
        BaseClass.ItemPostFrame();

        if( self.pev.fuser3 > 0.0f )
        {
            self.m_flNextPrimaryAttack = self.pev.fuser3;
            self.m_flNextSecondaryAttack = self.pev.fuser3;
            self.m_flNextTertiaryAttack = self.pev.fuser3;
            self.pev.fuser3 = 0.0f;
        }

        if( self.pev.fuser4 > 0.0f )
        {
            self.m_flNextPrimaryAttack = self.pev.fuser4;
            self.m_flNextSecondaryAttack = self.pev.fuser4;
            self.m_flNextTertiaryAttack = self.pev.fuser4;
            self.pev.fuser4 = 0.0f;
        }
    }

    void Reload()
    {
        if( self.m_iClip == config.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
        {
            return;
        }

        float flNextAttack = self.m_flNextPrimaryAttack - 0.3f;
        if( flNextAttack > g_Engine.time )
        {
            return;
        }

        Flashlight::TurnOff( this.owner, self, config );

        int anim = ( self.m_iClip != 0 ) ? config.reload_anim : config.reload_empty_anim;
        self.DefaultReload( config.max_clip, anim, config.reload_time, this.body );
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
        if( !config.reload_sound.IsEmpty() )
        {
            PlaySound( this.config.reload_sound, 0.2f );
        }
        BaseClass.Reload();
    }
}
