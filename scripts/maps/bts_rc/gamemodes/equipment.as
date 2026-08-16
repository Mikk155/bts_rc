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

// Class representing set equipment
final class ASEquipmentSet
{
    private array<string> m_Items;
    private array<dictionary> m_Entities;
    private string m_Description;

    const string& get_Description()
    {
        return this.m_Description;
    }

    // dictionary constructor
    ASEquipmentSet() {}

    ASEquipmentSet( const string&in setName, meta_api::json::v2::json@ config )
    {
        this.m_Description = config.ValueOrDefault( "description", String::EMPTY_STRING );

        meta_api::json::v2::json@ items = config[ "items" ];

        if( items !is null )
        {
            uint itemsLength = items.Length();

            for( uint ui = 0; ui < itemsLength; ui++ )
            {
                meta_api::json::v2::json@ item = items[ui];

                if( !item.is_string() )
                    g_Logger.critical.print( "only strings allowed in items at index {} for equipment {}", { string(ui), setName } );

                this.m_Items.insertLast( string( items[ui] ) );
            }
        }

        meta_api::json::v2::json@ entities = config[ "entities" ];

        if( entities !is null )
        {
            uint entitiesLength = entities.Length();

            for( uint ui = 0; ui < entitiesLength; ui++ )
            {
                meta_api::json::v2::json@ entity = entities[ui];
                const array<string>@ entityKeys = entity.Keys;
                uint entityLength = entity.Length();
                dictionary@ entityData = {};

                for( uint ui2 = 0; ui2 < entityLength; ui2++ )
                {
                    string keyName = entityKeys[ui2];

                    meta_api::json::v2::json@ entityValue = entity[keyName];

                    if( !entityValue.is_string() )
                        g_Logger.critical.print( "only strings allowed in entities at index {} for equipment {} at key {}", { string(ui), setName, keyName } );

                    entityData[ keyName ] = string( entityValue );
                }

                if( entityData.getSize() <= 0 )
                    continue;

                string className;

                if( !entityData.get( "classname", className ) || className.IsEmpty() )
                    g_Logger.critical.print( "Missing \"classname\" field for entity at index {} for equipment {}", { string(ui), setName } );

                if( g_MapConfig.MapLoading )
                {
                    CBaseEntity@ entityCreated = g_EntityFuncs.Create( className, g_vecZero, g_vecZero, false, null );

                    if( entityCreated is null )
                        g_Logger.critical.print( "Failed to create entity at index {} for equipment {}", { string(ui), setName } );

                    entityCreated.Precache();

                    entityCreated.pev.flags |= FL_KILLME;
                }

                this.m_Entities.insertLast( entityData );
            }
        }
    }

    void Equip( CBasePlayer@ player )
    {
        uint itemsLength = this.m_Items.length();

        for( uint ui = 0; ui < itemsLength; ui++ )
        {
            player.GiveNamedItem( this.m_Items[ui] );
        }

        uint entitiesLength = this.m_Entities.length();

        for( uint ui = 0; ui < entitiesLength; ui++ )
        {
            dictionary@ entData = this.m_Entities[ui];

            CBaseEntity@ entity = g_EntityFuncs.CreateEntity( string( entData[ "classname" ] ), entData );

            if( entity !is null )
            {
                entity.Touch( player );
            }
        }
    }
}

// Class representing a classification equipment
final class ASEquipmentCharacter
{
    private string m_Description;
    private uint[] m_HUDFade(3);
    private uint[] m_HUDMessage(3);
    private int m_LastEquipment;
    private array<ASEquipmentSet@> m_Sets;
    private array<ASEquipmentSet@> m_SetsEnforced;

    // dictionary constructor
    ASEquipmentCharacter() {}

    ASEquipmentCharacter( const Classification&in classification, meta_api::json::v2::json@ config )
    {
        // Get random sets
        meta_api::json::v2::json@ sets = config[ "sets" ];

        if( sets !is null )
        {
            uint setsLength = sets.Length();

            for( uint ui = 0; ui < setsLength; ui++ )
            {
                string setName = string( sets[ui] );

                ASEquipmentSet@ equipSet = gpEquipment.EquipmentSet( setName );

                if( equipSet is null )
                    g_Logger.critical.print( "undefined kit sets with name {} at index {} for character {}", { setName, string(ui), string(int(classification)) } );

                m_Sets.insertLast( equipSet );
            }

            // Randomize list
            for( uint ui = setsLength - 1; ui > 0; ui-- )
            {
                uint ui2 = Math.RandomLong( 0, ui );

                ASEquipmentSet@ temp = this.m_Sets[ui];
                @this.m_Sets[ui] = this.m_Sets[ui2];
                @this.m_Sets[ui2] = temp;
            }

            this.m_LastEquipment = -1;
        }

        // Get enforced sets
        meta_api::json::v2::json@ sets_enforce = config[ "sets_enforce" ];

        if( sets_enforce !is null )
        {
            uint setsLength = sets_enforce.Length();

            for( uint ui = 0; ui < setsLength; ui++ )
            {
                string setName = string( sets_enforce[ui] );

                ASEquipmentSet@ equipSet = gpEquipment.EquipmentSet( setName );

                if( equipSet is null )
                    g_Logger.critical.print( "undefined kit at sets_enforce with name {} at index {} for character {} in ", { setName, string(ui), string(int(classification)) } );

                m_SetsEnforced.insertLast( equipSet );
            }
        }

        this.m_Description = config.ValueOrDefault( "description", String::EMPTY_STRING );

        if( !this.m_Description.IsEmpty() )
        {
            meta_api::json::v2::json@ fade = config[ "fade" ];
            this.m_HUDFade[0] = uint( int( fade[0] ) );
            this.m_HUDFade[1] = uint( int( fade[1] ) );
            this.m_HUDFade[2] = uint( int( fade[2] ) );

            meta_api::json::v2::json@ notice = config[ "notice" ];
            this.m_HUDMessage[0] = uint( int( notice[0] ) );
            this.m_HUDMessage[1] = uint( int( notice[1] ) );
            this.m_HUDMessage[2] = uint( int( notice[2] ) );
        }
    }

    void Equip( CBasePlayer@ player )
    {
        if( ++this.m_LastEquipment >= int(m_Sets.length()) )
            this.m_LastEquipment = 0;

        ASEquipmentSet@ kitSet = this.m_Sets[this.m_LastEquipment];

        if( !this.m_Description.IsEmpty() )
        {
            string buffer;
            snprintf( buffer, this.m_Description, string( player.pev.netname ), kitSet.Description );
            auto msgParams = gpEquipment.MessageParams( this.m_HUDMessage[0], this.m_HUDMessage[1], this.m_HUDMessage[2] );
            g_PlayerFuncs.HudMessageAll( msgParams, buffer );
            g_PlayerFuncs.ClientPrintAll( HUD_PRINTCONSOLE, buffer );
        }

        if( this.m_HUDFade[0] != 0 || this.m_HUDFade[1] != 0 && this.m_HUDFade[2] != 0 )
        {
            Vector color( this.m_HUDFade[0], this.m_HUDFade[1], this.m_HUDFade[2] );
            g_PlayerFuncs.ScreenFade( player, color, 0.25f, 1.0f, 255.0f, FFADE_OUT );
            g_Scheduler.SetTimeout( @g_PlayerFuncs, "ScreenFade", 1.0f, @player, color, 1.0f, 0.0f, 255.0f, FFADE_IN );
        }
    }
}

final class ASEquipmentConfig : IConfigurable
{
    const string& GetName() const override {
        return "equipment";
    }

    const string GetSchema() const override {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Player Equipment",
            "description": "Player equipment kits configuration.",
            "allOf":
            [
                "IConfigurable"
            ],
            "properties":
            {
                "sets":
                {
                    "type": "object",
                    "title": "kit sets",
                    "description": "Set to equip, additional objects in within are entities to create and give to the player.",
                    "unevaluatedProperties": false,
                    "additionalProperties":
                    {
                        "type": "object",
                        "unevaluatedProperties": false,
                        "title": "Player Equipment",
                        "description": "Player equipment kits configuration.",
                        "properties":
                        {
                            "description":
                            {
                                "type": "string",
                                "description": "Description of the kit."
                            },
                            "items":
                            {
                                "type": "array",
                                "description": "List of weapon/item classname to give to the player.",
                                "items": { "type": "string" }
                            },
                            "entities":
                            {
                                "type": "array",
                                "description": "List of entities key-value pairs to create onto the player.",
                                "items":
                                {
                                    "unevaluatedProperties": true,
                                    "description": "Object representing a entity key-value pairs.",
                                    "type": "object"
                                }
                            }
                        }
                    }
                },
                "characters":
                {
                    "type": "array",
                    "minItems": 6,
                    "maxItems": 6,
                    "description": "Characters equipment config. each objects corresponds to Security, Scientist, Maintenance, HEV, Hazard and Operative respectivelly.",
                    "items":
                    {
                        "type": "object",
                        "unevaluatedProperties": false,
                        "properties":
                        {
                            "description":
                            {
                                "type": "string",
                                "description": "message used on equipment where %1 is the player name and %2 is the set's description."
                            },
                            "sets":
                            {
                                "type": "array",
                                "description": "List of sets names to pick up randomly.",
                                "items": { "type": "string" }
                            },
                            "fade":
                            {
                                "type": "array",
                                "minItems": 3,
                                "maxItems": 3,
                                "description": "RGB used for the fade effect.",
                                "items": { "type": "integer" }
                            },
                            "notice":
                            {
                                "type": "array",
                                "minItems": 3,
                                "maxItems": 3,
                                "description": "RGB used for the notice message.",
                                "items": { "type": "integer" }
                            },
                            "trigger":
                            {
                                "type": "string",
                                "description": "Target after equip, passes the player as !activator."
                            },
                            "sets_enforce":
                            {
                                "type": "array",
                                "description": "List of sets names to always equip.",
                                "items": { "type": "string" }
                            }
                        }
                    }
                }
            }
        }""";
    }

    private array<ASEquipmentCharacter@> m_Characters;

    // Return the list of character equipents where the index ordering equals to Classification enum.
    const array<ASEquipmentCharacter@>@ get_Characters()
    {
        return this.m_Characters;
    }

    private dictionary m_AllEquipments;

    // Return the map of all equipment sets
    const dictionary& get_Equipments()
    {
        return this.m_AllEquipments;
    }

    private HUDTextParams m_MessageParams;

    const HUDTextParams& MessageParams( uint red, uint green, uint blue )
    {
        this.m_MessageParams.r1 = red;
        this.m_MessageParams.g1 = green;
        this.m_MessageParams.b1 = blue;
        return this.m_MessageParams;
    }

    ASEquipmentSet@ EquipmentSet( const string&in setName )
    {
        ASEquipmentSet@ equipSet = null;
        this.m_AllEquipments.get( setName, @equipSet );
        return equipSet;
    }

    void Equip( CBasePlayer@ player )
    {
        ASEquipmentCharacter@ equipmentCharacter = this.m_Characters[ util::GetClass( player ) ];
        equipmentCharacter.Equip( player );
    }

    bool Register( meta_api::json::v2::json@ config ) override
    {
        this.m_AllEquipments.deleteAll();
        this.m_Characters.resize(0);

        // Register all sets
        {
            meta_api::json::v2::json@ sets = config[ "sets" ];
            const array<string>@ setsNames = sets.Keys;
            uint setsLength = sets.Length();

            for( uint ui = 0; ui < setsLength; ui++ )
            {
                string setName = setsNames[ui];
                meta_api::json::v2::json@ setProperties = sets[ setName ];
                ASEquipmentSet@ kitSet = ASEquipmentSet( setName, setProperties );
                this.m_AllEquipments[ setName ] = kitSet;
            }
        }

        // Register all character sets
        {
            meta_api::json::v2::json@ characters = config[ "characters" ];

            this.m_Characters = {
                @ASEquipmentCharacter( Classification::Security, characters[0] ),
                @ASEquipmentCharacter( Classification::Scientist, characters[1] ),
                @ASEquipmentCharacter( Classification::Maintenance, characters[2] ),
                @ASEquipmentCharacter( Classification::HEV, characters[3] ),
                @ASEquipmentCharacter( Classification::Hazard, characters[4] ),
                @ASEquipmentCharacter( Classification::Operative, characters[5] )
            };
        }

        this.m_MessageParams.x = 0;
        this.m_MessageParams.y = 0;
        this.m_MessageParams.effect = 2;
        this.m_MessageParams.a1 = 0;
        this.m_MessageParams.r2 = 240;
        this.m_MessageParams.g2 = 110;
        this.m_MessageParams.b2 = 0;
        this.m_MessageParams.a2 = 0;
        this.m_MessageParams.fadeinTime = 0.05f;
        this.m_MessageParams.fadeoutTime = 0.5f;
        this.m_MessageParams.holdTime = 1.2f;
        this.m_MessageParams.fxTime = 0.025f;
        this.m_MessageParams.channel = 5;

        return true;
    }
}

ASEquipmentConfig gpEquipment;

#if SERVER
RegisterCommand@ ASEquipmentTestCommand;
#endif
