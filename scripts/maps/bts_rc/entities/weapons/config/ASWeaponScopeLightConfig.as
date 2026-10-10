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

bool ASWeaponScopeLightConfigSchema = g_MapConfig.RegisterSchemaDefinition( "ASWeaponScopeLightConfig",
"""{
    "scope_fov":
    {
        "description": "FOV when using scope",
        "type": "integer",
        "minimum": 10,
        "maximum": 70
    },
    "scope_color":
    {
        "description": "Night vision color when using scope",
        "type": "array",
        "items": { "type": "integer", "minimum": 0, "maximum": 255 },
        "minItems": 3,
        "maxItems": 3
    }
}""" );

// ASWeaponConfig::WeaponHolster is too late!! Call DisableZoom yourself in your weapon.
abstract class ASWeaponScopeLightConfig : ASWeaponConfig
{
    private int m_FOV;
    private int[] m_Color;

    // view model used when scope is active
    const string& get_zoom_view_model()
    {
        return this.view_model;
    }

    const string& get_zoom_animation_extension()
    {
        return this.animation_extension;
    }

    const uint8 get_animation_zoom()
    {
        return this.animation_draw;
    }

    void ToggleZoom( CBasePlayer@ player, CBasePlayerWeapon@ weapon )
    {
        g_SoundSystem.EmitSoundDyn( weapon.edict(), SOUND_CHANNEL::CHAN_WEAPON, "weapons/sniper_zoom.wav", 1.0f, ATTN_NORM, 0, PITCH_NORM );

        if( player.m_iFOV == 0 )
        {
            weapon.pev.fuser1 = g_Engine.time + this.secondary_cooldown;
            weapon.SendWeaponAnim( this.animation_zoom + ( weapon.m_iClip == 0 ? 1 : 0 ), 0, weapon.pev.body );
            g_PlayerFuncs.ScreenFade( player, g_vecZero, this.secondary_cooldown, 0.5f, 255.0f, FFADE_OUT );
        }
        else
        {
            player.m_iFOV = 0;
            player.m_szAnimExtension = this.animation_extension;
            player.pev.viewmodel = this.view_model;
            weapon.SendWeaponAnim( this.animation_zoom + ( weapon.m_iClip == 0 ? 3 : 2 ), 0, weapon.pev.body );
            g_PlayerFuncs.ScreenFade( player, g_vecZero, 0.5f, 0.3f, 255.0f, FFADE_IN );
        }
    }

    // Disable zoom. returns whatever it was active
    bool DisableZoom( CBasePlayer@ player, CBasePlayerWeapon@ weapon )
    {
        if( player.m_iFOV != 0 )
        {
            this.ToggleZoom( player, weapon );
            return true;
        }
        return false;
    }

    void WeaponSecondaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        this.ToggleZoom( player, weapon );
        weapons::SetCooldown( weapon, player, this.GetCooldown( util::IsTrainedPersonal( player ), AttackType::Secondary ) + 0.3f );
    }

    void PlayerThink( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        ASWeaponConfig::PlayerThink( player, weapon, character );

        if( weapon.pev.fuser1 > 0 )
        {
            if( weapon.pev.fuser1 <= g_Engine.time )
            {
                player.m_iFOV = this.m_FOV;
                player.m_szAnimExtension = this.zoom_animation_extension;
                player.pev.viewmodel = this.zoom_view_model;
                weapon.pev.fuser1 = 0;
            }
            return;
        }

        if( player.m_iFOV == 0 )
            return;

        Vector vecSrc = player.GetGunPosition();

        Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );

        TraceResult tr;

        edict_t@ edict = player.edict();

        Vector vecEnd = vecSrc + g_Engine.v_forward * 2048;
        g_Utility.TraceLine(
            vecSrc,
            vecEnd,
            IGNORE_MONSTERS::dont_ignore_monsters,
            IGNORE_GLASS::ignore_glass,
            edict,
            tr
        );

        g_PlayerFuncs.ScreenFade( player, Vector( this.m_Color[0], this.m_Color[1], this.m_Color[2] ), 0.5f, 0.0f, 255.0f, FFADE_MODULATE | FFADE_IN );

        {
            NetworkMessage m( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, edict );
                m.WriteByte( TE_DLIGHT );
                m.WriteCoord( tr.vecEndPos.x );
                m.WriteCoord( tr.vecEndPos.y );
                m.WriteCoord( tr.vecEndPos.z );
                m.WriteByte( 128 );   // radius
                m.WriteByte( 255 );
                m.WriteByte( 255 );
                m.WriteByte( 255 );
                m.WriteByte( 2 );
                m.WriteByte( 1 );
            m.End();
        }

        {
            NetworkMessage m( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, edict );
                m.WriteByte( TE_DLIGHT );
                m.WriteCoord( player.pev.origin.x );
                m.WriteCoord( player.pev.origin.y );
                m.WriteCoord( player.pev.origin.z );
                m.WriteByte( 16 );   // radius
                m.WriteByte( 255 );
                m.WriteByte( 255 );
                m.WriteByte( 255 );
                m.WriteByte( 2 );
                m.WriteByte( 1 );
            m.End();
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
                "ASWeaponScopeLightConfig"
            ],
            "properties":
            {
            }
        }""";
    }

    void Precache() override
    {
        g_Game.PrecacheModel( this.zoom_view_model );
        g_SoundSystem.PrecacheSound( "weapons/sniper_zoom.wav" );
        ASWeaponConfig::Precache();
    }

    bool Register( btson@ config ) override
    {
        config.Get( "scope_fov", this.m_FOV, false );

        btson@ nightvision = config.ValueOrDefault( "scope_color" );
        m_Color = { int( nightvision[0] ), int( nightvision[1] ), int( nightvision[2] ) };

        return ASWeaponConfig::Register( config );
    }
}
