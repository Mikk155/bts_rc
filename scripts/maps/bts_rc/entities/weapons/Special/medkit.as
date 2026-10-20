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
*   Author: mikk
*/

enum WeaponMedkitAnim
{
    Idle = 0,
    LongIdle,
    LongUse,
    ShortUse,
    Holster,
    Draw,
    Heal,
    IDK
};

final class ASWeaponMedkitConfig : ASWeaponConfig
{
    const string& GetName() const override {
        return "weapon_medkit";
    }

    const string& get_view_model() override {
        return "models/bts_rc/weapons/v_medkit.mdl";
    }

    const string& get_player_model() override {
        return "models/hlclassic/p_medkit.mdl";
    }

    const uint8 get_animation_draw() override {
        return WeaponMedkitAnim::Draw;
    }

    const string& get_animation_extension() override {
        return "trip";
    }

    const bool IsCustomWeapon() override
    {
        return false;
    }

    void WeaponDeploy( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        weapons::Deploy( weapon, player, gpWeaponMedkitConfig );
    }

    void WeaponPrimaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        weapon.PrimaryAttack();

        if( player.pev.weaponanim == WeaponMedkitAnim::Idle )
            g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_ITEM, "items/medshotno1.wav", 1.0f, ATTN_NORM );

        weapons::SetCooldown( weapon, player, this.GetCooldown( false, AttackType::Primary ) );
    }

    void WeaponSecondaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        weapon.SecondaryAttack();
        weapons::SetCooldown( weapon, player, this.GetCooldown( false, AttackType::Secondary ) );
    }

    void WeaponTertiaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        weapons::SetCooldown( weapon, player, this.GetCooldown( false, AttackType::Tertiary ) );

        int iAmmoLeft = player.m_rgAmmo( weapon.m_iPrimaryAmmoType );

        float flMissingHP = player.pev.max_health - player.pev.health;

        if( iAmmoLeft <= 0 || flMissingHP <= 0 )
        {
            g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_ITEM, "items/medshotno1.wav", 1.0f, ATTN_NORM );
            return;
        }

        // Clamp desired heal to missing HP
        float flDesiredHealHP = Math.min( this.health_gain, flMissingHP );

        // Convert HP → ammo (3 ammo per 1 HP)
        float flAmmoNeeded = ( flDesiredHealHP / this.health_gain ) * float( health_cost );

        // Clamp by available ammo
        float flAmmoUsed = Math.min( flAmmoNeeded, float( iAmmoLeft ) );

        // Convert back ammo → actual heal
        float flHealAmount = ( flAmmoUsed / float( health_cost ) ) * this.health_gain;

        // Apply same diminishing behavior as normal heal
        if( iAmmoLeft <= health_ammount * 0.75f )
            flHealAmount = Math.min( health_ammount * 0.2f, flHealAmount );
        else if( iAmmoLeft < health_ammount * 1.5f )
            flHealAmount = Math.min( health_ammount * 0.2f, flHealAmount );
        else if( iAmmoLeft < health_ammount * 6 )
            flHealAmount = Math.min( health_ammount * 0.5f, flHealAmount );

        flHealAmount = int( Math.Ceil( flHealAmount ) );
        flAmmoUsed = int( Math.Ceil( ( flHealAmount / this.health_gain ) * health_cost ) );

        if( flHealAmount <= 0 || flAmmoUsed <= 0 )
            return;

        // Execute heal
        player.SetAnimation( PLAYER_ATTACK1 );
        weapon.SendWeaponAnim( WeaponMedkitAnim::Heal, 0, this.WeaponBody( player, weapon, character ) );

        player.TakeHealth( flHealAmount, DMG_MEDKITHEAL );
        player.m_rgAmmo( weapon.m_iPrimaryAmmoType, iAmmoLeft - int( flAmmoUsed ) );

        int pitch = Math.RandomLong( 50, 60 );

        if( iAmmoLeft < health_ammount * 13 )
            pitch += int( float( iAmmoLeft ) / 1.25f );

        g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "items/medshot4.wav", 1.0f, ATTN_NORM, 0, pitch );
    }

    float health_ammount;
    float health_gain;
    float health_cost;

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapon configuration",
            "description": "Control medkit configuration",
            "allOf":
            [
                "ASWeaponConfig"
            ],
            "properties":
            {
                "health_ammount":
                {
                    "type": "integer",
                    "description": "Ammount of health to heal"
                },
                "health_gain":
                {
                    "type": "integer"
                },
                "health_cost":
                {
                    "type": "integer"
                }
            }
        }""";
    }

    bool Register( meta_api::json::v2::json@ config ) override
    {
        this.health_ammount = config.ValueOrDefault( "health_ammount", 10, false, false );
        this.health_gain = config.ValueOrDefault( "health_gain", 10, false, false );
        this.health_cost = config.ValueOrDefault( "health_cost", 30, false, false );

        return ASWeaponConfig::Register( config );
    }
}

ASWeaponMedkitConfig gpWeaponMedkitConfig;

namespace MedkitAmmo
{
    CBaseEntity@ GetHealthStation( CBasePlayer@ player )
    {
        if( ( player.pev.button & IN_USE ) == 0 )
            return null;

        Math.MakeVectors( player.pev.v_angle );
        TraceResult trace;
        g_Utility.TraceLine( player.GetGunPosition(), player.GetGunPosition() + g_Engine.v_forward * 64.0f,
            dont_ignore_monsters, player.edict(), trace );

        if( trace.pHit is null )
            return null;

        CBaseEntity@ entity = g_EntityFuncs.Instance( trace.pHit );
        if( entity is null || entity.GetClassname() != "func_healthcharger" || entity.pev.frame == 1 )
            return null;

        return entity;
    }

    void Think( CBasePlayer@ player )
    {
        CBasePlayerWeapon@ medkit = cast<CBasePlayerWeapon@>( player.HasNamedPlayerItem( "weapon_medkit" ) );
        if( medkit is null || medkit.m_iPrimaryAmmoType < 0 )
            return;

        dictionary@ data = player.GetUserData();
        int currentAmmo = player.m_rgAmmo( medkit.m_iPrimaryAmmoType );
        int previousAmmo;

        if( !data.get( "medkit_previous_ammo", previousAmmo ) )
        {
            data[ "medkit_previous_ammo" ] = currentAmmo;
            return;
        }

        // The stock medkit passively grants one point at a time. Roll that back;
        // larger gains still work for explicit ammo pickups and scripted grants.
        if( currentAmmo == previousAmmo + 1 )
        {
            player.m_rgAmmo( medkit.m_iPrimaryAmmoType, previousAmmo );
            currentAmmo = previousAmmo;
        }

        CBaseEntity@ station = GetHealthStation( player );
        int maxAmmo = gpWeaponMedkitConfig.primary_maxammo;

        // Consume a real health-station charge and convert the health point into
        // medkit ammo once the player is already at full health.
        if( station !is null && currentAmmo < maxAmmo && player.pev.health >= player.pev.max_health )
        {
            float previousHealth = player.pev.health;
            player.pev.health = player.pev.max_health - 0.45f;
            int healthFloor = int( Math.Floor( player.pev.health ) );

            station.Use( player, player, USE_ON );
            int supplied = int( player.pev.health - healthFloor );
            player.pev.health = previousHealth;

            if( supplied > 0 )
            {
                currentAmmo = Math.min( currentAmmo + supplied, maxAmmo );
                player.m_rgAmmo( medkit.m_iPrimaryAmmoType, currentAmmo );
            }

            // Prevent the engine from invoking the same charger a second time.
            player.pev.button &= ~IN_USE;
            player.m_afButtonPressed &= ~IN_USE;
        }

        data[ "medkit_previous_ammo" ] = currentAmmo;
    }
}
