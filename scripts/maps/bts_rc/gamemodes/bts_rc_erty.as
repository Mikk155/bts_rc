/**
* Map initialisation handler.
* @return void
*/

/**
* ######################################################
* #  When integrating with the rest of the scripts,    #
* #  remove everything above and including this box.   #
* #  Add "BTS_RC_ERTY::MapActivate();" to MapActivate  #
* ######################################################
*/

namespace BTS_RC_ERTY
{
    HUDTextParams msgParams;

// Loadouts

    array<array<string>> rgLoadoutSolo = {
        { "weapon_bts_flashlight" }
    };
    array<array<string>> rgLoadoutSecurity = {
        { "weapon_bts_eagle", "ammo_bts_eagle", "ammo_bts_eagle", "weapon_bts_flashlight" },
        { "weapon_bts_beretta", "ammo_9mmclip", "ammo_9mmclip", "weapon_bts_flashlight" },
        { "weapon_bts_glock", "ammo_9mmclip", "ammo_9mmclip", "weapon_bts_flashlight" },
        { "weapon_bts_glock17f", "ammo_9mmclip", "ammo_9mmclip", "weapon_bts_flashlight" }
    };
    array<array<string>> rgLoadoutScientist = {
        { "weapon_medkit", "weapon_bts_flashlight" }
    };
    array<array<string>> rgLoadoutRepair = {
        { "weapon_bts_screwdriver", "weapon_bts_flashlight" },
        { "weapon_bts_crowbar", "weapon_bts_flashlight" }
    };

    array<string> GetRandomLoadout(array<array<string>>& in loadout)
    {
        uint size = loadout.length();
        if (size == 1) { return loadout[0]; }
        return loadout[Math.RandomLong(0, size - 1)];
    }


// Playermodels

    uint uiPlayermodelIndexSolo = 0;
    uint uiPlayermodelIndexSecurity = 0;
    uint uiPlayermodelIndexScientist = 0;
    uint uiPlayermodelIndexRepair = 0;

    array<string> rgPlayermodelSolo = {
        "bts_barney3"
    };
    array<string> rgPlayermodelSecurity = {
        "bts_otis",
        "bts_barney",
        "bts_barney2"
    };
    array<string> rgPlayermodelScientist = {
        "bts_scientist",
        "bts_scientist2",
        "bts_scientist3",
        "bts_scientist4",
        "bts_scientist5",
        "bts_scientist6"
    };
    array<string> rgPlayermodelRepair = {
        "bts_construction"
    };


// Class select messages

    string szMessageSolo = "USER MODE SELECTED\nSECURITY CLEARANCE LEVEL 5\nADMINISTRATOR OBSERVING\nTECHNICIAN OBSERVING\nTROUBLE SHOOTING ENABLED\nGENERATING USER SCENARIOS\n10%.. 20%.. 30%.. 40%.. 50%.. 60%..\n70%.. 80%.. 90%.. 100%.. COMPLETE\nSIMUL";
    string szMessageSecurity = "Selection confirmed\nyou have chosen to join the\nBlackmesa Security Force";
    string szMessageScientist = "Selection confirmed\nyou have chosen to join the\nBlackmesa Science Team";
    string szMessageRepair = "Selection confirmed\nyou have chosen to join the\nBlackmesa Maintenance Group";


// Utility functions

    /**
    * Map activation handler.
    * @return void
    */
    void MapActivate()
    {
        msgParams.x           = 0;
        msgParams.y           = 0;
        msgParams.effect      = 2;
        msgParams.r1          = 255;
        msgParams.g1          = 255;
        msgParams.b1          = 255;
        msgParams.a1          = 0;
        msgParams.r2          = 240;
        msgParams.g2          = 110;
        msgParams.b2          = 0;
        msgParams.a2          = 0;
        msgParams.fadeinTime  = 0.05f;
        msgParams.fadeoutTime = 0.5f;
        msgParams.holdTime    = 1.2f;
        msgParams.fxTime      = 0.025f;
        msgParams.channel     = 3;
        
        ShuffleArray(rgPlayermodelSolo);
        ShuffleArray(rgPlayermodelSecurity);
        ShuffleArray(rgPlayermodelScientist);
        ShuffleArray(rgPlayermodelRepair);
    }


    void ShuffleArray(array<string> &arr)
    {
        if (arr.length() == 1) { return; }
        int j = 0;
        string temp;
        for (int i = arr.length() - 1; i >= 0; i--) {
            j = Math.RandomLong(0, i);
            temp = arr[i];
            arr[i] = arr[j];
            arr[j] = temp;
        }
    }


    string GetNextPlayermodelSolo() { return rgPlayermodelSolo[0]; }
    string GetNextPlayermodelSecurity()
    {
        if ((uiPlayermodelIndexSecurity + 1) >= rgPlayermodelSecurity.length()) {
            ShuffleArray(rgPlayermodelSecurity);
            uiPlayermodelIndexSecurity = 0;
        }
        string pm = rgPlayermodelSecurity[uiPlayermodelIndexSecurity];
        uiPlayermodelIndexSecurity++;
        return pm;
    }
    string GetNextPlayermodelScientist()
    {
        if ((uiPlayermodelIndexScientist + 1) >= rgPlayermodelScientist.length()) {
            ShuffleArray(rgPlayermodelScientist);
            uiPlayermodelIndexScientist = 0;
        }
        string pm = rgPlayermodelScientist[uiPlayermodelIndexScientist];
        uiPlayermodelIndexScientist++;
        return pm;
    }
    string GetNextPlayermodelRepair() { return rgPlayermodelRepair[0]; }


    void PlaySoundAtTarget(CBaseEntity@ target, string sample)
    {
        g_SoundSystem.EmitAmbientSound(
            target.edict(), target.pev.origin, sample, 0.5f, ATTN_IDLE, 0, 100
        );
    }

    void DisplayMessage(CBasePlayer@ pPlayer, string message)
    {
        g_PlayerFuncs.HudMessage(pPlayer, msgParams, message);
    }

    void PlayerFade(CBasePlayer@ pPlayer, Vector& in color, int flags)
    {
        g_PlayerFuncs.ScreenFade(pPlayer, color, 0.25f, 1.0f, 255.0f, flags);
    }


    void ApplyLoadout(
        CBaseEntity@ pActivator,
        CBaseEntity@ pCaller,
        array<string> loadout,
        string playermodel,
        string sound,
        string message,
        Vector& in fadeColor
    ) {
        if (pActivator is null || !pActivator.IsPlayer()) {
            return;
        }

        CBasePlayer@ pPlayer = cast<CBasePlayer>(pActivator);
        if (pPlayer is null || !pPlayer.IsConnected()) {
            return;
        }

        // Weaponstrip first
        // pPlayer.RemoveAllItems();

        pPlayer.SetOverriddenPlayerModel(playermodel);

        uint size = loadout.length();
        for (int i = 0; i < size; i++) {
            pPlayer.GiveNamedItem(loadout[i]);
        }

        PlayerFade(pPlayer, fadeColor, FFADE_IN);
        g_Scheduler.SetTimeout("PlayerFade", 1, @pPlayer, fadeColor, FFADE_OUT);

        PlaySoundAtTarget(pCaller, sound);
        g_Scheduler.SetTimeout("PlaySoundAtTarget", 1, @pCaller, "vox/authorized.wav");

        g_Scheduler.SetTimeout("DisplayMessage", 3, @pPlayer, message);
    }

    int iKeycardIndex = 0;
    void GiveKeycard(
        CBaseEntity@ pActivator,
        CBaseEntity@ pCaller,
        int skin,
        string description,
        string displayName,
        string itemName,
        string itemIcon,
        string itemGroup = ""
    ) {
        string szName = "SETCLASS_KEYCARD_" + string(iKeycardIndex);

        dictionary oKeycard = {
            { "targetname",             szName },
            { "origin",                 pActivator.pev.origin.ToString() },
            { "model",                  "models/w_security.mdl" },
            { "delay",                  "0" },
            { "holder_timelimit_wait_until_activated", "0" },
            { "description",            description },
            { "display_name",           displayName },
            { "item_name",              itemName },
            { "m_flCustomRespawnTime",  "0" },
            { "return_timelimit",       "-1" },
            { "skin",                   formatInt(skin) },
            { "carried_hidden",         "1" },
            { "holder_can_drop",        "1" },
            { "item_icon",              itemIcon },
            { "holder_keep_on_death",   "0" },
            { "holder_keep_on_respawn", "0" }
        };

        if (!itemGroup.IsEmpty()) {
            oKeycard.set("item_group", itemGroup);
        }

        g_EntityFuncs.CreateEntity("item_inventory", oKeycard);
        iKeycardIndex++;

        g_EntityFuncs.FireTargets(szName, pActivator, pCaller, USE_TOGGLE);
    }

    int iToolboxIndex = 0;
    void GiveToolbox(CBaseEntity@ pActivator, CBaseEntity@ pCaller)
    {
        string szName = "SETCLASS_TOOLBOX_" + string(iToolboxIndex);

        dictionary oToolbox = {
            { "targetname",             szName },
            { "origin",                 pActivator.pev.origin.ToString() },
            { "model",                  "models/tool_box.mdl" },
            { "delay",                  "0" },
            { "holder_timelimit_wait_until_activated", "0" },
            { "description",            "Blackmesa Maintenance Toolcase" },
            { "display_name",           "Maintenance Toolbox (10 SLOTS)" },
            { "item_name",              "GM_TOOLBOX" },
            { "m_flCustomRespawnTime",  "0" },
            { "return_timelimit",       "-1" },
            { "carried_hidden",         "1" },
            { "holder_can_drop",        "1" },
            { "item_icon",              "bts_rc/inv_card_maint.spr" },
            { "holder_keep_on_death",   "0" },
            { "weight",                 "10" },
            { "scale",                  "0.8" },
            { "holder_keep_on_respawn", "0" }
        };

        g_EntityFuncs.CreateEntity("item_inventory", oToolbox);
        iToolboxIndex++;

        g_EntityFuncs.FireTargets(szName, pActivator, pCaller, USE_TOGGLE);
    }


// Map hooks

    /**
     * Map hook: Apply SOLO class loadout
     * @param  CBaseEntity@|null pActivator Activator entity
     * @param  CBaseEntity@|null pCaller    Caller entity
     * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
     * @param  float             flValue    Use value, or unspecified to assume `0.0f`
     * @return void
     */
    void ApplyLoadoutSolo(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        ApplyLoadout(
            pActivator, pCaller,
            GetRandomLoadout(rgLoadoutSolo),
            GetNextPlayermodelSolo(),
            "vox/user.wav",
            szMessageSolo,
            Vector(255, 0, 0)
        );
    }

    /**
     * Map hook: Apply SECURITY class loadout
     * @param  CBaseEntity@|null pActivator Activator entity
     * @param  CBaseEntity@|null pCaller    Caller entity
     * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
     * @param  float             flValue    Use value, or unspecified to assume `0.0f`
     * @return void
     */
    void ApplyLoadoutSecurity(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        ApplyLoadout(
            pActivator, pCaller,
            GetRandomLoadout(rgLoadoutSecurity),
            GetNextPlayermodelSecurity(),
            "vox/security.wav",
            szMessageSecurity,
            Vector(0, 170, 255)
        );

        GiveKeycard(
            pActivator, pCaller, 3,
            "Blackmesa Security Clearance level 1",
            "Security Keycard lvl 1",
            "Blackmesa_Security_Clearance_1",
            "bts_rc/inv_card_security.spr",
            "security"
        );
    }

    /**
     * Map hook: Apply SCIENTIST class loadout
     * @param  CBaseEntity@|null pActivator Activator entity
     * @param  CBaseEntity@|null pCaller    Caller entity
     * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
     * @param  float             flValue    Use value, or unspecified to assume `0.0f`
     * @return void
     */
    void ApplyLoadoutScientist(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        ApplyLoadout(
            pActivator,
            pCaller,
            GetRandomLoadout(rgLoadoutScientist),
            GetNextPlayermodelScientist(),
            "vox/research.wav",
            szMessageScientist,
            Vector(0, 255, 93)
        );

        GiveKeycard(
            pActivator, pCaller, 2,
            "Blackmesa Research Clearance level 1",
            "Research Keycard lvl 1",
            "Blackmesa_Research_Clearance_1",
            "bts_rc/inv_card_research.spr"
        );
    }

    /**
     * Map hook: Apply REPAIR class loadout
     * @param  CBaseEntity@|null pActivator Activator entity
     * @param  CBaseEntity@|null pCaller    Caller entity
     * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
     * @param  float             flValue    Use value, or unspecified to assume `0.0f`
     * @return void
     */
    void ApplyLoadoutRepair(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        ApplyLoadout(
            pActivator, pCaller,
            GetRandomLoadout(rgLoadoutRepair),
            GetNextPlayermodelRepair(),
            "vox/maintenance.wav",
            szMessageSecurity,
            Vector(255, 255, 127)
        );

        GiveKeycard(
            pActivator, pCaller, 2,
            "Blackmesa Maintenance Clearance",
            "Maintenance Keycard",
            "Blackmesa_Maintenance_Clearance",
            "bts_rc/inv_card_maint.spr"
        );

        GiveToolbox(pActivator, pCaller);
    }

}
