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

#include "../../../mikk155/Logger/v2"
#include "../../../mikk155/Logger/v2/time"
#include "../../../mikk155/Logger/v2/file"

final class ASLoggingSystem
{
    bool get_Active() property {
        return bool( this.Data[ "active" ] );
    }

    bool get_WriteFile() property {
        return bool( this.Data[ "file" ] );
    }

    private
        dictionary m_data;

    dictionary@ get_Data() property {
        return @this.m_data;
    }

    void Print( string&in message )
    {
        while( message.Length() > 1 )
        {
            uint length = Math.min( 128, int( message.Length() ) );
            string bufferPrint = message.SubString( 0, length );
            message = message.SubString( length, String::INVALID_INDEX );

            if( g_EngineFuncs.IsDedicatedServer() )
            {
                g_EngineFuncs.ServerPrint( bufferPrint );
            }
            // Host is not yet fully connected, print to server console not network client
            else if( g_Engine.time < 5 )
            {
                auto host = g_PlayerFuncs.FindPlayerByIndex(0);

                if( host is null || !host.IsConnected() )
                {
                    g_EngineFuncs.ServerPrint( bufferPrint );
                }
            }

            g_PlayerFuncs.ClientPrintAll( HUD_PRINTCONSOLE, bufferPrint );
        }
    }

    CScheduledFunction@ __WriteDatafn__;

    void WriteData()
    {
        if( this.__WriteDatafn__ is null )
        {
            @this.__WriteDatafn__ = g_Scheduler.SetTimeout( @this, "__WriteData__", 0.5f );
        }
    }

    void __WriteData__()
    {
        auto@ schema = meta_api::json::v2::json();
            schema.Set( "$schema", "https://json-schema.org/draft/2020-12/schema" );
            schema.Set( "type", "object" );
            schema.Set( "unevaluatedProperties", false );
            schema.Set( "title", "Logging settings" );
            schema.Set( "description", "Default state for different loggers." );
            auto@ properties = schema.ValueOrDefault( "properties", null, true );
                auto@ schemaReference = properties.ValueOrDefault( "$schema", null, true );
                    schemaReference.Set( "type", "string" );
                auto@ active = properties.ValueOrDefault( "active", null, true );
                    active.Set( "type", "boolean" );
                    active.Set( "description", "Whatever logging is enabled" );
                auto@ file = properties.ValueOrDefault( "file", null, true );
                    file.Set( "type", "boolean" );
                    file.Set( "description", "Whatever logging to bts_rc.log is active" );
            auto@ additionalProperties = schema.ValueOrDefault( "additionalProperties", null, true );
                additionalProperties.Set( "description", "Settings for the logger with the given key name." );
                auto@ critical = additionalProperties.ValueOrDefault( "critical", null, true );
                    critical.Set( "description", "Critical level. printed when something went really wrong." );
                    critical.Set( "type", "string" );
                    critical.Set( "default", "true" );
                auto@ error = additionalProperties.ValueOrDefault( "error", null, true );
                    error.Set( "description", "Error level. printed when something went wrong." );
                    error.Set( "type", "string" );
                    error.Set( "default", "true" );
                auto@ warning = additionalProperties.ValueOrDefault( "warning", null, true );
                    warning.Set( "description", "Warning level. printed when something may be wrong." );
                    warning.Set( "type", "string" );
                    warning.Set( "default", "true" );
                auto@ info = additionalProperties.ValueOrDefault( "info", null, true );
                    info.Set( "description", "Information level. printed when something is being informed." );
                    info.Set( "type", "string" );
                auto@ debug = additionalProperties.ValueOrDefault( "debug", null, true );
                    debug.Set( "description", "Debug level. Like info but more spaming." );
                    debug.Set( "type", "string" );
                auto@ trace = additionalProperties.ValueOrDefault( "trace", null, true );
                    trace.Set( "description", "Trace level. Like debug but more spaming." );
                    trace.Set( "type", "string" );

        meta_api::json::v2::Serialize(
            schema,
            "store/bts_rc_log_schema.json",
            meta_api::json::parser::Indentation::OneSpace,
            meta_api::json::parser::Style::AllMan
        );

        meta_api::json::v2::json@ serializationFix = meta_api::json::v2::json();
        serializationFix.Set( "file", bool( this.Data[ "file" ] ) );
        serializationFix.Set( "active", bool( this.Data[ "active" ] ) );
        serializationFix.Set( "$schema", "bts_rc_log_schema.json" );

        const array<string>@ keyNames = this.Data.getKeys();
        const uint length = keyNames.length();

        for( uint ui = 0; ui < length; ui++ )
        {
            string keyName = keyNames[ui];

            dictionary@ obj;
            if( this.Data.get( keyName, @obj ) && obj !is null )
            {
                meta_api::json::v2::json@ obj2 = serializationFix.ValueOrDefault( keyName, null, true );

                const array<string>@ levelNames = obj.getKeys();
                const uint length2 = levelNames.length();

                for( uint ui2 = 0; ui2 < length2; ui2++ )
                {
                    string levelName = levelNames[ui2];
                    obj2.Set( levelName, bool( obj[ levelName ] ) );
                }
            }
        }

        meta_api::json::v2::Serialize(
            serializationFix,
            "store/bts_rc_log.json",
            meta_api::json::parser::Indentation::OneSpace,
            meta_api::json::parser::Style::AllMan
        );

        g_Scheduler.RemoveTimer( this.__WriteDatafn__ );
        @this.__WriteDatafn__ = null;
    }

    ASLoggingSystem()
    {
        this.Data[ "active" ] = ( meta_api::json::v1::Deserialize( "store/bts_rc_log.json", this.m_data ) && bool( this.m_data[ "active" ] ) );
    }

    void __Init__()
    {
        RegisterCommand(
            "output",
            "",
            "Write current config into svencoop/scripts/maps/store/bts_rc_log.json",
            function( CBasePlayer@ player, array<string>@ arguments )
            {
                g_PlayerFuncs.ClientPrint( player, HUD::HUD_PRINTCONSOLE, "Wrote to \"svencoop/scripts/maps/store/bts_rc_log.json\"\n" );
                g_PlayerFuncs.ClientPrint( player, HUD::HUD_PRINTCONSOLE, "Next time the map reloads the config will be filled.\n" );
                gpLogging.Data[ "active" ] = true;
                gpLogging.Data[ "file" ] = false;
                dictionary@ logData = {
                    { "critical", true },
                    { "error", true },
                    { "warning", true },
                    { "info", false },
                    { "debug", false },
                    { "trace", false }
                };
                @gpLogging.Data[ "global" ] = logData;
                gpLogging.WriteData();
            },
            true,
            "log"
        );

        if( !this.Active )
        {
            Logger::Config.SetDisableAllLoggers( true );
            this.Print( "[bts_rc] Logging system disabled. use \"bts_rc log output\" to instantiate a configuration file.\n" );
            return;
        }

        RegisterCommand(
            "toggle",
            "[Logger name] [Logger level]",
            "Toggle logger level for the given logger name",
            function( CBasePlayer@ player, array<string>@ arguments )
            {
                if( arguments is null || arguments.length() < 2 )
                {
                    g_PlayerFuncs.ClientPrint( player, HUD::HUD_PRINTCONSOLE, "Not enough arguments\n" );
                    return;
                }

                string loggerName = arguments[0];
                string loggerLevelName = arguments[1];

                Logger@ logger = Logger::First( loggerName );

                if( logger is null )
                {
                    g_PlayerFuncs.ClientPrint( player, HUD::HUD_PRINTCONSOLE, "Logger with name \"" + loggerName + "\" does not exists!\n" );
                    return;
                }

                Logger::Level@ level = logger.GetLevel( loggerLevelName );

                if( level is null )
                {
                    g_PlayerFuncs.ClientPrint( player, HUD::HUD_PRINTCONSOLE, "Logger level with name \"" + loggerLevelName + "\" does not exists!\n" );
                    return;
                }

                const string dataLoggerName = ( logger.name.IsEmpty() ? "global" : logger.name );
                dictionary@ logData;

                if( !gpLogging.Data.get( dataLoggerName, @logData ) || logData is null )
                {
                    @logData = {};
                    @gpLogging.Data[ dataLoggerName ] = logData;
                }

                level.active = !level.active;
                logData[ loggerLevelName ] = level.active;
                g_PlayerFuncs.ClientPrint( player, HUD::HUD_PRINTCONSOLE, "Logger \"" + dataLoggerName + "\" level \"" + loggerLevelName + "\" has been set to \"" + String::from_bool( level.active ) + "\"\n" );
                gpLogging.WriteData();
            },
            true,
            "log"
        );

        RegisterCommand(
            "set",
            "[Logger level] [state]",
            "Set logger level state for all registered loggers",
            function( CBasePlayer@ player, array<string>@ arguments )
            {
                if( arguments is null || arguments.length() < 2 )
                {
                    g_PlayerFuncs.ClientPrint( player, HUD::HUD_PRINTCONSOLE, "Not enough arguments\n" );
                    return;
                }

                const string loggerLevelName = arguments[0];
                bool state;

                string normalized = arguments[1];
                normalized.ToLowercase();

                if( normalized == "true" || normalized == "1" )
                {
                    state = true;
                }
                else if( normalized == "false" || normalized == "0" )
                {
                    state = false;
                }
                else
                {
                    g_PlayerFuncs.ClientPrint( player, HUD::HUD_PRINTCONSOLE, "State must be true, false, 1 or 0\n" );
                    return;
                }

                Logger::Iterator it;
                Logger@ logger;

                while( it.Next( logger ) )
                {
                    Logger::Level@ level = logger.GetLevel( loggerLevelName );

                    if( level is null )
                    {
                        g_PlayerFuncs.ClientPrint( player, HUD::HUD_PRINTCONSOLE, "Logger level with name \"" + loggerLevelName + "\" does not exists!\n" );
                        return;
                    }

                    const string dataLoggerName = ( logger.name.IsEmpty() ? "global" : logger.name );
                    dictionary@ logData;

                    if( !gpLogging.Data.get( dataLoggerName, @logData ) || logData is null )
                    {
                        @logData = {};
                        @gpLogging.Data[ dataLoggerName ] = logData;
                    }

                    level.active = state;
                    logData[ loggerLevelName ] = state;
                }

                g_PlayerFuncs.ClientPrint( player, HUD::HUD_PRINTCONSOLE, "All logger's level \"" + loggerLevelName + "\" has been set to \"" + String::from_bool( state ) + "\"\n" );
                gpLogging.WriteData();
            },
            true,
            "log"
        );


        RegisterCommand(
            "file",
            "[state]",
            "Set logger file write state",
            function( CBasePlayer@ player, array<string>@ arguments )
            {
                if( arguments is null || arguments.length() < 1 )
                {
                    g_PlayerFuncs.ClientPrint( player, HUD::HUD_PRINTCONSOLE, "Not enough arguments\n" );
                    return;
                }

                string normalized = arguments[0];
                normalized.ToLowercase();

                if( normalized == "true" || normalized == "1" )
                {
                    gpLogging.Data[ "file" ] = true;
                }
                else if( normalized == "false" || normalized == "0" )
                {
                    gpLogging.Data[ "file" ] = false;
                }
                else
                {
                    g_PlayerFuncs.ClientPrint( player, HUD::HUD_PRINTCONSOLE, "State must be true, false, 1 or 0\n" );
                    return;
                }

                g_PlayerFuncs.ClientPrint( player, HUD::HUD_PRINTCONSOLE, "Set logging file write to \"" + String::from_bool( gpLogging.WriteFile ) + "\"\n" );
                gpLogging.WriteData();
            },
            true,
            "log"
        );

        Logger::Config
        .SetGlobalName( "bts_rc" )
        .SetAppendNewline( true )
        .SetPrefixWithGlobalName( true )
        .SetSensitiveArguments( true )
        .SetSensitiveKeywordArguments( true )
        .SetCreatedCallback( function( const string&in name, Logger@ logger )
        {
            dictionary@ logData;

            if( !gpLogging.Data.get( name, @logData ) || logData is null )
            {
                @logData = {
                    { "critical", true },
                    { "error", true },
                    { "warning", true },
                    { "info", false },
                    { "debug", false },
                    { "trace", false }
                };

                @gpLogging.Data[ name ] = logData;
                gpLogging.WriteData();
            }
            else
            {
                const array<string>@ levelNames = logData.getKeys();
                const uint length = levelNames.length();

                for( uint ui = 0; ui < length; ui++ )
                {
                    string levelName = levelNames[ui];
                    bool state = bool( logData[ levelName ] );
                    Logger::Level@ level = logger.GetLevel( levelName );

                    if( level !is null )
                    {
                        level.active = state;
                    }
                }
            }
        } )
        .SetCallback( function( string&in message, const Logger::Level&in level )
        {
            Logger::time::format( message, message );

            if( gpLogging.WriteFile )
            {
                Logger::file::write( message, "bts_rc.log" );
            }

            gpLogging.Print( message );

            return true;
        } );

        // Find existent loggers not catched in SetCreatedCallback
        Logger::Iterator it;
        Logger@ logger;

        while( it.Next( logger ) )
        {
            string objName = ( logger.name.IsEmpty() ? "global" : logger.name );

            dictionary@ loggerObject;

            if( !this.Data.get( objName, @loggerObject ) || loggerObject is null )
                continue;

            const array<string>@ levelNames = loggerObject.getKeys();
            const uint length = levelNames.length();

            for( uint ui = 0; ui < length; ui++ )
            {
                string levelName = levelNames[ui];
                bool state = bool( loggerObject[ levelName ] );
                Logger::Level@ level = logger.GetLevel( levelName );

                if( level !is null )
                {
                    level.active = state;
                }
            }
        }
    }
}

weakref<Logger> g_Logger = Logger::Register();

ASLoggingSystem gpLogging;
