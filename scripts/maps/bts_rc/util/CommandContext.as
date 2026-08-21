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

final class ASCommand
{
    string Command;
    string Arguments;
    string Help;
    CommandCallback@ Lambda;
    bool AdminOnly;
    string Section;

    ASCommand()
    {
        RegisterCommand( @this );
    }

    ASCommand(
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

        RegisterCommand( @this );
    }
}

array<ASCommand@> __CommandContexts__(0);

ASCommand@ RegisterCommand( ASCommand@ command )
{
    if( command is null || command.Command.IsEmpty() )
        return null;

    uint length = __CommandContexts__.length();

    for( uint ui = 0; ui < length; ui++ )
    {
        ASCommand@ registered = __CommandContexts__[ui];

        if( registered.Command == command.Command && registered.Section == command.Section )
        {
            if( g_Logger.warning.active )
            {
                g_Logger.warning.print( "Skipping duplicate command registration for {}{}", {
                    command.Section.IsEmpty() ? String::EMPTY_STRING : command.Section + " ",
                    command.Command
                } );
            }
            return @registered;
        }
    }

    __CommandContexts__.insertLast( @command );
    return @command;
}

ASCommand@ RegisterCommand(
    const string&in command,
    const string&in arguments,
    const string&in help,
    CommandCallback@ lambda,
    bool admin_only = false,
    const string&in section = String::EMPTY_STRING
)
{
    ASCommand@ context = ASCommand();
    context.Command = command;
    context.Arguments = arguments;
    context.Help = help;
    @context.Lambda = lambda;
    context.AdminOnly = admin_only;
    context.Section = section;

    if( g_Logger.info.active )
        g_Logger.info.print( snprintf( glog, "Registering command %1", command ) );

    return RegisterCommand( context );
}

void PrintCommandHelp( CBasePlayer@ player, const string&in section = String::EMPTY_STRING )
{
    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "--- Black Mesa Training: Resonance Cascade commands ---\n" );

    uint length = __CommandContexts__.length();

    for( uint ui = 0; ui < length; ui++ )
    {
        ASCommand@ context = __CommandContexts__[ui];

        if( !section.IsEmpty() && context.Section != section )
            continue;

        string buffer;

        if( context.Section.IsEmpty() )
            snprintf( buffer, ".bts_rc %1 %2\n", context.Command, context.Arguments );
        else
            snprintf( buffer, ".bts_rc %1 %2 %3\n", context.Section, context.Command, context.Arguments );

        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );

        snprintf( buffer, "- %1\n%2", context.Help, ( context.AdminOnly ? "- Administrator only\n" : "\n" ) );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );
    }
}

bool IsCommandSection( const string&in name )
{
    uint length = __CommandContexts__.length();

    for( uint ui = 0; ui < length; ui++ )
    {
        if( __CommandContexts__[ui].Section == name )
            return true;
    }

    return false;
}

CClientCommand __CommandContextCallback__( "bts_rc", "bts_rc commands", function( const CCommand@ args )
{
    auto player = g_ConCommandSystem.GetCurrentPlayer();

    if( player is null )
        return;

    uint length = __CommandContexts__.length();

    if( args.ArgC() == 1 || args[1] == "help" )
    {
        PrintCommandHelp( player, args.ArgC() > 2 && IsCommandSection( args[2] ) ? args[2] : String::EMPTY_STRING );
        return;
    }

    if( args.ArgC() == 2 && IsCommandSection( args[1] ) )
    {
        PrintCommandHelp( player, args[1] );
        return;
    }

    AdminLevel_t adminLevel = g_PlayerFuncs.AdminLevel( player );
    bool isAdmin = ( adminLevel == AdminLevel_t::ADMIN_YES || adminLevel == AdminLevel_t::ADMIN_OWNER );

    for( uint ui = 0; ui < length; ui++ )
    {
        auto context = __CommandContexts__[ui];

        uint start = 0;

        if( context.Section.IsEmpty() )
        {
            if( args.ArgC() < 2 || args[1] != context.Command )
                continue;
            start = 2;
        }
        else
        {
            if( args.ArgC() < 3 || args[1] != context.Section || args[2] != context.Command )
                continue;
            start = 3;
        }

        if( context.AdminOnly && !isAdmin )
        {
            g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "This command is for administrators only.\n" );
            return;
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
            return;
        }
    }
    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Unknown command.\n" );
} );
