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


bool ASWeaponLaserConfigSchema = g_MapConfig.RegisterSchemaDefinition( "ASWeaponLaserConfig",
"""{
    "laser_accuracy":
    {
        "title": "Laser accuracy multiplier",
        "description": "Multimplier for the accuracy cone when the laser spot is disabled",
        "type": "number",
        "minimum": 0.1
    },
    "laser_cooldown":
    {
        "title": "Laser cooldown multiplier",
        "description": "Multimplier for the cooldown when the laser spot is enabled",
        "type": "number",
        "minimum": 0.1
    },
    "laser_size":
    {
        "title": "Laser sprite size multiplier",
        "description": "Multimplier for the sprite model when the laser spot is enabled",
        "type": "number",
        "minimum": 0.1
    }
}""" );

// Retains one reusable laser spot entity for each player slot.
array<EHandle> gpLaserSpots( g_Engine.maxClients );

// Retains one reusable laser spot entity for each player slot.
namespace LaserSpot
{
    // Get a valid laser entity (info_target) for the given player
    CBaseEntity@ Entity( CBasePlayer@ player )
    {
        if( player is null )
            return null;

        int index = player.entindex() - 1;
        EHandle laserHandle = gpLaserSpots[ index ];
        CBaseEntity@ laserEntity = null;

        if( !laserHandle.IsValid() || ( @laserEntity = laserHandle.GetEntity() ) is null )
        {
            @laserEntity = g_EntityFuncs.CreateEntity( "info_target", null, false );

            g_EntityFuncs.SetModel( laserEntity, "sprites/laserdot.spr" );

            laserEntity.pev.movetype = MOVETYPE_NONE;
            laserEntity.pev.solid = SOLID_NOT;
            laserEntity.pev.rendermode = kRenderGlow;
            laserEntity.pev.renderfx = kRenderFxNoDissipation;
            laserEntity.pev.effects |= EF_NODRAW;

            g_EntityFuncs.DispatchSpawn( laserEntity.edict() );

            laserHandle.opAssign( laserEntity );
            gpLaserSpots[ index ] = laserHandle;
        }

        return laserHandle.GetEntity();
    }
}

abstract class ASWeaponLaserConfig : ASWeaponConfig
{
    float laser_accuracy;
    float laser_cooldown;
    float laser_size;

    // Called when the laser is enabled or disabled
    void LaserUpdate( bool active, CBasePlayer@ player, CBasePlayerWeapon@ weapon )
    {
        if( active )
        {
            g_SoundSystem.EmitSoundDyn( weapon.edict(), SOUND_CHANNEL::CHAN_WEAPON, "weapons/desert_eagle_sight.wav", 1.0f, ATTN_NORM, 0, PITCH_NORM );
        }
        else
        {
            g_SoundSystem.EmitSoundDyn( weapon.edict(), SOUND_CHANNEL::CHAN_WEAPON, "weapons/desert_eagle_sight2.wav", 1.0f, ATTN_NORM, 0, PITCH_NORM );
        }
    }

    // Toggle laser and sets cooldown based on type
    void LaserToggle( bool is_trained_personal, AttackType type, CBasePlayerWeapon@ weapon, CBasePlayer@ player )
    {
        weapon.pev.iuser1 = ( weapon.pev.iuser1 == 1 ? 0 : 1 );

        float cooldown = this.GetCooldown( is_trained_personal, type );

        if( weapon.pev.iuser1 != 0 )
        {
            cooldown *= this.laser_cooldown;
        }

        weapons::SetCooldown( weapon, player, cooldown );
    }

    // Call BTS_FireWeapon::Accuracy and pass the result in. returns a modified accuracy cone based on laser spot
    float LaserAccuracy( float cone, CBasePlayerWeapon@ weapon )
    {
        if( weapon.pev.iuser1 == 0 )
        {
            cone *= this.laser_accuracy;
        }

        return cone;
    }

    void WeaponHolster( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        ASWeaponConfig::WeaponHolster( player, weapon, character );

        if( weapon.pev.iuser1 != 1 )
            return;

        CBaseEntity@ laser = LaserSpot::Entity( player );

        if( laser is null )
            return;

        if( ( laser.pev.effects & EF_NODRAW ) == 0 )
        {
            laser.pev.effects |= EF_NODRAW;
            LaserUpdate( false, player, weapon );
        }
    }

    void PlayerThink( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        ASWeaponConfig::PlayerThink( player, weapon, character );

        CBaseEntity@ laser = LaserSpot::Entity( player );

        if( laser is null )
            return;

        if( weapon.pev.iuser1 == 1 )
        {
            if( weapon.m_fInReload )
            {
                if( ( laser.pev.effects & EF_NODRAW ) == 0 )
                {
                    laser.pev.effects |= EF_NODRAW;
                    LaserUpdate( false, player, weapon );
                }
                return;
            }

            if( ( laser.pev.effects & EF_NODRAW ) != 0 )
            {
                laser.pev.effects &= ~EF_NODRAW;
                laser.pev.renderamt = 0;
                LaserUpdate( true, player, weapon );
            }

            // Gradual turn on
            if( laser.pev.renderamt < 255 )
                laser.pev.renderamt += 5;

            laser.pev.scale = this.laser_size;

            Math.MakeVectors( player.pev.v_angle );
            Vector vecSrc = player.GetGunPosition();
            Vector vecEnd = vecSrc + ( g_Engine.v_forward * 8192 );

            TraceResult tr;
            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, player.edict(), tr );
            g_EntityFuncs.SetOrigin( laser, tr.vecEndPos );
            return;
        }

        if( ( laser.pev.effects & EF_NODRAW ) == 0 )
        {
            laser.pev.effects |= EF_NODRAW;
            LaserUpdate( false, player, weapon );
        }
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapon config",
            "description": "weapon-related gameplay modifiers.",
            "allOf":
            [
                "ASWeaponConfig",
                "ASWeaponLaserConfig"
            ],
            "properties":
            {
            }
        }""";
    }

    void Precache() override
    {
        g_Game.PrecacheModel( "sprites/laserdot.spr" );

        g_SoundSystem.PrecacheSound( "weapons/desert_eagle_sight.wav" );
        g_SoundSystem.PrecacheSound( "weapons/desert_eagle_sight2.wav" );

        ASWeaponConfig::Precache();
    }

    bool Register( meta_api::json::v2::json@ config ) override
    {
        this.laser_accuracy = config.ValueOrDefault( "laser_accuracy", this.laser_accuracy );
        this.laser_cooldown = config.ValueOrDefault( "laser_cooldown", this.laser_cooldown );
        this.laser_size = config.ValueOrDefault( "laser_size", this.laser_size );

        return ASWeaponConfig::Register( config );
    }
}
