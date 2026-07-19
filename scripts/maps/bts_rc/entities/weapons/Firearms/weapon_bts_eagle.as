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

final class ASWeaponEagleConfig : ASWeaponLaserConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_eagle";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_desert_eagle.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_desert_eagle.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_desert_eagle.mdl";
    }

    const string& get_animation_extension() override
    {
        return "onehanded";
    }

    const string& get_primary_ammo() override
    {
        return "357";
    }

    const string& get_primary_ammoentity() override
    {
        return "ammo_bts_eagle";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponEagleAnim::Draw;
    }

    const uint8 get_hands_group() override
    {
        return 2;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "weapons/desert_eagle_fire.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        ASWeaponLaserConfig::Precache();
    }

    void LaserUpdate( bool active, CBasePlayer@ player, CBasePlayerWeapon@ weapon ) override
    {
        weapon.SendWeaponAnim( WeaponEagleAnim::LaserToggle, 0, weapon.pev.body );
        ASWeaponLaserConfig::LaserUpdate( active, player, weapon );
    }
}

ASWeaponEagleConfig gpWeaponEagleConfig;

enum WeaponEagleAnim
{
    Idle1 = 0,
    Idle2,
    Idle3,
    Idle4,
    Idle5,
    Shoot,
    ShootEmpty,
    ReloadNoShot,
    Reload,
    Draw,
    Holster,
    LaserToggle
};

class weapon_bts_eagle : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponEagleConfig;
    }

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 1, gpWeaponEagleConfig.max_clip );
        self.m_iDefaultSecAmmo = Math.RandomLong( 1, 2 );
        BTS_FireWeapon::Spawn();
        pev.scale = 1.2;
    }

    float Idle() override
    {
        self.ResetEmptySound();

        if( self.m_iClip <= 0 )
        {
            return 2.0f;
        }

        const float flNextIdle = Math.RandomFloat( 0.0f, 1.0f );

        if( self.pev.iuser1 != 0 )
        {
            if( flNextIdle > 0.5f )
            {
                PlayAnim( WeaponEagleAnim::Idle5 );
                return 2.0f;
            }
            else
            {
                PlayAnim( WeaponEagleAnim::Idle4 );
                return 2.5f;
            }
        }
        else
        {
            if( flNextIdle <= 0.3f )
            {
                PlayAnim( WeaponEagleAnim::Idle1 );
                return 2.5f;
            }
            else if( flNextIdle > 0.6f )
            {
                PlayAnim( WeaponEagleAnim::Idle3 );
                return 1.633f;
            }
            else
            {
                PlayAnim( WeaponEagleAnim::Idle2 );
                return 2.5f;
            }
        }
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        bool isTrainedPersonal = util::IsTrainedPersonal( player );

        switch( type )
        {
            case AttackType::Secondary:
            {
                gpWeaponEagleConfig.LaserToggle( isTrainedPersonal, type, self, this.owner );
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

                float cone = gpWeaponEagleConfig.LaserAccuracy( Accuracy( 0.01f, 0.05f, 0.009f, 0.02f ), self );

                uint8 anim = self.m_iClip > 1 ? WeaponEagleAnim::Shoot : WeaponEagleAnim::ShootEmpty;

                FireBullet( 1, cone, gpWeaponEagleConfig.primary_damage, "weapons/desert_eagle_fire.wav", anim, models::shell, TE_BOUNCE_SHELL, Math.RandomFloat( 0.92f, 1.0f ) );

                player.pev.punchangle.x = isTrainedPersonal ? -4.0f : -11.0f;

                SetCooldown( isTrainedPersonal, type );

                break;
            }
        }
    }
}
