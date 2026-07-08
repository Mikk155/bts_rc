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

final class ASWeaponGlock17fConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_glock17f";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_glock17f.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_glock17f.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_glock17f.mdl";
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

    const string& get_secondary_ammo() override
    {
        return "bts_battery";
    }

    const string& get_secondary_ammoentity() override
    {
        return "ammo_bts_flashlight";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponGlock17fAnim::Draw;
    }

    const uint8 get_hands_group() override
    {
        return 2;
    }

    void WeaponHolster( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        Flashlight::Holster( player, weapon, character );
        ASWeaponConfig::WeaponHolster( player, weapon, character );
    }

    void PlayerThink( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        Flashlight::Think( player, weapon, character, this, this.player_model );
        ASWeaponConfig::PlayerThink( player, weapon, character );
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/glock_fire1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/9mm_clip.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        ASWeaponConfig::Precache();
    }

    void WeaponSecondaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        WeaponFlashlight( player, weapon, character );
    }

    void WeaponFlashlight( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        switch( Flashlight::Toggle( player, weapon, 5.0f ) )
        {
            case Flashlight::State::NoAmmo:
            {
                ASWeaponConfig::WeaponFlashlight( player, weapon, character );
                break;
            }
            case Flashlight::State::Reloading:
            {
                weapon.SendWeaponAnim( WeaponGlock17fAnim::Holster, 0, weapon.pev.body );
                break;
            }
            case Flashlight::State::TurnedOn:
            case Flashlight::State::TurnedOff:
            default:
            {
                weapon.SendWeaponAnim( WeaponGlock17fAnim::Flash, 0, weapon.pev.body );
                weapons::SetCooldown( weapon, player, this.GetCooldown( util::IsTrainedPersonal( player ), AttackType::Secondary ) );
                break;
            }
        }
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapon configuration",
            "description": "Control glock17f configuration",
            "allOf":
            [
                "ASWeaponConfig"
            ],
            "properties":
            {
            }
        }""";
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        this.slot = 1;
        this.position = 7;
        this.weight = 10;
        this.deploy_time = 0.6;
        this.primary_maxammo = 120;
        this.primary_dropammo = 17;
        this.secondary_maxammo = 10;
        this.secondary_dropammo = 1;
        this.max_clip = 17;
        this.primary_damage = 15;
        this.primary_cooldown = 0.10;
        this.primary_trained_cooldown = 0.05;
        this.secondary_cooldown = 0.5;
        this.secondary_trained_cooldown = 0.5;

        return ASWeaponConfig::Register( json );
    }
}

ASWeaponGlock17fConfig gpWeaponGlock17fConfig;

enum WeaponGlock17fAnim
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

class weapon_bts_glock17f : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponGlock17fConfig;
    }

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 8, gpWeaponGlock17fConfig.max_clip );
        self.m_iDefaultSecAmmo = Math.RandomLong( 1, 2 );
        BTS_FireWeapon::Spawn();
    }

    void Holster( int skiplocal = 0 ) override
    {
        Flashlight::Holster( this.owner, self, null );
        BTS_FireWeapon::Holster( skiplocal );
    }

    float Idle() override
    {
        switch( Math.RandomLong( 0, 3 ) )
        {
            case 0:
                PlayAnim( WeaponGlock17fAnim::Idle1 );
                break;
            case 1:
                PlayAnim( WeaponGlock17fAnim::Idle2 );
                break;
            default:
                PlayAnim( WeaponGlock17fAnim::Idle3 );
                break;
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

        // Wait for player to press attack key
        if( ( player.m_afButtonPressed & IN_ATTACK ) == 0 )
        {
            return;
        }

        bool isTrainedPersonal = util::IsTrainedPersonal( player );
        float spread = Accuracy( 0.01f, 0.05f, 0.01f, 0.05f );
        uint8 anim = self.m_iClip > 1 ? WeaponGlock17fAnim::Shoot : WeaponGlock17fAnim::ShootEmpty;

        FireBullet( 1, spread, gpWeaponGlock17fConfig.primary_damage, "bts_rc/weapons/glock_fire1.wav", anim, models::shell, TE_BOUNCE_SHELL, Math.RandomFloat( 0.92f, 1.0f ) );

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
        if( self.m_iClip == gpWeaponGlock17fConfig.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
        {
            return;
        }

        float flNextAttack = self.m_flNextPrimaryAttack - 0.3f;
        if( flNextAttack > g_Engine.time )
        {
            return;
        }

        if( this.owner.FlashlightIsOn() )
        {
            this.owner.FlashlightTurnOff();
        }

        self.DefaultReload( gpWeaponGlock17fConfig.max_clip, self.m_iClip != 0 ? WeaponGlock17fAnim::Reload : WeaponGlock17fAnim::ReloadEmpty, 1.5f, pev.body );
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
        PlaySound( "bts_rc/weapons/9mm_clip.wav", 0.2f );
        BaseClass.Reload();
    }
}
