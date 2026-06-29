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
        if( g_Logger.info.active )
            g_Logger.info.print( snprintf( glog, "Registering command %1", command ) );

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

    if( args.ArgC() == 1 || args[1] == "help" )
    {
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "--- Black Mesa Training: Resonance Cascade commands ---\n" );

        foreach( auto context : __CommandContexts__ )
        {
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

    foreach( auto context : __CommandContexts__ )
    {
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
