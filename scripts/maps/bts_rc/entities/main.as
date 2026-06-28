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

#include "ammo/main"
#include "items/main"
#include "weapons/main"

#include "monsters/custommonsters" //Nero ADDED 2026-01-07 Custom Monsters

#include "monsters/blackops_flashbang"
#include "monsters/bloodpuddle"
#include "monsters/engineer_sentry"
#include "monsters/lasers"
#include "monsters/robogrunt"
#include "monsters/zombie_engineer"
#include "monsters/zombie_uncrab"

#include "env_commentary"
#include "func_bts_recharger"
#if SERVER
#include "func_section"
#endif
#include "point_checkpoint"
#if SERVER
#include "trigger_logger"
#endif
#include "trigger_update_class"
