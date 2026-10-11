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

namespace weapons
{
    // Play effects
    void TraceEffects( CBasePlayerWeapon@ weapon, CBasePlayer@ player, ASWeaponConfig@ config, TraceResult &in tr )
    {
        CBaseEntity@ hit = null;
        CBaseMonster@ monster = null;

        if( !FreeEdicts( 5 )
        || !g_EntityFuncs.IsValidEntity( tr.pHit )
        || ( @hit = g_EntityFuncs.Instance( tr.pHit ) ) is null
        || !hit.IsMonster()
        || ( @monster = cast<CBaseMonster@>(hit) ) is null )
            return;

        dictionary@ data = hit.GetUserData();

        int damageTaken = int( data[ "damage_taken" ] );

        if( g_WeaponsConfig.blood_splash && monster.m_bloodColor != DONT_BLEED )
        {
            CSprite@ spr = null;

            if( monster.m_bloodColor == BLOOD_COLOR_RED )
            {
                switch( Math.RandomLong( 0, 2 ) )
                {
                    case 0: @spr = g_EntityFuncs.CreateSprite( "sprites/mikk155/particles/hblood_1.spr", tr.vecEndPos, true ); break;
                    case 1: @spr = g_EntityFuncs.CreateSprite( "sprites/mikk155/particles/hblood_2.spr", tr.vecEndPos, true ); break;
                    case 2: @spr = g_EntityFuncs.CreateSprite( "sprites/mikk155/particles/hblood_3.spr", tr.vecEndPos, true ); break;
                }
            }
            else if( monster.m_bloodColor == BLOOD_COLOR_GREEN || monster.m_bloodColor == BLOOD_COLOR_YELLOW )
            {
                switch( Math.RandomLong( 0, 4 ) )
                {
                    case 0: @spr = g_EntityFuncs.CreateSprite( "sprites/mikk155/particles/ablood_1.spr", tr.vecEndPos, true ); break;
                    case 1: @spr = g_EntityFuncs.CreateSprite( "sprites/mikk155/particles/ablood_2.spr", tr.vecEndPos, true ); break;
                    case 2: @spr = g_EntityFuncs.CreateSprite( "sprites/mikk155/particles/ablood_3.spr", tr.vecEndPos, true ); break;
                    case 3: @spr = g_EntityFuncs.CreateSprite( "sprites/mikk155/particles/ablood_4.spr", tr.vecEndPos, true ); break;
                    case 4: @spr = g_EntityFuncs.CreateSprite( "sprites/mikk155/particles/ablood_5.spr", tr.vecEndPos, true ); break;
                }
            }

            if( spr !is null )
            {
                spr.AnimateAndDie( 60.0f );
                spr.pev.scale = Math.RandomFloat( 0.05, 0.25 );
            }
        }

        auto ckv = hit.GetCustomKeyvalues();

        auto hasBloodColors = ckv.GetKeyvalue( "$i_bloodcolor" );

        if( hasBloodColors.Exists() )
        {
            NetworkMessage m( MSG_ALL, NetworkMessages::CreateBlood );
                m.WriteCoord(tr.vecEndPos.x );
                m.WriteCoord(tr.vecEndPos.y );
                m.WriteCoord(tr.vecEndPos.z );
                m.WriteByte( hasBloodColors.GetInteger() ); // Color pallete: https://github.com/baso88/SC_AngelScript/wiki/Temporary-Entities#palette-1
                m.WriteByte( Math.clamp( 0, 255, damageTaken ) ); // Count
            m.End();
        }

        if( g_WeaponsConfig.sparks_splash )
        {
            auto hasSparksColor = ckv.GetKeyvalue( "$i_spark_color" );

            if( hasSparksColor.Exists() )
            {
                int sparksColor = hasSparksColor.GetInteger();

                if( sparksColor < 0 || sparksColor > 11 )
                {
                    g_Logger.error.print("Entity {} with \"$i_spark_color\" out of range 0-11", { hit.GetClassname() } );
                    sparksColor = -1;
                }

                auto hasSparksBodyGroup = ckv.GetKeyvalue( "$i_spark_hitgroup" );

                if( hasSparksBodyGroup.Exists() && hasSparksBodyGroup.GetInteger() != tr.iHitgroup )
                {
                    sparksColor = -1;
                }

                if( sparksColor != -1 )
                {
                    switch( Math.RandomLong( 0, 4 ) )
                    {
                        case 0: g_SoundSystem.EmitSoundDyn( hit.edict(), CHAN_AUTO, "weapons/ric1.wav", 1.0, ATTN_NONE, 0, PITCH_NORM ); break;
                        case 1: g_SoundSystem.EmitSoundDyn( hit.edict(), CHAN_AUTO, "weapons/ric2.wav", 1.0, ATTN_NONE, 0, PITCH_NORM ); break;
                        case 2: g_SoundSystem.EmitSoundDyn( hit.edict(), CHAN_AUTO, "weapons/ric3.wav", 1.0, ATTN_NONE, 0, PITCH_NORM ); break;
                        case 3: g_SoundSystem.EmitSoundDyn( hit.edict(), CHAN_AUTO, "weapons/ric4.wav", 1.0, ATTN_NONE, 0, PITCH_NORM ); break;
                        case 4: g_SoundSystem.EmitSoundDyn( hit.edict(), CHAN_AUTO, "weapons/ric5.wav", 1.0, ATTN_NONE, 0, PITCH_NORM ); break;
                    }

                    {
                        NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, tr.vecEndPos );
                            m.WriteByte( TE_STREAK_SPLASH );
                            m.WriteCoord( tr.vecEndPos.x );
                            m.WriteCoord( tr.vecEndPos.y );
                            m.WriteCoord( tr.vecEndPos.z );
                            m.WriteCoord( 0 );
                            m.WriteCoord( 0 );
                            m.WriteCoord( g_Engine.v_forward.z );
                            m.WriteByte( sparksColor ); // Color pallete: https://github.com/baso88/SC_AngelScript/wiki/images/engine_palette_2.png
                            m.WriteShort( 30 );          // Count
                            m.WriteShort( 128 );         // Base speed
                            m.WriteShort( 100 );         // Random velocity
                        m.End();
                    }

                    {
                        NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, tr.vecEndPos );
                            m.WriteByte( TE_DLIGHT );
                            m.WriteCoord( tr.vecEndPos.x );
                            m.WriteCoord( tr.vecEndPos.y );
                            m.WriteCoord( tr.vecEndPos.z );
                            m.WriteByte( 5 );   // radius
                            m.WriteByte( 150 ); // R
                            m.WriteByte( 100 ); // G
                            m.WriteByte( 0 );   // B
                            m.WriteByte( 1 );   // life in 0.1's
                            m.WriteByte( 1 );   // decay in 0.1's
                        m.End();
                    }

                    g_Utility.Sparks( tr.vecEndPos );
                    g_Utility.Ricochet( tr.vecEndPos, Math.RandomFloat( 0.5, 1.5 ) );
                }
            }
        }
    }
}

void __TraceEffects_Blood__( float x, float y, float z, int color, int range, int repeats )
{
    if( --repeats < 0 )
        return;

    NetworkMessage m( MSG_ALL, NetworkMessages::CreateBlood );
        m.WriteCoord( x );
        m.WriteCoord( y );
        m.WriteCoord( z );
        m.WriteByte( color ); // Color pallete: https://github.com/baso88/SC_AngelScript/wiki/Temporary-Entities#palette-1
        m.WriteByte( range ); // Count
    m.End();

    g_Scheduler.SetTimeout( "__TraceEffects_Blood__", 0.5f, x, y, z, color, range, repeats );
}

ASCommand __TraceEffects_Blood_cmd__(
    "blood",
    "<0/255 color ranges> <0/255 particle amount (optional)>",
    "Spawn blood particles",
    function( CBasePlayer@ player, array<string>@ arguments )
    {
        if( arguments is null )
            arguments = { 20, 20 };

        while( arguments.length() < 2 )
            arguments.insertLast( 20 );

        TraceResult tr;
        Math.MakeVectors( player.pev.v_angle );
        g_Utility.TraceLine( player.GetGunPosition(), player.GetGunPosition() + ( g_Engine.v_forward * 128 ), dont_ignore_monsters, player.edict(), tr );

        int range = Math.clamp( 0, 255, atoi( arguments[1] ) );
        int color = Math.clamp( 0, 255, atoi( arguments[0] ) );

        g_PlayerFuncs.ClientPrint( player, HUD::HUD_PRINTCONSOLE, "Playing blood color " + color + " with amount " + range + '\n' );

        __TraceEffects_Blood__( tr.vecEndPos.x, tr.vecEndPos.y, tr.vecEndPos.z, color, range, 10 );
    }, true, "fx"
);
