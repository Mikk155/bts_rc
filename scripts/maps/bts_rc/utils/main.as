#include "precache"
#include "Logger"

//sven only has 8192 edicts at any given time
//so assume each player carries exactly 16 weapons, and then leave 100 slots free for various temporary things.
bool freeedicts( int overhead = 1 )
{
    return ( g_EngineFuncs.NumberOfEntities() >= g_Engine.maxEntities - ( 16 * g_Engine.maxClients ) - 100 - overhead );
}
