namespace Hooks
{
void ClientInitialized( CBasePlayer@ player )
{
    // Some high ping clients are lagged asf and freezed. let's wait until they press a key
    if( player is null || player.pev.button == 0 )
        return;

    dictionary@ data = player.GetUserData();

    data[ "connected" ] = true;

#if METAMOD_DEBUG
    if( true ) // Annoying sprite when testing stuff x[
        return;
#endif

    if( g_Game.GetGameVersion() == 526 )
    {
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTTALK, "NOTICE: If you have played older versions of this map previously\n" );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTTALK, "\t\tPlease consider updating manually to the latest version as many assets has been modified\n" );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTTALK, "\t\tAnd your gameplay most likely will be affected. Open the console to get the download link.\n" );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "http://scmapdb.wikidot.com/map:blackmesa-training-simulation:resonance-cascade\n" );
    }

    // Nero ADDED 2026-01-10
    HUDSpriteParams hudParamsTitle;
    hudParamsTitle.fadeinTime = 1.0;
    hudParamsTitle.holdTime = 4.0;
    hudParamsTitle.fadeoutTime = 1.5;
    hudParamsTitle.effect = 0;
    hudParamsTitle.channel = 2; // 0-15 (1 is used by snapbug)
    hudParamsTitle.spritename = "bts_rc/gametitle.spr";
    hudParamsTitle.x = 0.0;
    hudParamsTitle.y = 0.0;
    hudParamsTitle.flags = HUD_ELEM_SCR_CENTER_X | HUD_ELEM_SCR_CENTER_Y;
    hudParamsTitle.color1 = RGBA( 180, 180, 180, 255 );
    g_PlayerFuncs.HudCustomSprite( player, hudParamsTitle );
}
}
