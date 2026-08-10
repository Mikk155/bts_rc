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

final class ASBullet
{
    private bool m_Underwater;
    private uint m_Shots;
    private int m_FlashSize;
    private bool m_FlashLight;
    private int m_ShellModel;
    private TE_BOUNCE m_ShellType;
    private int m_WeaponVolume;
    private string m_SoundName;
    private float m_Volume;
    private int m_Pitch;
    private float m_Attenuation;

    // Amount of shots to fire (Shotguns would trace multiple pellets)
    ASBullet@ Shots( uint shots = 1 )
    {
        this.m_Shots = shots;
        return this;
    }

    // Whatever we can shoot under water
    ASBullet@ CanUseInWater( bool shootInWater = false )
    {
        this.m_Underwater = shootInWater;
        return this;
    }

    // Set muzzle flash size, -1 to not use muzzle flash at all
    ASBullet@ Flash( int flash = NORMAL_GUN_FLASH, bool dlight = true )
    {
        this.m_FlashSize = flash;
        this.m_FlashLight = dlight;
        return this;
    }

    // Sound to emit
    ASBullet@ Sound(
        const string &in soundName = String::EMPTY_STRING,
        float volume = 1.0,
        int pitch = PITCH_NORM,
        int weaponVolume = NORMAL_GUN_VOLUME,
        float attenuation = ATTN_NORM
    )
    {
        this.m_Pitch = pitch;
        this.m_Attenuation = attenuation;
        this.m_Volume = volume;
        this.m_WeaponVolume = weaponVolume;
        this.m_SoundName = soundName;
        return this;
    }

    // Shell model, -1 to not throw any shell. by default uses models::shell
    ASBullet@ Shell( int shellModel = -2, TE_BOUNCE shellType = TE_BOUNCE_SHELL )
    {
        if( shellModel == -2 )
            shellModel = models::shell;

        this.m_ShellModel = shellModel;
        this.m_ShellType = shellType;
        return this;
    }

    ASBullet@ Clear()
    {
        return this
            .Shots()
            .CanUseInWater()
            .Flash()
            .Sound()
            .Shell();
    }

    // Fire bullet
    void Fire( CBasePlayer@ player, BTS_Weapon@ weaponClass, AttackType attackType, ASWeaponConfig@ config, int Animation )
    {
        CBasePlayerWeapon@ weapon = weaponClass.Entity;

        int ammo;

        switch( attackType )
        {
            case AttackType::Primary:
            {
                if( config.max_clip != WEAPON_NOCLIP )
                    ammo = weapon.m_iClip;
                else
                    ammo = player.m_rgAmmo( weapon.m_iPrimaryAmmoType );
                break;
            }
            case AttackType::Secondary:
            {
                ammo = player.m_rgAmmo( weapon.m_iSecondaryAmmoType );
            }
        }

        bool isTrainedPersonal = util::IsTrainedPersonal( player );

        weapons::SetCooldown( weapon, player, config.GetCooldown( isTrainedPersonal, attackType ) );

        if( ( ammo <= 0 ) || ( !m_Underwater && player.pev.waterlevel == WATERLEVEL_HEAD ) )
        {
            weapon.PlayEmptySound();
            this.Clear();
            return;
        }

        float damage;
        float coneAccuracy;

        switch( attackType )
        {
            case AttackType::Primary:
            {
                if( config.max_clip != WEAPON_NOCLIP )
                    --weapon.m_iClip;
                else
                    player.m_rgAmmo( weapon.m_iPrimaryAmmoType, --ammo );

                damage = config.primary_damage;
                coneAccuracy = weapons::Accuracy( player, config.primary_accuracy, isTrainedPersonal );
                weapons::Kickback( player, config.primary_kickback, isTrainedPersonal );
                break;
            }
            case AttackType::Secondary:
            {
                player.m_rgAmmo( weapon.m_iSecondaryAmmoType, --ammo );
                damage = config.secondary_damage;
                coneAccuracy = weapons::Accuracy( player, config.secondary_accuracy, isTrainedPersonal );
                weapons::Kickback( player, config.secondary_kickback, isTrainedPersonal );
            }
        }

        player.m_iWeaponVolume = this.m_WeaponVolume;

        player.m_iWeaponFlash = this.m_FlashSize;

        if( ammo <= 0 && util::IsHEV( player ) )
        {
            player.SetSuitUpdate( "!HEV_AMO0", false, 0 );
        }

        if( m_FlashLight )
        {
            player.pev.effects |= EF_MUZZLEFLASH;
            weapon.pev.effects |= EF_MUZZLEFLASH;
        }

        Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );
        Vector vecSrc = player.GetGunPosition();
        Vector vecAiming = player.GetAutoaimVector( AUTOAIM_5DEGREES );

        float x, y;
        g_Utility.GetCircularGaussianSpread( x, y );

        Vector vecDir = vecAiming + x * coneAccuracy * g_Engine.v_right + y * coneAccuracy * g_Engine.v_up;
        Vector vecEnd = vecSrc + vecDir * 8192.0f;

        TraceResult tr;
        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, player.edict(), tr );
        weapon.FireBullets( m_Shots, vecSrc, vecDir, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, int(damage), player.pev );

        if( this.m_ShellModel > -1 )
        {
            Vector vecForward, vecRight, vecUp;
            g_EngineFuncs.AngleVectors( player.pev.v_angle, vecForward, vecRight, vecUp );
            Vector vecOrigin = player.GetGunPosition() + vecForward * 32.0f + vecRight * 6.0f - vecUp * 12.0f;
            Vector vecVelocity = player.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
            float flYaw = player.pev.v_angle.y;
            g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, flYaw, this.m_ShellModel, this.m_ShellType );
        }

        g_SoundSystem.EmitSoundDyn( weapon.edict(), SOUND_CHANNEL::CHAN_WEAPON, this.m_SoundName, this.m_Volume, this.m_Attenuation, 0, this.m_Pitch );

        weapon.SendWeaponAnim( Animation, 0, weaponClass.body );

        player.SetAnimation( PLAYER_ANIM::PLAYER_ATTACK1 );

        this.Clear();
    }
}

// Configure a bullet using Builder-Patterns and fire it.
ASBullet bullet;
