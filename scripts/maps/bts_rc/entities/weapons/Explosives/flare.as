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

final class ASWeaponFlareConfig : ASWeaponConfig, ASMFlareConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_flare";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_flare.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_flare.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_flare.mdl";
    }

    const string& get_animation_extension() override
    {
        return "gren";
    }

    const string& get_primary_ammo() override
    {
        return "Trip Mine";
    }

    const string& get_primary_ammoentity() override
    {
        return "weapon_bts_flare";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponFlareAnim::Draw;
    }

    const uint8 get_hands_group() override
    {
        return 0;
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapon config",
            "description": "weapon-related gameplay modifiers.",
            "allOf":
            [
                "ASWeaponConfig",
                "ASMFlareConfigSchema"
            ]
        }""";
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        flare_register(json);
        return ASWeaponConfig::Register( json );
    }
}

ASWeaponFlareConfig gpWeaponFlareConfig;

enum WeaponFlareAnim
{
    Idle = 0,
    PullPin,
    Throw,
    Draw,
    Toss,
    PullHold,
    Hold
};

class weapon_bts_flare : BTS_Weapon, IThrowable
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponFlareConfig;
    }

    private int throw = 0;
    private float m_fAttackStart = 0.0f;
    private ASFlare@ m_FlareOnHold;
    private bool m_bInAttack = false;
    private bool m_bThrown = false;
    private int m_iAmmoSave = 0;

    CBasePlayer@ get_Thrower() property { return this.owner; }
    CBasePlayerWeapon@ get_ThrowableWeapon() property { return self; }
    ASWeaponConfig@ get_ThrowableConfig() property { return this.config; }
    AttackType get_ThrowAttackType() property { return throw == 1 ? AttackType::Secondary : AttackType::Primary; }
    bool get_Rolling() property { return throw == 1; }

    void SpawnThrowable( const Vector&in source, const Vector&in velocity, float damage )
    {
        gpWeaponFlareConfig.flare_create( this.owner, source, velocity );
    }

    void Spawn() override
    {
        BTS_Weapon::Spawn();
    }

    bool CanHaveDuplicates()
    {
        return true;
    }

    bool Deploy() override
    {
        PlaySound( "bts_rc/weapons/flare_deploy.wav", 0.6f, PITCH_NORM, CHAN_ITEM );
        m_iAmmoSave = 0;
        return BTS_Weapon::Deploy();
    }

    bool CanHolster()
    {
        return m_fAttackStart == 0.0f;
    }

    bool CanDeploy()
    {
        return this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0;
    }

    CBasePlayerItem@ DropItem()
    {
        m_iAmmoSave = this.owner.AmmoInventory( self.m_iPrimaryAmmoType );
        return self;
    }

    void DropHoldingFlare()
    {
        if( this.m_FlareOnHold !is null )
        {
            this.owner.m_rgAmmo( self.m_iPrimaryAmmoType, this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
            this.m_FlareOnHold.self.pev.effects &= ~EF_NODRAW;
            this.m_FlareOnHold.self.pev.velocity.z = -90;
            this.m_FlareOnHold.self.pev.movetype = MOVETYPE_TOSS;
            @this.m_FlareOnHold = null;
        }
    }

    void Holster( int skiplocal = 0 )
    {
        m_bThrown = false;
        m_bInAttack = false;
        m_fAttackStart = 0.0f;

        ClearTimerList();

        if( this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
        {
            m_iAmmoSave = this.owner.m_rgAmmo( self.m_iPrimaryAmmoType );
        }

        if( m_iAmmoSave <= 0 )
        {
            g_Scheduler.SetTimeout( "DestroyThrowableWeapon", 0.1f, EHandle( self ) );
        }

        this.DropHoldingFlare();

        BaseClass.Holster( skiplocal );
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        this.DropHoldingFlare();

        if( this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        if( m_fAttackStart < 0.0f || m_fAttackStart > 0.0f )
            return;

        this.SetCooldown( util::IsTrainedPersonal( this.owner ), type );

        switch( type )
        {
            case AttackType::Primary:
            {
                throw = 0;
                m_bInAttack = true;
                m_fAttackStart = g_Engine.time + ( 25.0f / 30.0f );
                PlayAnim( WeaponFlareAnim::PullPin );
                break;
            }
            case AttackType::Secondary:
            {
                throw = 1;
                m_bInAttack = true;
                m_fAttackStart = g_Engine.time + ( 25.0f / 25.0f );
                PlayAnim( WeaponFlareAnim::PullPin );
                break;
            }
            case AttackType::Tertiary:
            {
                PlayAnim( WeaponFlareAnim::PullHold );
//                @this.m_FlareOnHold = FLARE::Toss( this.owner.pev, g_vecZero, g_vecZero, 0 );
//                this.m_FlareOnHold.self.pev.nextthink = self.m_flNextTertiaryAttack;
                break;
            }
        }

        self.m_flTimeWeaponIdle = g_Engine.time + ( 25.0f / 30.0f ) + ( 23.0f / 30.0f );
    }

    void LaunchThink()
    {
        weapons::Throw( this );

        this.owner.m_rgAmmo( self.m_iPrimaryAmmoType, this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
        m_fAttackStart = 0.0f;
    }

    void ItemPreFrame()
    {
        BaseClass.ItemPreFrame();

        if( this.m_FlareOnHold !is null )
        {
            Vector origin;
            g_EngineFuncs.GetAttachment( this.owner.edict(), 1, origin, void );
            g_EntityFuncs.SetOrigin( this.m_FlareOnHold.self, origin );
            this.m_FlareOnHold.self.pev.effects |= EF_NODRAW;
            return;
        }

        if( m_fAttackStart == 0.0f && m_bThrown == true && m_bInAttack == false && self.m_flTimeWeaponIdle - 0.1f < g_Engine.time )
        {
            if( this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
            {
                self.Holster();
            }
            else
            {
                self.Deploy();
                m_bThrown = false;
                m_bInAttack = false;
                m_fAttackStart = 0.0f;
            }
        }

        if( !m_bInAttack || CheckButton() || g_Engine.time < m_fAttackStart )
            return;

        self.m_flTimeWeaponIdle = weapons::SetCooldown( self, this.owner, ( 22.0f / 30.0f ) );

        if( throw == 0 )
            PlayAnim( WeaponFlareAnim::Throw, PLAYER_ANIM::PLAYER_ATTACK1 );
        else if( throw == 1 )
            PlayAnim( WeaponFlareAnim::Toss, PLAYER_ANIM::PLAYER_ATTACK1 );
        m_bThrown = true;
        m_bInAttack = false;

        StartSchedule( g_Scheduler.SetTimeout( @this, "LaunchThink", 0.2f ) );
    }

    float Idle() override
    {
        if( this.m_FlareOnHold !is null )
        {
           PlayAnim( WeaponFlareAnim::Hold );
        }
        else
        {
            PlayAnim( WeaponFlareAnim::Idle );
        }

        return Math.RandomFloat( 5.0f, 7.0f );
    }

    private bool CheckButton()
    {
        return ( this.owner.pev.button & ( IN_ATTACK | IN_ATTACK2 | IN_ALT1 ) ) != 0;
    }
}
