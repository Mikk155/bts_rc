"GameMenu"
{
    "1"
    {
        "label" "Test chamber"
        "command" "engine sv_lan 0;developer 1;maxplayers 32;map bts_rc_test_chamber"
        "NotInGame" "1"
    }
    "2"
    {
        "label" ""
        "command" ""
        "NotInGame" "1"
    }
    "3"
    {
        "label" "BTS_RC"
        "command" "engine sv_lan 0;developer 1;maxplayers 32;map bts_rc"
        "NotInGame" "1"
    }
    "4"
    {
        "label" "#GameUI_GameMenu_ResumeGame"
        "command" "ResumeGame"
        "OnlyInGame" "1"
    }
    "5"
    {
        "label" "#GameUI_GameMenu_Disconnect"
        "command" "Disconnect"
        "OnlyInGame" "1"
    }
    "6"
    {
        "label" "#GameUI_GameMenu_PlayerList"
        "command" "OpenPlayerListDialog"
        "OnlyInGame" "1"
        "notsingle" "1"
    }
    "7"
    {
        "label" ""
        "command" ""
    }
    "8"
    {
        "label" "#GameUI_GameMenu_FindServers"
        "command" "OpenServerBrowser"
        "notsingle" "1"
    }
    "9"
    {
        "label" "#GameUI_GameMenu_CreateServer"
        "command" "OpenCreateMultiplayerGameDialog"
        "notsingle" "1"
    }
    "10"
    {
        "label" "#GameUI_GameMenu_Options"
        "command" "OpenOptionsDialog"
    }
    "11"
    {
        "label" "#GameUI_GameMenu_Quit"
        "command" "Quit"
    }
}
