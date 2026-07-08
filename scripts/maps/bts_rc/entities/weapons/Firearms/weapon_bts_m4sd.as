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

final class ASWeaponM4SDConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_m4sd";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_m4sd.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_m4sd.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_m4sd.mdl";
    }

    const string& get_animation_extension() override
    {
        return "m16";
    }

    const string& get_primary_ammo() override
    {
        return "556";
    }

    const string& get_primary_ammoentity() override
    {
        return "ammo_bts_m4sd";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponM4SDAnim::DRAW;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/m4sd_fire1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/fidget_3.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/grenade_pinpull.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        ASWeaponConfig::Precache();
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapon configuration",
            "description": "Control m4sd configuration",
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
        this.position = 9;
        this.weight = 5;
        this.deploy_time = 1.2;
        this.primary_maxammo = 150;
        this.primary_dropammo = 30;
        this.max_clip = 30;
        this.primary_damage = 22;
        this.primary_cooldown = 0.105;
        this.primary_trained_cooldown = 0.105;

        return ASWeaponConfig::Register( json );
    }
}

ASWeaponM4SDConfig gpWeaponM4SDConfig;

enum WeaponM4SDAnim
{
    LONGIDLE = 0,
    IDLE1,
    RELOAD,
    DRAW,
    SHOOT1,
    SHOOT2,
    SHOOT3
};

enum M4SDMode
{
    M4SD_SEMI = 0,
    M4SD_FULL_AUTO
};

class weapon_bts_m4sd : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponM4SDConfig;
    }

    private int m_iTracerCount = 0;
    private int m_iFireMode = M4SD_SEMI;

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 9, gpWeaponM4SDConfig.max_clip );
        BTS_FireWeapon::Spawn();
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        if( type == AttackType::Secondary )
        {
            if( m_iFireMode == M4SD_SEMI )
            {
                m_iFireMode = M4SD_FULL_AUTO;
                g_EngineFuncs.ClientPrintf( player, print_center, " Full-Auto\n" );
                PlaySound( "bts_rc/weapons/grenade_pinpull.wav", 0.8f, 100 );
            }
            else
            {
                m_iFireMode = M4SD_SEMI;
                g_EngineFuncs.ClientPrintf( player, print_center, " Semi\n" );
                PlaySound( "bts_rc/weapons/grenade_pinpull.wav", 0.8f, 115 );
            }
            PlayAnim( WeaponM4SDAnim::LONGIDLE );
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
            self.m_flNextPrimaryAttack = g_Engine.time + 0.10f;
            return;
        }

        if( m_iFireMode == M4SD_SEMI )
        {
            if( ( player.m_afButtonPressed & IN_ATTACK ) == 0 )
                return;
        }

        bool isTrainedPersonal = util::IsTrainedPersonal( player );
        float cone = Accuracy( ( player.IsMoving() ? 0.02618f : 0.01f ), ( player.IsMoving() ? 0.1f : 0.05f ), 0.01f, 0.05f );
        if( m_iFireMode == M4SD_SEMI )
        {
            cone *= 0.8f;
        }

        uint8 anim;
        switch( Math.RandomLong( 0, 2 ) )
        {
            case 0: anim = WeaponM4SDAnim::SHOOT1; break;
            case 1: anim = WeaponM4SDAnim::SHOOT2; break;
            default: anim = WeaponM4SDAnim::SHOOT3; break;
        }

        FireBullet( 1, cone, gpWeaponM4SDConfig.primary_damage, "bts_rc/weapons/m4sd_fire1.wav", anim, models::saw_shell, TE_BOUNCE_SHELL, Math.RandomFloat( 0.92f, 1.0f ), 98 + Math.RandomLong( 0, 3 ), false, QUIET_GUN_VOLUME, 0 );

        if( ( m_iTracerCount++ % 4 ) == 0 )
        {
            Vector vecSrc = player.GetGunPosition();
            Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );
            Vector vecAiming = player.GetAutoaimVector( AUTOAIM_5DEGREES );
            Vector vecDir = vecAiming + cone * g_Engine.v_right * Math.RandomFloat( -0.5f, 0.5f ) + cone * g_Engine.v_up * Math.RandomFloat( -0.5f, 0.5f );
            Vector vecEnd = vecSrc + vecDir * 8192.0f;

            TraceResult tr;
            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, player.edict(), tr );

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
            player.pev.punchangle.x = -2.75f;
        }
        else
        {
            player.pev.punchangle.x = player.IsMoving() ? float( Math.RandomLong( -6, 3 ) ) : float( Math.RandomLong( -3, 2 ) );
        }

        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + ( m_iFireMode != M4SD_SEMI ? 0.124f : 0.105f );
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
    }

    void Reload()
    {
        if( ShouldReload( WeaponM4SDAnim::RELOAD, 2.75f ) )
        {
            self.SetFOV( 0 );
            PlaySound( "bts_rc/weapons/fidget_3.wav", 0.6f );
            self.m_flTimeWeaponIdle = g_Engine.time + 3.0f;
            BaseClass.Reload();
        }
    }

    float Idle() override
    {
        self.ResetEmptySound();

        switch( Math.RandomLong( 0, 1 ) )
        {
            case 0:
                PlayAnim( WeaponM4SDAnim::LONGIDLE );
                break;
            case 1:
            default:
                PlayAnim( WeaponM4Anim::IDLE1 );
                break;
        }

        return Math.RandomFloat( 10.0f, 15.0f );
    }
}
