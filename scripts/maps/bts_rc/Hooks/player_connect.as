/*
    Author: Mikk
*/

namespace notice_assets
{
    void delayed_notice( EHandle hplayer )
    {
        if( !hplayer.IsValid() )
            return;

        CBaseEntity@ entity = hplayer.GetEntity();

        if( entity is null )
            return;

        CBasePlayer@ player = cast<CBasePlayer@>( entity );

        if( player is null )
            return;

        g_PlayerFuncs.ClientPrint( player, HUD_PRINTTALK, "NOTICE: If you have played older versions of this map previously\n" );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTTALK, "\t\tPlease consider updating manually to the latest version as many assets has been modified\n" );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTTALK, "\t\tAnd your gameplay most likely will be affected. Open the console to get the download link.\n" );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "http://scmapdb.wikidot.com/map:blackmesa-training-simulation:resonance-cascade\n" );
    }

    // Nero ADDED 2026-01-10
    void DisplayGametitle( EHandle hPlayer )
    {
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer is null or !pPlayer.IsConnected() )
            return;

        const int HUD_SPRITE_TITLE = 2; // 0-15 (1 is used by snapbug)
        const int iRed = 180;
        const int iGreen = 180;
        const int iBlue = 180;
        const int iBrightness = 255;

        HUDSpriteParams hudParamsTitle;
        hudParamsTitle.fadeinTime = 1.0;
        hudParamsTitle.holdTime = 4.0;
        hudParamsTitle.fadeoutTime = 1.5;
        hudParamsTitle.effect = 0;
        hudParamsTitle.channel = HUD_SPRITE_TITLE;
        hudParamsTitle.spritename = "bts_rc/gametitle.spr";
        hudParamsTitle.x = 0.0;
        hudParamsTitle.y = 0.0;
        hudParamsTitle.flags = HUD_ELEM_SCR_CENTER_X | HUD_ELEM_SCR_CENTER_Y;
        hudParamsTitle.color1 = RGBA( iRed, iGreen, iBlue, iBrightness );
        g_PlayerFuncs.HudCustomSprite( pPlayer, hudParamsTitle );
    }

    HookReturnCode player_connect( CBasePlayer@ player )
    {
        if( player !is null )
        {
            g_Scheduler.SetTimeout( "delayed_notice", 6.0f, EHandle( player ) );
            // Nero ADDED 2026-01-10
            g_Scheduler.SetTimeout( "DisplayGametitle", 2.0, EHandle( player ) );
        }
        return HOOK_CONTINUE;
    }
}
