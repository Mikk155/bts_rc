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

final class ASWeaponBerettaConfig : ASWeaponLightConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_beretta";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_beretta.mdl";
    }

    const string& get_player_model_flashlight() override
    {
        return "models/bts_rc/weapons/p_beretta_cone.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_beretta.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_beretta.mdl";
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
        return "ammo_bts_beretta";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponBerettaAnim::Draw;
    }

    const int get_animation_holster() override
    {
        return WeaponBerettaAnim::Holster;
    }

    const uint8 get_animation_toggle() override
    {
        return WeaponBerettaAnim::Flash;
    }
}

ASWeaponBerettaConfig gpWeaponBerettaConfig;

enum WeaponBerettaAnim
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
    Flash
};

class weapon_bts_beretta : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponBerettaConfig;
    }

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 1, gpWeaponBerettaConfig.max_clip );
        self.m_iDefaultSecAmmo = Math.RandomLong( 1, 2 );
        BTS_FireWeapon::Spawn();
    }

    float Idle() override
    {
        self.ResetEmptySound();

        switch( RandomUint( 2 ) )
        {
            case 0:
            {
                PlayAnim( WeaponBerettaAnim::Idle1 );
                break;
            }
            case 1:
            {
                PlayAnim( WeaponBerettaAnim::Idle2 );
                break;
            }
            case 2:
            {
                PlayAnim( WeaponBerettaAnim::Idle3 );
                break;
            }
        }
        return Math.RandomFloat( 6.0f, 8.0f );
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        switch( type )
        {
            case AttackType::Tertiary:
            case AttackType::Secondary:
                return;
        }

        if( self.m_iClip <= 0 )
        {
            this.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.2f;
            return;
        }

        if( ( player.m_afButtonPressed & IN_ATTACK ) == 0 )
        {
            return;
        }

        bool isTrainedPersonal = util::IsTrainedPersonal( player );

        float cone = weapons::Accuracy( player, gpWeaponBerettaConfig.primary_accuracy, isTrainedPersonal );

        uint8 anim = self.m_iClip > 1 ? WeaponBerettaAnim::Shoot : WeaponBerettaAnim::ShootEmpty;

        FireBullet( 1, cone, gpWeaponBerettaConfig.primary_damage, "bts_rc/weapons/beretta_fire1.wav", anim, models::shell, TE_BOUNCE_SHELL, Math.RandomFloat( 0.92f, 1.0f ) );

        player.pev.punchangle.x = isTrainedPersonal ? -2.0f : -2.5f;

        self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.3f;
        self.m_flNextPrimaryAttack = g_Engine.time + ( isTrainedPersonal ? 0.05f : 0.10f );
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
    }

}
