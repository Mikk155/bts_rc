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

// disable W117
auto@ gpLoggerConfig = Logger::Config
    .SetGlobalName( "bts_rc" )
    .SetAppendNewline( true )
    .SetPrefixWithGlobalName( true )
    .SetSensitiveArguments( true )
    .SetSensitiveKeywordArguments( true )
    .SetCallback(
        function( string&in message, const Logger::Level&in level )
        {
            Logger::time::format( message, message );
            Logger::file::write( message, "bts_rc.log" );

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
            return true;
        }
    );
// enable W117

class ASLogger : IConfigurable
{
    bool Register( meta_api::json::v2::json@ config ) override
    {
        if( !bool( config[ "active" ] ) )
        {
            Logger::Shutdown();
            return false;
        }

        Logger::json::v2::configure( config );

        return false;
    }

    const string GetSchema() const override
    {
        // All loggers starts on in debug.
        if( g_Debug )
        {
            Logger::SetStateAll( true, true );
        }
        meta_api::json::v2::json@ schema = Logger::json::v2::schema();
        meta_api::json::v2::json@ allOf = meta_api::json::v2::json();
        allOf.SetType( meta_api::json::Type::Array );
        allOf.Append( "IConfigurable" );
        schema.Set( "allOf", allOf );
        // HACK to python checkers xd
        """{}""";
        return schema.ToString();
    }

    const string& GetName() const override
    {
        return "logging";
    }
}

weakref<Logger> g_Logger = Logger::Register();
