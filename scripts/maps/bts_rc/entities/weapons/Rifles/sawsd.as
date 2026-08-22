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

final class ASWeaponSawSDConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_sawsd";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_sawsd.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_sawsd.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_sawsd.mdl";
    }

    const string& get_animation_extension() override
    {
        return "saw";
    }

    const string& get_primary_ammo() override
    {
        return "556";
    }

    const string& get_primary_ammoentity() override
    {
        return "ammo_bts_sawsd";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponSawSDAnim::DRAW;
    }

    void Precache() override
    {
        g_Game.PrecacheModel( "models/saw_link.mdl" );
        g_SoundSystem.PrecacheSound( "weapons/pl_gun2.wav" );
        ASWeaponConfig::Precache();
    }
}

ASWeaponSawSDConfig gpWeaponSawSDConfig;

enum WeaponSawSDAnim
{
    SLOWIDLE = 0,
    IDLE2,
    RELOAD_START,
    RELOAD_END,
    HOLSTER,
    DRAW,
    SHOOT1,
    SHOOT2,
    SHOOT3
};

class weapon_bts_sawsd : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponSawSDConfig;
    }

    private bool m_bAlternatingEject = false;
    private int m_iTracerCount = 0;
    private bool m_bFixBeltAfterReload = false;
    private int m_iLink = 0;

    void Spawn() override
    {
        BTS_FireWeapon::Spawn();
        pev.scale = 0.8;
        m_iLink = g_Game.PrecacheModel( "models/saw_link.mdl" );
    }

    void Holster( int skiplocal = 0 )
    {
        BaseClass.Holster( skiplocal );
    }

    void Reload() override
    {
        if( self.m_iClip == config.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_flNextPrimaryAttack > g_Engine.time )
            return;

        self.DefaultReload( config.max_clip, WeaponSawSDAnim::RELOAD_START, config.reload_time, this.body );

        if( !self.m_fInReload )
            return;

        m_bFixBeltAfterReload = true;
        self.m_flTimeWeaponIdle = g_Engine.time + config.reload_time;
        PlaySound( "bts_rc/weapons/saw_reload.wav", VOL_NORM );
        StartSchedule( g_Scheduler.SetTimeout( @this, "FinishAnim", 1.33f ) );
        BaseClass.Reload();
    }

    void ItemPostFrame()
    {
        BaseClass.ItemPostFrame();

        if( m_bFixBeltAfterReload && !self.m_fInReload )
        {
            m_bFixBeltAfterReload = false;
            RecalculateBody( self.m_iClip );
        }

        if( this.owner.pev.sequence == 172 || this.owner.pev.sequence == 176 )
            this.owner.pev.framerate = 2.0f;
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        switch( type )
        {
            case AttackType::Tertiary:
            case AttackType::Secondary:
                return;
        }

        if( player.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
        {
            this.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.09f;
            return;
        }

        m_bAlternatingEject = !m_bAlternatingEject;

        bool isTrainedPersonal = util::IsTrainedPersonal( player );
        bullet.Weapon( this )
            .Sound( "weapons/pl_gun2.wav", Math.RandomFloat( 0.92f, 1.0f ), 98 + Math.RandomLong( 0, 3 ), QUIET_GUN_VOLUME )
            .Shell( m_bAlternatingEject ? m_iLink : models::saw_shell )
            .Flash( 0, false )
            .Tracer( ( m_iTracerCount++ % 2 ) == 0 )
            .Animation( Math.RandomLong( WeaponSawSDAnim::SHOOT1, WeaponSawSDAnim::SHOOT3 ) )
        .Fire();

        RecalculateBody( self.m_iClip );
        g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_ITEM, "bts_rc/weapons/gun_fire4.wav", 0.5f, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 15 ) );
        player.pev.punchangle.x = isTrainedPersonal ? Math.RandomFloat( -2.0f, 2.0f ) : Math.RandomFloat( -10.0f, 2.0f );
        player.pev.punchangle.y = isTrainedPersonal ? Math.RandomFloat( -1.0f, 1.0f ) : Math.RandomFloat( -2.0f, 1.0f );

        self.m_flNextPrimaryAttack = g_Engine.time + 0.099f;
        self.m_flTimeWeaponIdle = g_Engine.time + 0.2f;

        if( g_WeaponsConfig.m249_knockback )
        {
            const float flZVel = player.pev.velocity.z;
            Vector vecInvPushDir = g_Engine.v_forward * ( isTrainedPersonal ? 60.0f : 35.0f );
            player.pev.velocity = player.pev.velocity - vecInvPushDir;
            player.pev.velocity.z = flZVel * 1.15f;
        }
    }



    private void RecalculateBody( int iClip )
    {
        if( iClip <= 0 )
        {
            this.bodygroup( 2, 8 );
        }
        else if( iClip < 8 )
        {
            this.bodygroup( 2, 9 - iClip );
        }
        else
        {
            this.bodygroup( 2, 0 );
        }
    }

    void FinishAnim()
    {
        PlayAnim( WeaponSawSDAnim::RELOAD_END );
        PlaySound( "bts_rc/weapons/saw_reload2.wav", VOL_NORM, 94 + Math.RandomLong( 0, 15 ) );
    }

    float Idle() override
    {
        self.ResetEmptySound();

        const float flNextIdle = Math.RandomFloat( 0.0f, 1.0f );
        if( flNextIdle <= 0.95f )
        {
            PlayAnim( WeaponSawSDAnim::SLOWIDLE );
            return 5.0f;
        }
        else
        {
            PlayAnim( WeaponSawSDAnim::IDLE2 );
            return 6.16f;
        }
    }
}
