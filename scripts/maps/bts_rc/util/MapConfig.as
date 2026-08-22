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

void RegisterContexts()
{
    // Items
    g_MapConfig.Register( gpItemsConfig ); // Always active

    // Weapons
    g_MapConfig.Register( gpWeaponCrowbarConfig ); // Always active
    g_MapConfig.Register( gpWeaponScrewDriverConfig ); // Always active
    g_MapConfig.Register( gpWeaponPoolstickConfig ); // Always active
    g_MapConfig.Register( gpWeaponPipeWrenchConfig ); // Always active
    g_MapConfig.Register( gpWeaponPipeConfig ); // Always active
    g_MapConfig.Register( gpWeaponKnifeConfig ); // Always active
    g_MapConfig.Register( gpWeaponAxeConfig ); // Always active
    g_MapConfig.Register( gpWeaponBroomConfig ); // Always active
    g_MapConfig.Register( gpWeaponSpannerConfig ); // Always active
    g_MapConfig.Register( gpWeaponBerettaConfig ); // Always active
    g_MapConfig.Register( gpWeaponEagleConfig ); // Always active
    g_MapConfig.Register( gpWeaponGlockConfig ); // Always active
    g_MapConfig.Register( gpWeaponGlock17fConfig ); // Always active
    g_MapConfig.Register( gpWeaponGlock18Config ); // Always active
    g_MapConfig.Register( gpWeaponGlockSDConfig ); // Always active
    g_MapConfig.Register( gpWeaponSW637Config ); // Always active
    g_MapConfig.Register( gpWeaponPythonConfig ); // Always active
    g_MapConfig.Register( gpWeaponMP5Config ); // Always active
    g_MapConfig.Register( gpWeaponMP5GLConfig ); // Always active
    g_MapConfig.Register( gpWeaponUziConfig ); // Always active
    g_MapConfig.Register( gpWeaponUziSDConfig ); // Always active
    g_MapConfig.Register( gpWeaponM4Config ); // Always active
    g_MapConfig.Register( gpWeaponM4SDConfig ); // Always active
    g_MapConfig.Register( gpWeaponM16Config ); // Always active
    g_MapConfig.Register( gpWeaponM16SDConfig ); // Always active
    g_MapConfig.Register( gpWeaponSniperRifleConfig ); // Always active
    g_MapConfig.Register( gpWeaponShotgunConfig ); // Always active
    g_MapConfig.Register( gpWeaponSBShotgunConfig ); // Always active
    g_MapConfig.Register( gpWeaponSawConfig ); // Always active
    g_MapConfig.Register( gpWeaponSawSDConfig ); // Always active
    g_MapConfig.Register( gpWeaponM79Config ); // Always active
    g_MapConfig.Register( gpWeaponXBowConfig ); // Always active
    g_MapConfig.Register( gpWeaponHandGrenadeConfig ); // Always active
    g_MapConfig.Register( gpWeaponFlamethrowerConfig ); // Always active
    g_MapConfig.Register( gpWeaponFlareConfig ); // Always active
    g_MapConfig.Register( gpWeaponFlareGunConfig ); // Always active
    g_MapConfig.Register( gpWeaponMedkitConfig ); // Always active
    g_MapConfig.Register( gpWeaponFlashlight ); // Always active

    g_MapConfig.Register( g_WeaponsConfig ); // Always active

    g_MapConfig.Register( gpEquipment ); // Always active

    // No ordering required:
    g_MapConfig.Register( ASBloodPuddleConfig() );
    g_MapConfig.Register( ASDynamicAmmoConfig() );
    g_MapConfig.Register( ASZombieUncrabConfig() );
    g_MapConfig.Register( ASDeathDropConfig() );
    g_MapConfig.Register( ASAimingLasersConfig() );
    g_MapConfig.Register( ASBlackOpsFlashbang() );
    g_MapConfig.Register( ASGruntEngineer() );
    g_MapConfig.Register( ASWallRechargerConfig() ); // Always active

    g_MapConfig.Register( gpRoboGrunt ); // Always active
    g_MapConfig.Register( gpRoboGruntBoss ); // Always active
    g_MapConfig.Register( gpZombieEngineer ); // Always active
    g_MapConfig.Register( gpPanthereyeConfig ); // Always active
}

#include "../../../mikk155/meta_api"
#include "../../../mikk155/meta_api/json/v2"
#include "../../../mikk155/meta_api/json/v2/schema"
#include "../../../mikk155/meta_api/json/v2/fmt/ToArray"
#include "../../../mikk155/Server/chrono"

// Inherit from this interface to configure contexts from one key at the root json
// Register your contexts at ASMapConfig::Registry()
// Do NOT hold references to your object if Register can return false.
interface IConfigurable
{
    // Unique key name in the root json object
    const string& GetName() const;

    // Schema for validating your object. return null to avoid validation.
    // In this project the key "allOf" in your root object works differently than in regular schema validations,
    // It is an array of string containing key names defined in the schema's "$defs" which you can insert properties using ASMapConfig::RegisterSchemaDefinition
    // Whose values of the property in $defs will be added to your object's properties but not overriden so you can have custom default values, descriptions and the likes.
    const string GetSchema() const;

    // Called at MapInit with the json object at the root containing GetName() as key.
    // Return false to remove reference to the context.
    // In this method you can reference "this" to any variable handle.
    bool Register( meta_api::json::v2::json@ config );
}

final class ASMapConfig
{
    private
        meta_api::json::v2::json@ m_json;

    private
        meta_api::json::v2::json@ m_defaults;

    private
        meta_api::json::v2::json@ m_GlobalSchema = meta_api::json::v2::json();
    private
        meta_api::json::v2::json@ m_GlobalSchemaDefinitions = meta_api::json::v2::json();
    private
        meta_api::json::v2::json@ m_GlobalSchemaProperties = meta_api::json::v2::json();

    private
        bool m_MapInit = true;

        // Return true if we're still at MapInit parsing the config for a first time
        const bool get_MapLoading() const
        {
            return m_MapInit;
        }

    private
        bool m_AllowReload = false;

    private
        bool m_ShouldWriteServerConfig = false;

    private
        bool m_ShouldWriteSchema = false;

    const bool WritingSchema() const {
// Always write schema & defaults while on development.
#if SERVER
        if( true )
            return true;
#endif
        return this.m_ShouldWriteSchema;
    }

    private
        array<IConfigurable@> m_Contexts(0);

    private
        Server::chrono@ m_chrono;

    // Get a handle to the map configuration. this is null after MapInit
    const meta_api::json::v2::json@ get_json()
    {
        return this.m_json;
    }

    // Register a schema "$def" property to use globaly
    bool RegisterSchemaDefinition( const string&in name, const string&in value )
    {
        if( this.m_GlobalSchemaDefinitions.Contains( name ) )
        {
            if( g_Logger.warning.active )
                g_Logger.warning.print( "Failed to parse RegisterSchemaDefinition() for \"{}\" key name already exists!", { name } );
            return false;
        }

        meta_api::json::v2::json@ definition;
        meta_api::json::Error err;

        if( meta_api::json::v2::Deserialize( value, definition, err ) && definition !is null )
        {
            this.m_GlobalSchemaDefinitions.Set( name, definition );
            return true;
        }

        switch( err )
        {
            case meta_api::json::Error::SYNTAX_ERROR:
                g_Logger.critical.print( "Failed to parse RegisterSchemaDefinition() for \"{}\" syntax error!", { name } );
            break;
        }

        return false;
    }

    // This is parsed by python builders. do not change.
    const string __GetDefaultConfig__()
    {
        return """scripts/maps/bts_rc/default_config.json""";
    }

    void __LoadMapConfiguration__()
    {
        meta_api::json::Error err;

        if( m_chrono is null )
        {
            @m_chrono = Server::chrono();
        }

        if( !meta_api::json::v2::Deserialize( this.__GetDefaultConfig__(), m_defaults ) )
        {
            g_Logger.critical.print( "Failed to parse weapon data! \"const string __GetDefaultConfig__()\"" );
            array<int> arr(0);
            arr[1]; // When SetException x[
        }

        if( !meta_api::json::v2::Deserialize( "store/bts_rc.json", this.m_json, err ) )
        {
            @this.m_json = meta_api::json::v2::json();
        }

        string buffer = "Error parsing \"scripts/maps/store/bts_rc.json\"\n";

        this.m_chrono.Stop();

        switch( err )
        {
            case meta_api::json::Error::OK:
            {
                snprintf( buffer, "Parsed map configuration JSON in %1:%2 seconds\n", this.m_chrono.Seconds, this.m_chrono.Miliseconds );
                break;
            }
            case meta_api::json::Error::FILE_NOT_FOUND:
            case meta_api::json::Error::EMPTY_INPUT:
            {
                this.m_ShouldWriteSchema = true;
                this.m_ShouldWriteServerConfig = true;
                break;
            }
            case meta_api::json::Error::SYNTAX_ERROR:
            default:
            {
                break;
            }
        }

        g_EngineFuncs.ServerPrint( "==============================================================\n" );
        g_EngineFuncs.ServerPrint( "==============================================================\n" );
        g_EngineFuncs.ServerPrint( buffer );
        g_EngineFuncs.ServerPrint( "==============================================================\n" );
        g_EngineFuncs.ServerPrint( "==============================================================\n" );

        if( MapLoading )
        {
            this.RegisterSchemaDefinition( "IConfigurable", """{
                "active":
                {
                    "type": "boolean",
                    "default": true,
                    "description": "Should this context be active?"
                }
            }""" );
        }
    }

    void Register( IConfigurable@ context )
    {
        if( g_Logger.info.active )
            g_Logger.info.print( "Initializing context {}", { context.GetName() } );

#if SERVER
        if( context.GetName().IsEmpty() )
            g_Logger.critical.print( "Got a IConfigurable with empty GetName method!" );

        for( uint ui = 0; ui < this.m_Contexts.length(); ui++ )
        {
            if( this.m_Contexts[ui].GetName() == context.GetName() )
                g_Logger.critical.print( "Got a IConfigurable with repeated GetName! \"{}\"", { context.GetName() } );
        }
#endif

        this.m_Contexts.insertLast( @context );
    }

    // Get a configurable context by name
    // return null if not found or is inactive.
    IConfigurable@ GetContext( const string&in name )
    {
        uint length = this.m_Contexts.length();

        for( uint ui = 0; ui < length; ui++ )
        {
            IConfigurable@ context = this.m_Contexts[ui];

            if( context.GetName() == name )
                return @context;
        }
        return null;
    }

    void __ValidateMapConfiguration__()
    {
        if( g_Logger.info.active )
            this.m_chrono.Restart();

        array<IConfigurable@> inactiveContexts(0);

        uint length = this.m_Contexts.length();

        if( MapLoading )
        {
            m_GlobalSchema.Set( "$schema", "https://json-schema.org/draft/2020-12/schema" );
            m_GlobalSchema.Set( "type", "object" );
            m_GlobalSchema.Set( "unevaluatedProperties", false );
                auto@ properties = meta_api::json::v2::json();
                    auto@ schemaProperty = meta_api::json::v2::json();
                        schemaProperty.Set( "type", "string" );
                        schemaProperty.Set( "description", "Reference to the JSON schema file used for validation and editor hinting." );
                    this.m_GlobalSchemaProperties.Set( "$schema", schemaProperty );
                    auto@ allowReloadPoperty = meta_api::json::v2::json();
                        allowReloadPoperty.Set( "type", "boolean" );
                        allowReloadPoperty.Set( "description", "When true the map scripts will keep json schemas in memory and register a command to reload json files run time." );
                    this.m_GlobalSchemaProperties.Set( "allow_reload", allowReloadPoperty );
            m_GlobalSchema.Set( "properties", this.m_GlobalSchemaProperties );
        }

        for( uint ui = 0; ui < length; ui++ )
        {
            IConfigurable@ context = this.m_Contexts[ui];

            string schemaString = context.GetSchema();

            if( schemaString.IsEmpty() )
            {
                if( g_Logger.info.active )
                    g_Logger.info.print( "Skipping context {} at priority {} which returned an empty schema.", { context.GetName(), ui } );
                continue;
            }

            meta_api::json::v2::json@ config = this.m_json.ValueOrDefault( context.GetName(), null, true );

            if( g_Logger.info.active )
            {
                g_Logger.info.print( "Validating context {} at priority {} with {} variables", { context.GetName(), ui, config.Count() } );

                if( g_Logger.trace.active && config.Length() > 0 )
                    g_Logger.trace.print( "serialized config: {}", { config.ToString() } );
            }

            meta_api::json::v2::json@ schema;

            meta_api::json::Error err;

#if REMOVED_FROM_VALIDATION
            if( schemaString.IsEmpty() )
            {
#if SERVER
                if( g_Logger.warning.active )
                    g_Logger.warning.print( "Got empty schema for \"{}\" is this intended by design? If so ignore this warning.", { context.GetName() } );
#endif
                // HACK onto empty string schemas since unevaluated properties
                this.m_GlobalSchemaProperties.Set( context.GetName(), defaultEmptySchema );
            }
            else
#endif
            if( meta_api::json::v2::Deserialize( schemaString, schema, err ) && schema !is null )
            {
                auto@ defaultConfigurations = m_defaults[ context.GetName() ];

                // Inject default configuration data
                if( defaultConfigurations !is null )
                {
                    auto@ weaponProperties = schema.ValueOrDefault( "properties", null, true );

                    uint defConfigLength = defaultConfigurations.Length();
                    const array<string>@ wpnKeys = defaultConfigurations.Keys;

                    for( uint ui2 = 0; ui2 < defConfigLength; ui2++ )
                    {
                        string keyName = wpnKeys[ ui2 ];
                        auto@ defaultValue = defaultConfigurations[ keyName ];
                        if( defaultValue !is null )
                        {
                            auto@ weaponProperty = weaponProperties.ValueOrDefault( keyName, null, true );
                            weaponProperty.Set( "default", defaultValue );
                        }
                    }
                }

                if( schema.Contains( "allOf" ) )
                {
                    auto@ allOf = schema[ "allOf" ];

                    if( allOf.is_array() )
                    {
                        auto@ schemaProperties = schema.ValueOrDefault( "properties", null, true );

                        uint allOfLength = allOf.Length();

                        for( uint uia = 0; uia < allOfLength; uia++ )
                        {
                            auto@ allOfItem = allOf[uia];
#if SERVER
                            if( !allOfItem.is_string() )
                            {
                                g_Logger.error.print( "schema for {} contains \"allOf\" but value at index {} is not a string type!", { context.GetName(), uia } );
                                continue;
                            }
#endif
                            string copyKeyName = string( allOfItem );
#if SERVER
                            if( !this.m_GlobalSchemaDefinitions.Contains( copyKeyName ) )
                            {
                                g_Logger.error.print( "schema for {} contains \"allOf\" with value {} at index {} but does not exists in the schema definition!", { context.GetName(), copyKeyName, uia } );
                                continue;
                            }
#endif
                            auto@ definition = this.m_GlobalSchemaDefinitions[ copyKeyName ];
                            uint definitionLength = definition.Length();
                            for( uint uid = 0; uid < definitionLength; uid++ )
                            {
                                auto@ property = definition[uid];
                                uint propertyLength = property.Length();
                                auto@ schemaProperty = schemaProperties.ValueOrDefault( property.Name, null, true );
                                for( uint uip = 0; uip < propertyLength; uip++ )
                                {
                                    auto@ val = property[uip];
                                    if( !schemaProperty.Contains( val.Name ) )
                                        schemaProperty.Set( val.Name, val );
                                }
                            }
                        }
                        schema.Remove( "allOf" );
                    }
                    else
                    {
                        g_Logger.error.print( "schema for {} contains \"allOf\" but is not an array type!", { context.GetName() } );
                    }
                }
                this.m_GlobalSchemaProperties.Set( context.GetName(), schema );
            }
            else
            {
                switch( err )
                {
                    case meta_api::json::Error::SYNTAX_ERROR:
                        g_Logger.critical.print( "Failed to parse GetSchema() for context \"{}\"", { context.GetName() } );
                    break;
                }
            }
        }

        if( !meta_api::json::v2::schema::Validate( this.m_json, this.m_GlobalSchema, false ) )
        {
            if( g_Logger.warning.active )
                g_Logger.warning.print( "Error validating some values for json. Using default values..." );
        }

        for( uint ui = 0; ui < length; ui++ )
        {
            IConfigurable@ context = this.m_Contexts[ui];
            auto@ config = this.m_json[ context.GetName() ];

            if( g_Logger.info.active )
            {
                g_Logger.info.print( "==============================================================" );
                if( config is null )
                {
                    if( g_Logger.warning.active )
                        g_Logger.warning.print( "Got empty json for \"{}\" is this intended by design? If so ignore this warning.", { context.GetName() } );
                }
                else
                {
                    g_Logger.info.print( "Registering context {} at priority {} with {} variables", { context.GetName(), ui, config.Count() } );

                    if( g_Logger.trace.active && config.Length() > 0 )
                        g_Logger.trace.print( "serialized config: {}", { config.ToString() } );
                }
                g_Logger.info.print( "==============================================================" );
            }

            bool result = context.Register( config );

            if( !result )
            {
                if( g_Logger.info.active )
                    g_Logger.info.print( "Context {} set as inactive. Dereferencing...", { context.GetName() } );

                inactiveContexts.insertLast( context );
            }
        }

        // Remove inactive items separatelly since the above loop is ordered x[
        length = inactiveContexts.length();
        for( uint ui = 0; ui < length; ui++ )
        {
            this.m_Contexts.removeAt( this.m_Contexts.findByRef( inactiveContexts[ui] ) );
        }

        if( g_Logger.info.active )
        {
            this.m_chrono.Stop();
            g_Logger.info.print( "Validated all map configuration JSON schemas in {}:{} seconds", { this.m_chrono.Seconds, this.m_chrono.Miliseconds } );
            this.m_chrono.Restart();
        }

        if( this.m_ShouldWriteServerConfig && MapLoading )
        {
            File@ file = g_FileSystem.OpenFile( "scripts/maps/store/bts_rc.json", OpenFile::WRITE );
            if( file !is null )
            {
#if FALSE
                // For some reason this is adding double new lines
                file.Write( """/**   This file has been generated by bts_rc and it's used for external configuration.
*   Use Visual studio code or any other editor that support schema validation to get more specific information on configuring the map.
*   The file "bts_rc_defaults.json next to this file is unused by the map but generated by it with all the default values from the map.
*   Check the web site documentation if you can't validate schema through a proper editor: https://mikk155.github.io/bts_rc/
**/
{
    "$schema": "bts_rc_schema.json"
}
""" );
#endif
                file.Write( "/**\n*   This file has been generated by bts_rc and it's used for external configuration.\n*   Use Visual studio code or any other editor that support schema validation to get more specific information on configuring the map.\n*   The file \"bts_rc_defaults.json\" next to this file is unused by the map but generated by it with all the default values from the map.\n*   Check the web site documentation if you can't validate schema through a proper editor: https://mikk155.github.io/bts_rc/\n**/\n{\n    \"$schema\": \"bts_rc_schema.json\"\n}\n" );
                file.Close();
            }
        }

        if( this.WritingSchema() )
        {
            meta_api::json::parser::Style schemaStyle = meta_api::json::parser::Style::AllMan;
            meta_api::json::parser::Indentation schemaIndentation = meta_api::json::parser::Indentation::OneTabSpace;

            // Write out schemas
            meta_api::json::v2::Serialize( this.m_GlobalSchema, "store/bts_rc_schema.json", schemaIndentation, schemaStyle );

            // Write out default values for reference
            this.m_defaults.Set( "$schema", "bts_rc_schema.json" );
            meta_api::json::v2::Serialize( this.m_defaults, "store/bts_rc_defaults.json", schemaIndentation, schemaStyle );

            if( g_Logger.info.active )
            {
                this.m_chrono.Stop();
                g_Logger.info.print( "Wrote to \"scripts/maps/store/bts_rc*\" in {}:{} seconds", { this.m_chrono.Seconds, this.m_chrono.Miliseconds } );
                this.m_chrono.Restart();
            }
        }

#if SERVER
        this.m_AllowReload = true;
#endif
        this.m_AllowReload = this.m_json.ValueOrDefault( "allow_reload", this.m_AllowReload, false );

        if( !this.m_AllowReload )
        {
            // Let the garbage collector remove these later, may improve loading time.
            // this.m_json.Clear();
            // this.m_defaults.Clear();
            // this.m_GlobalSchema.Clear();
            // this.m_GlobalSchemaDefinitions.Clear();
            // this.m_GlobalSchemaProperties.Clear();

            @this.m_json = null;
            @this.m_defaults = null;
            @this.m_GlobalSchema = null;
            @this.m_GlobalSchemaDefinitions = null;
            @this.m_GlobalSchemaProperties = null;
        }

        @this.m_chrono = null;

        this.m_MapInit = false;
    }

    void __MapInitialize__()
    {
        auto chrono = Server::chrono();
        __LoadMapConfiguration__();
        this.Register( g_Logger );
        RegisterContexts();
        this.Register( gpCharactersConfig );
        this.__ValidateMapConfiguration__();
        chrono.Stop();

        string buffer;
        snprintf( buffer, "Done with all map configuration in %1:%2 seconds\n", chrono.Seconds, chrono.Miliseconds );
        g_EngineFuncs.ServerPrint( buffer );

        if( this.m_AllowReload )
        {
            RegisterCommand( "update", "", "Updates the json config for all contexts",
            @CommandCallback( function( CBasePlayer@ player, array<string>@ arguments )
            {
                auto chrono = Server::chrono();

                g_MapConfig.__LoadMapConfiguration__();
                g_MapConfig.__ValidateMapConfiguration__();

                chrono.Stop();

                string buffer;
                snprintf( buffer, "Done with all map configuration in %1:%2 seconds\n", chrono.Seconds, chrono.Miliseconds );
                g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );
            } ), true, "json" );
        }
    }
}

ASMapConfig g_MapConfig;
