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

funcdef void FireBulletCallback( TraceResult&in );

namespace HEVVoice
{
    void UpdateAmmo( CBasePlayer@ player, CBasePlayerWeapon@ weapon, int currentAmmo, int reserveAmmo, int maxAmmo )
    {
        if( player is null || weapon is null || !util::IsHEV( player ) )
            return;

        if( currentAmmo <= 0 && reserveAmmo <= 0 )
        {
            player.SetSuitUpdate( "!HEV_AMO0", false, 0 );
            return;
        }

        if( maxAmmo <= 0 || currentAmmo + reserveAmmo >= maxAmmo / 4 )
            return;

        dictionary@ data = player.GetUserData();
        float lastAmmoNotice;
        string keyName = "HEV_lowammo_" + weapon.GetClassname();

        if( !data.get( keyName, lastAmmoNotice ) || lastAmmoNotice < g_Engine.time )
        {
            data[ keyName ] = g_Engine.time + 60.0f;
            g_SoundSystem.EmitSoundDyn( weapon.edict(), CHAN_ITEM, "bts_rc/fvox/ammowarning.wav", 1.0f, ATTN_NORM, 0, PITCH_NORM );
        }
    }
}

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
    private CBasePlayer@ m_Player;
    private BTS_Weapon@ m_Weapon;
    private CBasePlayerWeapon@ m_WeaponEntity;
    private ASWeaponConfig@ m_Config;
    private AttackType m_AttackType;
    private uint m_WeaponAnim;
    private PLAYER_ANIM m_PlayerAnim;
    private int m_PlayerAnimMode;
    private bool m_PlayerIsTrainedPersonal;
    private FireBulletCallback@ m_Callback;
    private Bullet m_BulletType;
    private float m_AccuracyOverride;
    private float m_DamageOverride;
    private float m_DistanceOverride;
    private uint m_AmmoCost;
    private bool m_Tracer;
    private Vector m_SpreadOverride;

    ASBullet()
    {
        Clear();
    }

    // Set a custom logic instead of our FireBullets call you fire it yourself using a class or something
    ASBullet@ Callback( FireBulletCallback@ callback = null )
    {
        @this.m_Callback = callback;
        return this;
    }

    // Animation
    ASBullet@ Animation( uint weaponAnim = 0, PLAYER_ANIM playerAnim = PLAYER_ANIM::PLAYER_ATTACK1, int playerAnimMode = 0 )
    {
        this.m_WeaponAnim = weaponAnim;
        this.m_PlayerAnim = playerAnim;
        this.m_PlayerAnimMode = playerAnimMode;
        return this;
    }

    // Weapon that is shooting
    ASBullet@ Weapon( BTS_Weapon@ weapon = null )
    {
        if( weapon is null )
        {
            @this.m_Weapon = null;
            @this.m_Player = null;
            @this.m_Config = null;
            return this;
        }

        @this.m_Weapon = weapon;
        @this.m_Player = weapon.owner;
        @this.m_Config = weapon.config;
        @this.m_WeaponEntity = weapon.Entity;

        this.m_PlayerIsTrainedPersonal = util::IsTrainedPersonal( this.m_Player );

        return this;
    }

    // AttackType we're launching
    ASBullet@ Type( AttackType type = AttackType::Primary )
    {
        this.m_AttackType = type;
        return this;
    }

    // Amount of shots to fire (Shotguns would trace multiple pellets)
    ASBullet@ Shots( uint shots = 1 )
    {
        this.m_Shots = shots;
        return this;
    }

    ASBullet@ AmmoCost( uint ammoCost = 1 )
    {
        this.m_AmmoCost = ammoCost;
        return this;
    }

    ASBullet@ Accuracy( float accuracy = -1.0f )
    {
        this.m_AccuracyOverride = accuracy;
        return this;
    }

    ASBullet@ Damage( float damage = -1.0f )
    {
        this.m_DamageOverride = damage;
        return this;
    }

    ASBullet@ Range( float distance = -1.0f )
    {
        this.m_DistanceOverride = distance;
        return this;
    }

    ASBullet@ Tracer( bool enabled = false )
    {
        this.m_Tracer = enabled;
        return this;
    }

    ASBullet@ Spread( const Vector&in spread = Vector( -1.0f, -1.0f, -1.0f ) )
    {
        this.m_SpreadOverride = spread;
        return this;
    }

    // Whatever we can shoot under water
    ASBullet@ CanUseInWater( bool shootInWater = false )
    {
        this.m_Underwater = shootInWater;
        return this;
    }

    // Set muzzle flash size, 0 to not use muzzle flash at all
    ASBullet@ Flash( int flash = NORMAL_GUN_FLASH, bool dlight = true )
    {
#if SERVER
        switch( flash )
        {
            case 0:
            case 128:
            case 256:
            case 512:
                break;
            default:
                g_Logger.critical.print( "Weapon {} called bullet.Flash with value other than DIM_GUN_FLASH, BRIGHT_GUN_FLASH or NORMAL_GUN_FLASH!", { this.m_Config.GetName() } );
        }
#endif
        this.m_FlashSize = flash;
        this.m_FlashLight = dlight;
        return this;
    }

    // Volume for sound
    ASBullet@ Volume( float volume = 1.0, int weaponVolume = NORMAL_GUN_VOLUME )
    {
#if SERVER
        if( volume > 1.0 )
        {
            g_Logger.critical.print( "Weapon {} called bullet.Volume with value higher than 1.0!", { this.m_Config.GetName() } );
        }
        else if( volume <= 0.0 )
        {
            g_Logger.critical.print( "Weapon {} called bullet.Volume with value lower than 0.0!", { this.m_Config.GetName() } );
        }
#endif

        this.m_Volume = volume;
        this.m_WeaponVolume = weaponVolume;
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
        Volume( volume, weaponVolume );
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
            .Shell()
            .Type()
            .Weapon()
            .Animation()
            .Callback()
            .AmmoCost()
            .Accuracy()
            .Damage()
            .Range()
            .Tracer()
            .Spread();
    }

    // Return ammo count for the current type
    int get_CurrentAmmo() property
    {
        switch( this.m_AttackType )
        {
            case AttackType::Primary:
            {
                if( this.m_Config.max_clip != WEAPON_NOCLIP )
                    return this.m_WeaponEntity.m_iClip;
                return this.m_Player.m_rgAmmo( this.m_WeaponEntity.m_iPrimaryAmmoType );
            }
            case AttackType::Secondary:
            {
                return this.m_Player.m_rgAmmo( this.m_WeaponEntity.m_iSecondaryAmmoType );
            }
            default:
                return 0;
        }
    }

    int get_ReserveAmmo() property
    {
        switch( this.m_AttackType )
        {
            case AttackType::Primary:
            {
                if( this.m_Config.max_clip == WEAPON_NOCLIP )
                    return 0;
                return this.m_Player.m_rgAmmo( this.m_WeaponEntity.m_iPrimaryAmmoType );
            }
            case AttackType::Secondary:
            {
                return 0;
            }
            default:
                return 0;
        }
    }

    int get_MaxAmmo() property
    {
        return this.m_AttackType == AttackType::Secondary ? this.m_WeaponEntity.iMaxAmmo2() : this.m_WeaponEntity.iMaxAmmo1();
    }

    float get_ResolvedDamage() property
    {
        if( this.m_DamageOverride >= 0.0f )
            return this.m_DamageOverride;

        switch( this.m_AttackType )
        {
            case AttackType::Primary:
            {
                return this.m_Config.primary_damage;
            }
            case AttackType::Secondary:
            {
                return this.m_Config.secondary_damage;
            }
            default:
                return 0;
        }
    }

    float get_ResolvedAccuracy() property
    {
        float ironSightMultiplier = ( this.m_Player.pev.button & IN_ALT1 ) != 0 ? this.m_Config.iron_sight_accuracy : 1.0f;

        if( this.m_AccuracyOverride >= 0.0f )
            return this.m_AccuracyOverride * ironSightMultiplier;

        switch( this.m_AttackType )
        {
            case AttackType::Primary:
            {
                float accuracy = weapons::Accuracy( this.m_Player, this.m_Config.primary_accuracy, this.m_PlayerIsTrainedPersonal );
                ASWeaponLaserConfig@ laserConfig = cast<ASWeaponLaserConfig@>( this.m_Config );
                accuracy = laserConfig is null ? accuracy : laserConfig.LaserAccuracy( accuracy, this.m_WeaponEntity );
                return accuracy * ironSightMultiplier;
            }
            case AttackType::Secondary:
            {
                float accuracy = weapons::Accuracy( this.m_Player, this.m_Config.secondary_accuracy, this.m_PlayerIsTrainedPersonal );
                ASWeaponLaserConfig@ laserConfig = cast<ASWeaponLaserConfig@>( this.m_Config );
                accuracy = laserConfig is null ? accuracy : laserConfig.LaserAccuracy( accuracy, this.m_WeaponEntity );
                return accuracy * ironSightMultiplier;
            }
            default:
                return 0;
        }
    }

    Vector get_ResolvedSpread() property
    {
        if( this.m_SpreadOverride.x >= 0.0f )
        {
            float multiplier = ( this.m_Player.pev.button & IN_ALT1 ) != 0 ? this.m_Config.iron_sight_accuracy : 1.0f;
            return this.m_SpreadOverride * multiplier;
        }

        Vector configuredSpread = this.m_AttackType == AttackType::Secondary ? this.m_Config.secondary_spread : this.m_Config.primary_spread;
        if( configuredSpread.x >= 0.0f )
        {
            float multiplier = ( this.m_Player.pev.button & IN_ALT1 ) != 0 ? this.m_Config.iron_sight_accuracy : 1.0f;
            return configuredSpread * multiplier;
        }

        float accuracy = this.ResolvedAccuracy;
        return Vector( accuracy, accuracy, 0.0f );
    }

    void DeduceAmmo( uint value )
    {
        if( g_WeaponsConfig.infinite_ammo )
            return;

        int ammo = CurrentAmmo - int( value );

        switch( this.m_AttackType )
        {
            case AttackType::Primary:
            {
                if( this.m_Config.max_clip != WEAPON_NOCLIP )
                    this.m_WeaponEntity.m_iClip = ammo;
                else
                    this.m_Player.m_rgAmmo( this.m_WeaponEntity.m_iPrimaryAmmoType, ammo );
                break;
            }
            case AttackType::Secondary:
            {
                this.m_Player.m_rgAmmo( this.m_WeaponEntity.m_iSecondaryAmmoType, ammo );
                break;
            }
        }

        HEVVoice::UpdateAmmo( this.m_Player, this.m_WeaponEntity, ammo, this.ReserveAmmo, this.MaxAmmo );
    }

    float get_Distance() property
    {
        if( this.m_DistanceOverride > 0.0f )
            return this.m_DistanceOverride;

        float configuredDistance;

        switch( this.m_AttackType )
        {
            case AttackType::Primary: configuredDistance = this.m_Config.primary_distance; break;
            case AttackType::Secondary: configuredDistance = this.m_Config.secondary_distance; break;
            case AttackType::Tertiary: configuredDistance = this.m_Config.tertiary_distance; break;
        }

        return configuredDistance > 0.0f ? configuredDistance : 8192.0f;
    }

    // Fire bullet
    // If something in here is needed they could be moved to methods just like this.DeduceAmmo, get_Damage etc
    bool FireMonster( CBaseMonster@ monster, const Vector&in source, const Vector&in direction,
        const Vector&in spread, float distance, int damage, uint shots = 1 )
    {
        if( monster is null )
            return false;

        monster.FireBullets( shots, source, direction, spread, distance,
            Bullet::BULLET_PLAYER_CUSTOMDAMAGE, 0, damage, monster.pev );
        return true;
    }

    bool Fire()
    {
        int ammo = CurrentAmmo;

        if( ammo < int( this.m_AmmoCost ) || ( !this.m_Underwater && this.m_Player.pev.waterlevel == WATERLEVEL_HEAD ) )
        {
            this.m_WeaponEntity.pev.fuser4 = weapons::SetCooldown(
                this.m_WeaponEntity,
                this.m_Player,
                this.m_Config.GetCooldown( this.m_PlayerIsTrainedPersonal, this.m_AttackType, true )
            );
            this.m_WeaponEntity.PlayEmptySound();
            HEVVoice::UpdateAmmo( this.m_Player, this.m_WeaponEntity, ammo, this.ReserveAmmo, this.MaxAmmo );
            Clear();
            return false;
        }

        this.m_WeaponEntity.pev.fuser3 = weapons::SetCooldown(
            this.m_WeaponEntity,
            this.m_Player,
            this.m_Config.GetCooldown( this.m_PlayerIsTrainedPersonal, this.m_AttackType )
        );

        Vector gunPosition = this.m_Player.GetGunPosition();

        Math.MakeVectors( this.m_Player.pev.v_angle + this.m_Player.pev.punchangle );
        Vector vecSrc = gunPosition;
        Vector vecAiming = this.m_Player.GetAutoaimVector( AUTOAIM_5DEGREES );

        float x, y;
        g_Utility.GetCircularGaussianSpread( x, y );

        Vector spread = this.ResolvedSpread;
        Vector vecDir = vecAiming + x * spread.x * g_Engine.v_right + y * spread.y * g_Engine.v_up;

        TraceResult tr;

        if( this.m_Callback !is null )
        {
            Vector vecEnd = vecSrc + vecDir * this.Distance;
            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, this.m_Player.edict(), tr );
            this.m_Callback( tr );
        }
        else
        {
            this.m_WeaponEntity.FireBullets(
                this.m_Shots,
                vecSrc,
                vecAiming,
                spread,
                this.Distance,
                Bullet::BULLET_PLAYER_CUSTOMDAMAGE,
                0,
                int(this.ResolvedDamage),
                this.m_Player.pev
            );

            tr = g_Utility.GetGlobalTrace();
        }

        weapons::TraceEffects( this.m_WeaponEntity, this.m_Player, this.m_Config, tr );

        // -TODO Move these to build-pattern option when silencer weapons are made
        CSoundEnt@ sound = GetSoundEntInstance();
        sound.InsertSound( bits_SOUND_PLAYER, gunPosition, 2048, 0.3, this.m_Player );
        // Bullet impact
        sound.InsertSound( bits_SOUND_COMBAT, tr.vecEndPos, 1024, 0.3, this.m_Player );

        this.m_Player.m_iWeaponVolume = this.m_WeaponVolume;
        this.m_Player.m_iWeaponFlash = this.m_FlashSize;

        if( this.m_FlashLight )
        {
            this.m_Player.pev.effects |= EF_MUZZLEFLASH;
            this.m_WeaponEntity.pev.effects |= EF_MUZZLEFLASH;
        }

        g_SoundSystem.EmitSoundDyn( this.m_WeaponEntity.edict(), SOUND_CHANNEL::CHAN_WEAPON, this.m_SoundName, this.m_Volume, this.m_Attenuation, 0, this.m_Pitch );

        this.m_WeaponEntity.SendWeaponAnim( this.m_WeaponAnim, 0, this.m_Weapon.body );

        this.m_Player.SetAnimation( this.m_PlayerAnim );

        g_Utility.BubbleTrail( gunPosition, tr.vecEndPos, 16 );

        if( this.m_Tracer )
        {
            Vector playerHandPosition;
            g_EngineFuncs.GetAttachment( this.m_Player.edict(), 0, playerHandPosition, void );
            playerHandPosition = playerHandPosition + g_Engine.v_forward * 64 + g_Engine.v_right * 2;

            NetworkMessage msg( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
                msg.WriteByte( TE_TRACER );
                msg.WriteCoord( playerHandPosition.x );
                msg.WriteCoord( playerHandPosition.y );
                msg.WriteCoord( playerHandPosition.z );
                msg.WriteCoord( tr.vecEndPos.x );
                msg.WriteCoord( tr.vecEndPos.y );
                msg.WriteCoord( tr.vecEndPos.z );
            msg.End();
        }

        if( this.m_FlashLight )
        {
            NetworkMessage msg( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, gunPosition );
                msg.WriteByte( TE_DLIGHT );
                msg.WriteCoord( gunPosition.x );
                msg.WriteCoord( gunPosition.y );
                msg.WriteCoord( gunPosition.z );

                if( this.m_FlashSize >= BRIGHT_GUN_FLASH )
                    msg.WriteByte( 30 );
                else if( this.m_FlashSize >= NORMAL_GUN_FLASH )
                    msg.WriteByte( 20 );
                else
                    msg.WriteByte( 10 );

                msg.WriteByte( 255 );
                msg.WriteByte( 200 );
                msg.WriteByte( 150 );
                msg.WriteByte( 1 );
                msg.WriteByte( 100 );
            msg.End();
        }

        if( this.m_ShellModel > -1 )
        {
            Vector vecForward, vecRight, vecUp;
            g_EngineFuncs.AngleVectors( this.m_Player.pev.v_angle, vecForward, vecRight, vecUp );
            Vector vecOrigin = gunPosition + vecForward * 32.0f + vecRight * 6.0f - vecUp * 12.0f;
            Vector vecVelocity = this.m_Player.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
            float flYaw = this.m_Player.pev.v_angle.y;
            g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, flYaw, this.m_ShellModel, this.m_ShellType );
        }

        this.DeduceAmmo( this.m_AmmoCost );

        switch( this.m_AttackType )
        {
            case AttackType::Primary:
            {
                weapons::Kickback( this.m_Player, this.m_Config.primary_kickback, this.m_PlayerIsTrainedPersonal );
                break;
            }
            case AttackType::Secondary:
            {
                weapons::Kickback( this.m_Player, this.m_Config.secondary_kickback, this.m_PlayerIsTrainedPersonal );
            }
        }

        Clear();

        return true;
    }
}

// Configure a bullet using Builder-Patterns and fire it.
ASBullet bullet;
