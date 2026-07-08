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

final class ASWeaponEagleConfig : ASWeaponConfig
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
        return WeaponEagleAnim::Draw;
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
        g_Game.PrecacheModel( "sprites/laserdot.spr" );
        g_SoundSystem.PrecacheSound( "weapons/desert_eagle_fire.wav" );
        g_SoundSystem.PrecacheSound( "weapons/desert_eagle_sight.wav" );
        g_SoundSystem.PrecacheSound( "weapons/desert_eagle_sight2.wav" );
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
                weapon.SendWeaponAnim( WeaponEagleAnim::Holster, 0, weapon.pev.body );
                break;
            }
            case Flashlight::State::TurnedOn:
            case Flashlight::State::TurnedOff:
            default:
            {
                weapon.SendWeaponAnim( WeaponEagleAnim::Flash, 0, weapon.pev.body );
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
            "description": "Control eagle configuration",
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
        this.position = 9;
        this.weight = 10;
        this.deploy_time = 1.0;
        this.primary_maxammo = 18;
        this.primary_dropammo = 3;
        this.secondary_maxammo = 10;
        this.secondary_dropammo = 1;
        this.max_clip = 9;
        this.primary_damage = 65;
        this.primary_cooldown = 0.22;
        this.primary_trained_cooldown = 0.22;
        this.secondary_cooldown = 0.5;
        this.secondary_trained_cooldown = 0.5;

        return ASWeaponConfig::Register( json );
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
    Flash
};

class weapon_bts_eagle : BTS_FireWeapon
{
    private EHandle m_hLaser;
    private int m_kLaserState = 0;

    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponEagleConfig;
    }

    private CBaseEntity@ get_m_pLaser() property
    {
        if( !m_hLaser )
        {
            m_hLaser = EHandle( g_EntityFuncs.CreateEntity( "info_target", null, false ) );
            CBaseEntity@ laser = m_hLaser.GetEntity();
            g_EntityFuncs.SetModel( laser, "sprites/laserdot.spr" );
            laser.pev.movetype = MOVETYPE_NONE;
            laser.pev.solid = SOLID_NOT;
            laser.pev.scale = 0.75f;
            laser.pev.rendermode = kRenderGlow;
            laser.pev.renderamt = 255.0f;
            laser.pev.renderfx = kRenderFxNoDissipation;
            g_EntityFuncs.DispatchSpawn( laser.edict() );
        }
        return m_hLaser.GetEntity();
    }

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 1, gpWeaponEagleConfig.max_clip );
        self.m_iDefaultSecAmmo = Math.RandomLong( 1, 2 );
        BTS_FireWeapon::Spawn();
        pev.scale = 1.2;
        m_kLaserState = 0;
    }

    bool Deploy() override
    {
        m_kLaserState = 0;
        return BTS_FireWeapon::Deploy();
    }

    void Holster( int skiplocal = 0 ) override
    {
        if( m_hLaser )
        {
            g_EntityFuncs.Remove( m_hLaser.GetEntity() );
        }
        m_kLaserState = 0;
        Flashlight::Holster( this.owner, self, null );
        BTS_FireWeapon::Holster( skiplocal );
    }

    void UpdateOnRemove() override
    {
        if( m_hLaser )
        {
            g_EntityFuncs.Remove( m_hLaser.GetEntity() );
        }
        BTS_FireWeapon::UpdateOnRemove();
    }

    void ItemPostFrame()
    {
        UpdateLaser();
        BaseClass.ItemPostFrame();
    }

    float Idle() override
    {
        self.ResetEmptySound();

        if( self.m_iClip <= 0 )
        {
            return 2.0f;
        }

        const float flNextIdle = Math.RandomFloat( 0.0f, 1.0f );
        if( this.owner.FlashlightIsOn() )
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

        bool isTrainedPersonal = util::IsTrainedPersonal( player );

        float cone = Accuracy( 0.01f, 0.05f, 0.009f, 0.02f );
        if( m_kLaserState != 1 )
        {
            cone *= 3.0f;
        }

        uint8 anim = self.m_iClip > 1 ? WeaponEagleAnim::Shoot : WeaponEagleAnim::ShootEmpty;

        FireBullet( 1, cone, gpWeaponEagleConfig.primary_damage, "weapons/desert_eagle_fire.wav", anim, models::shell, TE_BOUNCE_SHELL, Math.RandomFloat( 0.92f, 1.0f ) );

        player.pev.punchangle.x = isTrainedPersonal ? -4.0f : -11.0f;

        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + ( ( m_kLaserState != 0 ) ? 0.5f : 0.22f );
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
    }

    void Reload()
    {
        if( self.m_iClip == gpWeaponEagleConfig.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
        {
            return;
        }

        float flNextAttack = self.m_flNextPrimaryAttack - 0.625;
        if( flNextAttack > g_Engine.time )
        {
            return;
        }

        if( this.owner.FlashlightIsOn() )
        {
            this.owner.FlashlightTurnOff();
        }
        m_kLaserState = 0;

        self.DefaultReload( gpWeaponEagleConfig.max_clip, self.m_iClip != 0 ? WeaponEagleAnim::Reload : WeaponEagleAnim::ReloadNoShot, 1.5f, pev.body );
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
        BaseClass.Reload();
    }

    private void UpdateLaser()
    {
        // Laser matches flashlight state
        if( this.owner.FlashlightIsOn() )
        {
            if( m_kLaserState == 0 )
            {
                m_kLaserState = 2; // trigger deploy sound and activation on next tick
            }
        }
        else
        {
            m_kLaserState = 0;
            if( m_hLaser )
            {
                m_hLaser.GetEntity().pev.effects |= EF_NODRAW;
            }
            return;
        }

        if( m_kLaserState == 0 )
        {
            return;
        }

        Math.MakeVectors( this.owner.pev.v_angle );
        Vector vecSrc = this.owner.GetGunPosition();
        Vector vecEnd = vecSrc + ( g_Engine.v_forward * 8192.0f );

        TraceResult tr;
        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, this.owner.edict(), tr );
        g_EntityFuncs.SetOrigin( m_pLaser, tr.vecEndPos );

        if( m_kLaserState == 2 )
        {
            m_kLaserState = 1;
            m_pLaser.pev.effects &= ~EF_NODRAW;
            PlaySound( "weapons/desert_eagle_sight.wav" );
        }

        if( m_pLaser.pev.dmgtime != 0.0f && g_Engine.time > m_pLaser.pev.dmgtime )
        {
            m_pLaser.pev.dmgtime = 0.0f;
            m_pLaser.pev.effects &= ~EF_NODRAW;
        }
    }
}
