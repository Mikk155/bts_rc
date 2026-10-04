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

enum DynamicEquipmentType
{
    Undefined = -1,
    Ammunition = 0,
    Weapon,
    Armor,
    Health
};

final class ASDynamicAmmoData
{
    string m_Classname;
    // Entity classname
    const string& get_classname() const
    {
        return this.m_Classname;
    }

    DynamicEquipmentType m_Type = DynamicEquipmentType::Undefined;
    // Type of equipment. if Ammunition/Weapon then refeer to index for CBasePlayer::m_rgAmmo index.
    const DynamicEquipmentType get_type() const
    {
        return this.m_Type;
    }

    int m_Index = DynamicEquipmentType::Undefined;
    // Index for CBasePlayer::m_rgAmmo
    const int get_index() const
    {
        return this.m_Index;
    }

    int m_Min;
    // minimum ammount to give ammo.
    const int get_min() const
    {
        return this.m_Min;
    }

    int m_Max;
    // maximum ammount to give ammo.
    const int get_max() const
    {
        return this.m_Max;
    }

    // Get corresponding ammo
    int get( int players = 0 ) const
    {
        if( !gpDynamicAmmo.Active )
            return this.max;

        players = Math.min( Math.max( players, 0 ), g_Engine.maxClients );

        if( players == 0 )
        {
            players = g_PlayerFuncs.GetNumPlayers();
        }

        if( g_Engine.maxClients <= 1 || players == 1 )
            return this.max;

        // t = 0.0 when solo (1 player), 1.0 when full (g_Engine.maxClients players)
        float t = float( players - 1 ) / float( g_Engine.maxClients - 1 );

        // Lerp from this.max (solo) to data.min (full)
        float result = float( this.max ) + t * float( this.min - this.max );

        return Math.max( 1, int( Math.Ceil( result ) ) );
    }
}

final class ASDynamicAmmoConfig : IConfigurable
{
    private
        dictionary m_AmmoData;

    const dictionary@ get_AmmoData() const
    {
        return @this.m_AmmoData;
    }

    const string& GetName() const override {
        return "dynamic_ammo";
    }

    const string GetSchema() const override {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "description": "Scales ammo pickup amounts based on connected player count.",
            "allOf":
            [
                "IConfigurable"
            ],
            "additionalProperties":
            {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "description": "Scaled minimum and maximum amount of ammo to give for each entity based on player count.",
                "items":
                {
                    "minimum": 1,
                    "type": "integer"
                },
                "prefixItems":
                [
                    { "description": "Ammo given when only one player connected." },
                    { "description": "Ammo given when max server capacity of players connected" }
                ]
            }
        }""";
    }

    private bool m_Active;

    const bool get_Active() const
    {
        return this.m_Active;
    }

    private
        ClientPutInServerHook@ m_pValidation;

    private
        HookReturnCode ValidateAmunition( CBasePlayer@ player )
        {
            if( player is null || !player.IsConnected() )
                return HOOK_CONTINUE;

            g_Hooks.RemoveHook( Hooks::Player::ClientPutInServer, @this.m_pValidation );
            @this.m_pValidation = null;

            player.Revive();

            const array<string>@ itemNames = this.m_AmmoData.getKeys();
            const uint length = itemNames.length();

            int[] ammoInventory(MAX_AMMO_TYPES);
            float[] armor = { player.pev.armorvalue, player.pev.armortype };
            float[] health = { player.pev.health, player.pev.max_health };
            player.pev.armorvalue = player.pev.health = 0;
            player.pev.armortype = player.pev.max_health = 1000;

            for( size_t idx = 0 ; idx < MAX_AMMO_TYPES; idx++ )
            {
                ammoInventory[idx] = player.m_rgAmmo(idx);
            }

            for( uint ui = 0; ui < length; ui++ )
            {
                ASDynamicAmmoData@ data;

                this.m_AmmoData.get( itemNames[ui], @data );

                this.m_Lock = true;
                player.GiveNamedItem( data.classname, ( SF_CREATEDWEAPON | SF_GIVENITEM ), 1 );
                this.m_Lock = false;

                CBasePlayerWeapon@ weapon = cast<CBasePlayerWeapon@>( player.HasNamedPlayerItem( data.classname ) );

                if( weapon !is null )
                {
                    data.m_Index = weapon.PrimaryAmmoIndex();
                    data.m_Type = DynamicEquipmentType::Weapon;
                }
                else if( player.pev.health > 0 )
                {
                    data.m_Type = DynamicEquipmentType::Health;
                }
                else if( player.pev.armorvalue > 0 )
                {
                    data.m_Type = DynamicEquipmentType::Armor;
                }
                else
                {
                    for( size_t idx = 0; idx < MAX_AMMO_TYPES; idx++ )
                    {
                        int old = ammoInventory[ idx ];
                        int now = player.m_rgAmmo( idx );
                        player.m_rgAmmo( idx, old );

                        if( old < now )
                        {
                            data.m_Index = idx;
                            data.m_Type = DynamicEquipmentType::Ammunition;
                            break;
                        }
                    }
                }

                player.pev.health = player.pev.armorvalue = 0;
                player.RemoveAllItems( false, false );

                switch( data.m_Type )
                {
                    case DynamicEquipmentType::Undefined:
                    {
                        g_Logger.error.print( "[{}] Can not guess ammo type of \"{}\"", { this.GetName(), data.classname } );
                        int[]a(0);a[1];
                        break;
                    }
                    case DynamicEquipmentType::Weapon:
                    case DynamicEquipmentType::Ammunition:
                    {
                        if( g_Logger.debug.active )
                            g_Logger.debug.print( "[{}] \"{}\": min={} max={} index={}", { this.GetName(), data.classname, data.min, data.max, data.index } );
                        break;
                    }
                    case DynamicEquipmentType::Armor:
                    {
                        if( g_Logger.debug.active )
                            g_Logger.debug.print( "[{}] \"{}\": min={} max={} armor", { this.GetName(), data.classname, data.min, data.max } );
                        break;
                    }
                    case DynamicEquipmentType::Health:
                    {
                        if( g_Logger.debug.active )
                            g_Logger.debug.print( "[{}] \"{}\": min={} max={} healths", { this.GetName(), data.classname, data.min, data.max } );
                        break;
                    }
                }
            }

            player.pev.armorvalue = armor[0];
            player.pev.armortype = armor[1];
            player.pev.health = health[0];
            player.pev.max_health = health[1];

            if( g_Logger.info.active )
                g_Logger.info.print( "[{}] Registered {} dynamic ammo types.", { this.GetName(), this.m_AmmoData.getSize() } );

            return HOOK_CONTINUE;
        }

    bool Register( btson@ config ) override
    {
        this.m_Active = bool( config.Remove( "active" ) );

        const array<string>@ ammoTypes = config.Keys;
        uint size = ammoTypes.length();

        for( uint ui = 0; ui < size; ui++ )
        {
            string classname = ammoTypes[ui];

            ASDynamicAmmoData data;

            btson@ range = config[ classname ];

            data.m_Min = int( range[0] );
            data.m_Max = int( range[1] );
            data.m_Classname = classname;

            if( data.min > data.max )
            {
                g_Logger.error.print( "[{}] Inverted min/max values at \"{}\"", { this.GetName(), classname } );
                int[]a(0);a[1];
            }

            @this.m_AmmoData[ classname ] = data;
        }

        @this.m_pValidation = ClientPutInServerHook( @this.ValidateAmunition );
        g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @this.m_pValidation );

#if SERVER
        if( g_MapConfig.MapLoading )
        {
            RegisterCommand(
                "dynamic force",
                "<int 0/" + g_Engine.maxClients + " (optional)>",
                "Set force number of players for dynamic ammo, use zero to reset to actual number of players",
                function( CBasePlayer@ player, array<string>@ arguments )
                {
                    gpDynamicAmmo.forcenumplayers = ( arguments is null || arguments.length() <= 0 ) ? 0 : Math.min( atoi( arguments[0] ), g_Engine.maxClients );

                    if( gpDynamicAmmo.forcenumplayers <= 0 )
                        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Reseted number of players.\n" );
                    else
                        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Set force number of players to " + gpDynamicAmmo.forcenumplayers + "\n" );
                }, true, "ammo"
            );

            RegisterCommand(
                "dynamic_info",
                "<int 1/" + g_Engine.maxClients + " (optional)>",
                "Print dynamic ammo values for all configured types. Pass a number to simulate that many players connected.",
                function( CBasePlayer@ player, array<string>@ arguments )
                {
                    int simPlayers = gpDynamicAmmo.Players;

                    if( arguments !is null && arguments.length() > 0 )
                    {
                        simPlayers = atoi( arguments[0] );
                        if( simPlayers < 1 ) simPlayers = 1;
                        if( simPlayers > g_Engine.maxClients ) simPlayers = g_Engine.maxClients;
                    }

                    string buffer;
                    snprintf( buffer, "[Dynamic Ammo] g_Engine.maxClients=%1 connected=%2 simulated=%3\n", g_Engine.maxClients, g_PlayerFuncs.GetNumPlayers(), simPlayers );
                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );

                    float t = 0.0f;
                    if( g_Engine.maxClients > 1 )
                        t = float( simPlayers - 1 ) / float( g_Engine.maxClients - 1 );

                    snprintf( buffer, "[Dynamic Ammo] t=%1 (0=solo, 1=full)\n", t );
                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );

                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "--- Ammo Type ---   --- Give ---\n" );

                    const array<string> keys = gpDynamicAmmo.AmmoData.getKeys();
                    const uint length = keys.length();

                    for( uint ui = 0; ui < length; ui++ )
                    {
                        const ASDynamicAmmoData@ data = gpDynamicAmmo.Find( keys[ui] );
                        snprintf( buffer, "  %1: %2  (range: %3-%4)\n", data.classname, data.get(simPlayers), data.min, data.max );
                        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );
                    }

                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "--- End ---\n" );
                },
                false, "ammo"
            );
        }
#endif
        return true;
    }

    // Get the ASDynamicAmmoData instance for the given classname
    const ASDynamicAmmoData@ Find( const string&in classname ) const
    {
        ASDynamicAmmoData@ data;
        this.m_AmmoData.get( classname, @data );
        return @data;
    }

    int forcenumplayers = 0;

    int get_Players() const
    {
        if( this.forcenumplayers > 0 )
            return this.forcenumplayers;
        return g_PlayerFuncs.GetNumPlayers();
    }

    private
        bool m_Lock;

    bool PlayerCanCollect( CBasePlayer@ player, CBaseEntity@ pickup )
    {
        if( player is null || pickup is null || this.m_Lock )
            return true;

        CBasePlayerItem@ pickupItem = cast<CBasePlayerItem@>( pickup );

        // Skip drops from players
        if( pickupItem !is null && pickupItem.m_dropType != DropTypes::DROP_DEFAULT )
            return true;

#if FALSE
        switch( pickupItem.m_dropType )
        {
            case DropTypes::DROP_NPC_DEATH:
                break;
            case DropTypes::DROP_PLAYER_CMD:
            case DropTypes::DROP_PLAYER_DEATH:
            case DropTypes::DROP_NPC_DEATH:
            default:
                return true;
        }
#endif

        const ASDynamicAmmoData@ data = this.Find( pickup.GetClassname() );

        if( data is null )
            return true;

        CBasePlayerWeapon@ weapon;

        // If it's a weapon equip it and set ammo to zero
        if( data.index == DynamicEquipmentType::Weapon )
        {
            if( ( @weapon = cast<CBasePlayerWeapon@>( player.HasNamedPlayerItem( data.classname ) ) ) is null )
            {
                this.m_Lock = true;
                player.GiveNamedItem( data.classname, SF_GIVENITEM );
                this.m_Lock = false;
                @weapon = cast<CBasePlayerWeapon@>( player.HasNamedPlayerItem( data.classname ) );
                player.m_rgAmmo( data.index, 0 );
            }
        }

        int count = data.get(this.forcenumplayers);

        switch( data.type )
        {
            case DynamicEquipmentType::Weapon:
            case DynamicEquipmentType::Ammunition:
            {
                int max = player.GetMaxAmmo( data.index );
                int current = player.m_rgAmmo( data.index );
                int add = Math.min( count, max - current );

                if( add < 1 )
                    return true;

                pickup.pev.flags |= FL_KILLME;

                int totalAmmo = current + add;

                // Fill clip with a random amount of bullets
                if( weapon !is null )
                {
                    int maxClip = weapon.iMaxClip();

                    if( maxClip != WEAPON_NOCLIP )
                    {
                        weapon.m_iClip = Math.RandomLong( 0, Math.min( totalAmmo, maxClip ) );
                        totalAmmo -= weapon.m_iClip;
                    }
                }

                player.m_rgAmmo( data.index, totalAmmo );

                NetworkMessage msg( MSG_ONE, NetworkMessages::AmmoPickup, player.edict() );
                    msg.WriteByte( data.index );
                    msg.WriteLong( add );
                msg.End();

                NetworkMessage message( MSG_ONE, NetworkMessages::AmmoX, player.edict() );
                    message.WriteByte( data.index );
                    message.WriteLong( add );
                message.End();

                g_SoundSystem.EmitSound( player.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1.0, ATTN_NORM );

                if( g_Logger.trace.active )
                    g_Logger.trace.print( "[{}] gave {} of \"{}\" (id: {}) to player \"{}\": min={} max={}", {
                        this.GetName(), count, data.classname, data.index, player.pev.netname, data.min, data.max } );

                return false;
            }
            case DynamicEquipmentType::Armor:
            {
                float oldArmor = player.pev.armorvalue;

                if( oldArmor < player.pev.armortype && pickupItem.AddToPlayer( player ) )
                {
                    pickup.pev.flags |= FL_KILLME;
                    player.pev.armorvalue = oldArmor + Math.clamp( 0, player.pev.armortype, count );

                    if( g_Logger.trace.active )
                        g_Logger.trace.print( "[{}] gave {} of armor to player \"{}\": min={} max={}", {
                            this.GetName(), count, data.classname, player.pev.netname, data.min, data.max } );
                }

                return false;
            }
            case DynamicEquipmentType::Health:
            {
                float oldHealth = player.pev.health;

                if( oldHealth < player.pev.max_health && pickupItem.AddToPlayer( player ) )
                {
                    pickup.pev.flags |= FL_KILLME;
                    player.pev.health = oldHealth + Math.clamp( 0, player.pev.max_health, count );

                    if( g_Logger.trace.active )
                        g_Logger.trace.print( "[{}] gave {} of health to player \"{}\": min={} max={}", {
                            this.GetName(), count, data.classname, player.pev.netname, data.min, data.max } );
                }

                return false;
            }
        }

        return false;
    }
}

ASDynamicAmmoConfig gpDynamicAmmo;
