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

final class ASWeaponGlockSDConfig : ASWeaponLaserConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_glocksd";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_9mmhandgunsd.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_9mmhandgunsd.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_9mmhandgunsd.mdl";
    }

    const string& get_player_model_laser() override
    {
        return "models/bts_rc/weapons/p_9mmhandgunsd_laser.mdl";
    }

    uint get_laser_animation() override
    {
        return WeaponGlockSDAnim::LaserToggle;
    }

    const string& get_animation_extension() override
    {
        return "onehanded";
    }

    const string& get_primary_ammo() override
    {
        return "9mm";
    }

    const string& get_primary_ammoentity() override
    {
        return "ammo_9mmclip";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponGlockSDAnim::Draw;
    }

    const uint8 get_hands_group() override
    {
        return 2;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/glocksd_fire1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/glocksd_fire2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/9mm_clip.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        ASWeaponLaserConfig::Precache();
    }
}

ASWeaponGlockSDConfig gpWeaponGlockSDConfig;

enum WeaponGlockSDAnim
{
    Idle1 = 0,
    Idle2,
    Idle3,
    Shoot,
    ShootEmpty,
    ReloadEmpty,
    Reload,
    Draw,
    Holster,
    AddSilencer,
    LaserToggle
};

class weapon_bts_glocksd : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponGlockSDConfig;
    }

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 8, gpWeaponGlockSDConfig.max_clip );
        BTS_FireWeapon::Spawn();
    }

    float Idle() override
    {
        switch( Math.RandomLong( 0, 3 ) )
        {
            case 0:
                PlayAnim( WeaponGlockSDAnim::Idle1 );
                break;
            case 1:
                PlayAnim( WeaponGlockSDAnim::Idle2 );
                break;
            default:
                PlayAnim( WeaponGlockSDAnim::Idle3 );
                break;
        }
        return Math.RandomFloat( 6.0f, 8.0f );
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        bool isTrainedPersonal = util::IsTrainedPersonal( player );

        switch( type )
        {
            case AttackType::Secondary:
            {
                gpWeaponGlockSDConfig.LaserToggle( isTrainedPersonal, type, self, this.owner );
                break;
            }
            case AttackType::Primary:
            {
                if( self.m_iClip <= 0 )
                {
                    this.PlayEmptySound();
                    self.m_flNextPrimaryAttack = g_Engine.time + 0.2f;
                    return;
                }

                float cone = gpWeaponGlockSDConfig.LaserAccuracy( Accuracy( 0.01f, 0.05f, 0.01f, 0.05f ), self );

                uint8 anim = self.m_iClip > 1 ? WeaponGlockSDAnim::Shoot : WeaponGlockSDAnim::ShootEmpty;
                string szSound = ( Math.RandomLong( 0, 1 ) == 0 ) ? "bts_rc/weapons/glocksd_fire1.wav" : "bts_rc/weapons/glocksd_fire2.wav";

                FireBullet( 1, cone, gpWeaponGlockSDConfig.primary_damage, szSound, anim, models::shell, TE_BOUNCE_SHELL, Math.RandomFloat( 0.9f, 1.0f ), 98 + Math.RandomLong( 0, 3 ), false, QUIET_GUN_VOLUME, 0 );

                player.pev.punchangle.x = isTrainedPersonal ? -2.0f : -2.65f;

                gpWeaponGlockSDConfig.SetCooldown( isTrainedPersonal, type, self, this.owner );

                self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );

                break;
            }
        }
    }
}
