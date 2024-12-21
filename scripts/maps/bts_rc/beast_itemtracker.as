/* bts_rc Item Tracker - System to check who is carrying what item via an in-game menu
Author: Outerbeast
*/
#include "game_menu"

EHandle hItemTrackerMenu;

EHandle SetupMenu()
{
    dictionary 
        dictMenu =
        {
            { "message", "Who has what?" },
            { "1:Area 1 - Retina component", "RETINA_COMPONENT" },
            { "2:Area 1 - Override Valve 1", "VALVE_1" },
            { "3:Area 1 - Override Valve 2", "VALVE_1"},
            { "4:Area 3 - Gear 1", "GEAR_1" },
            { "5:Area 3 - Gear 2", "GEAR_2" },
            { "6:Area 3 - Gear 3", "GEAR_3" },
            { "7:Area 3 - Gear", "GEAR_4" },
            { "8:Area 2 - Yard managers keycard", "WAREHOUSE_YARDKEY" },
            { "9:Area 1 - A-101 Dorms key 1", "DORMS_CARD_101" },
            { "10:Area 1 - A-101 Dorms key 2", "DORMS_CARD_101" },
            { "11:Area 1 - A-106 Dorms key 3", "DORMS_CARD_106" },
            { "12: Area 1 - B-201 Dorms key 4", "DORMS_CARD_201" },
            { "13:Service Elevator codes", "CODES_1" },
            { "14:Maintenance Access level 2 keycard", "Blackmesa_Maintenance_Clearance_2" },
            { "15:Maintenance Access level 2 keycard Alt", "Blackmesa_Maintenance_Clearance_2" },
            { "16:Maintenance Access level 2 keycard X", "Blackmesa_Maintenance_Clearance_2" },
            { "17:Reception key 1", "d5_officekey" },
            { "18:Reception key 2", "d5_officekey" },
            { "19:Doctors key", "d5_doctorkey" },
            { "20:Blackmesa Security Clearance level 3", "Blackmesa_Security_Clearance_3" }
        },
        dictRelay =
        {
            { "target", "find_players_carrying" },
            { "triggerstate", "1" },
            { "spawnflags", "64" }
        },
        dictTS =
        {
            { "targetname", "find_players_carrying" },
            { "m_iszScriptFunctionName", "FindPlayersCarrying" },
            { "m_iMode", "1" }
        };

    array<string> STR_KEYS = dictMenu.getKeys();
    STR_KEYS.sort( function(a, b) { return atoi( a ) < atoi( b ); } );

    for( uint i = 0; i < STR_KEYS.length(); i++ )
    {
        dictRelay["targetname"] = string( dictMenu[STR_KEYS[i]] );
        string str = STR_KEYS[i].SubString( 2 );
        str.Trim( " " );
        dictRelay["noise"] = str;
        g_EntityFuncs.CreateEntity( "trigger_relay", dictRelay );
    }

    g_EntityFuncs.CreateEntity( "trigger_script", dictTS );
    g_Hooks.RegisterHook( Hooks::Player::ClientSay, PlayerOpenMenu );

    return g_EntityFuncs.CreateEntity( "game_menu", dictMenu );
}

void FindPlayersCarrying(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    string 
        strItemName = pCaller.GetTargetname(),
        strItemDesc = pCaller.pev.noise,
        strPlayersCarrying;

    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

        if( pPlayer is null || !pPlayer.IsConnected() || pPlayer.get_m_pInventory() is null )
            continue;

        InventoryList@ pInventory = pPlayer.get_m_pInventory();

        do
        {
            CItemInventory@ pInventoryItem = cast<CItemInventory@>( pInventory.hItem.GetEntity() );

            if( pInventoryItem !is null && pInventoryItem.m_szItemName == strItemName )
                strPlayersCarrying += string( pPlayer.pev.netname ) + "\n";

            @pInventory = pInventory.pNext;
        }
        while( pInventory !is null );
    }

    if( strPlayersCarrying != "" )
        g_PlayerFuncs.SayText( cast<CBasePlayer@>( pActivator ), "Players carrying item '" + strItemDesc + "':\n" + strPlayersCarrying + "\n" );
    else
        g_PlayerFuncs.SayText( cast<CBasePlayer@>( pActivator ), "Nobody is carrying item '" + strItemDesc + "'.\n" );
}

HookReturnCode PlayerOpenMenu(SayParameters@ pParams)
{
    if( pParams is null )
        return HOOK_CONTINUE;

    CBasePlayer@ pPlayer = pParams.GetPlayer();
    const CCommand@ cmdArgs = pParams.GetArguments();

    if( cmdArgs.ArgC() < 1 || !cmdArgs[0].StartsWith( "!whw" ) || pPlayer is null || !pPlayer.IsConnected() || !hItemTrackerMenu )
        return HOOK_CONTINUE;

    pParams.set_ShouldHide( true );
    hItemTrackerMenu.GetEntity().Use( pPlayer, pPlayer, USE_ON );

    return HOOK_CONTINUE;
}
