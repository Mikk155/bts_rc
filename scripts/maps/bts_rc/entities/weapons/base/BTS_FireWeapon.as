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

    void PlayEmptySound()
    {
        if( self.m_bPlayEmptySound )
        {
            self.m_bPlayEmptySound = false;
            PlaySound( "hlclassic/weapons/357_cock1.wav", 0.8f );
        }
    }

    void FireBullet( int cShots, float flSpread, float flDamage, const string& in szSound, uint8 shootAnim, int iShellModel = -1, TE_BOUNCE iShellType = TE_BOUNCE_SHELL, float flVolume = 1.0f, int iPitch = 98 + Math.RandomLong( 0, 3 ), bool bMuzzleFlash = true, int iWeaponVolume = NORMAL_GUN_VOLUME, int iWeaponFlash = NORMAL_GUN_FLASH )
    {
        auto player = this.owner;

        if( player.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
        {
            this.PlayEmptySound();
            return;
        }

        player.m_iWeaponVolume = iWeaponVolume;
        player.m_iWeaponFlash = iWeaponFlash;

        --self.m_iClip;

        if( bMuzzleFlash )
        {
            player.pev.effects |= EF_MUZZLEFLASH;
            pev.effects |= EF_MUZZLEFLASH;
        }
        player.SetAnimation( PLAYER_ATTACK1 );

        Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );
        Vector vecSrc = player.GetGunPosition();
        Vector vecAiming = player.GetAutoaimVector( AUTOAIM_5DEGREES );

        float x, y;
        g_Utility.GetCircularGaussianSpread( x, y );

        Vector vecDir = vecAiming + x * flSpread * g_Engine.v_right + y * flSpread * g_Engine.v_up;
        Vector vecEnd = vecSrc + vecDir * 8192.0f;

        TraceResult tr;
        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, player.edict(), tr );
        self.FireBullets( cShots, vecSrc, vecDir, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, int( flDamage ), player.pev );
        TraceEffects( tr, Bullet::BULLET_PLAYER_CUSTOMDAMAGE );

        PlayAnim( shootAnim );
        PlaySound( szSound, flVolume, iPitch );

        if( iShellModel != -1 )
        {
            Vector vecForward, vecRight, vecUp;
            g_EngineFuncs.AngleVectors( player.pev.v_angle, vecForward, vecRight, vecUp );
            Vector vecOrigin = player.GetGunPosition() + vecForward * 32.0f + vecRight * 6.0f - vecUp * 12.0f;
            Vector vecVelocity = player.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
            float flYaw = player.pev.v_angle.y;
            g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, flYaw, iShellModel, iShellType );
        }
    }
}
