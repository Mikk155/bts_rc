namespace randomizer
{
    #if SERVER
        CLogger@ m_Logger = CLogger( "Randomizer" );
    #endif

    const array<string> keys()
    {
        return {
            "item",
            "npc",
            "hull",
            "boss",
            "headcrab",
            "wave"
        };
    }

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

    class randomizer_npc : CRandomizerEntity { }
    class randomizer_item : CRandomizerEntity { }
    class randomizer_hull : CRandomizerEntity { }
    class randomizer_boss : CRandomizerEntity { }
    class randomizer_wave : CRandomizerEntity { }
    class randomizer_headcrab : CRandomizerEntity { }

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
        array<string>@ entities() { return {}; }

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

            array<string> entities_names = this.entities();

            int index = indexes.length();

            for( uint ui = 0; ui < entities_names.length(); ui++, index-- )
            {
                const string ent_name = entities_names[ui];

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

        array<string>@ entities()
        {
            return
            {
                "GM_HEAD_S1",
                "GM_HEAD_S2",
                "GM_HEAD_S3",
                "GM_HEAD_S4",
                "GM_HEAD_S5",
                "GM_HEAD_S6",
                "GM_HEAD_S7",
                "GM_HEAD_S8"
            };
        }
    }

    CRanomizerItems g_RandomizerItem;
    final class CRanomizerItems : CRandomizer
    {
        string name() { return "item"; }

        array<string>@ entities()
        {
            return
            {   // WEAPONS
                "GM_SG_1",
                "GM_SG_2",
                "GM_SG_3",
                "GM_SG_4",
                "GM_CB_1",
                "GM_CB_2",
                "GM_CB_3",
                "GM_CB_4",
                "GM_KN_1",
                "GM_PIPE_1",
                "GM_PIPE_2",
                "GM_PS_1",
                "GM_SD_1",
                "GM_AXE_1",
                "GM_MAG_1",
                "GM_MAG_2",
                "GM_DE_1",
                "GM_DE_2",
                "GM_HG_1",
                "GM_HG_2",
                "GM_HG_3",
                "GM_HG_4",
                "GM_HG_5",
                "GM_HG_6",
                "GM_HG_7",
                "GM_HG_8",
                "GM_G18_1",
                "GM_PHK_1",
                "GM_PHK_2",
                "GM_UZI_1",
                "GM_MP5_1",
                "GM_MP5_2",
                "GM_M4_1",
                "GM_M16_1",
                "GM_SAW_1",
                // ITEMS
                "GM_HK_1",
                "GM_HK_2",
                "GM_HK_3",
                // AMMO
                "GM_AMMO_1",
                "GM_AMMO_2",
                "GM_AMMO_3",
                "GM_AMMO_4",
                "GM_AMMO_5",
                "GM_AMMO_6",
                "GM_AMMO_7",
                "GM_AMMO_8",
                "GM_AMMO_9",
                "GM_AMMO_10",
                "GM_AMMO_11",
                "GM_AMMO_12",
                "GM_AMMO_13",
                "GM_AMMO_14",
                "GM_AMMO_15",
                "GM_AMMO_16",
                "GM_AMMO_17",
                "GM_AMMO_18",
                "GM_AMMO_19",
                "GM_AMMO_20",
                "GM_AMMO_21",
                "GM_AMMO_22",
                "GM_AMMO_23",
                "GM_AMMO_24",
                "GM_AMMO_25",
                "GM_AMMO_26",
                "GM_AMMO_27",
                "GM_AMMO_28",
                "GM_AMMO_29",
                "GM_AMMO_30",
                "AU_AMMO_1",
                "AU_AMMO_2",
                "AU_AMMO_3",
                "AU_AMMO_4",
                "AU_AMMO_5",
                "AU_AMMO_6",
                "AU_AMMO_7",
                "AU_AMMO_8",
                "AU_AMMO_9",
                "AU_AMMO_10",
                "AU_AMMO_11",
                "AU_AMMO_12",
                // PLAYER COUNT AMMO
                "GM_AMMO_PC1",
                "GM_AMMO_PC2",
                "GM_AMMO_PC3",
                "GM_AMMO_PC4",
                "GM_AMMO_PC5",
                "GM_AMMO_PC6",
                "GM_AMMO_PC7",
                // BATTERIES
                "GM_BA_1",
                "GM_BA_2",
                "GM_BA_3",
                "GM_BA_4",
                "GM_BA_5",
                // ITEMS
                "objective_dorms_key3",
                "objective_dorms_key4",
                "GM_ANTIDOTE_1",
                "GM_ANTIDOTE_2",
                "GM_ANTIDOTE_3",
                "GM_ANTIDOTE_4",
                "GM_FLR_1",
                "GM_FLR_2",
                "GM_FLR_3",
                "GM_FLR_4",
                "GM_FLR_5",
                "GM_FLR_6",
                "GM_FLASH_1",
                "GM_FLASH_2",
                "GM_FLASH_3",
                "GM_FLASH_4",
                "GM_TOOLBOX_1",
                "GM_TOOLBOX_2"
            };
        }
    }
    
    CRanomizerHulls g_RandomizerHull;
    final class CRanomizerHulls : CRandomizer
    {
        string name() { return "hull"; }

        array<string>@ entities()
        {
            return
            {
                "GM_AGRUNT_S1",
                "GM_VOLT_S1",
                "GM_BULL_S1",
                "GM_BULL_S2",
                "GM_BULL_S3"
            };
        }
    }
    
    CRanomizerBosss g_RandomizerBoss;
    final class CRanomizerBosss : CRandomizer
    {
        string name() { return "boss"; }

        array<string>@ entities()
        {
            return
            {
                "GM_KPIN_S1",
                "GM_TOR_S1",
                "GM_VOLT_S2",
                "GM_BGARG_S1"
            };
        }
    }
    
    CRanomizerNpcs g_RandomizerNpc;
    final class CRanomizerNpcs : CRandomizer
    {
        string name() { return "npc"; }

        array<string>@ entities()
        {
            return
            {
                "GM_STUK_S1",
                "GM_STUK_S2",
                "GM_SLAVE_S1",
                "GM_SLAVE_S2",
                "GM_SLAVE_S3",
                "GM_SLAVE_S4",
                "GM_SLAVE_S5",
                "GM_SLAVE_S6",
                "GM_SLAVE_S7",
                "GM_SLAVE_S8",
                "GM_SHOCKTROOPER_S1",
                "GM_SHOCKTROOPER_S2",
                "GM_PITDRONE_S1",
                "GM_PITDRONE_S2",
                "GM_PITDRONE_S3",
                "GM_PITDRONE_S4",
                "GM_SNARK_S1",
                "GM_SNARK_S2",
                "GM_SNARK_S3",
                "GM_HOUND_S1",
                "GM_HOUND_S2",
                "GM_HOUND_S3",
                "GM_HOUND_S4",
                "GM_HOUND_S5",
                "GM_HOUND_S6",
                "GM_GONOME_S1",
                "GM_GONOME_S2",
                "GM_GONOME_S3",
                "GM_GONOME_S4",
                "GM_GONOME_S5",
                "GM_GONOME_S6",
                "GM_ZM_S1",
                "GM_ZM_S2",
                "GM_ZM_S3",
                "GM_ZM_S4",
                "GM_ZM_S5",
                "GM_ZM_S6",
                "GM_ZM_S7",
                "GM_ZM_S8",
                "GM_ZM_S9",
                "GM_ZM_S10",
                "GM_ZM_S11",
                "GM_ZM_S12",
                "GM_ZM_S13",
                "GM_ZM_S14",
                "GM_ZM_S15",
                "GM_ZM_S16",
                "GM_ZM_S17",
                "GM_ZM_S18",
                "GM_ZM_S19",
                "GM_ZM_S20",
                "GM_ZM_S21",
                "GM_ZM_S22",
                "GM_ZM_S23",
                "GM_ZM_S24",
                "GM_ZM_S25",
                "GM_ZM_S26",
                "GM_ZM_S27",
                "GM_ZM_S28",
                "GM_ZM_S29",
                "GM_ZM_S30"
            };
        }
    }
    
    CRanomizerWaves g_RandomizerWave;
    final class CRanomizerWaves : CRandomizer
    {
        string name() { return "wave"; }

        array<string>@ entities()
        {
            return
            {
                "GM_R_SLAVE_S1",
                "GM_R_SLAVE_S2",
                "GM_R_SLAVE_S3",
                "GM_R_SLAVE_S4",
                "GM_R_SLAVE_S5",
                "GM_R_SLAVE_S6",
                "GM_R_SLAVE_S7",
                "GM_R_SLAVE_S8",
                "GM_R_HOUND_S1",
                "GM_R_HOUND_S2",
                "GM_R_HOUND_S3",
                "GM_R_HOUND_S4",
                "GM_R_HOUND_S5",
                "GM_R_HOUND_S6",
                "GM_R_SNARK_S1",
                "GM_R_SNARK_S2",
                "GM_R_AGRUNT_S1",
                "GM_R_AGRUNT_S2",
                "GM_R_PITDRONE_S1",
                "GM_R_PITDRONE_S2",
                "GM_R_PITDRONE_S3",
                "GM_R_CRAB_S1",
                "GM_R_CRAB_S2",
                "GM_R_CRAB_S3",
                "GM_R_CRAB_S4",
                "GM_R_CRAB_S5"
            };
        }
    }
}
