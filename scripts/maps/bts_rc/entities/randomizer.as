namespace randomizer
{
#if SERVER
    CLogger@ m_Logger = CLogger( "Randomizer" );
#endif

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
#if SERVER
            m_Logger.debug( "Random origin for \"{}\" at \"{}\"", { self.GetClassname(), self.GetOrigin().ToString() } );

            if( ( LoggerLevel & LoggerLevels::Info ) != 0 )
                self.pev.nextthink = g_Engine.time + 0.1;
#endif
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
#if SERVER
            m_Logger.info( "Swapped list {} indexes", { this.name() } );
#endif
        }

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
                { "GM_TOOLBOX_2", null },
                // LOCATIONS
                { "gm_z1", null },
                { "gm_z2", null },
                { "gm_z3", null },
                { "gm_z4", null },
                { "gm_z5", null },
                { "gm_z6", null },
                { "gm_z7", null },
                { "gm_z8", null },
                { "gm_z9", null },
                { "gm_z10", null },
                { "gm_z11", null },
                { "gm_z12", null },
                { "gm_z13", null },
                { "gm_z14", null },
                { "gm_z15", null },
                { "gm_z16", null },
                { "gm_z17", null },
                { "gm_z18", null },
                { "gm_z19", null },
                { "gm_z20", null },
                { "gm_z21", null },
                { "gm_z22", null },
                { "gm_z23", null },
                { "gm_z24", null },
                { "gm_z25", null },
                { "gm_z26", null },
                { "gm_z27", null },
                { "gm_z28", null },
                { "gm_z29", null },
                { "gm_z30", null },
                { "gm_z31", null },
                { "gm_z32", null },
                { "gm_z33", null },
                { "gm_z34", null },
                { "gm_z35", null },
                { "gm_z36", null },
                { "gm_z37", null },
                { "gm_z38", null },
                { "gm_z39", null },
                { "gm_z40", null },
                { "gm_z41", null },
                { "gm_z42", null },
                { "gm_z43", null },
                { "gm_z44", null },
                { "gm_z45", null },
                { "gm_z46", null },
                { "gm_z47", null },
                { "gm_z48", null },
                { "gm_z49", null },
                { "gm_z50", null },
                { "gm_z51", null },
                { "gm_z52", null },
                { "gm_z53", null },
                { "gm_z54", null },
                { "gm_z55", null },
                { "gm_z56", null },
                { "gm_z57", null },
                { "gm_z58", null },
                { "gm_z59", null },
                { "gm_z60", null },
                { "gm_z61", null },
                { "gm_z62", null },
                { "gm_z63", null },
                { "gm_z64", null },
                { "gm_z65", null },
                { "gm_z66", null },
                { "gm_z67", null },
                { "gm_z68", null },
                { "gm_z69", null },
                { "gm_z70", null },
                { "gm_z71", null },
                { "gm_z72", null },
                { "gm_z73", null },
                { "gm_z74", null },
                { "gm_z75", null },
                { "gm_z76", null },
                { "gm_z77", null },
                { "gm_z78", null },
                { "gm_z79", null },
                { "gm_z80", null },
                { "gm_z81", null },
                { "gm_z82", null },
                { "gm_z83", null },
                { "gm_z84", null },
                { "gm_z85", null },
                { "gm_z86", null },
                { "gm_z87", null },
                { "gm_z88", null },
                { "gm_z89", null },
                { "gm_z90", null },
                { "gm_z91", null },
                { "gm_z92", null },
                { "gm_z93", null },
                { "gm_z94", null },
                { "gm_z95", null },
                { "gm_z96", null },
                { "gm_z97", null },
                { "gm_z98", null },
                { "gm_z99", null },
                { "gm_z100", null },
                { "gm_z101", null },
                { "gm_z102", null },
                { "gm_z103", null },
                { "gm_z104", null },
                { "gm_z105", null },
                { "gm_z106", null },
                { "gm_z107", null },
                { "gm_z108", null },
                { "gm_z109", null },
                { "gm_z110", null },
                { "gm_z111", null },
                { "gm_z112", null },
                { "gm_z113", null },
                { "gm_z114", null },
                { "gm_z115", null },
                { "gm_z116", null },
                { "gm_z117", null },
                { "gm_z118", null },
                { "gm_z119", null },
                { "gm_z120", null },
                { "gm_z121", null },
                { "gm_z122", null },
                { "gm_z123", null },
                { "gm_z124", null },
                { "gm_z125", null },
                { "gm_z126", null },
                { "gm_z127", null },
                { "gm_z128", null },
                { "gm_z129", null },
                { "gm_z130", null },
                { "gm_z131", null },
                { "gm_z132", null },
                { "gm_z133", null },
                { "gm_z134", null },
                { "gm_z135", null },
                { "gm_z136", null },
                { "gm_z137", null },
                { "gm_z138", null },
                { "gm_z139", null },
                { "gm_z140", null },
                { "gm_z141", null },
                { "gm_z142", null },
                { "gm_z143", null },
                { "gm_z144", null },
                { "gm_z145", null },
                { "gm_z146", null },
                { "gm_z147", null },
                { "gm_z148", null },
                { "gm_z149", null },
                { "gm_z150", null },
                { "gm_z151", null },
                { "gm_z152", null },
                { "gm_z153", null },
                { "gm_z154", null },
                { "gm_z155", null },
                { "gm_z156", null },
                { "gm_z157", null },
                { "gm_z158", null },
                { "gm_z159", null },
                { "gm_z160", null },
                { "gm_z161", null },
                { "ls_1", null },
                { "ls_2", null },
                { "ls_3", null },
                { "ls_4", null },
                { "ls_5", null },
                { "ls_6", null },
                { "ls_7", null },
                { "ls_8", null },
                { "ls_9", null },
                { "ls_10", null },
                { "ls_11", null },
                { "ls_12", null }
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
                { "GM_BULL_S3", null },
                { "HULL2_1", null },
                { "HULL2_2", null },
                { "HULL2_3", null },
                { "HULL2_4", null },
                { "HULL2_5", null },
                { "HULL2_6", null }
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
                { "GM_BGARG_S1", null },
                { "BS_1", null },
                { "BS_2", null },
                { "BS_3", null },
                { "BS_4", null }
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
                { "GM_ZM_S30", null },
                // LOCATIONS
                { "MS_1", null },
                { "MS_2", null },
                { "MS_3", null },
                { "MS_4", null },
                { "MS_5", null },
                { "MS_6", null },
                { "MS_7", null },
                { "MS_8", null },
                { "MS_9", null },
                { "MS_10", null },
                { "MS_11", null },
                { "MS_12", null },
                { "MS_13", null },
                { "MS_14", null },
                { "MS_15", null },
                { "MS_16", null },
                { "MS_17", null },
                { "MS_18", null },
                { "MS_19", null },
                { "MS_20", null },
                { "MS_21", null },
                { "MS_22", null },
                { "MS_23", null },
                { "MS_24", null },
                { "MS_25", null },
                { "MS_26", null },
                { "MS_27", null },
                { "MS_28", null },
                { "MS_29", null },
                { "MS_30", null },
                { "MS_31", null },
                { "MS_32", null },
                { "MS_33", null },
                { "MS_34", null },
                { "MS_35", null },
                { "MS_36", null },
                { "MS_37", null },
                { "MS_38", null },
                { "MS_39", null },
                { "MS_40", null },
                { "MS_41", null },
                { "MS_42", null },
                { "MS_43", null },
                { "MS_44", null },
                { "MS_45", null },
                { "MS_46", null },
                { "MS_47", null },
                { "MS_48", null },
                { "MS_49", null },
                { "MS_50", null },
                { "MS_51", null },
                { "MS_52", null },
                { "MS_53", null },
                { "MS_54", null },
                { "MS_55", null },
                { "MS_56", null },
                { "MS_57", null },
                { "MS_58", null },
                { "MS_59", null },
                { "MS_60", null },
                { "MS_61", null },
                { "MS_62", null },
                { "MS_63", null },
                { "MS_64", null },
                { "MS_65", null },
                { "MS_66", null },
                { "MS_67", null },
                { "MS_68", null },
                { "MS_69", null },
                { "MS_70", null },
                { "MS_71", null },
                { "MS_72", null },
                { "MS_73", null },
                { "MS_74", null },
                { "MS_75", null },
                { "MS_76", null },
                { "MS_77", null },
                { "MS_78", null },
                { "MS_79", null },
                { "MS_80", null },
                { "MS_81", null },
                { "MS_82", null },
                { "MS_83", null },
                { "MS_84", null },
                { "MS_85", null },
                { "MS_86", null },
                { "MS_87", null },
                { "MS_88", null },
                { "MS_89", null },
                { "MS_90", null },
                { "MS_91", null },
                { "MS_92", null },
                { "MS_93", null },
                { "MS_94", null },
                { "MS_95", null },
                { "MS_96", null },
                { "MS_97", null },
                { "MS_98", null },
                { "MS_99", null },
                { "MS_100", null },
                { "MS_101", null },
                { "MS_102", null },
                { "MS_103", null },
                { "MS_104", null },
                { "MS_105", null },
                { "MS_106", null },
                { "MS_107", null },
                { "MS_108", null },
                { "MS_109", null },
                { "MS_110", null },
                { "MS_111", null },
                { "MS_112", null },
                { "MS_113", null },
                { "MS_114", null },
                { "MS_115", null },
                { "MS_116", null },
                { "MS_117", null },
                { "MS_118", null },
                { "MS_119", null },
                { "MS_120", null },
                { "MS_121", null },
                { "MS_122", null },
                { "MS_123", null },
                { "MS_124", null },
                { "MS_125", null },
                { "MS_126", null },
                { "MS_127", null },
                { "MS_128", null },
                { "MS_129", null },
                { "MS_130", null },
                { "MS_131", null },
                { "MS_132", null },
                { "MS_133", null },
                { "MS_134", null }
            };
        }
    }
}
