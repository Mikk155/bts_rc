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

class CWeaponBerettaConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_beretta";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_beretta.mdl";
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
        return WeaponBerettaAnim::Draw;
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
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/beretta_fire1.wav" );
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
                weapon.SendWeaponAnim( WeaponBerettaAnim::Holster, 0, weapon.pev.body );
                break;
            }
            case Flashlight::State::TurnedOn:
            case Flashlight::State::TurnedOff:
            default:
            {
                weapon.SendWeaponAnim( WeaponBerettaAnim::Flash, 0, weapon.pev.body );
                weapons::SetCooldown( weapon, player, this.GetCooldown( util::IsTrainedPersonal( player ), AttackType::Secondary ) );
                break;
            }
        }
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        this.slot = 1;
        this.position = 6;
        this.weight = 10;
        this.deploy_time = 1.0;
        this.primary_maxammo = 120;
        this.primary_dropammo = 15;
        this.secondary_maxammo = 10;
        this.secondary_dropammo = 1;
        this.max_clip = 15;
        this.primary_damage = 15;
        this.primary_cooldown = 0.10;
        this.primary_trained_cooldown = 0.05;
        this.secondary_cooldown = 0.5;
        this.secondary_trained_cooldown = 0.5;

        return ASWeaponConfig::Register( json );
    }
}

CWeaponBerettaConfig gpWeaponBerettaConfig;

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

    void PlayEmptySound()
    {
        if( self.m_bPlayEmptySound )
        {
            self.m_bPlayEmptySound = false;
            PlaySound( "hlclassic/weapons/357_cock1.wav", 0.8f );
        }
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

        if( ( player.m_afButtonPressed & IN_ATTACK ) == 0 )
        {
            return;
        }

        player.m_iWeaponVolume = NORMAL_GUN_VOLUME;
        player.m_iWeaponFlash = NORMAL_GUN_FLASH;

        --self.m_iClip;

        player.pev.effects |= EF_MUZZLEFLASH;
        pev.effects |= EF_MUZZLEFLASH;

        Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );
        Vector vecSrc = player.GetGunPosition();
        Vector vecAiming = player.GetAutoaimVector( AUTOAIM_5DEGREES );

        float x, y;
        g_Utility.GetCircularGaussianSpread( x, y );

        bool isTrainedPersonal = util::IsTrainedPersonal( player );

        float cone = Accuracy( 0.01f, 0.05f, 0.009f, 0.02f );
        cone *= 0.6f;

        Vector vecDir = vecAiming + x * cone * g_Engine.v_right + y * cone * g_Engine.v_up;
        Vector vecEnd = vecSrc + vecDir * 8192.0f;

        TraceResult tr;
        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, player.edict(), tr );
        self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, int( gpWeaponBerettaConfig.primary_damage ), player.pev );
        TraceEffects( tr, Bullet::BULLET_PLAYER_CUSTOMDAMAGE );

        PlayAnim( self.m_iClip != 0 ? WeaponBerettaAnim::Shoot : WeaponBerettaAnim::ShootEmpty );
        PlaySound( "bts_rc/weapons/beretta_fire1.wav", Math.RandomFloat( 0.92f, 1.0f ), 98 + Math.RandomLong( 0, 3 ) );
        player.pev.punchangle.x = isTrainedPersonal ? -2.0f : -2.5f;

        Vector vecForward, vecRight, vecUp;
        g_EngineFuncs.AngleVectors( player.pev.v_angle, vecForward, vecRight, vecUp );
        Vector vecOrigin = player.GetGunPosition() + vecForward * 32.0f + vecRight * 6.0f - vecUp * 12.0f;
        Vector vecVelocity = player.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
        g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, player.pev.v_angle.y, models::shell, TE_BOUNCE_SHELL );

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
        if( self.m_iClip == gpWeaponBerettaConfig.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
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

        self.DefaultReload( gpWeaponBerettaConfig.max_clip, self.m_iClip != 0 ? WeaponBerettaAnim::Reload : WeaponBerettaAnim::ReloadEmpty, 1.5f, pev.body );
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
        g_SoundSystem.EmitSoundDyn( this.owner.edict(), SOUND_CHANNEL::CHAN_ITEM, "bts_rc/weapons/9mm_clip.wav", 0.2f, ATTN_NORM, 0, PITCH_NORM );
        BaseClass.Reload();
    }
}
