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

namespace Hooks
{
    HUDTextParams g_DisplayDataParams;

    void DisplayDataInit()
    {
        g_EngineFuncs.CVarSetFloat( "mp_allowplayerinfo", 0 );
        g_EngineFuncs.CVarSetFloat( "mp_allowmonsterinfo", 0 );

        g_DisplayDataParams.fxTime = g_DisplayDataParams.fadeinTime = g_DisplayDataParams.fadeoutTime = 0.0f;
        g_DisplayDataParams.holdTime = 0.5f;
        g_DisplayDataParams.x = 0.0f;
        g_DisplayDataParams.y = -1;
    }

    HookReturnCode PlayerThink( CBasePlayer@ player )
    {
        if( player is null || !player.IsConnected() )
            return HOOK_CONTINUE;

        dictionary@ data = player.GetUserData();

        auto character = GetCharacter(player);

        auto aiment = g_Utility.FindEntityForward( player );

        if( aiment !is null )
        {
            CBaseMonster@ monster;

            if( aiment.IsMonster() && ( @monster = cast<CBaseMonster@>( aiment ) ) !is null )
            {
                bool isPlayer = monster.IsPlayer();
                bool canSeeMonster = ( ( character !is null && character.IsHEV ) || monster.IRelationship( player ) == R_AL );

                string displayData;

                if( isPlayer )
                {
                    auto targetCharacter = GetCharacter(monster);

                    if( targetCharacter !is null )
                    {
                        displayData.opAddAssign( "[" );
                        displayData.opAddAssign( Classification::ToString( targetCharacter.Classify ) );
                        displayData.opAddAssign( "] " );
                    }

                    displayData.opAddAssign( monster.pev.netname );
                }
                else if( canSeeMonster )
                {
                    string monsterName = monster.m_FormattedName;

                    if( monsterName.IsEmpty() )
                    {
                        monsterName = monster.GetClassname();
                        monsterName = monsterName.Replace( "monster_", '' );
                        monsterName = monsterName.Replace( '_', ' ' );
                        monsterName = string( monsterName[0] ).ToUppercase() + monsterName.SubString( 1 );
                    }

                    displayData.opAddAssign( monsterName );
                }

                if( isPlayer || canSeeMonster )
                {
                    displayData.opAddAssign( '\nHealth: ' );

                    displayData.opAddAssign( Math.max( 0, int(monster.pev.health) ) );
                    displayData.opAddAssign( '/' );
                    displayData.opAddAssign( int(monster.pev.max_health) );

                    if( isPlayer )
                    {
                        displayData.opAddAssign( '\nArmor: ' );
                        displayData.opAddAssign( int(monster.pev.armorvalue) );
                        displayData.opAddAssign( '/' );
                        displayData.opAddAssign( int(monster.pev.armortype) );

                        g_DisplayDataParams.r1 = g_DisplayDataParams.b1 = 0;
                        g_DisplayDataParams.g1 = 255;
                    }
                    else if( monster.IRelationship( player ) == R_AL )
                    {
                        g_DisplayDataParams.r1 = 0;
                        g_DisplayDataParams.g1 = g_DisplayDataParams.b1 = 255;
                    }
                    else
                    {
                        g_DisplayDataParams.g1 = g_DisplayDataParams.b1 = 0;
                        g_DisplayDataParams.r1 = 255;
                    }
                    g_PlayerFuncs.HudMessage( player, g_DisplayDataParams, displayData );
                }
            }
        }

#if SERVER
        if( !g_IsMainMap )
        {
            TraceResult tr;
            Math.MakeVectors( player.pev.v_angle );
            g_Utility.TraceLine( player.EyePosition(), player.EyePosition() + player.GetAutoaimVector( 1.0 ) * 500.0f, dont_ignore_monsters, player.edict(), tr );

            if( g_EntityFuncs.IsValidEntity( tr.pHit ) )
            {
                CBaseEntity@ hit = g_EntityFuncs.Instance( tr.pHit );

                if( hit !is null )
                {
                    auto ckv = hit.GetCustomKeyvalues();

                    if( ckv.HasKeyvalue( "$s_message" ) )
                    {
                        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCENTER, ckv.GetKeyvalue( "$s_message" ).GetString() + "\n" );
                    }
                }
            }
        }
#endif

        // Some high ping clients are lagged asf and freezed. let's wait until they press a key
        if( !data.exists( "connected" ) && player.pev.button != 0 )
        {
            data[ "connected" ] = true;
            PlayerInitialized( player, data );
        }

        if( character is null )
        {
            auto observer = player.GetObserver();

            if( !observer.IsObserver() )
            {
                observer.StartObserver( player.pev.origin, player.pev.angles, false );
            }

            // Let late joined players join a role
            if( float( data[ "pm_selectcd" ] ) <= g_Engine.time )
            {
                data[ "pm_selectcd" ] = g_Engine.time + 1.0f;
                g_ClassSelectionMenu.Open( player );
            }
            return HOOK_CONTINUE;
        }

        if( !player.IsAlive() )
            return HOOK_CONTINUE;

        player.m_iHideHUD |= HIDEHUD_FLASHLIGHT;

        // Change impulse 101 command with our own weapons
        if( player.pev.impulse == 101 && ( !g_IsMainMap || g_PlayerFuncs.AdminLevel( player ) >= ADMIN_YES ) )
        {
            const array<string>@ weaponNames = g_WeaponsConfig.WeaponNames();
            uint length = weaponNames.length();

            for( uint ui = 0; ui < length; ui++ )
            {
                const string weapon_name = weaponNames[ui];

                player.GiveNamedItem( weapon_name );

                CBasePlayerItem@ item = player.HasNamedPlayerItem( weapon_name );

                if( item !is null )
                {
                    CBasePlayerWeapon@ weapon = cast<CBasePlayerWeapon@>( item );

                    if( weapon !is null )
                    {
                        if( weapon.m_iPrimaryAmmoType > 0 )
                            player.m_rgAmmo( weapon.m_iPrimaryAmmoType, weapon.iMaxAmmo1() );

                        weapon.m_iClip = weapon.iMaxClip();

                        if( weapon.m_iSecondaryAmmoType > 0 )
                            player.m_rgAmmo( weapon.m_iSecondaryAmmoType, weapon.iMaxAmmo2() );
                    }
                }
            }
            player.pev.impulse = 0;
        }

        // Don't allow flashlight while busy
        if( player.pev.impulse == 100 )
        {
            if( player.m_flNextAttack <= 0 )
                player.m_flNextAttack = 0.5f;
            else
                player.pev.impulse = 0;
        }

        if( g_WeaponsConfig.item_tracking )
            item_tracker::Think( player );

        MedkitAmmo::Think( player );

        player.SetOverriddenPlayerModel(character.Name);

        if( player.m_hActiveItem.IsValid() )
        {
            auto weapon = cast<CBasePlayerWeapon@>( player.m_hActiveItem.GetEntity() );

            CBasePlayerWeapon@ lastWeapon = cast<CBasePlayerWeapon@>( data[ "current_weapon" ] );

            if( lastWeapon !is null && weapon !is lastWeapon )
            {
                ASWeaponConfig@ lastWeaponConfig = cast<ASWeaponConfig@>( g_WeaponsConfig.Interfaces[ lastWeapon.GetClassname() ] );

                if( lastWeaponConfig !is null )
                {
                    lastWeaponConfig.WeaponHolster( player, lastWeapon, character );
                }
            }

            const string classname = ( weapon is null ? String::EMPTY_STRING : weapon.GetClassname() );

            @data[ "current_weapon" ] = weapon;

            if( weapon !is null )
            {
                ASWeaponConfig@ weaponConfig = cast<ASWeaponConfig@>( g_WeaponsConfig.Interfaces[ classname ] );

                // We assume weaponConfig is not null.
                // If it is null then is a third party weapon.
                // the map is not designed to have other weapons than ours.
                // I don't have time to redesign this nor i care.
                if( weaponConfig is null )
                {
                    player.RemovePlayerItem( weapon );
                }
                else
                {
                    // Call deploy for vanilla weapons to update their models
                    if( player.pev.viewmodel != weaponConfig.view_model )
                    {
                        weaponConfig.WeaponDeploy( player, weapon, character );
                    }

                    // Can we attack?
                    if( player.m_flNextAttack <= 0 )
                    {
                        if( ( player.pev.button & IN_ATTACK ) != 0 )
                        {
                            if( weapon.m_flNextPrimaryAttack < g_Engine.time )
                                weaponConfig.WeaponPrimaryAttack( player, weapon, character );
                        }

                        if( ( player.pev.button & IN_ATTACK2 ) != 0 )
                        {
                            if( weapon.m_flNextSecondaryAttack < g_Engine.time )
                                weaponConfig.WeaponSecondaryAttack( player, weapon, character );
                        }

                        if( ( player.pev.button & IN_ALT1 ) != 0 )
                        {
                            if( weapon.m_flNextTertiaryAttack < g_Engine.time )
                                weaponConfig.WeaponTertiaryAttack( player, weapon, character );
                        }
                    }

                    weaponConfig.PlayerThink( player, weapon, character );

                    if( player.pev.impulse == 100 )
                    {
                        if( Flashlight::IsValidWeapon( player, weapon, weaponConfig ) )
                        {
                            player.pev.impulse = 0;

                            ASWeaponLightConfig@ weaponFlashlightConfig = cast<ASWeaponLightConfig@>( weaponConfig );

                            if( weaponFlashlightConfig !is null )
                            {
                                weaponFlashlightConfig.FlashlightToggle( player, weapon );
                            }
                        }
                        else if( character.IsHEV && player.pev.armorvalue > 0 )
                        {
                            // Dummy. night vision code all bellow.
                        }
                        else
                        {
                            player.pev.impulse = 0;

                            CBasePlayerWeapon@ flashlightWeapon = null;

                            for( uint ui = 0; ui < MAX_ITEM_TYPES; ui++ )
                            {
                                CBasePlayerItem@ item = player.m_rgpPlayerItems(ui);

                                while( item !is null )
                                {
                                    @flashlightWeapon = cast<CBasePlayerWeapon@>(item);
                                    ASWeaponLightConfig@ weaponFlashlightConfig = null;

                                    if( flashlightWeapon !is null )
                                        @weaponFlashlightConfig = cast<ASWeaponLightConfig@>( g_WeaponsConfig.Interfaces[ flashlightWeapon.GetClassname() ] );

                                    if( weaponFlashlightConfig !is null && Flashlight::IsValidWeapon( player, flashlightWeapon, weaponFlashlightConfig ) )
                                    {
                                        weaponFlashlightConfig.FlashlightToggle( player, flashlightWeapon, true );

                                        ui = MAX_ITEM_TYPES; // Break for loop
                                        break;
                                    }

                                    @flashlightWeapon = null;
                                    @item = cast<CBasePlayerWeapon@>( item.m_hNextItem.GetEntity() );
                                }
                            }

                            if( flashlightWeapon is null )
                            {
                                if( player.HasNamedPlayerItem( "weapon_bts_flaregun" ) !is null )
                                {
                                    player.SelectItem( "weapon_bts_flaregun" );
                                }
                                else if( player.HasNamedPlayerItem( "weapon_bts_flare" ) !is null )
                                {
                                    player.SelectItem( "weapon_bts_flare" );
                                }
                                else
                                {
                                    g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "bts_rc/items/flashlight1.wav", 0.8f, ATTN_NORM, 0, PITCH_NORM );
                                }
                            }
                        }
                    }
                }
            }
        }

        if( character.IsHEV )
        {
            int state = int( data["helmet_nv_state"] );

            // Not enough power, Shut down
            if( player.pev.armorvalue <= 0 )
            {
                if( state == 1 )
                {
                    g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "bts_rc/items/nvg_off.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
                    g_PlayerFuncs.ScreenFade( player, Vector( 250, 200, 20 ), 1.0f, 0.5f, 255.0f, 2 );
                }
                else if( player.pev.impulse == 100 )
                {
                    g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "items/suitchargeno1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
                }

                data["helmet_nv_state"] = state = 0;
            }
            // Catch impulse command and toggle night vision state
            else if( player.pev.impulse == 100 )
            {
                data["helmet_nv_state"] = ( state == 1 ? 0 : 1 );

                if( state == 1 )
                    data["helmet_nv_startup"] = 0;

                g_PlayerFuncs.ScreenFade( player, Vector( 250, 200, 20 ), 1.0f, 0.5f, 255.0f, state == 0 ? 6 : 2 );
                g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, ( state == 1 ? "bts_rc/items/nvg_off.wav" : "bts_rc/items/nvg_on.wav" ), 1.0, ATTN_NORM, 0, PITCH_NORM );
            }

            // Night vision ON, drain and light.
            if( state == 1 )
            {
                // Show even when dead lying.
                if( !player.GetObserver().IsObserver() )
                {
                    if( float( data["helmet_nv_drain"] ) <= g_Engine.time )
                    {
                        player.pev.armorvalue--;
                        data["helmet_nv_drain"] = 12 + g_Engine.time;
                    }

                    int nv_radius = int( data["helmet_nv_startup"] );

                    if( nv_radius <= 40 )
                    {
                        nv_radius++;
                        data["helmet_nv_startup"] = nv_radius;
                    }

                    NetworkMessage m( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, player.edict() );
                        m.WriteByte( TE_DLIGHT );
                        m.WriteCoord( player.pev.origin.x );
                        m.WriteCoord( player.pev.origin.y );
                        m.WriteCoord( player.pev.origin.z );
                        m.WriteByte( nv_radius );
                        m.WriteByte( 255 );
                        m.WriteByte( 255 );
                        m.WriteByte( 255 );
                        m.WriteByte( 2 );
                        m.WriteByte( 1 );
                    m.End();
                }
                else
                {
                    g_PlayerFuncs.ScreenFade( player, g_vecZero, 0.0f, 0.0f, 0.0f, ( FFADE_OUT | FFADE_STAYOUT ) );
                    data["helmet_nv_state"] = 0;
                }
            }
        }

        if( player.pev.impulse == 100 )
            player.pev.impulse = 0;

        return HOOK_CONTINUE;
    }
}
