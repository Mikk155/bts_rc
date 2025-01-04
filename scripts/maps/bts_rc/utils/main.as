
#if SERVER
#include "Logger"
#endif

#include "precache"
#include "player_class"

//sven only has 8192 edicts at any given time
//so assume each player carries exactly 16 weapons, and then leave 100 slots free for various temporary things.
bool freeedicts( int overhead = 1 )
{
    return ( g_EngineFuncs.NumberOfEntities() >= g_Engine.maxEntities - ( 16 * g_Engine.maxClients ) - 100 - overhead );
}

int LINK_ENTITY_TO_CLASS( const string classname, const string Namespace = String::EMPTY_STRING )
{
    if( Namespace != String::EMPTY_STRING )
    {
        string ClassSpace;
        snprintf( ClassSpace, "%1::%2", Namespace, classname );
        g_CustomEntityFuncs.RegisterCustomEntity( ClassSpace, classname );
    }

    if( !g_CustomEntityFuncs.IsCustomEntity( classname ) )
    {
        g_CustomEntityFuncs.RegisterCustomEntity( classname, classname );
    }

    return 0;
}
