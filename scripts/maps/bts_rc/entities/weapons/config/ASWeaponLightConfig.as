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

// Retains one reusable flashlight spot entity for each player slot.
namespace Flashlight
{
    bool ASWeaponLightConfigSchema = g_MapConfig.RegisterSchemaDefinition( "ASWeaponLightConfig",
"""{
    "flashlight_drain":
    {
        "type": "number",
        "default": 0.8,
        "minimum": 0.1,
        "description": "flashlight drain time"
    },
    "secondary_maxammo":
    {
//        "type": "integer",
        "default": 10,
        "minimum": 0,
        "description": "Quantity of ammo carry for flashlight weapons"
    },
    "flashlight_ammount":
    {
        "type": "integer",
        "default": 100,
        "minimum": 10,
        "description": "Quantity of ammo carry for flashlight battery clip"
    }
}""" );

    // Retains one reusable flashlight spot entity for each player slot.
    array<EHandle> gpFlashlightSpots( g_Engine.maxClients );

    const string __AmmoName__ = "bts_battery";

    const string& GetAmmoName()
    {
        return __AmmoName__;
    }

    int __AmmoIndex__ = -1;

    const int GetAmmoIndex()
    {
        if( __AmmoIndex__ == -1 )
        {
            __AmmoIndex__ = g_PlayerFuncs.GetAmmoIndex( GetAmmoName() );
        }

        return __AmmoIndex__;
    }

    enum State
    {
        Inactive = 0,
        Active,
        Activate,
        Deactivate
    };

    // Get a valid spot entity (info_target) for the given player
    CBaseEntity@ Entity( CBasePlayer@ player )
    {
        if( player is null )
            return null;

        int index = player.entindex() - 1;
        EHandle flashlightHandle = gpFlashlightSpots[ index ];
        CBaseEntity@ flashlightEntity = null;

        if( !flashlightHandle.IsValid() || ( @flashlightEntity = flashlightHandle.GetEntity() ) is null )
        {
            @flashlightEntity = g_EntityFuncs.CreateEntity( "info_target", null, false );

            g_EntityFuncs.SetModel( flashlightEntity, "sprites/glow01.spr" );

            flashlightEntity.pev.movetype = MOVETYPE_NONE;
            flashlightEntity.pev.solid = SOLID_NOT;
            flashlightEntity.pev.scale = 2.5;
            flashlightEntity.pev.rendermode = kRenderGlow;
            flashlightEntity.pev.renderfx = kRenderFxNoDissipation;
            flashlightEntity.pev.effects |= EF_NODRAW;

            g_EntityFuncs.DispatchSpawn( flashlightEntity.edict() );

            flashlightHandle.opAssign( flashlightEntity );
            gpFlashlightSpots[ index ] = flashlightHandle;
        }

        return flashlightHandle.GetEntity();
    }

    void TurnOff( CBasePlayer@ player, CBasePlayerWeapon@ weapon )
    {
        // Cancel any reload
        if( weapon.m_fInReload )
        {
            g_SoundSystem.StopSound( player.edict(), CHAN_WEAPON, "bts_rc/items/battery_reload.wav" );

            dictionary@ data = player.GetUserData();
            weapon.m_fInReload = false;
            data.delete( "flashlight_reload" );
        }

        if( player.FlashlightIsOn() )
        {
            player.FlashlightTurnOff();
        }

        CBaseEntity@ spot = Flashlight::Entity( player );

        if( ( spot.pev.effects & EF_NODRAW ) == 0 )
        {
            spot.pev.effects |= EF_NODRAW;
            spot.pev.renderamt = 0;
        }

        weapon.pev.iuser1 = Flashlight::State::Inactive;
    }

    void TurnOn( CBasePlayer@ player, CBasePlayerWeapon@ weapon )
    {
        if( !player.FlashlightIsOn() )
        {
            player.FlashlightTurnOn();
        }

        CBaseEntity@ spot = Flashlight::Entity( player );

        if( ( spot.pev.effects & EF_NODRAW ) != 0 )
        {
            spot.pev.effects &= ~EF_NODRAW;
            spot.pev.renderamt = 0;
        }

        weapon.pev.iuser1 = Flashlight::State::Active;
    }

    int GetClip( CBasePlayer@ player, CBasePlayerWeapon@ weapon, ASWeaponLightConfig@ config )
    {
        dictionary@ data = player.GetUserData();
        const string classname = weapon.GetClassname();

        int Battery;
        if( !data.get( classname, Battery ) )
        {
            Battery = Math.RandomLong( 0, config.flashlight_ammount );
            data[ classname ] = Battery;
        }

        return Battery;
    }

    bool HasClip( CBasePlayer@ player, CBasePlayerWeapon@ weapon, ASWeaponLightConfig@ config )
    {
        return ( GetClip( player, weapon, config ) > 0 );
    }

    bool HasFullClip( CBasePlayer@ player, CBasePlayerWeapon@ weapon, ASWeaponLightConfig@ config )
    {
        return ( GetClip( player, weapon, config ) >= config.flashlight_ammount );
    }

    bool HasReserves( CBasePlayer@ player )
    {
        return ( player.m_rgAmmo( GetAmmoIndex() ) > 0 );
    }

    bool HasAnyReserve( CBasePlayer@ player, CBasePlayerWeapon@ weapon, ASWeaponLightConfig@ config )
    {
        return ( HasClip( player, weapon, config ) || HasReserves( player ) );
    }

    bool HasAnyReserve( CBasePlayer@ player, CBasePlayerWeapon@ weapon, ASWeaponConfig@ config )
    {
        return ( HasClip( player, weapon, cast<ASWeaponLightConfig@>( config ) ) || HasReserves( player ) );
    }

    /// Return whatever we have ammo or not.
    /// Will start reloading if needed.
    /// The reload will be completed after the given "time" if the player didn't swap weapon during that time.
    bool Reload( CBasePlayer@ player, CBasePlayerWeapon@ weapon, float time, ASWeaponLightConfig@ config )
    {
        if( HasClip( player, weapon, config ) )
            return true;

        if( !HasReserves( player ))
        {
            g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "hlclassic/weapons/357_cock1.wav", 0.8f, ATTN_NORM, 0, PITCH_NORM );
            weapon.SendWeaponAnim( config.animation_toggle, 0, weapon.pev.body );
            return false;
        }

        g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "bts_rc/items/battery_reload.wav", 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

        weapons::SetCooldown( weapon, player, time );
        weapon.m_fInReload = true;
        player.GetUserData()[ "flashlight_reload" ] = weapon.m_flNextPrimaryAttack;

        weapon.pev.body = g_ModelFuncs.SetBodygroup( config.view_model_index, weapon.pev.body, config.hands_group, 0 );
        player.pev.weaponmodel = config.player_model;
        weapon.SendWeaponAnim( config.animation_holster, 0, weapon.pev.body );

        return true;
    }
}

abstract class ASWeaponLightConfig : ASWeaponConfig
{
    float flashlight_drain;
    int flashlight_ammount;

    // player model used when flashlight is active
    const string& get_player_model_flashlight()
    {
        return this.player_model;
    }

    // Animation used for toggle flashlight
    const uint8 get_animation_toggle()
    {
        return 0;
    }

    // Animation used for reload flashlight
    const uint8 get_animation_reload()
    {
        return 0;
    }

    // flashlight ammo entity name
    const string& get_secondary_ammo() override
    {
        return Flashlight::GetAmmoName();
    }

    void FlashlightToggle( CBasePlayer@ player, CBasePlayerWeapon@ weapon )
    {
        // Method was called just after weapon deployed in ASWeaponConfig so skip the cooldown check & set.
        if( g_Engine.time > weapon.pev.fuser1 )
        {
            if( weapon.m_flNextSecondaryAttack > g_Engine.time )
                return;

            weapons::SetCooldown( weapon, player, this.GetCooldown( false, AttackType::Secondary ) );
        }

        int Battery = Flashlight::GetClip( player, weapon, this );
        
        if( Battery <= 0 )
        {
            if( !Flashlight::Reload( player, weapon, 0.5f, this ) )
                return;
        }
 
        switch( weapon.pev.iuser1 )
        {
            case Flashlight::State::Inactive:
            {
                weapon.pev.iuser1 = Flashlight::State::Activate;
                break;
            }
            case Flashlight::State::Active:
            {
                weapon.pev.iuser1 = Flashlight::State::Deactivate;
                break;
            }
        }
    }

    void WeaponSecondaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        this.FlashlightToggle( player, weapon );
    }

    void WeaponHolster( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        ASWeaponConfig::WeaponHolster( player, weapon, character );
        Flashlight::TurnOff( player, weapon );
    }

    void PlayerThink( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        ASWeaponConfig::PlayerThink( player, weapon, character );

        player.m_iHideHUD &= ~HideHUDFlags::HIDEHUD_FLASHLIGHT;

        dictionary@ data = player.GetUserData();

        int Battery = Flashlight::GetClip( player, weapon, this );

        float reloadTime;
        if( data.get( "flashlight_reload", reloadTime ) )
        {
            if( reloadTime > g_Engine.time )
            {
                weapon.pev.body = g_ModelFuncs.SetBodygroup( this.view_model_index, weapon.pev.body, this.hands_group, 0 );
                player.pev.weaponmodel = this.player_model;
                weapon.SendWeaponAnim( player.pev.weaponanim, 0, weapon.pev.body );
                player.m_iFlashBattery = 0;
                return;
            }

            g_SoundSystem.StopSound( player.edict(), CHAN_WEAPON, "bts_rc/items/battery_reload.wav" );

            int ammoCount = player.m_rgAmmo( Flashlight::GetAmmoIndex() );

            weapon.m_fInReload = false;
            data[ this.GetName() ] = Battery = flashlight_ammount;
            player.m_rgAmmo( Flashlight::GetAmmoIndex(), ammoCount - 1 );
            data.delete( "flashlight_reload" );
            weapon.SendWeaponAnim( this.animation_draw, 0, weapon.pev.body );
        }

        switch( weapon.pev.iuser1 )
        {
            case Flashlight::State::Activate:
            {
                if( weapon.m_fInReload )
                    break;

                // Weapon just deployed from ASWeaponConfig::WeaponFlashlight.
                if( g_Engine.time <= weapon.pev.fuser1 )
                    break;

                weapon.pev.body = g_ModelFuncs.SetBodygroup( this.view_model_index, weapon.pev.body, this.hands_group, 1 );
                player.pev.weaponmodel = this.player_model_flashlight;
                weapon.SendWeaponAnim( this.animation_toggle, 0, weapon.pev.body );
                Flashlight::TurnOn( player, weapon );
                weapons::SetCooldown( weapon, player, this.GetCooldown( false, AttackType::Secondary ) );
                break;
            }
            case Flashlight::State::Deactivate:
            {
                if( weapon.m_fInReload )
                    break;

                weapon.pev.body = g_ModelFuncs.SetBodygroup( this.view_model_index, weapon.pev.body, this.hands_group, 0 );
                player.pev.weaponmodel = this.player_model;
                weapon.SendWeaponAnim( this.animation_toggle, 0, weapon.pev.body );
                Flashlight::TurnOff( player, weapon );
                weapons::SetCooldown( weapon, player, this.GetCooldown( false, AttackType::Secondary ) );
                break;
            }
            case Flashlight::State::Active:
            {
                if( weapon.m_fInReload )
                {
                    Flashlight::TurnOff( player, weapon );
                    weapon.pev.iuser1 = Flashlight::State::Activate;
                    break;
                }

                if( player.FlashlightIsOn() )
                {
                    float nextDrain = float( data[ "flashlight_nextdrain" ] );

                    if( nextDrain <= g_Engine.time )
                    {
                        data[ "flashlight_nextdrain" ] = g_Engine.time + flashlight_drain;

                        Battery--;

                        if( Battery <= 0 )
                        {
                            Battery = 0;
                            weapon.pev.body = g_ModelFuncs.SetBodygroup( this.view_model_index, weapon.pev.body, this.hands_group, 0 );
                            player.pev.weaponmodel = this.player_model;
                            weapon.SendWeaponAnim( player.pev.weaponanim, 0, weapon.pev.body );
                            Flashlight::TurnOff( player, weapon );
                            break;
                        }
                    }

                    CBaseEntity@ spot = Flashlight::Entity( player );

                    // Gradual turn on
                    if( spot.pev.renderamt < 100 )
                        spot.pev.renderamt += 5;

                    Math.MakeVectors( player.pev.v_angle );
                    Vector vecSrc = player.GetGunPosition();
                    Vector vecEnd = vecSrc + ( g_Engine.v_forward * 8192 ); // -TODO Fade out if nothing hit?

                    TraceResult tr;
                    g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, player.edict(), tr );
                    g_EntityFuncs.SetOrigin( spot, tr.vecEndPos );
                }
                break;
            }
        }

        // Normalize to a percentaje 0-100 so flashlight_ammount can be anything else than 100.
        data[ this.GetName() ] = Battery;
        player.m_iFlashBattery = int( ( Battery * 100.0f ) / flashlight_ammount + 0.5f );
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
                "ASWeaponLightConfig"
            ],
            "properties":
            {
            }
        }""";
    }

    void Precache() override
    {
        g_Game.PrecacheModel( this.player_model_flashlight );
        g_Game.PrecacheModel( "sprites/glow01.spr" );

        g_SoundSystem.PrecacheSound( "bts_rc/items/battery_reload.wav" );

        ASWeaponConfig::Precache();
    }

    bool Register( meta_api::json::v2::json@ config ) override
    {
        this.flashlight_drain = config.ValueOrDefault( "flashlight_drain", this.flashlight_drain );
        this.flashlight_ammount = config.ValueOrDefault( "flashlight_ammount", this.flashlight_ammount );

#if SERVER
        this.flashlight_drain = 0.1f;
#endif

        return ASWeaponConfig::Register( config );
    }
}
