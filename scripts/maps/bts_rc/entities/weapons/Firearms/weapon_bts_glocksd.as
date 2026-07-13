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

final class ASWeaponGlockSDConfig : ASWeaponConfig
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
        return WeaponGlockSDAnim::Draw;
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
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/glocksd_fire1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/glocksd_fire2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/9mm_clip.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/desert_eagle_sight.wav" );
        g_SoundSystem.PrecacheSound( "weapons/desert_eagle_sight2.wav" );
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
                weapon.SendWeaponAnim( WeaponGlockSDAnim::Holster, 0, weapon.pev.body );
                break;
            }
            case Flashlight::State::TurnedOn:
            case Flashlight::State::TurnedOff:
            default:
            {
                weapon.SendWeaponAnim( WeaponGlockSDAnim::Flash, 0, weapon.pev.body );
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
            "description": "Control glocksd configuration",
            "allOf":
            [
                "ASWeaponConfig"
            ],
            "properties":
            {
            }
        }""";
    }

    bool Register( meta_api::json::v2::json@ json ) override {
        // Reload properties
        this.reload_time = 1.5f;

        return ASWeaponConfig::Register( json );
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
    Flash
};

class weapon_bts_glocksd : BTS_FireWeapon
{
    private EHandle m_hLaser;
    private int m_kLaserState = 0;

    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponGlockSDConfig;
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
            laser.pev.scale = 0.5f;
            laser.pev.rendermode = kRenderGlow;
            laser.pev.renderamt = 255.0f;
            laser.pev.renderfx = kRenderFxNoDissipation;
            g_EntityFuncs.DispatchSpawn( laser.edict() );
        }
        return m_hLaser.GetEntity();
    }

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 8, gpWeaponGlockSDConfig.max_clip );
        BTS_FireWeapon::Spawn();
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
        if( self.m_fInReload )
        {
            m_kLaserState = 0;
        }

        UpdateLaser();
        BaseClass.ItemPostFrame();
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
        float cone = Accuracy( 0.01f, 0.05f, 0.01f, 0.05f );
        if( m_kLaserState != 0 )
        {
            cone *= 0.3f;
        }

        uint8 anim = self.m_iClip > 1 ? WeaponGlockSDAnim::Shoot : WeaponGlockSDAnim::ShootEmpty;
        string szSound = ( Math.RandomLong( 0, 1 ) == 0 ) ? "bts_rc/weapons/glocksd_fire1.wav" : "bts_rc/weapons/glocksd_fire2.wav";

        FireBullet( 1, cone, gpWeaponGlockSDConfig.primary_damage, szSound, anim, models::shell, TE_BOUNCE_SHELL, Math.RandomFloat( 0.9f, 1.0f ), 98 + Math.RandomLong( 0, 3 ), false, QUIET_GUN_VOLUME, 0 );

        player.pev.punchangle.x = isTrainedPersonal ? -2.0f : -2.65f;

        self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.3f;
        
        self.m_flNextPrimaryAttack = g_Engine.time + ( isTrainedPersonal ? 0.05f : 0.10f );
        if( m_kLaserState != 0 )
        {
            self.m_flNextPrimaryAttack = g_Engine.time + ( isTrainedPersonal ? 0.10f : 0.13f );
        }

        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
    }

    

    private void UpdateLaser()
    {
        if( this.owner.FlashlightIsOn() )
        {
            if( m_kLaserState == 0 )
            {
                m_kLaserState = 2;
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
