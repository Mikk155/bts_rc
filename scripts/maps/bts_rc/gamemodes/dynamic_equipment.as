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

final class ASDynamicEquipmentData
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
    // maximum ammount to give.
    const int get_max() const
    {
        return this.m_Max;
    }

    // Get corresponding ammount.
    int get( int players = 0 ) const
    {
        if( !gpDynamicEquipment.Active )
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

final class ASDynamicEquipentConfig : IConfigurable
{
    private
        dictionary m_EquipentData;

    const dictionary@ get_EquipentData() const
    {
        return @this.m_EquipentData;
    }

    const string& GetName() const override {
        return "dynamic_equipment";
    }

    const string GetSchema() const override {
        return """{
            "type": "object",
            "description": "Scales equipment pickup amounts based on connected player count.",
            "allOf":
            [
                "IConfigurable"
            ],
            "additionalProperties":
            {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items":
                {
                    "minimum": 1,
                    "type": "integer",
                    "description": "Minimum and maximum amount to give for each entity based on player count."
                },
                "description": "Scaled minimum and maximum amount to give for each entity based on player count."
            }
        }""";
    }

    private bool m_Active;

    const bool get_Active() const
    {
        return this.m_Active;
    }

    private
        bool m_Validated = false;

    private
        bool Validated( CBasePlayer@ player )
        {
            if( this.m_Validated )
                return true;

            if( player is null || !player.IsConnected() || !player.IsAlive() )
                return false;

            this.Lock();

            const array<string>@ itemNames = this.m_EquipentData.getKeys();
            const uint length = itemNames.length();

            float[] armor = { player.pev.armorvalue, player.pev.armortype };
            float[] health = { player.pev.health, player.pev.max_health };
            player.pev.armorvalue = player.pev.health = 0;
            player.pev.armortype = player.pev.max_health = 1000;
            player.RemoveAllItems( false, false );

            for( uint ui = 0; ui < length; ui++ )
            {
                ASDynamicEquipmentData@ data;

                this.m_EquipentData.get( itemNames[ui], @data );

                int[] prefixedItem;
                if( this.m_prefixedItems.get( data.classname, prefixedItem ) )
                {
                    data.m_Type = DynamicEquipmentType( prefixedItem[0] );

                    if( prefixedItem[1] > -1 )
                        data.m_Index = prefixedItem[1];

                    this.m_prefixedItems.delete( data.classname );
                }

                if( data.m_Type == DynamicEquipmentType::Undefined )
                {
                    auto entity = g_EntityFuncs.Create( data.classname, g_vecZero, g_vecZero, true, null );

                    if( entity is null )
                    {
                        g_Logger.error.print( "[{}] Can not create null entity \"{}\"", { this.GetName(), data.classname } );
                        int[]a(0);a[1];
                    }

                    entity.pev.flags |= FL_KILLME;
                    entity.pev.spawnflags |= SF_NORESPAWN;
                    entity.pev.spawnflags |= SF_CREATEDWEAPON;
                    entity.pev.spawnflags |= SF_GIVENITEM;
                    g_EntityFuncs.DispatchSpawn( entity.edict() );

                    CBasePlayerItem@ item;
                    CBasePlayerAmmo@ ammo;

                    if( ( @item = cast<CBasePlayerItem@>( entity ) ) !is null )
                        player.AddPlayerItem( item );
                    else if( ( @ammo = cast<CBasePlayerAmmo@>( entity ) ) !is null )
                        ammo.AddAmmo( player );

                    CBasePlayerWeapon@ weapon = cast<CBasePlayerWeapon@>( player.HasNamedPlayerItem( data.classname ) );

                    if( weapon !is null )
                    {
                        weapons::Given( player, weapon, null, false );

                        data.m_Index = weapon.m_iPrimaryAmmoType;

                        // Weapons that are their own ammo i.e flare/grenade
                        if( data.m_Index < 0 )
                        {
                            data.m_Index = g_PlayerFuncs.GetAmmoIndex( cast<ASWeaponConfig@>( g_WeaponsConfig.Interfaces[ weapon.GetClassname() ] ).primary_ammo );
                        }

                        data.m_Type = DynamicEquipmentType::Weapon;

                        player.RemoveAllItems( false, false );
                    }
                    else if( player.pev.health > 0 )
                    {
                        data.m_Type = DynamicEquipmentType::Health;
                        player.pev.health = 0;
                    }
                    else if( player.pev.armorvalue > 0 )
                    {
                        data.m_Type = DynamicEquipmentType::Armor;
                        player.pev.armorvalue = 0;
                    }
                    else
                    {
                        for( size_t idx = 0; idx < MAX_AMMO_TYPES; idx++ )
                        {
                            if( player.m_rgAmmo( idx ) > 0 )
                            {
                                data.m_Index = idx;
                                data.m_Type = DynamicEquipmentType::Ammunition;
                                player.RemoveAllItems( false, false );
                                break;
                            }
                        }
                    }
                }

                switch( data.m_Type )
                {
                    case DynamicEquipmentType::Undefined:
                    {
                        g_Logger.error.print( "[{}] Can not guess entity type of \"{}\"", { this.GetName(), data.classname } );
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
            player.RemoveAllItems( false, false );

            if( g_Logger.info.active )
                g_Logger.info.print( "[{}] Registered {} dynamic equipment types.", { this.GetName(), this.m_EquipentData.getSize() } );

            this.UnLock();

            this.m_Validated = true;
            return true;
        }

    bool Register( btson@ config ) override
    {
        this.m_Active = bool( config.Remove( "active" ) );

        const array<string>@ equipmentItems = config.Keys;
        uint size = equipmentItems.length();

        for( uint ui = 0; ui < size; ui++ )
        {
            string classname = equipmentItems[ui];

            ASDynamicEquipmentData data;

            btson@ range = config[ classname ];

            data.m_Min = int( range[0] );
            data.m_Max = int( range[1] );
            data.m_Classname = classname;

            if( data.min > data.max )
            {
                g_Logger.error.print( "[{}] Inverted min/max values at \"{}\"", { this.GetName(), classname } );
                int[]a(0);a[1];
            }

            @this.m_EquipentData[ classname ] = data;
        }

        if( g_MapConfig.MapLoading )
        {
            RegisterCommand(
                "dynamic force",
                "<int 0/" + g_Engine.maxClients + " (optional)>",
                "Set force number of players for dynamic equipment, use zero to reset to actual number of players",
                function( CBasePlayer@ player, array<string>@ arguments )
                {
                    gpDynamicEquipment.forcenumplayers = ( arguments is null || arguments.length() <= 0 ) ? 0 : Math.min( atoi( arguments[0] ), g_Engine.maxClients );

                    if( gpDynamicEquipment.forcenumplayers <= 0 )
                        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Reseted number of players.\n" );
                    else
                        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Set force number of players to " + gpDynamicEquipment.forcenumplayers + "\n" );
                }, true, "equipment"
            );

            RegisterCommand(
                "dynamic_info",
                "<int 1/" + g_Engine.maxClients + " (optional)>",
                "Print dynamic equipment values for all configured types. Pass a number to simulate that many players connected.",
                function( CBasePlayer@ player, array<string>@ arguments )
                {
                    int simPlayers = gpDynamicEquipment.Players;

                    if( arguments !is null && arguments.length() > 0 )
                    {
                        simPlayers = atoi( arguments[0] );
                        if( simPlayers < 1 ) simPlayers = 1;
                        if( simPlayers > g_Engine.maxClients ) simPlayers = g_Engine.maxClients;
                    }

                    string buffer;
                    snprintf( buffer, "[Dynamic Equipment] g_Engine.maxClients=%1 connected=%2 simulated=%3\n", g_Engine.maxClients, g_PlayerFuncs.GetNumPlayers(), simPlayers );
                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );

                    float t = 0.0f;
                    if( g_Engine.maxClients > 1 )
                        t = float( simPlayers - 1 ) / float( g_Engine.maxClients - 1 );

                    snprintf( buffer, "[Dynamic Equipment] t=%1 (0=solo, 1=full)\n", t );
                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );

                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "--- Type ---   --- Give ---\n" );

                    const array<string> keys = gpDynamicEquipment.EquipentData.getKeys();
                    const uint length = keys.length();

                    for( uint ui = 0; ui < length; ui++ )
                    {
                        const ASDynamicEquipmentData@ data = gpDynamicEquipment.Find( keys[ui] );
                        snprintf( buffer, "  %1: %2  (range: %3-%4)\n", data.classname, data.get(simPlayers), data.min, data.max );
                        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );
                    }

                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "--- End ---\n" );
                },
                false, "equipment"
            );
        }
        return true;
    }

    // Get the ASDynamicEquipmentData instance for the given classname
    const ASDynamicEquipmentData@ Find( const string&in classname ) const
    {
        ASDynamicEquipmentData@ data;
        this.m_EquipentData.get( classname, @data );
        return @data;
    }

    private
        dictionary m_prefixedItems;

    // Set item type ahead of time, and index if ammo/weapon.
    void SetType( const string&in classname, DynamicEquipmentType type, int index = -1 )
    {
        int[] list = { int(type), index };
        this.m_prefixedItems[ classname ] = list;
    }

    int forcenumplayers = 0;

    int get_Players() const
    {
        if( this.forcenumplayers > 0 )
            return this.forcenumplayers;
        return g_PlayerFuncs.GetNumPlayers();
    }

    private
        bool m_Locked = false;

    bool get_Locked() const
    {
        return this.m_Locked;
    }

    void Lock()
    {
        this.m_Locked = true;
    }

    void UnLock()
    {
        this.m_Locked = false;
    }

    bool PlayerCanCollect( CBasePlayer@ player, CBaseEntity@ pickup )
    {
        if( player is null || pickup is null || this.Locked || !this.Validated( player ) )
            return true;

        CBasePlayerItem@ pickupItem = cast<CBasePlayerItem@>( pickup );
        CBasePlayerAmmo@ pickupAmmo = cast<CBasePlayerAmmo@>( pickup );

        // Skip weapon drops from players
        if( pickupItem !is null && pickupItem.m_dropType != DropTypes::DROP_DEFAULT )
            return true;

#if SVENCOOP_527
        // -TODO Remove macro after 5.27 if kerncore made its commit.
        if( pickupAmmo !is null && pickupAmmo.m_dropType != DropTypes::DROP_DEFAULT )
            return true;
#endif

        const ASDynamicEquipmentData@ data = this.Find( pickup.GetClassname() );

        if( data is null )
            return true;

        CBasePlayerWeapon@ weapon;

        // If it's a weapon equip it and set ammo to zero
        if( data.type == DynamicEquipmentType::Weapon )
        {
            if( ( @weapon = cast<CBasePlayerWeapon@>( player.HasNamedPlayerItem( data.classname ) ) ) is null )
            {
                this.Lock();
                player.GiveNamedItem( data.classname, SF_GIVENITEM );
                @weapon = cast<CBasePlayerWeapon@>( player.HasNamedPlayerItem( data.classname ) );
                weapons::Given( player, weapon, null );
                player.m_rgAmmo( data.index, 0 );
                this.UnLock();
            }
            else
            {
                // Don't adjust clip
                @weapon = null;
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

                if( oldArmor < player.pev.armortype &&
                ( pickupAmmo !is null && pickupAmmo.AddAmmo( player ) ) || ( pickupItem !is null && pickupItem.AddToPlayer( player ) ) )
                {
                    pickup.pev.flags |= FL_KILLME;
                    player.pev.armorvalue = oldArmor + Math.clamp( 0, player.pev.armortype, count );

                    if( g_Logger.trace.active )
                        g_Logger.trace.print( "[{}] gave {} of \"{}\" to player \"{}\": min={} max={}", {
                            this.GetName(), count, data.classname, player.pev.netname, data.min, data.max } );
                }

                return false;
            }
            case DynamicEquipmentType::Health:
            {
                float oldHealth = player.pev.health;

                if( oldHealth < player.pev.max_health &&
                ( pickupAmmo !is null && pickupAmmo.AddAmmo( player ) ) || ( pickupItem !is null && pickupItem.AddToPlayer( player ) ) )
                {
                    pickup.pev.flags |= FL_KILLME;
                    player.pev.health = oldHealth + Math.clamp( 0, player.pev.max_health, count );

                    if( g_Logger.trace.active )
                        g_Logger.trace.print( "[{}] gave {} of \"{}\" to player \"{}\": min={} max={}", {
                            this.GetName(), count, data.classname, player.pev.netname, data.min, data.max } );
                }

                return false;
            }
        }

        return false;
    }
}

ASDynamicEquipentConfig gpDynamicEquipment;
