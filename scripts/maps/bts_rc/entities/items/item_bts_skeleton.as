namespace items
{
    class item_bts_skeleton : item_bts_armorvest
    {
        bool m_IsEmpty = false;

        protected const string& GetModel() override {
            return "models/bts_rc/items/skeleton_guard.mdl";
        }

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
}
