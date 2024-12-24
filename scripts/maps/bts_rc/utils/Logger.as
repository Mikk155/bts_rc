/*
    Logger. This is temporary for testing and should be removed on release
*/

enum LoggerLevels
{
    None = 0,
    Warning = ( 1 << 0 ),
    Debug = ( 1 << 1 ),
    Info = ( 1 << 2 ),
    Critical = ( 1 << 3 ),
    Error = ( 1 << 4 )
};

int LoggerLevel = LoggerLevels::None;

class CLogger
{
    private string __member__;

    CLogger( const string &in member )
    {
        __member__ = member;
    }

    private void __printf__( int&in level, const string &in logger, const string &in message, array<string>&in args )
    {
        if( ( LoggerLevel & level ) == 0 )
            return;

        string str;
        snprintf( str, "> %1 [%2] %3\n", __member__, logger, message );

        for( uint ui = 0; ui < args.length(); ui++ )
        {
            uint index = str.Find( "{}", 0 );

            if( index != String::INVALID_INDEX ) {
                str = str.SubString( 0, index ) + args[ui] + str.SubString( index + 2 );
            }
        }

        g_EngineFuncs.ServerPrint( str );
    }

    void warn( const string &in message, array<string>&in args = {} ) {
        this.__printf__( Warning, "WARNING", message, args );
    }

    void debug( const string &in message, array<string>&in args = {} ) {
        this.__printf__( Debug, "DEBUG", message, args );
    }

    void info( const string &in message, array<string>&in args = {} ) {
        this.__printf__( Info, "INFO", message, args );
    }

    void critical( const string &in message, array<string>&in args = {} ) {
        this.__printf__( Critical, "CRITICAL", message, args );
    }

    void error( const string &in message, array<string>&in args = {} ) {
        this.__printf__( Error, "ERROR", message, args );
    }
}

CLogger@ g_Logger = CLogger( "Global" );
