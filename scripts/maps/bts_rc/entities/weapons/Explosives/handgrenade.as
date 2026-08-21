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

class weapon_bts_handgrenade : BTS_Weapon, IThrowable
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponHandGrenadeConfig;
    }

    private float m_fAttackStart = 0.0f;
    private bool m_bInAttack = false;
    private bool m_bThrown = false;
    private int m_iAmmoSave = 0;
    private bool m_bRoll = false;

    CBasePlayer@ get_Thrower() property { return this.owner; }
    CBasePlayerWeapon@ get_ThrowableWeapon() property { return self; }
    ASWeaponConfig@ get_ThrowableConfig() property { return this.config; }
    AttackType get_ThrowAttackType() property { return m_bRoll ? AttackType::Secondary : AttackType::Primary; }
    bool get_Rolling() property { return m_bRoll; }

    void SpawnThrowable( const Vector&in source, const Vector&in velocity, float damage )
    {
        CGrenade@ grenade = g_EntityFuncs.ShootTimed( this.owner.pev, source, velocity, 3.0f );

        if( grenade !is null )
        {
            g_EntityFuncs.SetModel( grenade, this.config.world_model );
            grenade.pev.dmg = damage;
        }
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

        ClearTimerList();

        if( this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
        {
            m_iAmmoSave = this.owner.m_rgAmmo( self.m_iPrimaryAmmoType );
        }

        if( m_iAmmoSave <= 0 )
        {
            StartSchedule( g_Scheduler.SetTimeout( @this, "DestroyThink", 0.1f ) );
        }

        BaseClass.Holster( skiplocal );
    }

    void PrimaryAttack() override
    {
        StartThrow( false );
    }

    void SecondaryAttack() override
    {
        StartThrow( true );
    }

    private void StartThrow( bool rolling )
    {
        if( this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        if( m_fAttackStart < 0.0f || m_fAttackStart > 0.0f )
            return;

        self.m_flNextPrimaryAttack = g_Engine.time + ( 24.0f / 30.0f );
        PlayAnim( WeaponHandGrenadeAnim::PULLPIN );
        m_bRoll = rolling;

        m_bInAttack = true;
        m_fAttackStart = g_Engine.time + ( 24.0f / 30.0f );

        self.m_flTimeWeaponIdle = g_Engine.time + ( 24.0f / 30.0f ) + ( 9.0f / 30.0f );
    }

    void LaunchThink()
    {
        if( Math.RandomLong( 0, 1 ) == 0 )
            PlaySound( "bts_rc/weapons/grenade_throw1.wav", 1.0f, PITCH_NORM, CHAN_ITEM );
        else
            PlaySound( "bts_rc/weapons/grenade_throw2.wav", 1.0f, PITCH_NORM, CHAN_ITEM );

        weapons::Throw( this );

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

        if( m_bRoll )
            PlayAnim( WeaponHandGrenadeAnim::THROW1 );
        else
            PlayAnim( WeaponHandGrenadeAnim::THROW1 );

        m_bThrown = true;
        m_bInAttack = false;
        this.owner.SetAnimation( PLAYER_ATTACK1 );

        StartSchedule( g_Scheduler.SetTimeout( @this, "LaunchThink", 0.2f ) );

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

    void DestroyThink()
    {
        self.DestroyItem();
    }
}
