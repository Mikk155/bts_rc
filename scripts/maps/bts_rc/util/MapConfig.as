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

#include "../../../mikk155/meta_api"
#include "../../../mikk155/meta_api/json"
#include "../../../mikk155/meta_api/json/v2"
#include "../../../mikk155/meta_api/json/v2/schema"
#include "../../../mikk155/meta_api/json/v2/fmt/ToArray"
#include "../../../mikk155/Server/chrono"

// Inherit from this interface to configure contexts from one key at the root json
// Register your contexts at ASMapConfig::Registry()
// Do NOT hold references to your object if Register can return false.
interface IConfigurableContext
{
    // Unique key name in the root json object
    const string& GetName() const;

    // Schema for validating your object. return null to avoid validation.
    meta_api::json::v2::json@ GetSchema() const;

    // Called at MapInit with the json object at the root containing GetName() as key.
    // Return false to remove reference to the context.
    // In this method you can reference "this" to any variable handle. See #if EXAMPLE
    bool Register( meta_api::json::v2::json@ config );
}

// -TODO Maybe to wiki?
#if EXAMPLE
final class TestSomething : IConfigurableContext
{
    const string& GetName() const { return "something" }

    meta_api::json::v2::json@ GetSchema() const { return null; }

    bool Register( meta_api::json::v2::json@ config )
    {
        // ASMapConfig gets rid of our unique reference
        if( config.ValueOrDefault( "active", false ) )
            return false;

        // ASMapConfig and gpSomething holds this object.
        @gpSomething = this;
        return true;
    }
}

TestSomething@ gpSomething = null;
#endif

final class ASMapConfig
{
    private
        meta_api::json::v2::json@ m_json;

    private bool
        m_ShouldWriteJsonObject = false;

    // Get a handle to the map configuration. this is null after MapInit
    const meta_api::json::v2::json@ get_json() {
        return this.m_json;
    }

    private
        Server::chrono@ m_chrono = Server::chrono();

    private
        Server::chrono@ m_chronoMapStart = Server::chrono();

    void __LoadMapConfiguration__()
    {
        meta_api::json::Error err;

        // Also used at __ValidateMapConfiguration__
        const string configPath = "store/bts_rc.json";

        if( !meta_api::json::v2::Deserialize( configPath, this.m_json, err ) )
        {
            @this.m_json = meta_api::json::v2::json();
        }

        string buffer;

        this.m_chrono.Stop();

        switch( err )
        {
            case meta_api::json::Error::OK:
            {
                snprintf( buffer, "Parsed map configuration JSON in %1:%2 seconds\n", this.m_chrono.Seconds, this.m_chrono.Miliseconds );
                break;
            }
            case meta_api::json::Error::FILE_NOT_FOUND:
            {
                snprintf( buffer, "Could not find \"scripts/maps/%1\" writing with defaults...\n", configPath );
                this.m_ShouldWriteJsonObject = true;
                break;
            }
            case meta_api::json::Error::EMPTY_INPUT:
            {
                snprintf( buffer, "Error parsing \"scripts/maps/%1\" the file is empty! writing with defaults...\n", configPath );
                this.m_ShouldWriteJsonObject = true;
                break;
            }
            case meta_api::json::Error::SYNTAX_ERROR:
            {
                snprintf( buffer, "Error parsing \"scripts/maps/%1\" check the above messages. ignoring external, configuration using defaults...\n", configPath );
                break;
            }
        }

        g_EngineFuncs.ServerPrint( "==============================================================\n" );
        g_EngineFuncs.ServerPrint( "==============================================================\n" );
        g_EngineFuncs.ServerPrint( buffer );
        g_EngineFuncs.ServerPrint( "==============================================================\n" );
        g_EngineFuncs.ServerPrint( "==============================================================\n" );
    }

    private
        array<IConfigurableContext@> m_Contexts(0);

    void Register( IConfigurableContext@ context )
    {
        if( g_Logger.info.active )
            g_Logger.info.print( "Initializing context {}", { context.GetName() } );

#if SERVER
        if( context.GetName().IsEmpty() )
            g_Logger.critical.print( "Got a IConfigurableContext with empty GetName method!" );

        for( uint ui = 0; ui < this.m_Contexts.length(); ui++ )
        {
            if( this.m_Contexts[ui].GetName() == context.GetName() )
                g_Logger.critical.print( "Got a IConfigurableContext with repeated GetName! \"{}\"", { context.GetName() } );
        }
#endif

        this.m_Contexts.insertLast( @context );
    }

    void __ValidateMapConfiguration__()
    {
        if( g_Logger.info.active )
            this.m_chrono.Restart();

        array<IConfigurableContext@> inactiveContexts(0);

        uint length = this.m_Contexts.length();

        for( uint ui = 0; ui < length; ui++ )
        {
            IConfigurableContext@ context = this.m_Contexts[ui];

            if( g_Logger.info.active )
            {
                g_EngineFuncs.ServerPrint( "==============================================================\n" );
                g_Logger.info.print( "Parsing context {} with priority {}", { context.GetName(), ui } );
                g_EngineFuncs.ServerPrint( "==============================================================\n" );
            }
            /*
            if( !this.m_json.Contains( context.GetName() ) )
                this.m_json.Set( context.GetName(), meta_api::json::v2::json() );

            meta_api::json::v2::json@ config = this.m_json[ context.GetName() ];
            */
            meta_api::json::v2::json@ config = this.m_json.ValueOrDefault( context.GetName(), null, true );

            meta_api::json::v2::json@ schema = context.GetSchema();

            if( g_Logger.trace.active )
                g_Logger.trace.print( "config: {}", { config.ToString() } );

            if( schema !is null )
            {
                if( !meta_api::json::v2::schema::Validate( config, schema, false ) )
                {
                    g_Logger.warning.print( "Error validating schema for IConfigurableContext with name \"{}\" using default values...", { context.GetName() } );
                    this.m_ShouldWriteJsonObject = true;
                }
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
        for( uint ui = 0; ui < length; ui++ ) {
            this.m_Contexts.removeAt( this.m_Contexts.findByRef( inactiveContexts[ui] ) );
        }

        if( g_Logger.info.active )
        {
            this.m_chrono.Stop();
            g_Logger.info.print( "Validated all map configuration JSON schemas in {}:{} seconds", { this.m_chrono.Seconds, this.m_chrono.Miliseconds } );
            this.m_chrono.Restart();
        }

        if( this.m_ShouldWriteJsonObject )
        {
            const string configPath = "store/bts_rc.json";

            meta_api::json::v2::Serialize( this.m_json, configPath,
                meta_api::json::parser::Indentation::OneTabSpace,
                meta_api::json::parser::Style::AllMan
            );

            if( g_Logger.info.active )
            {
                this.m_chrono.Stop();
                g_Logger.info.print( "Wrote to \"scripts/maps/{}\" in {}:{} seconds", { this.m_chrono.Seconds, this.m_chrono.Miliseconds } );
                this.m_chrono.Restart();
            }
        }
    }
}

ASMapConfig g_MapConfig;
