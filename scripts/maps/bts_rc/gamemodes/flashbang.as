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

final class ASBlackOpsFlashbang : EntityOverriden, IConfigurableContext
{
    private float throw_flash_cooldown;
    private float detonate_time;

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
                "IConfigurableContext"
            ],
            "properties":
            {
                "interval":
                {
                    "title": "Think rate",
                    "type": "number",
                    "minimum": 0.0,
                    "default": 0.5,
                    "description": "Internal think rate interval. the lower the value the more cpu usage"
                },
                "throw_flash_cooldown":
                {
                    "type": "number",
                    "minimum": 1,
                    "default": 3,
                    "description": "Global cooldown for blackops to throw grenades"
                },
                "detonate_time":
                {
                    "type": "number",
                    "minimum": 1,
                    "default": 6,
                    "description": "Time, in seconds, at which the flashbang will detonate since it's thrown."
                }
            }
        }""";
    }

    bool Register( meta_api::json::v2::json@ config ) override
    {
        if( !bool( config[ "active" ] ) )
            return false;

        this.detonate_time = float( config[ "detonate_time" ] );
        this.throw_flash_cooldown = float( config[ "throw_flash_cooldown" ] );

        g_SoundSystem.PrecacheSound( "mikk/player/earringing.wav" );
        g_SoundSystem.PrecacheSound( "mikk/player/earringing_right.wav" );
        g_SoundSystem.PrecacheSound( "mikk/player/earringing_left.wav" );

        g_Game.PrecacheModel( "models/bts_rc/weapons/w_fgrenade.mdl" );

        EntityOverriden::SetThink( float( config[ "interval" ] ) );
        EntityOverriden::Register( this );
        return true;
    }

    bool AddEntity( uint index, CBaseEntity@ entity, CustomKeyvalues@ ckv, CBaseMonster@ monster ) override
    {
        if( ckv.GetKeyvalue( "$i_use_flashbang" ).GetInteger() != 1 )
            return false;

#if SERVER
        SetDebugName( entity, "Blackop with flashbang grenades" );
#endif

        return EntityOverriden::AddEntity( index, entity, ckv, monster );
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
    private EHandle m_hGrenade;
    private float m_flTracking;
    private uint m_uiTrackingOwner;

    void Think() override
    {
        if( !this.ShouldThink() )
            return;

        this.nextthink = g_Engine.time + this.interval;

        CGrenade@ grenade = null;

        if( m_hGrenade.IsValid() && ( @grenade = cast<CGrenade@>( m_hGrenade.GetEntity() ) ) !is null )
        {
            float flMaxDist = 1024.0f;

            Vector color( 255, 255, 255 );

            for( int i = 1; i <= g_Engine.maxClients; i++ )
            {
                auto player = g_PlayerFuncs.FindPlayerByIndex(i);

                if( player is null )
                    continue;

                float flDistance = ( grenade.pev.origin - player.pev.origin ).Length();

                // Player is too far away
                if( flDistance > flMaxDist )
                    continue;

                Vector vecSrc = player.pev.origin + player.pev.view_ofs;

                TraceResult tr;
                g_Utility.TraceLine( vecSrc, grenade.pev.origin, ignore_monsters, player.edict(), tr );

                if( tr.flFraction < 1.0 )
                    continue; // No line of sight

                Math.MakeVectors( player.pev.v_angle );
                Vector vecToTarget = ( grenade.pev.origin - vecSrc ).Normalize();
                float dot = DotProduct( g_Engine.v_forward, vecToTarget );

                // player is looking at it
                if( dot >= 0.5f )
                    g_PlayerFuncs.ScreenFade( player, color, 3.0, 1.0, 255, 0 );

                float flVolume = 1.0f - Math.clamp( flDistance / flMaxDist, 0.0f, 1.0f );

                float flEffect = dot * flVolume;

                float side = DotProduct( g_Engine.v_right, vecToTarget );

                if( ( side < 0 ? -side : side ) < 0.2f )
                {
                    g_SoundSystem.PlaySound( player.edict(), CHAN_ITEM, "mikk/player/earringing.wav", flVolume, ATTN_NORM, 0, PITCH_NORM, player.entindex() );
                }
                else if( side > 0 )
                {
                    g_SoundSystem.PlaySound( player.edict(), CHAN_ITEM, "mikk/player/earringing.wav", flVolume, ATTN_NORM, 0, PITCH_NORM, player.entindex() );
                }
                else
                {
                    g_SoundSystem.PlaySound( player.edict(), CHAN_ITEM, "mikk/player/earringing.wav", flVolume, ATTN_NORM, 0, PITCH_NORM, player.entindex() );
                }
            }

            g_EntityFuncs.Remove( grenade );
            this.nextthink = g_Engine.time + this.throw_flash_cooldown;
            return;
        }

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
                        @bestGrenade.pev.owner = null;
                        bestGrenade.pev.dmgtime = g_Engine.time + this.detonate_time + 1.0f;
                        g_EntityFuncs.SetModel( bestGrenade, "models/bts_rc/weapons/w_fgrenade.mdl" );

                        this.m_flTracking = 0;
                        this.m_hGrenade = EHandle( bestGrenade );
                        this.nextthink = g_Engine.time + this.detonate_time;
                    }
                }
            }
            return;
        }

        // Call on EntityThink
        EntityOverriden::Think();
    }
}
