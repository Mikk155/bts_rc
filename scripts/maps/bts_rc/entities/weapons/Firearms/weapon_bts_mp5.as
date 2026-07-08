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

final class ASWeaponMP5Config : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_mp5";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_9mmar.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_9mmar.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_9mmar.mdl";
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
        return "ammo_bts_mp5";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponMP5Anim::Draw;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/mp5_fire1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/mp5_slap.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/mp5_clip.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        ASWeaponConfig::Precache();
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapon configuration",
            "description": "Control mp5 configuration",
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
        this.slot = 2;
        this.position = 4;
        this.weight = 5;
        this.deploy_time = 0.6;
        this.primary_maxammo = 120;
        this.primary_dropammo = 30;
        this.max_clip = 30;
        this.primary_damage = 17;
        this.primary_cooldown = 0.09;
        this.primary_trained_cooldown = 0.09;

        return ASWeaponConfig::Register( json );
    }
}

ASWeaponMP5Config gpWeaponMP5Config;

enum WeaponMP5Anim
{
    LongIdle = 0,
    Idle1,
    Launch,
    Reload,
    Draw,
    Shoot1,
    Shoot2,
    Shoot3
};

enum MP5Mode
{
    MP5_BURST = 0,
    MP5_FULL_AUTO
};

class weapon_bts_mp5 : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponMP5Config;
    }

    private int m_iTracerCount = 0;
    private int m_iFireMode = MP5_FULL_AUTO;
    private int m_iBurstCount = 0, m_iBurstLeft = 0;
    private float m_flNextBurstFireTime = 0;

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 5, gpWeaponMP5Config.max_clip );
        BTS_FireWeapon::Spawn();
    }

    void Holster( int skiplocal = 0 )
    {
        BaseClass.Holster( skiplocal );
        m_iBurstLeft = 0;
    }

    void ItemPostFrame()
    {
        if( m_iFireMode == MP5_BURST )
        {
            if( m_iBurstLeft > 0 )
            {
                if( m_flNextBurstFireTime < g_Engine.time )
                {
                    if( self.m_iClip <= 0 )
                    {
                        m_iBurstLeft = 0;
                        return;
                    }
                    else
                    {
                        --m_iBurstLeft;
                    }

                    Fire();

                    if( m_iBurstLeft > 0 )
                    {
                        m_flNextBurstFireTime = ( self.m_flNextPrimaryAttack = g_Engine.time + 0.07f );
                    }
                    else
                    {
                        m_flNextBurstFireTime = 1.0f;
                    }
                }
                return;
            }
        }
        BaseClass.ItemPostFrame();
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        if( type == AttackType::Secondary )
        {
            if( m_iFireMode == MP5_BURST )
            {
                m_iFireMode = MP5_FULL_AUTO;
                g_EngineFuncs.ClientPrintf( player, print_center, " Full-Auto\n" );
                PlaySound( "bts_rc/weapons/mp5_slap.wav", 0.8f, 100 );
            }
            else
            {
                m_iFireMode = MP5_BURST;
                g_EngineFuncs.ClientPrintf( player, print_center, " Burst\n" );
                PlaySound( "bts_rc/weapons/mp5_slap.wav", 0.8f, 115 );
            }
            PlayAnim( WeaponMP5Anim::Launch );
            self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 5.0f, 10.0f );
            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
            return;
        }

        if( type != AttackType::Primary )
        {
            return;
        }

        if( self.m_iClip <= 0 )
        {
            this.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.09f;
            return;
        }

        if( m_iFireMode == MP5_BURST )
        {
            m_iBurstCount = Math.min( 3, self.m_iClip );
            m_iBurstLeft = m_iBurstCount - 1;

            m_flNextBurstFireTime = g_Engine.time + 0.09f;
            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.425f;
        }

        Fire();
    }

    void Fire()
    {
        bool isTrainedPersonal = util::IsTrainedPersonal( this.owner );
        float cone = Accuracy( ( this.owner.IsMoving() ? 0.02618f : 0.01f ), ( this.owner.IsMoving() ? 0.1f : 0.05f ), 0.01f, 0.05f );
        if( m_iFireMode == MP5_BURST )
        {
            cone *= 0.2f;
        }

        uint8 anim;
        switch( Math.RandomLong( 0, 2 ) )
        {
            case 0: anim = WeaponMP5Anim::Shoot1; break;
            case 1: anim = WeaponMP5Anim::Shoot2; break;
            default: anim = WeaponMP5Anim::Shoot3; break;
        }

        FireBullet( 1, cone, gpWeaponMP5Config.primary_damage, "bts_rc/weapons/mp5_fire1.wav", anim, models::shell, TE_BOUNCE_SHELL, 1.0f, 95 + Math.RandomLong( 0, 10 ) );

        if( ( m_iTracerCount++ % 2 ) == 0 )
        {
            Vector vecSrc = this.owner.GetGunPosition();
            Math.MakeVectors( this.owner.pev.v_angle + this.owner.pev.punchangle );
            Vector vecAiming = this.owner.GetAutoaimVector( AUTOAIM_5DEGREES );
            Vector vecDir = vecAiming + cone * g_Engine.v_right * Math.RandomFloat( -0.5f, 0.5f ) + cone * g_Engine.v_up * Math.RandomFloat( -0.5f, 0.5f );
            Vector vecEnd = vecSrc + vecDir * 8192.0f;

            TraceResult tr;
            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, this.owner.edict(), tr );

            Vector vecTracerSrc = vecSrc + Vector( 0.0f, 0.0f, -4.0f ) + g_Engine.v_right * 2.0f + g_Engine.v_forward * 16.0f;
            NetworkMessage tracer( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecTracerSrc );
            tracer.WriteByte( TE_TRACER );
            tracer.WriteCoord( vecTracerSrc.x );
            tracer.WriteCoord( vecTracerSrc.y );
            tracer.WriteCoord( vecTracerSrc.z );
            tracer.WriteCoord( tr.vecEndPos.x );
            tracer.WriteCoord( tr.vecEndPos.y );
            tracer.WriteCoord( tr.vecEndPos.z );
            tracer.End();
        }

        if( isTrainedPersonal )
        {
            this.owner.pev.punchangle.x = -2.0f;
        }
        else
        {
            this.owner.pev.punchangle.x = this.owner.pev.FlagBitSet( FL_DUCKING ) ? float( Math.RandomLong( -3, 2 ) ) : float( Math.RandomLong( -5, 3 ) );
        }

        if( self.m_iClip <= 0 && this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && util::IsHEV( this.owner ) )
        {
            this.owner.SetSuitUpdate( "!HEV_AMO0", false, 0 );
        }

        self.m_flNextPrimaryAttack = g_Engine.time + 0.09f;
        if( m_iFireMode == MP5_BURST )
        {
            self.m_flNextPrimaryAttack = g_Engine.time + 0.24f;
        }

        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
    }

    void Reload()
    {
        if( self.m_iClip == gpWeaponMP5Config.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
        {
            return;
        }

        self.DefaultReload( gpWeaponMP5Config.max_clip, WeaponMP5Anim::Reload, 1.5f, pev.body );
        PlaySound( "bts_rc/weapons/mp5_clip.wav", 0.15f );
        self.m_flTimeWeaponIdle = g_Engine.time + 3.0f;
        BaseClass.Reload();
    }

    float Idle() override
    {
        self.ResetEmptySound();

        switch( Math.RandomLong( 0, 2 ) )
        {
            case 0:
                PlayAnim( WeaponMP5Anim::LongIdle );
                break;
            case 1:
            default:
                PlayAnim( WeaponMP5Anim::Idle1 );
                break;
        }

        return Math.RandomFloat( 10.0f, 15.0f );
    }
}
