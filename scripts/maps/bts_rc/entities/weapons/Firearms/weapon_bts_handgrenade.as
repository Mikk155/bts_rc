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

final class ASWeaponHandGrenadeConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_handgrenade";
    }

    const string& get_player_model() override
    {
        return "models/hlclassic/p_grenade.mdl";
    }

    const string& get_world_model() override
    {
        return "models/hlclassic/w_grenade.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_grenade.mdl";
    }

    const string& get_animation_extension() override
    {
        return "gren";
    }

    const string& get_primary_ammo() override
    {
        return "Hand Grenade";
    }

    const string& get_primary_ammoentity() override
    {
        return "weapon_bts_handgrenade";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponHandGrenadeAnim::DRAW;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/grenade_draw.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/grenade_throw1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/grenade_throw2.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        ASWeaponConfig::Precache();
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapon configuration",
            "description": "Control handgrenade configuration",
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
        this.slot = 4;
        this.position = 6;
        this.weight = 20;
        this.deploy_time = 0.66;
        this.primary_maxammo = 10;
        this.primary_dropammo = 1;
        this.max_clip = WEAPON_NOCLIP;
        this.primary_damage = 130;

        return ASWeaponConfig::Register( json );
    }
}

ASWeaponHandGrenadeConfig gpWeaponHandGrenadeConfig;

enum WeaponHandGrenadeAnim
{
    IDLE = 0,
    FIDGET,
    PULLPIN,
    THROW1,
    THROW2,
    THROW3,
    HOLSTER,
    DRAW
};

class weapon_bts_handgrenade : BTS_Weapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponHandGrenadeConfig;
    }

    private float m_fAttackStart = 0.0f;
    private bool m_bInAttack = false;
    private bool m_bThrown = false;
    private int m_iAmmoSave = 0;

    void Spawn() override
    {
        g_EntityFuncs.SetModel( self, "models/hlclassic/w_grenade.mdl" );
        self.m_iDefaultAmmo = 1;
        self.FallInit();
    }

    bool CanHaveDuplicates()
    {
        return true;
    }

    bool Deploy() override
    {
        PlaySound( "bts_rc/weapons/grenade_draw.wav", 0.6f, PITCH_NORM, CHAN_ITEM );
        m_iAmmoSave = 0;
        m_fAttackStart = 0.0;
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

    void Holster( int skiplocal = 0 )
    {
        if( this.owner.pev.deadflag != DEAD_NO && m_fAttackStart != 0.0f )
        {
            Vector vecHandPos, vecVelocity;
            g_EngineFuncs.GetBonePosition( this.owner.edict(), 28, vecHandPos, void );

            vecVelocity = Vector( Math.RandomFloat( -20.0, 20.0 ), Math.RandomFloat( -20.0, 20.0 ), 40.0 );
            CGrenade@ pGrenade = g_EntityFuncs.ShootTimed( this.owner.pev, vecHandPos, vecVelocity, 3.0f );
            if( pGrenade !is null )
            {
                g_EntityFuncs.SetModel( pGrenade, "models/hlclassic/w_grenade.mdl" );
                pGrenade.pev.dmg = gpWeaponHandGrenadeConfig.primary_damage;
            }

            m_fAttackStart = 0.0;
        }

        m_bThrown = false;
        m_bInAttack = false;

        SetThink( null );

        if( this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
        {
            m_iAmmoSave = this.owner.m_rgAmmo( self.m_iPrimaryAmmoType );
        }

        if( m_iAmmoSave <= 0 )
        {
            SetThink( ThinkFunction( this.DestroyThink ) );
            pev.nextthink = g_Engine.time + 0.1f;
        }

        BaseClass.Holster( skiplocal );
    }

    void PrimaryAttack() override
    {
        if( this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        if( m_fAttackStart < 0.0f || m_fAttackStart > 0.0f )
            return;

        self.m_flNextPrimaryAttack = g_Engine.time + ( 24.0f / 30.0f );
        PlayAnim( WeaponHandGrenadeAnim::PULLPIN );

        m_bInAttack = true;
        m_fAttackStart = g_Engine.time + ( 24.0f / 30.0f );

        self.m_flTimeWeaponIdle = g_Engine.time + ( 24.0f / 30.0f ) + ( 9.0f / 30.0f );
    }

    private void LaunchThink()
    {
        Vector angThrow = this.owner.pev.v_angle + this.owner.pev.punchangle;

        if( Math.RandomLong( 0, 1 ) == 0 )
            PlaySound( "bts_rc/weapons/grenade_throw1.wav", 1.0f, PITCH_NORM, CHAN_ITEM );
        else
            PlaySound( "bts_rc/weapons/grenade_throw2.wav", 1.0f, PITCH_NORM, CHAN_ITEM );

        if( angThrow.x < 0.0f )
            angThrow.x = -10.0f + angThrow.x * ( ( 90.0f - 10.0f ) / 90.0f );
        else
            angThrow.x = -10.0f + angThrow.x * ( ( 90.0f + 10.0f ) / 90.0f );

        float flVel = ( 90.0f - angThrow.x ) * 4.0f;

        if( flVel > 500.0f )
            flVel = 500.0f;

        Math.MakeVectors( angThrow );
        Vector offset = Vector( 16.0f, 0.0f, 0.0f );
        Vector vecSrc = this.owner.GetGunPosition() + g_Engine.v_forward * offset.x + g_Engine.v_right * offset.y + g_Engine.v_up * offset.z;
        Vector vecThrow = g_Engine.v_forward * flVel + this.owner.pev.velocity;

        CGrenade@ pGrenade = g_EntityFuncs.ShootTimed( this.owner.pev, vecSrc, vecThrow, 3.0f );
        if( pGrenade !is null )
        {
            g_EntityFuncs.SetModel( pGrenade, "models/hlclassic/w_grenade.mdl" );
            pGrenade.pev.dmg = gpWeaponHandGrenadeConfig.primary_damage;
        }

        this.owner.m_rgAmmo( self.m_iPrimaryAmmoType, this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
        m_fAttackStart = 0.0f;
    }

    void ItemPreFrame()
    {
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

        self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + ( 9.0f / 30.0f );

        Vector angThrow = this.owner.pev.v_angle + this.owner.pev.punchangle;
        angThrow.x = -10.0f + angThrow.x * ( angThrow.x < 0.0f ? 0.888889f : 1.11111f );
        float flVel = Math.min( ( 90.0f - angThrow.x ) * 4.0f, 500.0f );

        if( flVel < 500.0f )
            PlayAnim( WeaponHandGrenadeAnim::THROW1 );
        else if( flVel < 1000.0f )
            PlayAnim( WeaponHandGrenadeAnim::THROW2 );
        else
            PlayAnim( WeaponHandGrenadeAnim::THROW3 );

        m_bThrown = true;
        m_bInAttack = false;
        this.owner.SetAnimation( PLAYER_ATTACK1 );

        SetThink( ThinkFunction( this.LaunchThink ) );
        pev.nextthink = g_Engine.time + 0.2f;

        BaseClass.ItemPreFrame();
    }

    float Idle() override
    {
        float flRand = Math.RandomFloat( 0.0f, 1.0f );
        if( flRand <= 0.75f )
        {
            PlayAnim( WeaponHandGrenadeAnim::IDLE );
            return Math.RandomFloat( 10.0f, 15.0f );
        }
        else
        {
            PlayAnim( WeaponHandGrenadeAnim::FIDGET );
            return 2.33f;
        }
    }

    private bool CheckButton()
    {
        return ( this.owner.pev.button & ( IN_ATTACK | IN_ATTACK2 | IN_ALT1 ) ) != 0;
    }

    private void DestroyThink()
    {
        SetThink( null );
        self.DestroyItem();
    }
}
