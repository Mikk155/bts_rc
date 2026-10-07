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

// ASWeaponConfig::WeaponHolster is too late!! Call DisableZoom yourself in your weapon.
abstract class ASWeaponScopeLightConfig : ASWeaponConfig
{
    // view model used when scope is active
    const string& get_zoom_view_model()
    {
        return this.view_model;
    }

    const string& get_zoom_animation_extension()
    {
        return this.animation_extension;
    }

    void ToggleZoom( CBasePlayer@ player, CBasePlayerWeapon@ weapon )
    {
        g_SoundSystem.EmitSoundDyn( weapon.edict(), SOUND_CHANNEL::CHAN_WEAPON, "weapons/sniper_zoom.wav", 1.0f, ATTN_NORM, 0, PITCH_NORM );

        if( player.m_iFOV == 0 )
        {
            player.m_iFOV = 18;
            player.m_szAnimExtension = this.zoom_animation_extension;
            player.pev.viewmodel = this.zoom_view_model;
            g_PlayerFuncs.ScreenFade( player, g_vecZero, this.secondary_cooldown, 0.1f, 255.0f, FFADE_OUT );
        }
        else
        {
            player.m_iFOV = 0;
            player.m_szAnimExtension = this.animation_extension;
            player.pev.viewmodel = this.view_model;
            g_PlayerFuncs.ScreenFade( player, g_vecZero, this.secondary_cooldown, 0.1f, 255.0f, FFADE_IN );
        }
    }

    void DisableZoom( CBasePlayer@ player, CBasePlayerWeapon@ weapon )
    {
        if( player.m_iFOV != 0 )
        {
            this.ToggleZoom( player, weapon );
        }
    }

    void WeaponSecondaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        this.ToggleZoom( player, weapon );
        weapons::SetCooldown( weapon, player, AttackType::Secondary, this );
    }

    void PlayerThink( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        ASWeaponConfig::PlayerThink( player, weapon, character );

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

        int[] color = { 255, 60, 60 };

        g_PlayerFuncs.ScreenFade( player, Vector( color[0], color[1], color[2] ), 0.5f, 0.0f, 255.0f, FFADE_MODULATE | FFADE_IN );

        {
            NetworkMessage m( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, edict );
                m.WriteByte( TE_DLIGHT );
                m.WriteCoord( tr.vecEndPos.x );
                m.WriteCoord( tr.vecEndPos.y );
                m.WriteCoord( tr.vecEndPos.z );
                m.WriteByte( 128 );   // radius
                m.WriteByte( color[0] );
                m.WriteByte( color[1] );
                m.WriteByte( color[2] );
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
                m.WriteByte( 64 );   // radius
                m.WriteByte( color[0] );
                m.WriteByte( color[1] );
                m.WriteByte( color[2] );
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
        return ASWeaponConfig::Register( config );
    }
}
