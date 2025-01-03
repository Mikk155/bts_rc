namespace randomizer
{
    CLogger@ m_Logger = CLogger( "Randomizer" );

    const array<string> keys(){ return { "item", "npc", "hull", "boss", "headcrab" }; }

    //============================================================================
    // Start of map-entities
    //============================================================================

    int register = register_all();
    int register_all()
    {
        const array<string> list = keys();

        for( uint ui = 0; ui < list.length(); ui++ )
        {
            string ent;
            snprintf( ent, "randomizer_%1", list[ui] );
            LINK_ENTITY_TO_CLASS( ent, "randomizer" );
        }

        return 0;
    }

    class CRandomizerEntity : ScriptBaseEntity
    {
        void Spawn()
        {
            m_Logger.debug( "Random origin for \"{}\" at \"{}\"", { self.GetClassname(), self.GetOrigin().ToString() } );
            self.pev.nextthink = g_Engine.time + 0.1;
        }

        // -TODO Remove this debug
        void Think()
        {
            NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
                m.WriteByte( TE_IMPLOSION );
                m.WriteVector( self.GetOrigin() );
                m.WriteByte( 30 );
                m.WriteByte( 10 );
                m.WriteByte( 10 );
            m.End();
            self.pev.nextthink = g_Engine.time + 1.0;
        }
    }

    class randomizer_headcrab : CRandomizerEntity
    {
    }

    class randomizer_npc : CRandomizerEntity
    {
    }

    class randomizer_item : CRandomizerEntity
    {
    }

    class randomizer_hull : CRandomizerEntity
    {
    }

    class randomizer_boss : CRandomizerEntity
    {
    }

    //============================================================================
    // End of map-entities
    //============================================================================

    //============================================================================
    // Start of swap logic
    //============================================================================

    class CRandomizer
    {
        // Identifier name for this class
        string name() { return String::EMPTY_STRING; }

        // List of entities names for this class
        dictionary entities() { return {}; }

        // Indexes of randomizer entities
        array<int> indexes;

        void swap_list()
        {
            array<int> swaps = indexes;
            for( int i = swaps.length() - 1; i > 0; i-- )
            {
                int j = Math.RandomLong( 0, i );
                int temp = swaps[i];
                swaps[i] = swaps[j];
                swaps[j] = temp;
            }
            indexes = swaps;
            m_Logger.info( "Swapped list {} indexes", { this.name() } );
        }

        void swap_squad( CBaseMonster@ pSquad_B )
        {
            CBaseEntity@ pRandomizer_A = g_EntityFuncs.Instance( indexes[ Math.RandomLong( 0, indexes.length() ) ] );
            CBaseEntity@ pRandomizer_B = g_EntityFuncs.Instance( pSquad_B.pev.owner );
            CBaseEntity@ pSquad_A = g_EntityFuncs.Instance( pRandomizer_B.pev.owner );

            if( pRandomizer_B !is null && pRandomizer_A !is null )
            {
                m_Logger.debug( "{}:swap_squad: \"{}\" Swap position from {} to {}", { this.name(), pSquad_B.GetClassname(), pRandomizer_B.GetOrigin().ToString(), pRandomizer_A.GetOrigin().ToString() } );
                @pSquad_B.pev.owner = pRandomizer_A.edict();
                @pSquad_A.pev.owner = pRandomizer_B.edict();
                @pRandomizer_B.pev.owner = pSquad_A.edict();
                @pRandomizer_A.pev.owner = pSquad_B.edict();
                g_EntityFuncs.SetOrigin( pSquad_A, pRandomizer_B.GetOrigin() );
                g_EntityFuncs.SetOrigin( pSquad_B, pRandomizer_A.GetOrigin() );
            }
        }

        void init()
        {
            const string name = this.name();
            string target;
            snprintf( target, "randomizer_%1", name );
            m_Logger.info( "Initializing swappers \"{}\"", { target } );

            // Find all randomizers and store them in indexes
            CBaseEntity@ pRandomizer = null;
            while( ( @pRandomizer = g_EntityFuncs.FindEntityByClassname( pRandomizer, target ) ) !is null )
            {
                m_Logger.info( "Got entity {} at \"{}\"", { pRandomizer.entindex(), pRandomizer.GetOrigin().ToString() } );
                indexes.insertLast( pRandomizer.entindex() );
            }

            // Randomize and swap the list
            this.swap_list();

            const dictionary entity_data = this.entities();
            const array<string> entities = entity_data.getKeys();

            int index = indexes.length();

            for( uint ui = 0; ui < entities.length(); ui++, index-- )
            {
                const string ent_name = entities[ui];

                @pRandomizer = g_EntityFuncs.Instance( indexes[ index - 1 ] );

                m_Logger.debug( "{}: \"{}\" Swap position to {}", { name, ent_name, pRandomizer.GetOrigin().ToString() } );

                CBaseEntity@ pTargetEntity = g_EntityFuncs.FindEntityByTargetname( null, ent_name );

                if( pTargetEntity !is null && pRandomizer !is null )
                {
                    @pRandomizer.pev.owner = pTargetEntity.edict();
                    @pTargetEntity.pev.owner = pRandomizer.edict();
                    g_EntityFuncs.SetOrigin( pTargetEntity, pRandomizer.GetOrigin() );
                }
            }
        }
    }

    CRanomizerHeadcrabs g_RandomizerHeadcrab;
    final class CRanomizerHeadcrabs : CRandomizer
    {
        string name() { return "headcrab"; }

        dictionary entities()
        {
            return
            {
                { "GM_HEAD_S1", null },
                { "GM_HEAD_S2", null },
                { "GM_HEAD_S3", null },
                { "GM_HEAD_S4", null },
                { "GM_HEAD_S5", null },
                { "GM_HEAD_S6", null },
                { "GM_HEAD_S7", null },
                { "GM_HEAD_S8", null },
                { "HCS_1", null },
                { "HCS_2", null },
                { "HCS_3", null },
                { "HCS_4", null },
                { "HCS_5", null },
                { "HCS_6", null },
                { "HCS_7", null },
                { "HCS_8", null },
                { "HCS_9", null },
                { "HCS_10", null },
                { "HCS_11", null },
                { "HCS_12", null },
                { "HCS_13", null },
                { "HCS_14", null },
                { "HCS_15", null },
                { "HCS_16", null },
                { "HCS_17", null },
                { "HCS_18", null },
                { "HCS_19", null },
                { "HCS_20", null },
                { "HCS_21", null },
                { "HCS_22", null }
            };
        }
    }
}
