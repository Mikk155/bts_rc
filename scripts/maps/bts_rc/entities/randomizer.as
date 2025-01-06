namespace randomizer
{
    #if SERVER
        CLogger@ m_Logger = CLogger( "Randomizer" );
    #endif

    const array<string> keys(){ return { "item", "npc", "hull", "boss", "headcrab", "wave" }; }

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
            #if SERVER
                m_Logger.debug( "Random origin for \"{}\" at \"{}\"", { self.GetClassname(), self.GetOrigin().ToString() } );
            #endif
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
    
    class randomizer_wave : CRandomizerEntity
    {
    }

    //============================================================================
    // End of map-entities
    //============================================================================

    //============================================================================
    // Start of swap logic
    //============================================================================

    CRandomizer g_Randomizer;
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

            #if SERVER
                m_Logger.info( "Swapped list {} indexes", { this.name() } );
            #endif
        }

        // -TODO Improve this shit swapping
        void swap_squad( CBaseMonster@ pSquad_B )
        {
            CBaseEntity@ pRandomizer_A = g_EntityFuncs.Instance( indexes[ Math.RandomLong( 0, indexes.length() ) ] );
            CBaseEntity@ pRandomizer_B = g_EntityFuncs.Instance( pSquad_B.pev.owner );
            CBaseEntity@ pSquad_A = g_EntityFuncs.Instance( pRandomizer_B.pev.owner );

            if( pRandomizer_B !is null && pRandomizer_A !is null )
            {
                #if SERVER
                    m_Logger.debug( "{}:swap_squad: \"{}\" Swap position from {} to {}", { this.name(), pSquad_B.GetClassname(), pRandomizer_B.GetOrigin().ToString(), pRandomizer_A.GetOrigin().ToString() } );
                #endif

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

            #if SERVER
                m_Logger.info( "Initializing swappers \"{}\"", { target } );
            #endif

            // Find all randomizers and store them in indexes
            CBaseEntity@ pRandomizer = null;
            while( ( @pRandomizer = g_EntityFuncs.FindEntityByClassname( pRandomizer, target ) ) !is null )
            {
                #if SERVER
                    m_Logger.info( "Got entity {} at \"{}\"", { pRandomizer.entindex(), pRandomizer.GetOrigin().ToString() } );
                #endif

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

                #if SERVER
                    m_Logger.debug( "{}: \"{}\" Swap position to {}", { name, ent_name, pRandomizer.GetOrigin().ToString() } );
                #endif

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
                { "GM_HEAD_S8", null }
            };
        }
    }
    CRanomizerItems g_RandomizerItem;
    final class CRanomizerItems : CRandomizer
    {
        string name() { return "item"; }

        dictionary entities()
        {
            return
            {   // WEAPONS
                { "GM_SG_1", null },
                { "GM_SG_2", null },
                { "GM_SG_3", null },
                { "GM_SG_4", null },
                { "GM_CB_1", null },
                { "GM_CB_2", null },
                { "GM_CB_3", null },
                { "GM_CB_4", null },
                { "GM_KN_1", null },
                { "GM_PIPE_1", null },
                { "GM_PIPE_2", null },
                { "GM_PS_1", null },
                { "GM_SD_1", null },
                { "GM_AXE_1", null },
                { "GM_MAG_1", null },
                { "GM_MAG_2", null },
                { "GM_DE_1", null },
                { "GM_DE_2", null },
                { "GM_HG_1", null },
                { "GM_HG_2", null },
                { "GM_HG_3", null },
                { "GM_HG_4", null },
                { "GM_HG_5", null },
                { "GM_HG_6", null },
                { "GM_HG_7", null },
                { "GM_HG_8", null },
                { "GM_G18_1", null },
                { "GM_PHK_1", null },
                { "GM_PHK_2", null },
                { "GM_UZI_1", null },
                { "GM_MP5_1", null },
                { "GM_MP5_2", null },
                { "GM_M4_1", null },
                { "GM_M16_1", null },
                { "GM_SAW_1", null },
                // ITEMS
                { "GM_HK_1", null },
                { "GM_HK_2", null },
                { "GM_HK_3", null },
                // AMMO
                { "GM_AMMO_1", null },
                { "GM_AMMO_2", null },
                { "GM_AMMO_3", null },
                { "GM_AMMO_4", null },
                { "GM_AMMO_5", null },
                { "GM_AMMO_6", null },
                { "GM_AMMO_7", null },
                { "GM_AMMO_8", null },
                { "GM_AMMO_9", null },
                { "GM_AMMO_10", null },
                { "GM_AMMO_11", null },
                { "GM_AMMO_12", null },
                { "GM_AMMO_13", null },
                { "GM_AMMO_14", null },
                { "GM_AMMO_15", null },
                { "GM_AMMO_16", null },
                { "GM_AMMO_17", null },
                { "GM_AMMO_18", null },
                { "GM_AMMO_19", null },
                { "GM_AMMO_20", null },
                { "GM_AMMO_21", null },
                { "GM_AMMO_22", null },
                { "GM_AMMO_23", null },
                { "GM_AMMO_24", null },
                { "GM_AMMO_25", null },
                { "GM_AMMO_26", null },
                { "GM_AMMO_27", null },
                { "GM_AMMO_28", null },
                { "GM_AMMO_29", null },
                { "GM_AMMO_30", null },
                { "AU_AMMO_1", null },
                { "AU_AMMO_2", null },
                { "AU_AMMO_3", null },
                { "AU_AMMO_4", null },
                { "AU_AMMO_5", null },
                { "AU_AMMO_6", null },
                { "AU_AMMO_7", null },
                { "AU_AMMO_8", null },
                { "AU_AMMO_9", null },
                { "AU_AMMO_10", null },
                { "AU_AMMO_11", null },
                { "AU_AMMO_12", null },
                // PLAYER COUNT AMMO
                { "GM_AMMO_PC1", null },
                { "GM_AMMO_PC2", null },
                { "GM_AMMO_PC3", null },
                { "GM_AMMO_PC4", null },
                { "GM_AMMO_PC5", null },
                { "GM_AMMO_PC6", null },
                { "GM_AMMO_PC7", null },
                // BATTERIES
                { "GM_BA_1", null },
                { "GM_BA_2", null },
                { "GM_BA_3", null },
                { "GM_BA_4", null },
                { "GM_BA_5", null },
                // ITEMS
                { "objective_dorms_key3", null },
                { "objective_dorms_key4", null },
                { "GM_ANTIDOTE_1", null },
                { "GM_ANTIDOTE_2", null },
                { "GM_ANTIDOTE_3", null },
                { "GM_ANTIDOTE_4", null },
                { "GM_FLR_1", null },
                { "GM_FLR_2", null },
                { "GM_FLR_3", null },
                { "GM_FLR_4", null },
                { "GM_FLR_5", null },
                { "GM_FLR_6", null },
                { "GM_FLASH_1", null },
                { "GM_FLASH_2", null },
                { "GM_FLASH_3", null },
                { "GM_FLASH_4", null },
                { "GM_TOOLBOX_1", null },
                { "GM_TOOLBOX_2", null }
            };
        }
    }
    
    CRanomizerHulls g_RandomizerHull;
    final class CRanomizerHulls : CRandomizer
    {
        string name() { return "hull"; }

        dictionary entities()
        {
            return
            {
                { "GM_AGRUNT_S1", null },
                { "GM_VOLT_S1", null },
                { "GM_BULL_S1", null },
                { "GM_BULL_S2", null },
                { "GM_BULL_S3", null }
            };
        }
    }
    
    CRanomizerBosss g_RandomizerBoss;
    final class CRanomizerBosss : CRandomizer
    {
        string name() { return "Boss"; }

        dictionary entities()
        {
            return
            {
                { "GM_KPIN_S1", null },
                { "GM_TOR_S1", null },
                { "GM_VOLT_S2", null },
                { "GM_BGARG_S1", null }
            };
        }
    }
    
    CRanomizerNpcs g_RandomizerNpc;
    final class CRanomizerNpcs : CRandomizer
    {
        string name() { return "Npc"; }

        dictionary entities()
        {
            return
            {
                { "GM_STUK_S1", null },
                { "GM_STUK_S2", null },
                { "GM_SLAVE_S1", null },
                { "GM_SLAVE_S2", null },
                { "GM_SLAVE_S3", null },
                { "GM_SLAVE_S4", null },
                { "GM_SLAVE_S5", null },
                { "GM_SLAVE_S6", null },
                { "GM_SLAVE_S7", null },
                { "GM_SLAVE_S8", null },
                { "GM_SHOCKTROOPER_S1", null },
                { "GM_SHOCKTROOPER_S2", null },
                { "GM_PITDRONE_S1", null },
                { "GM_PITDRONE_S2", null },
                { "GM_PITDRONE_S3", null },
                { "GM_PITDRONE_S4", null },
                { "GM_SNARK_S1", null },
                { "GM_SNARK_S2", null },
                { "GM_SNARK_S3", null },
                { "GM_HOUND_S1", null },
                { "GM_HOUND_S2", null },
                { "GM_HOUND_S3", null },
                { "GM_HOUND_S4", null },
                { "GM_HOUND_S5", null },
                { "GM_HOUND_S6", null },
                { "GM_GONOME_S1", null },
                { "GM_GONOME_S2", null },
                { "GM_GONOME_S3", null },
                { "GM_GONOME_S4", null },
                { "GM_GONOME_S5", null },
                { "GM_GONOME_S6", null },
                { "GM_ZM_S1", null },
                { "GM_ZM_S2", null },
                { "GM_ZM_S3", null },
                { "GM_ZM_S4", null },
                { "GM_ZM_S5", null },
                { "GM_ZM_S6", null },
                { "GM_ZM_S7", null },
                { "GM_ZM_S8", null },
                { "GM_ZM_S9", null },
                { "GM_ZM_S10", null },
                { "GM_ZM_S11", null },
                { "GM_ZM_S12", null },
                { "GM_ZM_S13", null },
                { "GM_ZM_S14", null },
                { "GM_ZM_S15", null },
                { "GM_ZM_S16", null },
                { "GM_ZM_S17", null },
                { "GM_ZM_S18", null },
                { "GM_ZM_S19", null },
                { "GM_ZM_S20", null },
                { "GM_ZM_S21", null },
                { "GM_ZM_S22", null },
                { "GM_ZM_S23", null },
                { "GM_ZM_S24", null },
                { "GM_ZM_S25", null },
                { "GM_ZM_S26", null },
                { "GM_ZM_S27", null },
                { "GM_ZM_S28", null },
                { "GM_ZM_S29", null },
                { "GM_ZM_S30", null }
            };
        }
    }
    
    CRanomizerWaves g_RandomizerWave;
    final class CRanomizerWaves : CRandomizer
    {
        string name() { return "Wave"; }

        dictionary entities()
        {
            return
            {
                { "GM_R_SLAVE_S1", null },
                { "GM_R_SLAVE_S2", null },
                { "GM_R_SLAVE_S3", null },
                { "GM_R_SLAVE_S4", null },
                { "GM_R_SLAVE_S5", null },
                { "GM_R_SLAVE_S6", null },
                { "GM_R_SLAVE_S7", null },
                { "GM_R_SLAVE_S8", null },
                { "GM_R_HOUND_S1", null },
                { "GM_R_HOUND_S2", null },
                { "GM_R_HOUND_S3", null },
                { "GM_R_HOUND_S4", null },
                { "GM_R_HOUND_S5", null },
                { "GM_R_HOUND_S6", null },
                { "GM_R_SNARK_S1", null },
                { "GM_R_SNARK_S2", null },
                { "GM_R_AGRUNT_S1", null },
                { "GM_R_AGRUNT_S2", null },
                { "GM_R_PITDRONE_S1", null },
                { "GM_R_PITDRONE_S2", null },
                { "GM_R_PITDRONE_S3", null },
                { "GM_R_CRAB_S1", null },
                { "GM_R_CRAB_S2", null },
                { "GM_R_CRAB_S3", null },
                { "GM_R_CRAB_S4", null },
                { "GM_R_CRAB_S5", null }
            };
        }
    }
}
