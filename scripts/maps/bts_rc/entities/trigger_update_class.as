namespace trigger_update_class
{
    int register = LINK_ENTITY_TO_CLASS( "trigger_update_class", "trigger_update_class" );

    class trigger_update_class : ScriptBaseEntity
    {
        private PM m_class = PM::SCIENTIST;

        void Spawn()
        {
            self.pev.movetype = MOVETYPE_NONE;
            self.pev.effects |= EF_NODRAW;
            self.pev.solid = SOLID_NOT;
        }

        bool KeyValue( const string& in szKeyName, const string& in szValue )
        {
            if( szKeyName == 'm_class' )
            {
                m_class = PM( atoi( szValue ) );
            }
            return false;
        }

        void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
        {
            if( pActivator !is null )
            {
                CBasePlayer@ player = cast<CBasePlayer@>( pActivator );

                if( player !is null )
                {
                    g_PlayerClass.set_class( player, m_class );
                }
                else
                {
                    g_PlayerClass.m_Logger.error( "Entity \"{}\" origin {} got an !activator that is not a player!", { self.GetTargetname(), self.GetOrigin().ToString() } );
                }
            }
            else
            {
                g_PlayerClass.m_Logger.error( "Entity \"{}\" origin {} got no !activator!", { self.GetTargetname(), self.GetOrigin().ToString() } );
            }
        }
    }
}