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
