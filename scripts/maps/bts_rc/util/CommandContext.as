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

funcdef void CommandCallback( CBasePlayer@ player, array<string>@ arguments );

final class RegisterCommand
{
    string Command;
    string Arguments;
    string Help;
    CommandCallback@ Lambda;
    bool AdminOnly;
    string Section;

    RegisterCommand()
    {
        __CommandContexts__.insertLast( @this );
    }

    RegisterCommand(
        const string&in command,
        const string&in arguments,
        const string&in help,
        CommandCallback@ lambda,
        bool admin_only = false,
        const string&in section = String::EMPTY_STRING
    )
    {
        if( g_Logger.info )
            g_Logger.info = snprintf( glog, "Registering command %1", command );

        this.Command = command;
        this.Arguments = arguments;
        this.Help = help;
        @this.Lambda = lambda;
        this.AdminOnly = admin_only;
        this.Section = section;

        __CommandContexts__.insertLast( @this );
    }
}

array<RegisterCommand@> __CommandContexts__(0);

CClientCommand __CommandContextCallback__( "bts_rc", "bts_rc commands", function( const CCommand@ args )
{
    auto player = g_ConCommandSystem.GetCurrentPlayer();

    if( player is null )
        return;

    uint length = __CommandContexts__.length();

    if( args.ArgC() == 1 || args[1] == "help" )
    {
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "--- Black Mesa Training: Resonance Cascade commands ---\n" );

        for( uint ui = 0; ui < length; ui++ )
        {
            auto context = __CommandContexts__[ui];
            string buffer;

            if( context.Section.IsEmpty() )
            {
                snprintf( buffer, ".bts_rc %1 %2\n", context.Command, context.Arguments );
            }
            else
            {
                snprintf( buffer, ".bts_rc %1 %2 %3\n", context.Section, context.Command, context.Arguments );
            }

            g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );

            snprintf( buffer, "- %1\n%2", context.Help, ( context.AdminOnly ? "- Administrator only\n" : "\n" ) );
            g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );
        }
        return;
    }

    AdminLevel_t adminLevel = g_PlayerFuncs.AdminLevel( player );
    bool isAdmin = ( adminLevel == AdminLevel_t::ADMIN_YES || adminLevel == AdminLevel_t::ADMIN_OWNER );

    for( uint ui = 0; ui < length; ui++ )
    {
        auto context = __CommandContexts__[ui];

        if( context.AdminOnly && !isAdmin )
        {
            g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "This command is for administrators only.\n" );
            continue;
        }

        uint start = 0;

        if( context.Section.IsEmpty() )
        {
            if( args.ArgC() < 2 || args[1] != context.Command )
                continue;
            start = 2;
        }
        else
        {
            if( args.ArgC() < 3 || args[1] != context.Section || args[1] != context.Command )
                continue;
            start = 1;
        }

        if( context.Lambda !is null )
        {
            array<string> newArguments;

            uint argsLength = args.ArgC();

            for( uint c = start; c < argsLength; c++ )
            {
                newArguments.insertLast( args[c] );
            }

            context.Lambda( player, newArguments.length() > 0 ? @newArguments : null );
        }
    }
} );
