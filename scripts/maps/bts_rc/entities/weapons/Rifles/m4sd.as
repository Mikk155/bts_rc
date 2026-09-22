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
        return WeaponM4SDAnim::Draw;
    }
}

ASWeaponM4SDConfig gpWeaponM4SDConfig;

enum WeaponM4SDAnim
{
    LongIdle = 0,
    Idle1 = 1,
    FireMode = 2,
    Reload = 3,
    Draw = 4,
    Shoot1 = 5,
    Shoot2 = 6,
    Shoot3 = 7
};

enum M4SDMode
{
    Semi = 0,
    Full
};

class weapon_bts_m4sd : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponM4SDConfig;
    }

    private int m_iTracerCount = 0;
    private int m_iFireMode = M4SDMode::Semi;

    void Spawn() override
    {
        BTS_FireWeapon::Spawn();
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        if( type == AttackType::Secondary )
        {
            if( m_iFireMode == M4SDMode::Semi )
            {
                m_iFireMode = M4SDMode::Full;
                g_EngineFuncs.ClientPrintf( player, print_center, " Full-Auto\n" );
                PlaySound( "bts_rc/weapons/grenade_pinpull.wav", 0.8f, 100 );
            }
            else
            {
                m_iFireMode = M4SDMode::Semi;
                g_EngineFuncs.ClientPrintf( player, print_center, " Semi\n" );
                PlaySound( "bts_rc/weapons/grenade_pinpull.wav", 0.8f, 115 );
            }
            PlayAnim( WeaponM4SDAnim::FireMode );
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

        if( m_iFireMode == M4SDMode::Semi )
        {
            if( ( player.m_afButtonPressed & IN_ATTACK ) == 0 )
                return;
        }

        bool isTrainedPersonal = util::IsTrainedPersonal( player );
        float cone = weapons::Accuracy( player, this.config.primary_accuracy, isTrainedPersonal );
        if( m_iFireMode == M4SDMode::Semi )
        {
            cone *= 0.8f;
        }

        uint8 anim;
        switch( Math.RandomLong( 0, 2 ) )
        {
            case 0: anim = WeaponM4SDAnim::Shoot1; break;
            case 1: anim = WeaponM4SDAnim::Shoot2; break;
            default: anim = WeaponM4SDAnim::Shoot3; break;
        }

        bullet.Weapon( this )
            .Accuracy( cone )
            .Sound( "bts_rc/weapons/m4sd_fire1.wav", Math.RandomFloat( 0.92f, 1.0f ), 98 + Math.RandomLong( 0, 3 ), QUIET_GUN_VOLUME )
            .Shell( models::saw_shell )
            .Flash( 0, false )
            .Animation( anim )
        .Fire();

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

        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + ( m_iFireMode != M4SDMode::Semi ? 0.124f : 0.105f );
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
    }

    float Idle() override
    {
        self.ResetEmptySound();

        switch( Math.RandomLong( 0, 1 ) )
        {
            case 0:
                PlayAnim( WeaponM4SDAnim::LongIdle );
                break;
            case 1:
            default:
                PlayAnim( WeaponM4SDAnim::Idle1 );
                break;
        }

        return Math.RandomFloat( 10.0f, 15.0f );
    }
}
