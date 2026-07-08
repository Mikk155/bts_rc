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

final class ASWeaponGlockConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_glock";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_9mmhandgun.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_9mmhandgun.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_9mmhandgun.mdl";
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
        return WeaponGlockAnim::Draw;
    }

    const uint8 get_hands_group() override
    {
        return 2;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/glock_fire1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/9mm_clip.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        ASWeaponConfig::Precache();
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        this.slot = 1;
        this.position = 4;
        this.weight = 10;
        this.deploy_time = 0.45;
        this.primary_maxammo = 120;
        this.primary_dropammo = 17;
        this.max_clip = 17;
        this.primary_damage = 15;
        this.primary_cooldown = 0.10;
        this.primary_trained_cooldown = 0.05;

        return ASWeaponConfig::Register( json );
    }
}

ASWeaponGlockConfig gpWeaponGlockConfig;

enum WeaponGlockAnim
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
    AddSilencer
};

class weapon_bts_glock : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponGlockConfig;
    }

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 8, gpWeaponGlockConfig.max_clip );
        BTS_FireWeapon::Spawn();
    }

    float Idle() override
    {
        switch( Math.RandomLong( 0, 3 ) )
        {
            case 0:
                PlayAnim( WeaponGlockAnim::Idle1 );
                break;
            case 1:
                PlayAnim( WeaponGlockAnim::Idle2 );
                break;
            default:
                PlayAnim( WeaponGlockAnim::Idle3 );
                break;
        }
        return Math.RandomFloat( 6.0f, 8.0f );
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        switch( type )
        {
            case AttackType::Tertiary:
                return;
        }

        // Glock shoots on primary AND secondary attack (secondary is faster but less accurate)
        const float spread = ( type == AttackType::Primary ) ?
            Accuracy( 0.01f, 0.03f, 0.01f, 0.04f ) :
            Accuracy( 0.1f, 0.2f, 0.01f, 0.02f );

        if( self.m_iClip <= 0 )
        {
            this.PlayEmptySound();
            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.2f;
            return;
        }

        // Wait for player to press attack key
        if( ( player.m_afButtonPressed & ( IN_ATTACK | IN_ATTACK2 ) ) == 0 )
        {
            return;
        }

        bool isTrainedPersonal = util::IsTrainedPersonal( player );
        uint8 anim = self.m_iClip > 1 ? WeaponGlockAnim::Shoot : WeaponGlockAnim::ShootEmpty;

        FireBullet( 1, spread, gpWeaponGlockConfig.primary_damage, "bts_rc/weapons/glock_fire1.wav", anim, models::shell, TE_BOUNCE_SHELL, Math.RandomFloat( 0.92f, 1.0f ) );

        player.pev.punchangle.x = isTrainedPersonal ? -2.0f : -2.65f;

        if( self.m_iClip <= 0 && player.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && util::IsHEV( player ) )
        {
            player.SetSuitUpdate( "!HEV_AMO0", false, 0 );
        }

        self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.3f;
        self.m_flNextPrimaryAttack = g_Engine.time + ( isTrainedPersonal ? 0.05f : 0.10f );
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
    }

    void Reload()
    {
        if( self.m_iClip == gpWeaponGlockConfig.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
        {
            return;
        }

        self.DefaultReload( gpWeaponGlockConfig.max_clip, self.m_iClip != 0 ? WeaponGlockAnim::Reload : WeaponGlockAnim::ReloadEmpty, 1.5f, pev.body );
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
        PlaySound( "bts_rc/weapons/9mm_clip.wav", 0.2f );
        BaseClass.Reload();
    }
}
