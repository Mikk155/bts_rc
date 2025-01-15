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
