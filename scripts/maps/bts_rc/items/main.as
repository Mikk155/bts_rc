/*
    Author: Mikk
    Ideas: AraseFiq
*/

namespace bts_items
{
    enum item_f
    {
        TouchOnly = 128,
        UseOnly = 256,
#if DISCARDED
        LINE_OF_SIGHT = 512,
#endif
        DisableRespawn = 1024,
    };
}

#include "item_bts_armorvest"
#include "item_bts_helmet"
#include "item_bts_hevbattery"
#include "item_bts_sprayaid"

namespace bts_items
{
    void register( const string&in classname )
    {
        string classspace;
        snprintf( classspace, "bts_items::%1", classname );
        g_CustomEntityFuncs.RegisterCustomEntity( classspace, classname );
        g_ItemRegistry.RegisterItem( classname, "bts_rc/items" );
#if DEVELOP
        g_Game.PrecacheOther( classname );
#endif
    }

    void register()
    {
        register( "item_bts_armorvest" );
        register( "item_bts_helmet" );
        register( "item_bts_hevbattery" );
        register( "item_bts_sprayaid" );
    }
}
