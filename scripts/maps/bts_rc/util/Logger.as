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

string glog;

namespace Logger
{
    final class ASLogger
    {
        protected
            bool m_IsActive = true;

        const bool get_active() const {
            return this.m_IsActive;
        }

        void SetLevel( bool value )
        {
            this.m_IsActive = value;
            snprintf( glog, "%1 logger level %2", ( value ? "Enabled" : "Disabled" ), this.id );
            this.print_buffer();
        }

        bool ToggleLevel()
        {
            SetLevel( !this.active );
            return this.active;
        }

        protected
            string m_Name;

        const string& get_name() const {
            return this.m_Name;
        }

        protected
            string m_Id;

        const string& get_id() const {
            return this.m_Id;
        }

        ASLogger( const string&in id, const string&in name )
        {
            this.m_Id = id;
            this.m_Name = name;
        }

        void print( const string&in message, array<string>@ arguments = null ) const
        {
            if( !this.active )
                return;

            glog = message;

            if( arguments !is null )
            {
                uint length = arguments.length();

                for( uint ui = 0; ui < length; ui++ )
                {
                    uint index = glog.Find( "{}" );

                    if( index == String::INVALID_INDEX )
                    {
                        g_Game.AlertMessage( at_console, "Error: Logger with id \"%1\" is printing more arguments than defined in message!\nIssued message: ", this.id );
                        break;
                    }
                    snprintf( glog, "%1%2%3", glog.SubString( 0, index ), arguments[ui], glog.SubString( index + 2 ) );
                }
            }

            this.print_buffer();
        }

        void print( const bool _snprintf ) const {
            if( this.active )
                this.print_buffer();
        }

        protected
            void print_buffer() const
            {
                string buffer;
                snprintf( buffer, "[%1] %2\n", this.name, glog );
                glog = String::EMPTY_STRING;

                if( Logger::gpWriteFile )
                {
                    File@ file = g_FileSystem.OpenFile( "scripts/maps/store/bts_rc.log", OpenFile::APPEND );

                    if( file is null || !file.IsOpen() )
                    {
                        @file = g_FileSystem.OpenFile( "scripts/maps/store/bts_rc.log", OpenFile::WRITE );
                        file.Write( " " );
                        file.Close();
                        @file = g_FileSystem.OpenFile( "scripts/maps/store/bts_rc.log", OpenFile::APPEND );
                    }

                    string header;

                    if( Logger::gpLastSecond != g_Engine.time )
                    {
                        snprintf( header, "=== Current frame: %1 ===\n", g_Engine.time );
                        Logger::gpLastSecond = g_Engine.time;
                    }

                    if( !header.IsEmpty() )
                        file.Write( header );

                    file.Write( buffer );
                }

                if( g_EngineFuncs.IsDedicatedServer() )
                {
                    g_EngineFuncs.ServerPrint( buffer );
                }
                // Host is not yet fully connected, print to server console not network client
                else if( g_Engine.time < 5 )
                {
                    auto host = g_PlayerFuncs.FindPlayerByIndex(0);

                    if( host is null || !host.IsConnected() )
                    {
                        g_EngineFuncs.ServerPrint( buffer );
                        return;
                    }
                }

                g_PlayerFuncs.ClientPrintAll( HUD_PRINTCONSOLE, buffer );
            }
    }
}

namespace Logger
{
    float gpLastSecond;
    bool gpWriteFile;
}

final class CLogger : IConfigurable
{
    protected
        array<Logger::ASLogger@> m_Loggers(0);
    
    const array<Logger::ASLogger@>@ get_Loggers()
    {
        return @this.m_Loggers;
    }

    protected 
        Logger::ASLogger@ GetLoggerHandle( const string&in id )
        {
            uint length = this.m_Loggers.length();

            for( uint ui = 0; ui < length; ui++ )
            {
                auto logger = this.m_Loggers[ui];

                if( logger.id == id )
                {
                    return @logger;
                }
            }
            return null;
        }

    const Logger::ASLogger@ GetLogger( const string&in id )
    {
        return this.GetLoggerHandle(id);
    }

    Logger::ASLogger trace( "trace", "Trace" );
    Logger::ASLogger debug( "debug", "Debug" );
    Logger::ASLogger info( "info", "Information" );
    Logger::ASLogger warning( "warning", "Warning" );
    Logger::ASLogger error( "error", "Error" );
    Logger::ASLogger critical( "critical", "Critical" );

    bool IsActive( const string&in id )
    {
        const auto logger = this.GetLoggerHandle(id);
        return ( logger !is null && logger.active );
    }

    bool SetLevel( const string&in id, bool&in value )
    {
        auto logger = this.GetLoggerHandle(id);

        if( logger !is null )
        {
            logger.SetLevel( value );
            return true;
        }
        g_Game.AlertMessage( at_console, "ERROR: Unexistent logger with name \"%1\"\n", id );
        return false;
    }

    bool Toggle( const string&in id )
    {
        auto logger = this.GetLoggerHandle(id);

        if( logger !is null )
        {
            return logger.ToggleLevel();
        }
        g_Game.AlertMessage( at_console, "ERROR: Unexistent logger with name \"%1\"\n", id );
        return false;
    }

    protected RegisterCommand@ command;
    const RegisterCommand@ get_Command()
    {
        return @this.command;
    }

    // IConfigurable start
    const string& GetName() const override {
        return "logger";
    }

    const string GetSchema() const override {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "description": "Logging configuration per severity level.",
            "title": "Logging",
            "properties":
            {
                "file": { "type": "boolean", "description": "Should we log into an unique scripts/maps/store/bts_rc.log file? the file is restored every map start.", "default": false },
                "trace": { "type": "boolean", "default": false },
                "debug": { "type": "boolean", "default": false },
                "info": { "type": "boolean", "default": false },
                "warning": { "type": "boolean", "default": true },
                "error": { "type": "boolean", "default": true },
                "critical": { "type": "boolean", "default": true }
            }
        }""";
    }

    bool Register( meta_api::json::v2::json@ config ) override
    {
        this.m_Loggers = {
            @this.trace,
            @this.debug,
            @this.info,
            @this.warning,
            @this.error,
            @this.critical
        };

        this.trace.SetLevel( bool( config[ "trace" ] ) );
        this.debug.SetLevel( bool( config[ "debug" ] ) );
        this.info.SetLevel( bool( config[ "info" ] ) );
        this.warning.SetLevel( bool( config[ "warning" ] ) );
        this.error.SetLevel( bool( config[ "error" ] ) );
        this.critical.SetLevel( bool( config[ "critical" ] ) );

        Logger::gpWriteFile = bool( config[ "file" ] );

        if( Logger::gpWriteFile )
        {
            File@ file = g_FileSystem.OpenFile( "scripts/maps/store/bts_rc.log", OpenFile::WRITE );
            file.Write( " " );
            file.Close();
        }

        string commandHelp = "One of: file, ";
        uint length = this.m_Loggers.length();
        for( uint ui = 0; ui < length; ui++ )
        {
            auto logger = this.m_Loggers[ui];
            snprintf( commandHelp, "%1%2%3", commandHelp, ( ui > 0 ? ", " : "" ), logger.id );
        }

        @command = RegisterCommand( "log", "<string logger>", commandHelp, 
            CommandCallback( function( CBasePlayer@ player, array<string>@ arguments )
            {
                bool isValid = ( arguments !is null && arguments.length() > 0 );

                const auto levels = g_Logger.Loggers;
                uint length = levels.length();

                if( isValid )
                {
                    string id = arguments[0];

                    if( id == "file" )
                    {
                        Logger::gpWriteFile = !Logger::gpWriteFile;
                        string buffer;
                        snprintf( buffer, "File logging %1%2\n", ( Logger::gpWriteFile ? "Enabled" : "Disabled" ), ( Logger::gpWriteFile ? " at scripts/maps/store/bts_rc.log" : "." ) );
                        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );
                        g_Game.AlertMessage( at_console, buffer );
                        return;
                    }

                    for( uint ui = 0; ui < length; ui++ )
                    {
                        if( ( isValid = levels[ui].id == id ) )
                            break;
                    }
                }

                if( !isValid )
                {
                    string buffer;
                    snprintf( buffer, "You have to provide a valid argument! %1\n", g_Logger.Command.Help );
                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );
                    return;
                }

                g_Logger.Toggle( arguments[0] );
            }
        ), true );

        return true;
    }
}

CLogger g_Logger;
