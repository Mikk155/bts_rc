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

final class ASWeaponGlock18Config : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_glock18";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_glock18.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_glock18.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_glock18.mdl";
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
        return WeaponGlock18Anim::Draw;
    }

    const uint8 get_hands_group() override
    {
        return 2;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/glock18_fire1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/9mm_clip.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/reload2.wav" );
        ASWeaponConfig::Precache();
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapon configuration",
            "description": "Control glock18 configuration",
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
        this.position = 10;
        this.weight = 10;
        this.deploy_time = 0.6;
        this.primary_maxammo = 120;
        this.primary_dropammo = 19;
        this.max_clip = 19;
        this.primary_damage = 15;
        this.primary_cooldown = 0.0625;
        this.primary_trained_cooldown = 0.0625;
        this.secondary_cooldown = 0.5;
        this.secondary_trained_cooldown = 0.5;

        return ASWeaponConfig::Register( json );
    }
}

ASWeaponGlock18Config gpWeaponGlock18Config;

enum WeaponGlock18Anim
{
    Idle1 = 0,
    Idle2,
    Idle3,
    Shoot,
    ShootEmpty,
    Reload,
    ReloadEmpty,
    Draw,
    Holster,
    AddSilencer
};

enum Glock18Mode
{
    SemiAuto = 0,
    FullAuto
}

class weapon_bts_glock18 : BTS_FireWeapon
{
    private Glock18Mode m_iFireMode = Glock18Mode::SemiAuto;

    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponGlock18Config;
    }

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 9, gpWeaponGlock18Config.max_clip );
        BTS_FireWeapon::Spawn();
        m_iFireMode = Glock18Mode::SemiAuto;
    }

    float Idle() override
    {
        switch( Math.RandomLong( 0, 3 ) )
        {
            case 0:
                PlayAnim( WeaponGlock18Anim::Idle1 );
                break;
            case 1:
                PlayAnim( WeaponGlock18Anim::Idle2 );
                break;
            default:
                PlayAnim( WeaponGlock18Anim::Idle3 );
                break;
        }
        return Math.RandomFloat( 6.0f, 8.0f );
    }

    void ToggleFireMode()
    {
        if( m_iFireMode == Glock18Mode::SemiAuto )
        {
            m_iFireMode = Glock18Mode::FullAuto;
            g_EngineFuncs.ClientPrintf( this.owner, print_center, " Full-Auto\n" );
            PlayAnim( WeaponGlock18Anim::AddSilencer );
            PlaySound( "hlclassic/weapons/reload2.wav", 0.8f, 112 );
        }
        else
        {
            m_iFireMode = Glock18Mode::SemiAuto;
            g_EngineFuncs.ClientPrintf( this.owner, print_center, " Semi-Auto\n" );
            PlayAnim( WeaponGlock18Anim::AddSilencer );
            PlaySound( "hlclassic/weapons/reload2.wav", 0.8f, 98 );
        }
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 5.0f, 10.0f );
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        if( type == AttackType::Secondary )
        {
            ToggleFireMode();
            return;
        }

        if( type != AttackType::Primary )
        {
            return;
        }

        if( self.m_iClip <= 0 )
        {
            this.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.2f;
            return;
        }

        bool isTrainedPersonal = util::IsTrainedPersonal( player );
        float cone = Accuracy( 0.01f, 0.05f, 0.01f, 0.05f );
        uint8 anim = self.m_iClip > 1 ? WeaponGlock18Anim::Shoot : WeaponGlock18Anim::ShootEmpty;

        FireBullet( 1, cone, gpWeaponGlock18Config.primary_damage, "bts_rc/weapons/glock18_fire1.wav", anim, models::shell, TE_BOUNCE_SHELL, Math.RandomFloat( 0.92f, 1.0f ) );

        if( m_iFireMode == Glock18Mode::SemiAuto )
        {
            player.pev.punchangle.x = isTrainedPersonal ? -2.0f : -4.0f;
        }
        else
        {
            player.pev.punchangle.x = isTrainedPersonal ? -2.0f : float( Math.RandomLong( -6, 3 ) );
        }

        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + ( ( m_iFireMode == Glock18Mode::SemiAuto ) ? 0.3f : 0.0625f );
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
    }

    void Reload()
    {
        if( self.m_iClip == gpWeaponGlock18Config.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
        {
            return;
        }

        self.DefaultReload( gpWeaponGlock18Config.max_clip, self.m_iClip != 0 ? WeaponGlock18Anim::ReloadEmpty : WeaponGlock18Anim::Reload, 2.0f, pev.body );
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
        PlaySound( "bts_rc/weapons/9mm_clip.wav", 0.2f );
        BaseClass.Reload();
    }
}
