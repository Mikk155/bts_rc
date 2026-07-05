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

class CWeaponMP5GLConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_mp5gl";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_9mmargl.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_9mmargl.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_9mmargl.mdl";
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
        return "ammo_bts_mp5gl";
    }

    const string& get_secondary_ammo() override
    {
        return "ARgrenades";
    }

    const string& get_secondary_ammoentity() override
    {
        return "ammo_bts_mp5gl_grenade";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponMP5GLAnim::Draw;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/mp5_fire1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/mp5_slap.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/mp5_clip.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/glauncher.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/glauncher2.wav" );
        g_Game.PrecacheModel( "models/hlclassic/grenade.mdl" );
        ASWeaponConfig::Precache();
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        this.slot = 2;
        this.position = 5;
        this.weight = 5;
        this.deploy_time = 0.6;
        this.primary_maxammo = 120;
        this.primary_dropammo = 30;
        this.secondary_maxammo = 10;
        this.secondary_dropammo = 1;
        this.max_clip = 30;
        this.primary_damage = 17;
        this.secondary_damage = 110;
        this.primary_cooldown = 0.09;
        this.primary_trained_cooldown = 0.09;
        this.secondary_cooldown = 2.5;
        this.secondary_trained_cooldown = 2.5;
        this.tertiary_cooldown = 0.5;
        this.tertiary_trained_cooldown = 0.5;

        return ASWeaponConfig::Register( json );
    }
}

CWeaponMP5GLConfig gpWeaponMP5GLConfig;

enum WeaponMP5GLAnim
{
    LongIdle = 0,
    Idle1,
    Launch,
    Reload,
    Draw,
    Shoot1,
    Shoot2,
    Shoot3,
    BurstE
};

enum MP5GLMode
{
    MP5GL_BURST = 0,
    MP5GL_FULL_AUTO
};

class weapon_bts_mp5gl : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponMP5GLConfig;
    }

    private int m_iTracerCount = 0;
    private int m_iFireMode = MP5GL_FULL_AUTO;
    private int m_iBurstCount = 0, m_iBurstLeft = 0;
    private float m_flNextBurstFireTime = 0;

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 9, gpWeaponMP5GLConfig.max_clip );
        self.m_iDefaultSecAmmo = Math.RandomLong( 0, 1 );
        BTS_FireWeapon::Spawn();
    }

    void Holster( int skiplocal = 0 )
    {
        BaseClass.Holster( skiplocal );
        m_iBurstLeft = 0;
    }

    void ItemPostFrame()
    {
        if( m_iFireMode == MP5GL_BURST )
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
        if( type == AttackType::Tertiary )
        {
            if( m_iFireMode == MP5GL_BURST )
            {
                m_iFireMode = MP5GL_FULL_AUTO;
                g_EngineFuncs.ClientPrintf( player, print_center, " Full-Auto\n" );
                PlaySound( "bts_rc/weapons/mp5_slap.wav", 0.8f, 100 );
            }
            else
            {
                m_iFireMode = MP5GL_BURST;
                g_EngineFuncs.ClientPrintf( player, print_center, " Burst\n" );
                PlaySound( "bts_rc/weapons/mp5_slap.wav", 0.8f, 115 );
            }
            PlayAnim( WeaponMP5GLAnim::BurstE );
            self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 5.0f, 10.0f );
            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.5f;
            return;
        }

        if( type == AttackType::Secondary )
        {
            if( player.pev.waterlevel == WATERLEVEL_HEAD || player.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0 )
            {
                this.PlayEmptySound();
                self.m_flNextSecondaryAttack = g_Engine.time + 0.15f;
                return;
            }

            player.m_iWeaponVolume = NORMAL_GUN_VOLUME;
            player.m_iWeaponFlash = BRIGHT_GUN_FLASH;

            player.m_iExtraSoundTypes = bits_SOUND_DANGER;
            player.m_flStopExtraSoundTime = g_Engine.time + 0.2f;

            player.m_rgAmmo( self.m_iSecondaryAmmoType, player.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );

            player.SetAnimation( PLAYER_ATTACK1 );

            Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );
            Vector vecSrc = player.pev.origin + g_Engine.v_forward * 16.0f + g_Engine.v_right * 6.0f;
            vecSrc = vecSrc + ( ( ( player.pev.button & IN_DUCK ) != 0 ) ? g_vecZero : ( player.pev.view_ofs * 0.5f ) );

            CGrenade@ pGrenade = g_EntityFuncs.ShootContact( player.pev, vecSrc, g_Engine.v_forward * 900.0f );
            if( pGrenade !is null )
            {
                g_EntityFuncs.SetModel( pGrenade, "models/hlclassic/grenade.mdl" );
                pGrenade.pev.dmg = gpWeaponMP5GLConfig.secondary_damage;
            }

            PlayAnim( WeaponMP5GLAnim::Launch );

            if( Math.RandomLong( 0, 1 ) != 0 )
            {
                PlaySound( "hlclassic/weapons/glauncher.wav", 0.8f );
            }
            else
            {
                PlaySound( "hlclassic/weapons/glauncher2.wav", 0.8f );
            }

            player.pev.punchangle.x = -10.0f;

            if( player.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0 && util::IsHEV( player ) )
            {
                player.SetSuitUpdate( "!HEV_AMO0", false, 0 );
            }

            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 2.5f;
            self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;
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

        if( m_iFireMode == MP5GL_BURST )
        {
            m_iBurstCount = Math.min( 3, self.m_iClip );
            m_iBurstLeft = m_iBurstCount - 1;

            m_flNextBurstFireTime = g_Engine.time + 0.09f;
            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.425f;
        }

        Fire();
    }

    void Fire()
    {
        bool isTrainedPersonal = util::IsTrainedPersonal( this.owner );
        float cone = Accuracy( ( this.owner.IsMoving() ? 0.02618f : 0.01f ), ( this.owner.IsMoving() ? 0.1f : 0.05f ), 0.01f, 0.05f );
        if( m_iFireMode == MP5GL_BURST )
        {
            cone *= 0.2f;
        }

        uint8 anim;
        switch( Math.RandomLong( 0, 2 ) )
        {
            case 0: anim = WeaponMP5GLAnim::Shoot1; break;
            case 1: anim = WeaponMP5GLAnim::Shoot2; break;
            default: anim = WeaponMP5GLAnim::Shoot3; break;
        }

        FireBullet( 1, cone, gpWeaponMP5GLConfig.primary_damage, "bts_rc/weapons/mp5_fire1.wav", anim, models::shell, TE_BOUNCE_SHELL, 1.0f, 95 + Math.RandomLong( 0, 10 ) );

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
        if( m_iFireMode == MP5GL_BURST )
        {
            self.m_flNextPrimaryAttack = g_Engine.time + 0.24f;
        }

        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
    }

    void TertiaryAttack()
    {
        Attack( this.owner, AttackType::Tertiary );
    }

    void Reload()
    {
        if( self.m_iClip == gpWeaponMP5GLConfig.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
        {
            return;
        }

        self.DefaultReload( gpWeaponMP5GLConfig.max_clip, WeaponMP5GLAnim::Reload, 3.0f, pev.body );
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
                PlayAnim( WeaponMP5GLAnim::LongIdle );
                break;
            case 1:
            default:
                PlayAnim( WeaponMP5GLAnim::Idle1 );
                break;
        }

        return Math.RandomFloat( 10.0f, 15.0f );
    }
}
