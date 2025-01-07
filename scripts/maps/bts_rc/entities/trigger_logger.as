namespace trigger_logger
{
    int register = LINK_ENTITY_TO_CLASS( "trigger_logger", "trigger_logger" );

    class trigger_logger : ScriptBaseEntity
    {
        void Spawn()
        {
            self.pev.solid = SOLID_TRIGGER;
            self.pev.movetype = MOVETYPE_NONE;
            self.pev.effects |= EF_NODRAW;
            g_EntityFuncs.SetModel( self, string( self.pev.model ) );
            g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
        }

        void Touch( CBaseEntity@ pOther )
        {
            if( pOther !is null && pOther.IsPlayer() )
            {
                g_PlayerFuncs.ClientPrint( cast<CBasePlayer@>(pOther), HUD_PRINTNOTIFY, string( self.pev.message ) + "\n" );
            }
        }
    }
}
