// Black Mesa Training Simulation - Resonance Cascade
// Credits:-
// Map Design: RaptorSKA
// Models: Valve, Gearbox Software, MTB, KernCore, ZikShadow, MiroSklenar, HAPE B, Ixnay, Organic700, DAVLevels, Sven Co-op Teams
// Scripts: KernCore, Nero0, Rizulix, Mikk155, Outerbeast, RaptorSKA, Valve, Gearbox Software
// Sound: Valve, Gearbox Software, MTB, LIL-PIF, KernCore, ZikShadow, TurtleRock Studios, Sven Co-op Teams
// Sprites: Valve, Gearbox Software, KernCore, KEZÆIV, ZikShadow, MiroSklenar, Ixnay, Organic700, DAVLevels, Sven Co-op Teams
// Hands Sleeve Difference based on Playermodels code: KernCore & Mikk155
// Bulet Wallpuff Code: KernCore, Rizulix

#include "trigger_script/survival.as"

#include "beast_itemtracker"
#include "list_weapons"
#include "mappings"
#include "player_voices/player_voices"
#include "monsters/npc_ammo"
#include "point_checkpoint"
#include "trigger_shuffle_position"
#include "selective_nvg"
#include "objective_indicator"

string strShuffleWeapons1 = "GM_ANTIDOTE_1;GM_ANTIDOTE_2;GM_ANTIDOTE_3;GM_ANTIDOTE_4;GM_TOOLBOX_1;GM_TOOLBOX_2;GM_SG_1;GM_SG_2;GM_SG_3;GM_SG_4;GM_CB_1;GM_CB_2;GM_CB_3;GM_CB_4;GM_KN_1;GM_SD_1;GM_PS_1;GM_AXE_1;GM_PIPE_1;GM_PIPE_2;GM_MAG_1;GM_MAG_2;GM_DE_1;GM_DE_2;GM_HG_1;GM_HG_2;GM_HG_3;GM_HG_4;GM_HG_5;GM_HG_6;GM_HG_7;GM_HG_8;GM_HK_1;GM_HK_2;GM_HK_3;GM_MP5_1;GM_MP5_2;GM_M4_1;GM_SAW_1;GM_M16_1;GM_AMMO_1;GM_AMMO_2;GM_AMMO_3;GM_AMMO_4;GM_AMMO_5;GM_AMMO_6;GM_AMMO_7;GM_AMMO_8;GM_AMMO_9;GM_AMMO_10;GM_AMMO_11;GM_AMMO_12;GM_AMMO_13;GM_AMMO_14;GM_AMMO_15;GM_AMMO_16;GM_AMMO_17;GM_AMMO_18;GM_AMMO_19;GM_AMMO_20;GM_AMMO_21;GM_AMMO_22;GM_AMMO_23;GM_AMMO_24;GM_AMMO_25;GM_AMMO_26;GM_AMMO_27;GM_AMMO_28;GM_AMMO_29;GM_AMMO_30;GM_BA_1;GM_BA_2;GM_BA_3;GM_BA_4;GM_BA_5;GM_PHK_1;GM_PHK_2;GM_G18_1;GM_UZI_1;";
string strShuffleWeapons2 = "gm_z1;gm_z2;gm_z3;gm_z4;gm_z5;gm_z6;gm_z7;gm_z8;gm_z9;gm_z10;gm_z11;gm_z12;gm_z13;gm_z14;gm_z15;gm_z16;gm_z17;gm_z18;gm_z19;gm_z20;gm_z21;gm_z22;gm_z23;gm_z24;gm_z25;gm_z26;gm_z27;gm_z28;gm_z29;gm_z30;gm_z31;gm_z32;gm_z33;gm_z34;gm_z35;gm_z36;gm_z37;gm_z38;gm_z39;gm_z40;gm_z41;gm_z42;gm_z43;gm_z44;gm_z45;gm_z46;gm_z47;gm_z48;gm_z49;gm_z50;gm_z51;gm_z52;gm_z53;gm_z54;gm_z55;gm_z56;gm_z57;gm_z58;gm_z59;gm_z60;gm_z61;gm_z62;gm_z63;gm_z64;gm_z65;objective_dorms_key3;objective_dorms_key4;GM_AMMO_PC1;GM_AMMO_PC2;GM_AMMO_PC3;GM_AMMO_PC4;GM_AMMO_PC5;GM_AMMO_PC6;GM_AMMO_PC7;";
string strShuffleWeapons3 = "gm_z66;gm_z67;gm_z68;gm_z69;gm_z70;gm_z71;gm_z72;gm_z73;gm_z74;gm_z75;gm_z76;gm_z77;gm_z78;gm_z79;gm_z80;gm_z81;gm_z82;gm_z83;gm_z84;gm_z85;gm_z86;gm_z87;gm_z88;gm_z89;gm_z90;gm_z91;gm_z92;gm_z93;gm_z94;gm_z95;gm_z96;gm_z97;gm_z98;gm_z99;gm_z100;gm_z101;gm_z102;gm_z103;gm_z104;gm_z105;gm_z106;gm_z107;gm_z108;gm_z109;gm_z110;gm_z111;gm_z112;gm_z113;gm_z114;gm_z115;gm_z116;gm_z117;gm_z118;gm_z119;gm_z120;gm_z121;gm_z122;gm_z123;gm_z124;gm_z125;gm_z126;gm_z127;gm_z128;gm_z129;gm_z130;gm_z131;gm_z132;gm_z133;gm_z134;gm_z135;gm_z136;gm_z137;gm_z138;gm_z139;gm_z140;gm_z141;gm_z142;gm_z143;gm_z144;gm_z145;gm_z146;gm_z147;gm_z148;gm_z149;gm_z150;gm_z151;gm_z152;gm_z153;gm_z154;gm_z155;gm_z156;gm_z157;gm_z158;gm_z159;gm_z160;gm_z161;GM_FLR_1;GM_FLR_2;GM_FLR_3;GM_FLR_4;GM_FLR_5;GM_FLR_6;GM_FLASH_1;GM_FLASH_2;GM_FLASH_3;GM_FLASH_4;ls_1;ls_2;ls_3;ls_4;ls_5;ls_6;ls_7;ls_8;ls_9;ls_10;ls_11;ls_12;AU_AMMO1;AU_AMMO2;AU_AMMO3;AU_AMMO4;AU_AMMO5;AU_AMMO6;AU_AMMO7;AU_AMMO8;AU_AMMO9;AU_AMMO10;AU_AMMO11;AU_AMMO12";

string ShuffleMonsters = "GM_STUK_S1;GM_STUK_S2;GM_SLAVE_S1;GM_SLAVE_S2;GM_SLAVE_S3;GM_SLAVE_S4;GM_SLAVE_S5;GM_SLAVE_S6;GM_SLAVE_S7;GM_SLAVE_S8;GM_SHOCKTROOPER_S1;GM_SHOCKTROOPER_S2;GM_PITDRONE_S1;GM_PITDRONE_S2;GM_PITDRONE_S3;GM_PITDRONE_S4;GM_SNARK_S1;GM_SNARK_S2;GM_SNARK_S3;GM_HOUND_S1;GM_HOUND_S2;GM_HOUND_S3;GM_HOUND_S4;GM_HOUND_S5;GM_HOUND_S6;GM_GONOME_S1;GM_GONOME_S2;GM_GONOME_S3;GM_GONOME_S4;GM_GONOME_S5;GM_GONOME_S6;GM_ZM_S1;GM_ZM_S2;GM_ZM_S3;GM_ZM_S4;GM_ZM_S5;GM_ZM_S6;GM_ZM_S7;GM_ZM_S8;GM_ZM_S9;GM_ZM_S10;GM_ZM_S11;GM_ZM_S12;GM_ZM_S13;GM_ZM_S14;GM_ZM_S15;GM_ZM_S16;GM_ZM_S17;GM_ZM_S18;GM_ZM_S19;GM_ZM_S20;GM_ZM_S21;GM_ZM_S22;GM_ZM_S23;GM_ZM_S24;GM_ZM_S25;GM_ZM_S26;GM_ZM_S27;GM_ZM_S28;GM_ZM_S29;GM_ZM_S30;MS_1;MS_2;MS_3;MS_4;MS_5;MS_6;MS_7;MS_8;MS_9;MS_10;MS_11;MS_12;MS_13;MS_14;MS_15;MS_16;MS_17;MS_18;MS_19;MS_20;MS_21;MS_22;MS_23;MS_24;MS_25;MS_26;MS_27;MS_28;MS_29;MS_30;MS_31;MS_32;MS_33;MS_34;MS_35;MS_36;MS_37;MS_38;MS_39;MS_40;MS_41;MS_42;MS_43;MS_44;MS_45;MS_46;MS_47;MS_48;MS_49;MS_50;MS_51;MS_52;MS_53;MS_54;MS_55;MS_56;MS_57;MS_58;MS_59;MS_60;MS_61;MS_62;MS_63;MS_64;MS_65;MS_66;MS_67;MS_68;MS_69;MS_70;MS_71;MS_72;MS_73;MS_74;MS_75;MS_76;MS_77;MS_78;MS_79;MS_80;MS_81;MS_82;MS_83;MS_84;MS_85;MS_86;MS_87;MS_88;MS_89;MS_90;MS_91;MS_92;MS_93;MS_94;MS_95;MS_96;MS_97;MS_98;MS_99;MS_100;MS_101;MS_102;MS_103;MS_104;MS_105;MS_106;MS_107;MS_108;MS_109;MS_110;MS_111;MS_112;MS_113;MS_114;MS_115;MS_116;MS_117;MS_118;MS_119;MS_120;MS_121;MS_122;MS_123;MS_124;MS_125;MS_126;MS_127;MS_128;MS_129;MS_130;MS_131;MS_132;MS_133;MS_134";
string ShuffleHeadcrabs = "GM_HEAD_S1;GM_HEAD_S2;GM_HEAD_S3;GM_HEAD_S4;GM_HEAD_S5;GM_HEAD_S6;GM_HEAD_S7;GM_HEAD_S8;HCS_1;HCS_2;HCS_3;HCS_4;HCS_5;HCS_6;HCS_7;HCS_8;HCS_9;HCS_10;HCS_11;HCS_12;HCS_13;HCS_14;HCS_15;HCS_16;HCS_17;HCS_18;HCS_19;HCS_20;HCS_21;HCS_22";
string ShuffleHull2 = "GM_AGRUNT_S1;GM_VOLT_S1;GM_BULL_S1;GM_BULL_S2;GM_BULL_S3;HULL2_1;HULL2_2;HULL2_3;HULL2_4;HULL2_5;HULL2_6";
string ShuffleBoss = "GM_KPIN_S1;GM_TOR_S1;GM_VOLT_S2;GM_BGARG_S1;BS_1;BS_2;BS_3;BS_4";

void ShuffleShitAround()
{
    //trigger_shuffle_position objTSP;
    //objTSP.Shuffle( strShuffleWeapons1 + ";" + strShuffleWeapons2 + ";" + strShuffleWeapons3, "", false, false );
    //objTSP.Shuffle( ShuffleMonsters, "", false, false );
    //objTSP.Shuffle( ShuffleHeadcrabs, "", false, false );
    //objTSP.Shuffle( ShuffleBoss, "", false, false );
    //objTSP.Shuffle( ShuffleHull2, "", false, false );
    // Outerbeast: staggered the shuffle executions with some delay to alleviate the freezing behaviour.
    float delay = 0.1f;
    g_Scheduler.SetTimeout( trigger_shuffle_position(), "Shuffle", delay * 0, strShuffleWeapons1 + ";" + strShuffleWeapons2 + ";" + strShuffleWeapons3, "", false, false );
    g_Scheduler.SetTimeout( trigger_shuffle_position(), "Shuffle", delay * 10, ShuffleMonsters, "", false, false );
    g_Scheduler.SetTimeout( trigger_shuffle_position(), "Shuffle", delay * 20, ShuffleHeadcrabs, "", false, false );
    g_Scheduler.SetTimeout( trigger_shuffle_position(), "Shuffle", delay * 30, ShuffleHull2, "", false, false );
    g_Scheduler.SetTimeout( trigger_shuffle_position(), "Shuffle", delay * 40, ShuffleBoss, "", false, false );
}

void MapStart()
{
    ShuffleShitAround();
    g_Log.PrintF( "Max entities: %1\nNumber of entities in bsp: %2", g_Engine.maxEntities, g_EngineFuncs.NumberOfEntities() );
}

void MapActivate()
{
    hItemTrackerMenu = SetupMenu();
    BTS_RC::MapActivate(); //Objective code debug
}

void MapInit()
{
    RegisterPointCheckPointEntity();

    RegisterBTSRCWeapons(); // Custom weapons registered

    BTSRC_NightVision(); // nightvision registered
    
    BTS_RC::ObjectiveInit(); // Objective indicator registered

    g_ClassicMode.ForceItemRemap( true );
    g_ClassicMode.SetItemMappings( @g_AmmoReplacement );

    // Hooks
    g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PLAYER_VOICES::BTSRC_PlayerSpawn );
    g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @PLAYER_VOICES::BTSRC_PlayerKilled );
    g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @PLAYER_VOICES::BTSRC_PlayerPostThink );
    g_Hooks.RegisterHook( Hooks::Monster::MonsterKilled, @NPC_DROPAMMO::BTSRC_MonsterKilled ); 

    // Sound Precache
    PLAYER_VOICES::BTSRC_PrecachePlayerSounds();
}
