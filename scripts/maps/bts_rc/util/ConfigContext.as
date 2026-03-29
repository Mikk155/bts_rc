/// Interface for configuration contexts
/// Call ConfigContext::Register( this ) on your class constructor.
interface IConfigContext
{
    /// Unique name for this context
    string GetName();

    /// Called at MapInit for parsing the object from the json with this class's GetName()
    void Parse( dictionary@ json );
}

namespace ConfigContext
{
    /// List containing all the registered IConfigContext instances for registration.
    array<IConfigContext@> g_ConfigContexts;

    void Register( IConfigContext@ context )
    {
        g_ConfigContexts.insertLast( context );
    }

    void MapInit( dictionary@ data )
    {
        uint length = g_ConfigContexts.length();

        for( uint ui = 0; ui < length; ui++ )
        {
            auto context = g_ConfigContexts[ui];
            string name = context.GetName();

            if( data.exists( name ) )
            {
                g_Log.PrintF( "Parsing configuration context for \"%1\"\n", context.GetName() );
                context.Parse( cast<dictionary@>( data[ name ] ) );
            }
        }
    }
}
