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

final class ASInventoryItemsConfig : IConfigurable
{
    private
        dictionary m_Templates;

    const string& GetName() const override
    {
        return "inventory_items";
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "title": "Item inventory templates",
            "description": "Templates used for inventory_template entity.",
            "unevaluatedProperties": true,
            "additionalProperties":
            {
                "type": "object",
                "title": "Item Inventory template",
                "description": "Template name used for inventory_template's netname. Represents a entity key-value pairs",
                "unevaluatedProperties": true,
                "additionalProperties":
                {
                    "type": "string",
                    "description": "Key-value pair, strictly string."
                }
            }
        }""";
    }

    bool Register( btson@ config ) override
    {
        meta_api::json::v1::Deserialize( config.ToString(), this.m_Templates );

        g_CustomEntityFuncs.RegisterCustomEntity( "ASInventoryTemplate", "inventory_template" );

        // -TODO Parse ourselves instead. will be faster.
#if FALSE
        const array<string> templates = config.Keys;
        const uint length = templates.length();

        for( uint ui = 0; ui < length; ui++ )
        {
        }
#endif
        return false;
    }

    bool Find( const string&in templateName, dictionary@&out template )
    {
        return ( this.m_Templates.get( templateName, @template ) );
    }
}

ASInventoryItemsConfig g_InventoryTemplates;

class ASInventoryTemplate : ScriptBaseItemEntity
{
    dictionary@ m_Template;

    void Spawn()
    {
        self.pev.flags |= EdictFlags::FL_KILLME;

        string templateName = string( self.pev.netname );

        if( !g_InventoryTemplates.Find( templateName, @m_Template ) )
        {
            g_Logger.error.print( "[{}] Could not find template with name \"{}\" at {}", { g_InventoryTemplates.GetName(), templateName, self.pev.origin.ToString() } );
            return;
        }

        this.m_Template[ "target_on_activate" ] = "ASInventoryTemplate";

        CBaseEntity@ inventoryItem = g_EntityFuncs.CreateEntity( "item_inventory", this.m_Template, false );
        g_EntityFuncs.SetOrigin( inventoryItem, self.pev.origin );
        g_EntityFuncs.DispatchSpawn( inventoryItem.edict() );
    }
}

namespace ASInventoryTemplate
{
    void Activate( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE useType, float value )
    {
        g_Game.AlertMessage( at_console, "Activator: %1 Caller: %2\n", activator is null ? "null" : activator.GetClassname(), caller is null ? "null" : caller.GetClassname() );
    }
}
