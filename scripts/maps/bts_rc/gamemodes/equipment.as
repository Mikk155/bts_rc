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

interface IEquipment
{
    // Equip the given player
    void Equip( CBasePlayer@ player ) const;
}

// Class representing set equipment
final class ASEquipment : IEquipment
{
    private array<string> m_Items;
    private array<dictionary> m_Entities;
    private RGBA m_HUDFade;
    private string m_Description;

    void Equip( CBasePlayer@ player ) const override
    {
        uint itemsLength = this.m_Items.length();

        for( uint ui = 0; ui < itemsLength; ui++ )
        {
            player.GiveNamedItem( m_Items[ui] );
        }

        uint entitiesLength = this.m_Entities.length();

        for( uint ui = 0; ui < entitiesLength; ui++ )
        {
            dictionary@ entData = m_Entities[ui];

            auto entity = g_EntityFuncs.CreateEntity( string( entData[ "classname" ] ), entData );

            if( entity !is null )
            {
                entity.Touch( player );
            }
        }
    }
}

// Class representing a classification equipment
final class ASEquipmentCharacter : IEquipment
{
    private array<ASEquipment@> m_Sets;

    // Last ASEquipment that was equiped to not repeat kits onto players
    private int m_LastEquipment;

    void Equip( CBasePlayer@ player ) const override
    {
    }
}

final class ASEquipmentConfig : IConfigurable
{
    // Container of character-equipments
    private array<ASEquipmentCharacter@> m_Characters(Classification::__Size__);
    private array<ASEquipment@> m_AllEquipments;

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
                    "unevaluatedProperties": true,
                    "properties":
                    {
                        "type": "array",
                        "description": "List of weapon/ammo/items to give to the player",
                        "items": { "type": "string" }
                    }
                }
            }
        }""";
    }

    bool Register( meta_api::json::v2::json@ config ) override
    {
        if( g_MapConfig.MapLoading )
        {
        }

        return true;
    }
}

ASEquipmentConfig@ gpEquipment;

#if SERVER
RegisterCommand@ ASEquipmentTestCommand;
#endif
