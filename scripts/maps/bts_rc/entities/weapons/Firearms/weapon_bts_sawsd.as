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
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/pl_gun2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/gun_fire4.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/saw_reload.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/saw_reload2.wav" );
        ASWeaponConfig::Precache();
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapon configuration",
            "description": "Control sawsd configuration",
            "allOf":
            [
                "ASWeaponConfig"
            ],
            "properties":
            {
            }
        }""";
    }

    bool Register( meta_api::json::v2::json@ json ) override {
        // Reload properties
        this.reload_time = 2.0f;

        return ASWeaponConfig::Register( json );
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
        self.m_iDefaultAmmo = Math.RandomLong( 19, gpWeaponSawSDConfig.max_clip );
        BTS_FireWeapon::Spawn();
        pev.scale = 0.8;
        m_iLink = g_Game.PrecacheModel( "models/saw_link.mdl" );
    }

    void Holster( int skiplocal = 0 )
    {
        SetThink( null );
        BaseClass.Holster( skiplocal );
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

        player.m_iWeaponVolume = QUIET_GUN_VOLUME;

        RecalculateBody( --self.m_iClip );
        m_bAlternatingEject = !m_bAlternatingEject;

        Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );
        Vector vecSrc = player.GetGunPosition();
        Vector vecAiming = player.GetAutoaimVector( AUTOAIM_5DEGREES );

        bool isTrainedPersonal = util::IsTrainedPersonal( player );
        float coneVal = Accuracy( ( player.IsMoving() ? 0.02618f : 0.01f ), ( player.IsMoving() ? 0.1f : 0.05f ), 0.01f, 0.05f );

        float x, y;
        g_Utility.GetCircularGaussianSpread( x, y );

        Vector vecDir = vecAiming + x * coneVal * g_Engine.v_right + y * coneVal * g_Engine.v_up;
        Vector vecEnd = vecSrc + vecDir * 8192.0f;

        TraceResult tr;
        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, player.edict(), tr );
        self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, gpWeaponSawSDConfig.primary_damage, player.pev );
        TraceEffects( tr, Bullet::BULLET_PLAYER_CUSTOMDAMAGE );

        if( ( m_iTracerCount++ % 2 ) == 0 )
        {
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

        PlayAnim( Math.RandomLong( WeaponSawSDAnim::SHOOT1, WeaponSawSDAnim::SHOOT3 ) );
        PlaySound( "weapons/pl_gun2.wav", Math.RandomFloat( 0.92f, 1.0f ), 98 + Math.RandomLong( 0, 3 ) );
        g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_ITEM, "bts_rc/weapons/gun_fire4.wav", 0.5f, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 15 ) );
        player.pev.punchangle.x = isTrainedPersonal ? Math.RandomFloat( -2.0f, 2.0f ) : Math.RandomFloat( -10.0f, 2.0f );
        player.pev.punchangle.y = isTrainedPersonal ? Math.RandomFloat( -1.0f, 1.0f ) : Math.RandomFloat( -2.0f, 1.0f );

        Vector vecForward, vecRight, vecUp;
        g_EngineFuncs.AngleVectors( player.pev.v_angle, vecForward, vecRight, vecUp );
        Vector vecOrigin = player.GetGunPosition() + vecForward * 14.0f + vecRight * 8.0f - vecUp * 10.0f;
        Vector vecVelocity = player.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
        g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, player.pev.v_angle.y, m_bAlternatingEject ? m_iLink : models::saw_shell, TE_BOUNCE_SHELL );

        CheckDepletedAmmo( self.m_iPrimaryAmmoType );

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
        int roundsBody;
        if( iClip <= 0 )
            roundsBody = 8;
        else if( iClip < 8 )
            roundsBody = 9 - iClip;
        else
            roundsBody = 0;

        pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( gpWeaponSawSDConfig.view_model ), pev.body, 2, roundsBody );
    }

    private void FinishAnim()
    {
        SetThink( null );
        int roundsBody = self.m_iClip;
        pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( gpWeaponSawSDConfig.view_model ), pev.body, 2, roundsBody );
        pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( gpWeaponSawSDConfig.view_model ), pev.body, 1, util::GetClass( this.owner ) );
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
