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

class CWeaponUziSDConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_uzisd";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_uzisd.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_uzisd.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_uzisd.mdl";
    }

    const string& get_animation_extension() override
    {
        return "mp5";
    }

    const string& get_primary_ammo() override
    {
        return "9mm";
    }

    const string& get_primary_ammoentity() override
    {
        return "ammo_bts_uzisd";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponUziSDAnim::Draw;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/uzi_fire1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/pl_gun2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/fidget1.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        ASWeaponConfig::Precache();
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        this.slot = 1;
        this.position = 15;
        this.weight = 10;
        this.deploy_time = 1.1;
        this.primary_maxammo = 120;
        this.primary_dropammo = 20;
        this.max_clip = 20;
        this.primary_damage = 17;
        this.primary_cooldown = 0.07;
        this.primary_trained_cooldown = 0.07;

        return ASWeaponConfig::Register( json );
    }
}

CWeaponUziSDConfig gpWeaponUziSDConfig;

enum WeaponUziSDAnim
{
    Idle1 = 0,
    Idle2,
    Idle3,
    Reload,
    Draw,
    Shoot,
    Draw2,
    Hhhhh,
    AkimboPull,
    AkimboIdle,
    AkimboReloadRight,
    AkimboReloadLeft,
    AkimboReloadBoth,
    AkimboShootLeft,
    AkimboShootRight,
    AkimboShootBoth,
    AkimboDeploy
};

class weapon_bts_uzisd : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponUziSDConfig;
    }

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 6, gpWeaponUziSDConfig.max_clip );
        BTS_FireWeapon::Spawn();
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
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
        float cone = Accuracy( 0.015f, 0.0175f, 0.015f, 0.0175f );

        // In Uzi SD we play weapons/pl_gun2.wav at full volume, and bts_rc/weapons/uzi_fire1.wav at 0.3f volume!
        FireBullet( 1, cone, gpWeaponUziSDConfig.primary_damage, "weapons/pl_gun2.wav", WeaponUziSDAnim::Shoot, models::shell, TE_BOUNCE_SHELL, Math.RandomFloat( 0.92f, 1.0f ), 98 + Math.RandomLong( 0, 3 ), false, QUIET_GUN_VOLUME, 0 );
        PlaySound( "bts_rc/weapons/uzi_fire1.wav", 0.3f, 98 + Math.RandomLong( 0, 3 ) );

        if( isTrainedPersonal )
        {
            player.pev.punchangle.x = -2.25f;
        }
        else
        {
            if( !player.pev.FlagBitSet( FL_ONGROUND ) )
            {
                player.pev.punchangle.x = float( Math.RandomLong( -5, 3 ) );
            }
            else if( player.pev.velocity.Length2D() > 0 )
            {
                player.pev.punchangle.x = float( Math.RandomLong( -4, 3 ) );
            }
            else if( player.pev.FlagBitSet( FL_DUCKING ) )
            {
                player.pev.punchangle.x = float( Math.RandomLong( -3, 2 ) );
            }
            else
            {
                player.pev.punchangle.x = float( Math.RandomLong( -3, 3 ) );
            }
        }

        if( self.m_iClip <= 0 && player.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && util::IsHEV( player ) )
        {
            player.SetSuitUpdate( "!HEV_AMO0", false, 0 );
        }

        self.m_flNextPrimaryAttack = g_Engine.time + 0.07f;
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
    }

    void Reload()
    {
        if( self.m_iClip == gpWeaponUziSDConfig.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
        {
            return;
        }

        self.DefaultReload( gpWeaponUziSDConfig.max_clip, WeaponUziSDAnim::Reload, 2.75f, pev.body );
        PlaySound( "bts_rc/weapons/fidget1.wav", 0.6f );
        self.m_flTimeWeaponIdle = g_Engine.time + 3.0f;
        BaseClass.Reload();
    }

    float Idle() override
    {
        self.ResetEmptySound();

        switch( Math.RandomLong( 0, 2 ) )
        {
            case 0:
                PlayAnim( WeaponUziSDAnim::Idle1 );
                break;
            case 1:
                PlayAnim( WeaponUziSDAnim::Idle2 );
                break;
            default:
                PlayAnim( WeaponUziSDAnim::Idle3 );
                break;
        }

        return Math.RandomFloat( 7.0f, 9.0f );
    }
}
