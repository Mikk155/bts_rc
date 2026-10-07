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

/*
    Author: Mikk
*/

namespace FlashbangGrenade
{
    const Vector color( 255, 255, 255 );

    const float max_view_distance = 800;
    float detonate_time;
    float fadeout;
    float fadehold;

    // Tracks a grenade entity to override it into a flashbang grenade.
    // If detonateTime is zero (By default) uses the json configured detonation time.
    void Create( CGrenade@ grenade, float detonateTime = 0 )
    {
        if( grenade !is null )
        {
            if( detonateTime <= 0.0 )
                detonateTime = detonate_time;

            @grenade.pev.owner = null;
            grenade.pev.dmgtime = g_Engine.time + detonateTime + 1.0f;
            g_EntityFuncs.SetModel( grenade, "models/bts_rc/weapons/w_fgrenade.mdl" );
            g_Scheduler.SetTimeout( "__ExplodeFlashbangGrenade__", detonateTime, EHandle( grenade ) );
        }
    }

    // Tracks a grenade entity to override it into a flashbang grenade.
    // If detonateTime is zero (By default) uses the json configured detonation time.
    void Create( CBaseEntity@ grenade, float detonateTime = 0 )
    {
        if( grenade !is null )
            Create( cast<CGrenade@>( grenade ) );
    }
}

void __ExplodeFlashbangGrenade__( EHandle handle )
{
    CGrenade@ grenade = null;

    if( !handle.IsValid() || handle.GetEntity() is null || ( @grenade = cast<CGrenade@>( handle.GetEntity() ) ) is null )
        return;


    g_SoundSystem.PlaySound( grenade.edict(), CHAN_AUTO, "mikk155/player/earringing.wav", 0.4f, ATTN_NORM, 0, PITCH_NORM );
    g_SoundSystem.PlaySound( grenade.edict(), CHAN_AUTO, "bts_rc/weapons/flashbang_pop.wav", 1.0f, ATTN_NORM, 0, PITCH_NORM );

    NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, grenade.pev.origin );
        m.WriteByte( TE_SPRITE );
        m.WriteCoord( grenade.pev.origin.x );
        m.WriteCoord( grenade.pev.origin.y );
        m.WriteCoord( grenade.pev.origin.z + 16.0  );
        m.WriteShort( models::xsmoke4 );
        m.WriteByte( 10 ); // scale * 10
        m.WriteByte( 128 ); // brightness
    m.End();

    for( int i = 1; i <= g_Engine.maxClients; i++ )
    {
        auto player = g_PlayerFuncs.FindPlayerByIndex(i);

        if( player is null || !player.IsAlive() )
            continue;

        float flDistance = ( grenade.pev.origin - player.pev.origin ).Length();

        // Player is too far away
        if( flDistance > FlashbangGrenade::max_view_distance )
            continue;

        Vector vecSrc = player.pev.origin + player.pev.view_ofs;

        TraceResult tr;
        g_Utility.TraceLine( vecSrc, grenade.pev.origin, ignore_monsters, ignore_glass, player.edict(), tr );

        if( tr.flFraction < 1.0 )
            continue; // No line of sight

        Math.MakeVectors( player.pev.v_angle );
        Vector vecToTarget = ( grenade.pev.origin - vecSrc ).Normalize();
        float dot = DotProduct( g_Engine.v_forward, vecToTarget );

        // player is looking at it
        if( dot >= 0.5f )
            g_PlayerFuncs.ScreenFade( player, FlashbangGrenade::color, FlashbangGrenade::fadeout, FlashbangGrenade::fadehold, 255, 0 );

        float flVolume = 1.0f - Math.clamp( flDistance / FlashbangGrenade::max_view_distance, 0.0f, 1.0f );

        float side = DotProduct( g_Engine.v_right, vecToTarget );

        if( ( side < 0 ? -side : side ) < 0.2f )
        {
            g_SoundSystem.PlaySound( player.edict(), CHAN_AUTO, "mikk155/player/earringing.wav", flVolume, ATTN_NORM, 0, PITCH_NORM, player.entindex() );
        }
        else if( side > 0 )
        {
            g_SoundSystem.PlaySound( player.edict(), CHAN_AUTO, "mikk155/player/earringing_right.wav", flVolume, ATTN_NORM, 0, PITCH_NORM, player.entindex() );
        }
        else
        {
            g_SoundSystem.PlaySound( player.edict(), CHAN_AUTO, "mikk155/player/earringing_left.wav", flVolume, ATTN_NORM, 0, PITCH_NORM, player.entindex() );
        }
    }

    g_EntityFuncs.Remove( grenade );
}

final class ASBlackOpsFlashbang : EntityOverriden, IConfigurable
{
    private float throw_flash_cooldown;

    const string& GetName() const override
    {
        return "blackops_flashbang";
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Blackops flashbangs",
            "description": "Controls blackops flashbangs feature",
            "allOf":
            [
                "IConfigurable"
            ],
            "properties":
            {
                "interval":
                {
                    "title": "Think rate",
                    "type": "number",
                    "minimum": 0.0,
                    "description": "Internal think rate interval. the lower the value the more cpu usage"
                },
                "fadehold":
                {
                    "type": "number",
                    "minimum": 0.1,
                    "description": "Fade hold time"
                },
                "fadeout":
                {
                    "type": "number",
                    "minimum": 0.1,
                    "description": "Fade out time"
                },
                "throw_flash_cooldown":
                {
                    "type": "number",
                    "minimum": 1,
                    "description": "Global cooldown for blackops to throw grenades"
                },
                "detonate_time":
                {
                    "type": "number",
                    "minimum": 1,
                    "description": "Time, in seconds, at which the flashbang will detonate since it's thrown."
                }
            }
        }""";
    }

    bool Register( btson@ config ) override
    {
        // Deathdrop may use these.
        config.Get( "detonate_time", FlashbangGrenade::detonate_time, false );
        config.Get( "fadeout", FlashbangGrenade::fadeout, false );
        config.Get( "fadehold", FlashbangGrenade::fadehold, false );

        if( !bool( config[ "active" ] ) )
            return false;

        config.Get( "throw_flash_cooldown", this.throw_flash_cooldown, false );

        EntityOverriden::SetThink( config.ValueOrDefault( "interval", 1.0f, false, false ) );

        if( g_MapConfig.MapLoading )
        {
            CustomKeyValues::Register( "$i_use_flashbang" );
            EntityOverriden::Register( this );
        }

        return true;
    }

    bool AddEntity( CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( monster is null || monster.GetCustomKeyvalues().GetKeyvalue( "$i_use_flashbang" ).GetInteger() != 1 )
            return false;

        if( !g_IsMainMap )
            SetDebugName( entity, "Blackop with flashbang grenades" );

        return EntityOverriden::AddEntity( entity, monster );
    }

    uint EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( monster is null || !monster.IsAlive() )
            return EntityOverridenAction::Remove;

        // Force somebody to throw a grenade.
        if( monster.m_hEnemy.IsValid() && monster.pev.sequence != 6 && monster.m_MonsterState != MONSTERSTATE::MONSTERSTATE_SCRIPT )
        {
            // let some seconds til he creates the grenade entity
            this.m_flTracking = g_Engine.time + 5.0f;

            this.m_uiTrackingOwner = index;

            monster.m_IdealActivity = ACT_RANGE_ATTACK2;
            monster.SetState( MONSTERSTATE::MONSTERSTATE_SCRIPT );
            monster.SetActivity( ACT_RANGE_ATTACK2 );

            return EntityOverridenAction::Break;
        }

        return EntityOverridenAction::None;
    }

    // Flashbang grenade
    private float m_flTracking;
    private uint m_uiTrackingOwner;

    void Think() override
    {
        if( !this.ShouldThink() )
            return;

        this.nextthink = g_Engine.time + this.interval;

        if( m_flTracking > g_Engine.time )
        {
            EHandle ownerHandle = this.m_Handles[this.m_uiTrackingOwner];

            if( ownerHandle.IsValid() )
            {
                CBaseEntity@ ownerEntity = ownerHandle.GetEntity();

                if( ownerEntity !is null )
                {
                    edict_t@ ownerEdict = ownerEntity.edict();

                    CBaseEntity@ grenadeEntity = null;
                    CBaseEntity@ bestGrenade = null;

                    while( ( @grenadeEntity = g_EntityFuncs.FindEntityByClassname( grenadeEntity, "grenade" ) ) !is null && grenadeEntity.pev.owner is ownerEdict )
                    {
                        // Done this way in case there's already a grenade (non flashbang) thrown by this owner
                        if( bestGrenade is null || ( bestGrenade.pev.origin - ownerEntity.pev.origin ).Length() > ( grenadeEntity.pev.origin - ownerEntity.pev.origin ).Length() )
                            @bestGrenade = grenadeEntity;
                    }

                    if( bestGrenade !is null )
                    {
                        this.m_flTracking = 0;
                        FlashbangGrenade::Create( bestGrenade );
                        this.nextthink = g_Engine.time + this.throw_flash_cooldown;
                    }
                }
            }
            return;
        }

        // Call on EntityThink
        EntityOverriden::Think();
    }
}
