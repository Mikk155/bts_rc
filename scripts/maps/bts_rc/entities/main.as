#include "env_bloodpuddle"
#include "func_bts_recharger"
#include "point_checkpoint"
#include "randomizer"
#include "trigger_script"
#include "trigger_update_class"

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

#include "items/item_bts_armorvest"
#include "items/item_bts_helmet"
#include "items/item_bts_hevbattery"
#include "items/item_bts_sprayaid"

#if SERVER
#include "trigger_logger"
#endif
