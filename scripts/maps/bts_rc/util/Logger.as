/**   MIT License
*   
*   Copyright (c) 2025 Mikk155 https://github.com/Mikk155/bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies or substantial portions of the Software.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*   SOFTWARE.
*/

string glog;

class CLogger
{
    bool __error__;
    bool __info__;
    bool __trace__;
    bool __warning__;
    bool __critical__ = true;

    bool Toggle( const string&in loggerName )
    {
        if( loggerName == "error" )
            this.__error__ = !this.__error__;
        else if( loggerName == "info" )
            this.__info__ = !this.__info__;
        else if( loggerName == "trace" )
            this.__trace__ = !this.__trace__;
        else if( loggerName == "warning" )
            this.__warning__ = !this.__warning__;
        else if( loggerName == "critical" )
            this.__critical__ = !this.__critical__;
        else
            return false;

        return true;
    }

    bool IsActive( const string&in loggerName )
    {
        if( loggerName == "error" )
            return this.__error__;
        else if( loggerName == "info" )
            return this.__info__;
        else if( loggerName == "trace" )
            return this.__trace__;
        else if( loggerName == "warning" )
            return this.__warning__;
        else if( loggerName == "critical" )
            return this.__critical__;
        return false;
    }

    void print( const string&in loggerName )
    {
        string buffer;
        snprintf( buffer, "[%1] %2\n", loggerName, glog );
        glog = String::EMPTY_STRING;

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

    bool error {
        get { return this.__error__; }
        set { this.print( "error" ); }
    }

    bool info {
        get { return this.__info__; }
        set { this.print( "info" ); }
    }

    bool trace {
        get { return this.__trace__; }
        set { this.print( "trace" ); }
    }

    bool warning {
        get { return this.__warning__; }
        set { this.print( "warning" ); }
    }

    bool critical {
        get { return this.__critical__; }
        set { this.print( "critical" ); }
    }

    void __Register__( dictionary@ json )
    {
        if( json.get( "error", this.__error__ ) && this.__error__ )
            g_Game.AlertMessage( at_console, "Enabled \"error\" logger\n" );
        if( json.get( "info", this.__info__ ) && this.__info__ )
            g_Game.AlertMessage( at_console, "Enabled \"info\" logger\n" );
        if( json.get( "trace", this.__trace__ ) && this.__trace__ )
            g_Game.AlertMessage( at_console, "Enabled \"trace\" logger\n" );
        if( json.get( "warning", this.__warning__ ) && this.__warning__ )
            g_Game.AlertMessage( at_console, "Enabled \"warning\" logger\n" );
        if( json.get( "critical", this.__critical__ ) && this.__critical__ )
            g_Game.AlertMessage( at_console, "Enabled \"critical\" logger\n" );

        RegisterCommand( "log", "<string logger>", "Toggle log levels. one of; error, info, trace, warning, critical.", 
            CommandCallback( function( CBasePlayer@ player, array<string>@ arguments )
            {
                if( arguments is null || arguments.length() <= 0 || !g_Logger.Toggle( arguments[0] ) )
                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "You have to provide a valid argument! one of; error, info, trace, warning, critical.\n" );
                else
                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Toggled logger " + arguments[0] + " to " + ( g_Logger.IsActive( arguments[0] ) ? "true" : "false" ) + ".\n" );
            }
        ), true );
    }
}

CLogger g_Logger;
