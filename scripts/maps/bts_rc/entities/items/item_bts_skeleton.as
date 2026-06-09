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

class item_bts_skeleton : item_bts_armorvest
{
    const string& get_m_Model() override {
        return "models/bts_rc/items/skeleton_guard.mdl";
    }

    bool m_IsEmpty = false;

    void Precache()
    {
        g_Game.PrecacheModel( self, "models/skeleton.mdl" );
        BTS_Item::Precache();
    }

    void Spawn()
    {
        BTS_Item::Spawn();
        self.pev.spawnflags |= 1; // Don't kill
    }

    bool AddAmmo( CBaseEntity@ other )
    {
        if( !m_IsEmpty && item_bts_armorvest::AddAmmo( other ) )
        {
            m_IsEmpty = true;
            self.pev.model = "models/skeleton.mdl";
            g_EntityFuncs.SetModel( self, this.model );
        }

        return false;
    }
}
