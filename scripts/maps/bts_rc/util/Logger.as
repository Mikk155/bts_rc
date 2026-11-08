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
#include "../../../mikk155/Logger/v2/json/v2"

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

    void WriteData()
    {
        meta_api::json::v1::Serialize(
            this.m_data,
            "store/bts_rc_log.json",
            meta_api::json::parser::Indentation::OneSpace,
            meta_api::json::parser::Style::AllMan
        );
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
    }
}

weakref<Logger> g_Logger = Logger::Register();

ASLoggingSystem gpLogging;
