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

final class ASWeaponM16Config : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_m16";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_m16.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_m16.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_m16a2.mdl";
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
        return "ammo_bts_m16";
    }

    const string& get_secondary_ammo() override
    {
        return "ARgrenades";
    }

    const string& get_secondary_ammoentity() override
    {
        return "ammo_bts_m16_grenade";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponM16Anim::DRAW;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "weapons/glauncher.wav" );
        g_SoundSystem.PrecacheSound( "weapons/glauncher2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/gl_reload.wav" );
        ASWeaponConfig::Precache();
    }

    const uint8 get_hands_group() override
    {
        return 2;
    }
}

ASWeaponM16Config gpWeaponM16Config;

enum WeaponM16Anim
{
    DRAW = 0,
    HOLSTER,
    IDLE,
    FIDGET,
    SHOOT1,
    SHOOT2,
    RELOAD,
    LAUNCH,
    RELOAD2
};

abstract class weapon_bts_m16_base : BTS_FireWeapon
{
    private int m_iTracerCount = 0;
    private float m_flGrenadeLaunchTime = 0;
    private bool m_bGrenadeFire = false;
    private float m_flLastPrimaryShot = 0.0f;

    bool IsSilenced()
    {
        return false;
    }

    void Spawn() override
    {
        BTS_FireWeapon::Spawn();
    }

    void Holster( int skiplocal = 0 )
    {
        m_bGrenadeFire = false;
        self.m_fInReload = false;
        BaseClass.Holster( skiplocal );
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        if( type == AttackType::Secondary )
        {
            if( player.pev.waterlevel == WATERLEVEL_HEAD || player.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0 )
            {
                this.PlayEmptySound( AttackType::Secondary );
                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.15f;
                return;
            }

            player.m_iWeaponVolume = LOUD_GUN_VOLUME;
            player.m_iWeaponFlash = BRIGHT_GUN_FLASH;
            player.m_iExtraSoundTypes = bits_SOUND_DANGER;
            player.m_flStopExtraSoundTime = g_Engine.time + 0.2f;

            player.m_rgAmmo( self.m_iSecondaryAmmoType, player.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );

            g_PlayerFuncs.ScreenShake( player.pev.origin, 7, 150.0, 0.3, 120 );

            PlayAnim( WeaponM16Anim::LAUNCH );

            player.m_Activity = ACT_RELOAD;
            player.pev.frame = 0;
            player.pev.sequence = 148;
            player.ResetSequenceInfo();

            if( Math.RandomLong( 0, 1 ) != 0 )
                PlaySound( "weapons/glauncher.wav", 1.0f );
            else
                PlaySound( "weapons/glauncher2.wav", 1.0f );

            Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );

            if( ( player.pev.button & IN_DUCK ) != 0 )
                g_EntityFuncs.ShootContact( player.pev, player.pev.origin + g_Engine.v_forward * 16.0f + g_Engine.v_right * 6.0f, g_Engine.v_forward * 1000.0f );
            else
                g_EntityFuncs.ShootContact( player.pev, player.pev.origin + player.pev.view_ofs * 0.5f + g_Engine.v_forward * 16.0f + g_Engine.v_right * 6.0f, g_Engine.v_forward * 1000.0f );

            if( player.m_rgAmmo( self.m_iSecondaryAmmoType ) > 0 )
            {
                m_bGrenadeFire = true;
                m_flGrenadeLaunchTime = g_Engine.time;
                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 2.79f;
            }
            else
            {
                m_bGrenadeFire = false;
                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 1.01f;
                self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;
            }

            HEVVoice::UpdateAmmo( player, self, player.m_rgAmmo( self.m_iSecondaryAmmoType ), 0, self.iMaxAmmo2() );

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

        bool isTrainedPersonal = util::IsTrainedPersonal( player );
        float cone = weapons::Accuracy( player, this.config.primary_accuracy, isTrainedPersonal );

        if( g_Engine.time - m_flLastPrimaryShot < 0.25f )
            cone *= this.config.automatic_accuracy_multiplier;
        m_flLastPrimaryShot = g_Engine.time;

        uint8 anim = ( Math.RandomLong( 0, 1 ) == 0 ) ? WeaponM16Anim::SHOOT1 : WeaponM16Anim::SHOOT2;

        bullet.Weapon( this )
            .Accuracy( cone )
            .Shell( models::saw_shell )
            .Animation( anim );

        if( IsSilenced() )
        {
            bullet.Flash( 0, false )
                .Sound( "bts_rc/weapons/m4sd_fire1.wav", 1.0f, 105 + Math.RandomLong( 0, 10 ), QUIET_GUN_VOLUME );
        }
        else
        {
            bullet.Sound( "bts_rc/weapons/m16_fire1.wav", 1.0f, 95 + Math.RandomLong( 0, 10 ) );
        }

        bullet.Fire();

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
            player.pev.punchangle.x = -3.0f;
        }
        else
        {
            player.pev.punchangle.x = player.pev.FlagBitSet( FL_DUCKING ) ? float( Math.RandomLong( -3, 2 ) ) : float( Math.RandomLong( -8, 3 ) );
        }

        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10.0f, 15.0f );
    }

    private void LoadGrenade()
    {
        PlayAnim( WeaponM16Anim::RELOAD2 );
        m_bGrenadeFire = false;
        m_flGrenadeLaunchTime = 0;
        PlaySound( "weapons/gl_reload.wav", 1.0f );

        this.owner.m_Activity = ACT_RELOAD;
        this.owner.pev.frame = 0;
        this.owner.pev.sequence = 150;
        this.owner.ResetSequenceInfo();
        self.m_flTimeWeaponIdle = g_Engine.time + 6.8f;
    }

    void ItemPostFrame()
    {
        if( m_bGrenadeFire && g_Engine.time >= m_flGrenadeLaunchTime + 1.0f && this.owner.m_rgAmmo( self.m_iSecondaryAmmoType ) > 0 )
            LoadGrenade();

        if( m_bGrenadeFire && g_Engine.time < m_flGrenadeLaunchTime + 2.9f && this.owner.m_rgAmmo( self.m_iSecondaryAmmoType ) >= 0 )
        {
            this.owner.pev.framerate = 1.25f;
        }
        BaseClass.ItemPostFrame();
    }

    

    float Idle() override
    {
        self.ResetEmptySound();

        float flNextIdle = Math.RandomFloat( 0.0f, 1.0f );
        if( flNextIdle <= 0.66f )
        {
            PlayAnim( WeaponM16Anim::IDLE );
            return 50.0f / 15.0f;
        }
        else
        {
            PlayAnim( WeaponM16Anim::FIDGET );
            return 86.0f / 30.0f;
        }
    }
}

class weapon_bts_m16 : weapon_bts_m16_base
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponM16Config;
    }
}
