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

class CWeaponM79Config : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_m79";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_m79.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_m79.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_m79.mdl";
    }

    const string& get_animation_extension() override
    {
        return "bow";
    }

    const string& get_primary_ammo() override
    {
        return "ARgrenades";
    }

    const string& get_primary_ammoentity() override
    {
        return "ammo_bts_m79";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponM79Anim::DRAW;
    }

    void Precache() override
    {
        g_Game.PrecacheModel( "models/grenade.mdl" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/m79_fire.wav" );
        ASWeaponConfig::Precache();
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        this.slot = 5;
        this.position = 4;
        this.weight = 20;
        this.deploy_time = 1.03;
        this.primary_maxammo = 10;
        this.primary_dropammo = 1;
        this.max_clip = 1;
        this.primary_damage = 130.0f;
        this.primary_cooldown = 1.0;
        this.primary_trained_cooldown = 1.0;

        g_CustomEntityFuncs.RegisterCustomEntity( "CM79Rocket", "m79_rocket" );

        return ASWeaponConfig::Register( json );
    }
}

CWeaponM79Config gpWeaponM79Config;

enum WeaponM79Anim
{
    IDLE = 0,
    SHOOT,
    RELOAD,
    DRAW,
    HOLSTER
};

class CM79Rocket : ScriptBaseEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetSize( pev, g_vecZero, g_vecZero );

        pev.movetype = MOVETYPE_TOSS;
        pev.solid = SOLID_BBOX;

        NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
        m1.WriteByte( TE_BEAMFOLLOW );
        m1.WriteShort( self.entindex() );
        m1.WriteShort( models::laserbeam );
        m1.WriteByte( 20 );
        m1.WriteByte( 2 );
        m1.WriteByte( 190 );
        m1.WriteByte( 190 );
        m1.WriteByte( 190 );
        m1.WriteByte( 200 );
        m1.End();

        SetThink( ThinkFunction( this.GrenadeThink ) );
        pev.nextthink = g_Engine.time + 0.01f;
        SetTouch( TouchFunction( this.GrenadeTouch ) );
    }

    void GrenadeThink()
    {
        pev.angles = Math.VecToAngles( pev.velocity.Normalize() );
        pev.nextthink = g_Engine.time + 0.1f;
    }

    void GrenadeTouch( CBaseEntity@ pOther )
    {
        if( g_EngineFuncs.PointContents( pev.origin ) == CONTENTS_SKY )
        {
            self.UpdateOnRemove();
            self.pev.flags |= FL_KILLME;
            return;
        }

        Explode();
    }

    void Explode()
    {
        TraceResult tr;
        Vector vecSpot = pev.origin - pev.velocity.Normalize() * 32.0f;
        Vector vecEnd = pev.origin + pev.velocity.Normalize() * 64.0f;
        g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, self.edict(), tr );

        pev.model = string_t();
        pev.solid = SOLID_NOT;

        pev.takedamage = DAMAGE_NO;

        if( tr.flFraction != 1.0f )
            pev.origin = tr.vecEndPos + ( tr.vecPlaneNormal * 24.0f );

        NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
        m1.WriteByte( TE_EXPLOSION );
        m1.WriteCoord( pev.origin.x );
        m1.WriteCoord( pev.origin.y );
        m1.WriteCoord( pev.origin.z );

        if( g_EngineFuncs.PointContents( pev.origin ) != CONTENTS_WATER )
        {
            for( int i = Math.RandomLong( 0, 3 ); i <= 3; i++ )
                g_EntityFuncs.Create( "spark_shower", pev.origin, tr.vecPlaneNormal, false );

            m1.WriteShort( models::zerogxplode );
        }
        else
        {
            m1.WriteShort( models::WXplo1 );
        }

        m1.WriteByte( 15 );
        m1.WriteByte( 10 );
        m1.WriteByte( TE_EXPLFLAG_NONE );
        m1.End();

        CSoundEnt@ sound = GetSoundEntInstance();
        if( sound !is null )
            sound.InsertSound( bits_SOUND_COMBAT, pev.origin, NORMAL_EXPLOSION_VOLUME, 3.0f, self );

        entvars_t@ pevOwner = pev;
        if( pev.owner !is null )
            @pevOwner = pev.owner.vars;

        g_WeaponFuncs.RadiusDamage( pev.origin, pev, pevOwner, pev.dmg, pev.fuser1, CLASS_NONE, DMG_BLAST );

        g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong( 0, 1 ) );

        pev.effects |= EF_NODRAW;
        SetThink( ThinkFunction( this.Smoke ) );
        pev.velocity = g_vecZero;
        pev.nextthink = g_Engine.time + 0.5;
    }

    void Smoke()
    {
        if( g_EngineFuncs.PointContents( pev.origin ) == CONTENTS_WATER )
        {
            g_Utility.Bubbles( pev.origin - Vector( 64, 64, 64 ), pev.origin + Vector( 64, 64, 64 ), 100 );
        }
        else
        {
            NetworkMessage msg1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
            msg1.WriteByte( TE_SMOKE );
            msg1.WriteCoord( pev.origin.x );
            msg1.WriteCoord( pev.origin.y );
            msg1.WriteCoord( pev.origin.z );
            msg1.WriteShort( models::steam1 );
            msg1.WriteByte( 40 );
            msg1.WriteByte( 6 );
            msg1.End();
        }
        self.UpdateOnRemove();
        self.pev.flags |= FL_KILLME;
    }
}

namespace M79_ROCKET
{
    CM79Rocket@ Shoot( entvars_t@ pevOwner, const Vector& in vecStart, const Vector& in vecVelocity, float flDmg, float flRadius, const string& in szModel )
    {
        CBaseEntity@ entity = g_EntityFuncs.CreateEntity( "m79_rocket", null, false );
        if( entity is null )
            return null;

        CM79Rocket@ pRocket = cast<CM79Rocket@>( CastToScriptClass( entity ) );
        if( pRocket is null )
            return null;

        g_EntityFuncs.SetModel( pRocket.self, szModel );
        g_EntityFuncs.SetOrigin( pRocket.self, vecStart );
        g_EntityFuncs.DispatchSpawn( pRocket.self.edict() );

        pRocket.pev.velocity = vecVelocity;
        pRocket.pev.angles = Math.VecToAngles( pRocket.pev.velocity );

        pRocket.pev.dmg = flDmg;
        pRocket.pev.fuser1 = flRadius;
        @pRocket.pev.owner = pevOwner.pContainingEntity;

        return pRocket;
    }
}

class weapon_bts_m79 : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponM79Config;
    }

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 0, 3 );
        BTS_FireWeapon::Spawn();
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        if( player.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;
            return;
        }

        if( type != AttackType::Primary )
            return;

        player.m_iWeaponVolume = NORMAL_GUN_VOLUME;
        player.m_iWeaponFlash = BRIGHT_GUN_FLASH;

        player.m_iExtraSoundTypes = bits_SOUND_DANGER;
        player.m_flStopExtraSoundTime = g_Engine.time + 0.2f;

        --self.m_iClip;

        player.pev.effects |= EF_MUZZLEFLASH;
        pev.effects |= EF_MUZZLEFLASH;

        player.SetAnimation( PLAYER_ATTACK1 );

        Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );
        Vector offset = Vector( 8.0f, 4.0f, -2.0f );
        Vector vecSrc = player.GetGunPosition() + g_Engine.v_forward * offset.x + g_Engine.v_right * offset.y + g_Engine.v_up * offset.z;
        Vector vecVelocity = g_Engine.v_forward * 1200.0f;

        M79_ROCKET::Shoot( player.pev, vecSrc, vecVelocity, gpWeaponM79Config.primary_damage, 240.0f, "models/grenade.mdl" );

        PlayAnim( WeaponM79Anim::SHOOT );
        PlaySound( "bts_rc/weapons/m79_fire.wav", Math.RandomFloat( 0.95f, 1.0f ), 93 + Math.RandomLong( 0, 0xf ) );
        player.pev.punchangle.x = Math.RandomFloat( -2.0f, -3.0f );

        if( self.m_iClip <= 0 && player.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && util::IsHEV( player ) )
            player.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;
        self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;
    }

    void Reload()
    {
        if( self.m_iClip == gpWeaponM79Config.max_clip || this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        self.DefaultReload( gpWeaponM79Config.max_clip, WeaponM79Anim::RELOAD, 3.88f, pev.body );
        BaseClass.Reload();
    }

    float Idle() override
    {
        self.ResetEmptySound();
        PlayAnim( WeaponM79Anim::IDLE );
        return Math.RandomFloat( 5.0f, 6.0f );
    }
}
