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

class CWeaponSW637Config : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_sw637";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_sw637.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_sw637.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_sw637.mdl";
    }

    const string& get_animation_extension() override
    {
        return "python";
    }

    const string& get_primary_ammo() override
    {
        return "sw637";
    }

    const string& get_primary_ammoentity() override
    {
        return "ammo_bts_sw637";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponSW637Anim::Draw;
    }

    const uint8 get_hands_group() override
    {
        return 1;
    }

    void Precache() override
    {
        g_Game.PrecacheModel( "models/bts_rc/weapons/w_38ammobox.mdl" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/38_shot1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/38_shot2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/sw_bullet_insert_1.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        ASWeaponConfig::Precache();
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_sw637", "ammo_bts_sw637" );
        g_CustomEntityFuncs.RegisterCustomEntity( "ammo_bts_sw637lmao", "ammo_bts_sw637lmao" );

        this.slot = 1;
        this.position = 17;
        this.weight = 10;
        this.deploy_time = 1.0;
        this.primary_maxammo = 60;
        this.primary_dropammo = 5;
        this.max_clip = 5;
        this.primary_damage = 25;
        this.primary_cooldown = 0.25;
        this.primary_trained_cooldown = 0.25;

        return ASWeaponConfig::Register( json );
    }
}

CWeaponSW637Config gpWeaponSW637Config;

enum WeaponSW637Anim
{
    Draw = 0,
    Idle,
    Shoot,
    ReloadStart,
    ReloadPart,
    ReloadFinish,
    Holster
};

const int SW637_BODYGROUP_ROUNDS = 2;
const int SW637_BODYGROUP_HANDS = 1;

class weapon_bts_sw637 : BTS_FireWeapon
{
    private bool m_fReloading = false;
    private float m_flNextInsert = 0.0f;

    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponSW637Config;
    }

    void UpdateViewBodygroups()
    {
        int mdl = g_ModelFuncs.ModelIndex( gpWeaponSW637Config.view_model );
        pev.body = g_ModelFuncs.SetBodygroup( mdl, pev.body, SW637_BODYGROUP_HANDS, int( util::GetClass( this.owner ) ) );
        pev.body = g_ModelFuncs.SetBodygroup( mdl, pev.body, SW637_BODYGROUP_ROUNDS, self.m_iClip );
    }

    void Spawn() override
    {
        self.m_iDefaultAmmo = 0;
        BTS_FireWeapon::Spawn();
    }

    bool Deploy() override
    {
        UpdateViewBodygroups();
        return BTS_FireWeapon::Deploy();
    }

    void Holster( int skiplocal = 0 ) override
    {
        m_fReloading = false;
        BTS_FireWeapon::Holster( skiplocal );
    }

    void ItemPostFrame()
    {
        if( m_fReloading )
        {
            // Allow interrupting reload to shoot
            if( ( this.owner.pev.button & IN_ATTACK ) != 0 )
            {
                m_fReloading = false;
                PrimaryAttack();
                return;
            }
        }
        BaseClass.ItemPostFrame();
    }

    float Idle() override
    {
        int mdl = g_ModelFuncs.ModelIndex( gpWeaponSW637Config.view_model );

        if( !m_fReloading )
        {
            PlayAnim( WeaponSW637Anim::Idle );
            UpdateViewBodygroups();
            return 3.0f;
        }

        if( g_Engine.time < m_flNextInsert )
        {
            return 0.1f;
        }

        // Insert rounds one by one
        if( self.m_iClip < gpWeaponSW637Config.max_clip && this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
        {
            self.m_iClip++;
            this.owner.m_rgAmmo( self.m_iPrimaryAmmoType, this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
            PlayAnim( WeaponSW637Anim::ReloadPart );
            UpdateViewBodygroups();
            m_flNextInsert = g_Engine.time + 0.5f;
            return 0.5f;
        }

        // Finished reloading
        pev.body = g_ModelFuncs.SetBodygroup( mdl, pev.body, SW637_BODYGROUP_ROUNDS, self.m_iClip - 1 );
        PlayAnim( WeaponSW637Anim::ReloadFinish );
        m_fReloading = false;
        return 1.5f;
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
            self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
            return;
        }

        if( ( player.m_afButtonPressed & IN_ATTACK ) == 0 )
        {
            return;
        }

        m_fReloading = false;

        float cone = Accuracy( 0.01f, 0.05f, 0.05f, 0.05f );
        string szSound = ( Math.RandomLong( 0, 1 ) == 0 ) ? "bts_rc/weapons/38_shot1.wav" : "bts_rc/weapons/38_shot2.wav";

        FireBullet( 1, cone, gpWeaponSW637Config.primary_damage, szSound, WeaponSW637Anim::Shoot, -1, TE_BOUNCE_SHELL, 1.0f, PITCH_NORM, true, LOUD_GUN_VOLUME, BRIGHT_GUN_FLASH );

        UpdateViewBodygroups();

        player.pev.punchangle.x = util::IsTrainedPersonal( player ) ? -3.0f : -7.0f;
        self.m_flNextPrimaryAttack = g_Engine.time + 0.25f;
        self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;
    }

    void Reload()
    {
        int mdl = g_ModelFuncs.ModelIndex( gpWeaponSW637Config.view_model );

        if( m_fReloading )
        {
            return;
        }

        if( self.m_iClip >= gpWeaponSW637Config.max_clip )
        {
            return;
        }

        if( this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
        {
            return;
        }

        this.owner.m_rgAmmo( self.m_iPrimaryAmmoType, this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) + self.m_iClip );
        self.m_iClip = 0;
        pev.body = g_ModelFuncs.SetBodygroup( mdl, pev.body, SW637_BODYGROUP_ROUNDS, 4 );

        m_fReloading = true;
        PlayAnim( WeaponSW637Anim::ReloadStart );
        UpdateViewBodygroups();

        m_flNextInsert = g_Engine.time + 1.2f;
        self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;
        self.m_flTimeWeaponIdle = m_flNextInsert;
    }
}

class ammo_bts_sw637 : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/w_38ammobox.mdl" );
        pev.scale = 1.0;
        BaseClass.Spawn();
    }

    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( 5, "sw637", 60 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "bts_rc/weapons/sw_bullet_insert_1.wav", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}

class ammo_bts_sw637lmao : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/w_38ammobox.mdl" );
        pev.scale = 1.0;
        BaseClass.Spawn();
    }

    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( 1, "sw637", 60 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "bts_rc/weapons/sw_bullet_insert_1.wav", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}
