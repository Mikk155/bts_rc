/*
    Author: Mikk
*/

#if SERVER
#include "Logger"
#endif

#include "entities/main"
#include "gamemodes/main"
#include "Hooks/main"
#include "weapons/main"

void MapActivate()
{
#if SERVER
    g_Logger.info( "Map entities {}/{}", { g_EngineFuncs.NumberOfEntities(), g_Engine.maxEntities } );
#endif

    g_sentry_laser.map_activate();
    BTS_RC_ERTY::MapActivate();
}

void MapInit()
{
#if SERVER
    LoggerLevel = ( Warning | Debug | Info | Critical | Error );
#endif

    g_VoiceResponse.init();

    RegisterPointCheckPointEntity();

    /*==========================================================================
    *   - Start of custom entities
    ==========================================================================*/
    g_CustomEntityFuncs.RegisterCustomEntity( "env_bloodpuddle::env_bloodpuddle", "env_bloodpuddle" );
    g_CustomEntityFuncs.RegisterCustomEntity( "func_bts_recharger::func_bts_recharger", "func_bts_recharger" );
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_update_class::trigger_update_class", "trigger_update_class" );
#if SERVER
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_logger::trigger_logger", "trigger_logger" );
#endif

    // Randomizer
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_npc", "randomizer_npc" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_item", "randomizer_item" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_hull", "randomizer_hull" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_boss", "randomizer_boss" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_wave", "randomizer_wave" );
    g_CustomEntityFuncs.RegisterCustomEntity( "randomizer::randomizer_headcrab", "randomizer_headcrab" );

    // Items
    g_CustomEntityFuncs.RegisterCustomEntity( "bts_items::item_bts_armorvest", "item_bts_armorvest" );
    g_CustomEntityFuncs.RegisterCustomEntity( "bts_items::item_bts_helmet", "item_bts_helmet" );
    g_CustomEntityFuncs.RegisterCustomEntity( "bts_items::item_bts_hevbattery", "item_bts_hevbattery" );
    g_CustomEntityFuncs.RegisterCustomEntity( "bts_items::item_bts_sprayaid", "item_bts_sprayaid" );

    // Projectiles
    g_CustomEntityFuncs.RegisterCustomEntity( "M79_ROCKET::CM79Rocket", "m79_rocket" );
    g_CustomEntityFuncs.RegisterCustomEntity( "FLARE::CFlare", "flare" );
    g_CustomEntityFuncs.RegisterCustomEntity( "DART::CDart", "gun_dart" );

    // Weapon Entities
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_AXE::weapon_bts_axe", "weapon_bts_axe" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_BERETTA::weapon_bts_beretta", "weapon_bts_beretta" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_CROWBAR::weapon_bts_crowbar", "weapon_bts_crowbar" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_DEAGLE::weapon_bts_eagle", "weapon_bts_eagle" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLARE::weapon_bts_flare", "weapon_bts_flare" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLAREGUN::weapon_bts_flaregun", "weapon_bts_flaregun" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLASHLIGHT::weapon_bts_flashlight", "weapon_bts_flashlight" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_GLOCK::weapon_bts_glock", "weapon_bts_glock" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_GLOCK17F::weapon_bts_glock17f", "weapon_bts_glock17f" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_GLOCK18::weapon_bts_glock18", "weapon_bts_glock18" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_GLOCKSD::weapon_bts_glocksd", "weapon_bts_glocksd" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_KNIFE::weapon_bts_knife", "weapon_bts_knife" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_HANDGRENADE::weapon_bts_handgrenade", "weapon_bts_handgrenade" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M4::weapon_bts_m4", "weapon_bts_m4" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M4SD::weapon_bts_m4sd", "weapon_bts_m4sd" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M16A3::weapon_bts_m16", "weapon_bts_m16" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_M79::weapon_bts_m79", "weapon_bts_m79" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_MEDKIT::weapon_bts_medkit", "weapon_bts_medkit" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5GL::weapon_bts_mp5gl", "weapon_bts_mp5gl" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5::weapon_bts_mp5", "weapon_bts_mp5" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_PIPE::weapon_bts_pipe", "weapon_bts_pipe" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_POOLSTICK::weapon_bts_poolstick", "weapon_bts_poolstick" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CPython::weapon_bts_python", "weapon_bts_python" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SHOTGUN::weapon_bts_shotgun", "weapon_bts_shotgun" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_UZI::weapon_bts_uzi", "weapon_bts_uzi" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CM249::weapon_bts_saw", "weapon_bts_saw" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SBSHOTGUN::weapon_bts_sbshotgun", "weapon_bts_sbshotgun" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SCREWDRIVER::weapon_bts_screwdriver", "weapon_bts_screwdriver" );

    // Ammo
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_BERETTA::ammo_bts_beretta", "ammo_bts_beretta" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_BERETTA::ammo_bts_beretta_battery", "ammo_bts_beretta_battery" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_DEAGLE::ammo_bts_eagle", "ammo_bts_eagle" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_DEAGLE::ammo_bts_eagle_battery", "ammo_bts_eagle_battery" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_DEAGLE::ammo_bts_eagle", "ammo_bts_dreagle" ); 
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLAREGUN::ammo_bts_flarebox", "ammo_bts_flarebox" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLASHLIGHT::ammo_bts_battery", "ammo_bts_battery" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_GLOCK::ammo_bts_glock", "ammo_bts_glock" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_GLOCK17F::ammo_bts_glock17f", "ammo_bts_glock17f" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_GLOCK17F::ammo_bts_glock17f_battery", "ammo_bts_glock17f_battery" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_GLOCK18::ammo_bts_glock18", "ammo_bts_glock18" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_GLOCKSD::ammo_bts_glocksd", "ammo_bts_glocksd" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_GLOCKSD::ammo_bts_glocksd", "ammo_bts_dglocksd" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M4::ammo_bts_m4", "ammo_bts_m4" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M4::ammo_bts_m4", "ammo_bts_556mag" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M4SD::ammo_bts_m4sd", "ammo_bts_m4sd" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M16A3::ammo_bts_m16", "ammo_bts_m16" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M16A3::ammo_bts_m16", "ammo_bts_556round" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_M16A3::ammo_bts_m16_grenade", "ammo_bts_m16_grenade" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_M79::ammo_bts_m79", "ammo_bts_m79" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5GL::ammo_bts_mp5gl", "ammo_bts_mp5gl" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5GL::ammo_bts_mp5gl", "ammo_bts_9mmbox" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5GL::ammo_bts_mp5gl_grenade", "ammo_bts_mp5gl_grenade" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5::ammo_bts_mp5", "ammo_bts_mp5" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_MP5::ammo_bts_mp5", "ammo_bts_dmp5" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CPython::ammo_bts_python", "ammo_bts_python" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CPython::ammo_bts_python", "ammo_bts_357cyl" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SHOTGUN::ammo_bts_shotgun", "ammo_bts_shotgun" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SHOTGUN::ammo_bts_shotgun", "ammo_bts_shotshell" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_UZI::ammo_bts_uzi", "ammo_bts_uzi" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CM249::ammo_bts_saw", "ammo_bts_saw" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CM249::ammo_bts_saw", "ammo_bts_dsaw" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SBSHOTGUN::ammo_bts_sbshotgun", "ammo_bts_sbshotgun" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_SBSHOTGUN::ammo_bts_sbshotgun_battery", "ammo_bts_sbshotgun_battery" );

    // Weapons
    g_ItemRegistry.RegisterWeapon( "weapon_bts_axe", "bts_rc/weapons" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_beretta", "bts_rc/weapons", "9mm", "bts:battery", "ammo_bts_beretta", "ammo_bts_beretta_battery" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_crowbar", "bts_rc/weapons" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_eagle", "bts_rc/weapons", "357", "bts:battery", "ammo_bts_eagle", "ammo_bts_eagle_battery" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_flare", "bts_rc/weapons", "weapon_bts_flare", "", "weapon_bts_flare", "" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_flaregun", "bts_rc/weapons", "bts:flare", "", "ammo_bts_flarebox", "" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_flashlight", "bts_rc/weapons", "bts:battery", "", "ammo_bts_battery", "" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_glock", "bts_rc/weapons", "9mm", "", "ammo_bts_glock", "" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_glock17f", "bts_rc/weapons", "9mm", "bts:battery", "ammo_bts_glock17f", "ammo_bts_glock17f_battery" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_glock18", "bts_rc/weapons", "9mm", "", "ammo_bts_glock18", "" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_glocksd", "bts_rc/weapons", "9mm", "", "ammo_bts_glocksd", "" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_knife", "bts_rc/weapons" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_handgrenade", "bts_rc/weapons", "Hand Grenade", "", "weapon_bts_handgrenade", "" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_m4", "bts_rc/weapons", "556", "", "ammo_bts_m4", "" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_m4sd", "bts_rc/weapons", "556", "", "ammo_bts_m4sd", "" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_m16", "bts_rc/weapons", "556", "ARgrenades", "ammo_bts_m16", "ammo_bts_m16_grenade" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_m79", "bts_rc/weapons", "ARgrenades", "", "ammo_bts_m79", "" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_medkit", "bts_rc/weapons", "health", "", "ammo_medkit" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_mp5gl", "bts_rc/weapons", "9mm", "ARgrenades", "ammo_bts_mp5gl", "ammo_bts_mp5gl_grenade" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_mp5", "bts_rc/weapons", "9mm", "", "ammo_bts_mp5", "" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_pipe", "bts_rc/weapons" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_poolstick", "bts_rc/weapons" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_python", "bts_rc/weapons", "357", "", "ammo_bts_python", "" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_shotgun", "bts_rc/weapons", "buckshot", "", "ammo_bts_shotgun", "" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_uzi", "bts_rc/weapons", "9mm", "", "ammo_bts_uzi", "" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_saw", "bts_rc/weapons", "556", "", "ammo_bts_saw", "" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_sbshotgun", "bts_rc/weapons", "buckshot", "bts:battery", "ammo_bts_sbshotgun", "ammo_bts_sbshotgun_battery" );
    g_ItemRegistry.RegisterWeapon( "weapon_bts_screwdriver", "bts_rc/weapons" );
    /*==========================================================================
    *   - End
    ==========================================================================*/

    /*==========================================================================
    *   - Start of Item Mapping
    ==========================================================================*/
    g_ClassicMode.ForceItemRemap( true );
    g_ClassicMode.SetItemMappings(
        {
            ItemMapping( "weapon_9mmhandgun", "ammo_bts_dglocksd" ),
            ItemMapping( "weapon_glock", "ammo_bts_dglocksd" ),
            ItemMapping( "weapon_357", "ammo_bts_357cyl" ),
            ItemMapping( "weapon_eagle", "ammo_bts_dreagle" ),
            ItemMapping( "weapon_9mmAR", "ammo_bts_9mmbox" ),
            ItemMapping( "weapon_mp5", "ammo_bts_9mmbox" ),
            ItemMapping( "weapon_shotgun", "ammo_bts_shotshell" ),
            ItemMapping( "weapon_m16", "ammo_bts_9mmbox" ),
            ItemMapping( "weapon_saw", "ammo_bts_dsaw" ),
            ItemMapping( "weapon_m249", "ammo_bts_dsaw" ),
            ItemMapping( "weapon_minigun", "ammo_bts_dsaw" ),
            ItemMapping( "weapon_medkit", "weapon_bts_medkit" )
        }
    );
    /*==========================================================================
    *   - End
    ==========================================================================*/

    /*==========================================================================
    *   - Start of precaching
    ==========================================================================*/
    models::WXplo1 = g_Game.PrecacheModel( "sprites/WXplo1.spr" );
    models::zerogxplode = g_Game.PrecacheModel( "sprites/zerogxplode.spr" );
    models::steam1 = g_Game.PrecacheModel( "sprites/steam1.spr" );
    models::laserbeam = g_Game .PrecacheModel( "sprites/laserbeam.spr" );
    models::shell = g_Game.PrecacheModel( "models/hlclassic/shell.mdl" );
    models::saw_shell = g_Game.PrecacheModel( "models/bts_rc/weapons/saw_shell.mdl" );
    models::shotgunshell = g_Game.PrecacheModel( "models/hlclassic/shotgunshell.mdl" );

    g_SoundSystem.PrecacheSound( "bts_rc/items/nvg_on.wav" );
    g_SoundSystem.PrecacheSound( "bts_rc/items/nvg_off.wav" );
    g_SoundSystem.PrecacheSound( "items/suitchargeno1.wav" );
    g_SoundSystem.PrecacheSound( "vox/user.wav" );
    g_SoundSystem.PrecacheSound( "vox/security.wav" );
    g_SoundSystem.PrecacheSound( "vox/research.wav" );
    g_SoundSystem.PrecacheSound( "vox/maintenance.wav" );
    g_SoundSystem.PrecacheSound( "vox/authorized.wav" );

    g_Game.PrecacheModel( "models/w_security.mdl" );
    g_Game.PrecacheModel( "models/tool_box.mdl" );
    g_Game.PrecacheModel( "sprites/bts_rc/inv_card_security.spr" );
    g_Game.PrecacheModel( "sprites/bts_rc/inv_card_research.spr" );
    g_Game.PrecacheModel( "sprites/bts_rc/inv_card_maint.spr" );

    g_Game.PrecacheGeneric( "sprites/bts_rc/wepspr.spr" );

    for( uint ui = 0; ui < BloodSplash::Red.length(); ui++ )
        g_Game.PrecacheModel( BloodSplash::Red[ui] );

    for( uint ui = 0; ui < BloodSplash::Yellow.length(); ui++ )
        g_Game.PrecacheModel( BloodSplash::Yellow[ui] );

#if MAP_HAS
    g_Game.PrecacheOther( "item_bts_armorvest" );
    g_Game.PrecacheOther( "item_bts_helmet" );
#endif
    g_Game.PrecacheOther( "item_bts_hevbattery" );
    g_Game.PrecacheOther( "item_bts_sprayaid" );
    g_Game.PrecacheOther( "m79_rocket" );
    g_Game.PrecacheOther( "flare" );
    g_Game.PrecacheOther( "gun_dart" );
    g_Game.PrecacheOther( "ammo_bts_beretta" );
    g_Game.PrecacheOther( "ammo_bts_beretta_battery" );
    g_Game.PrecacheOther( "ammo_bts_eagle" );
    g_Game.PrecacheOther( "ammo_bts_eagle_battery" );
    g_Game.PrecacheOther( "ammo_bts_flarebox" );
#if MAP_HAS
    g_Game.PrecacheOther( "ammo_bts_battery" );
#endif
    g_Game.PrecacheOther( "ammo_bts_glock" );
    g_Game.PrecacheOther( "ammo_bts_glock17f" );
    g_Game.PrecacheOther( "ammo_bts_glock17f_battery" );
    g_Game.PrecacheOther( "ammo_bts_glock18" );
    g_Game.PrecacheOther( "ammo_bts_glocksd" );
    g_Game.PrecacheOther( "ammo_bts_dglocksd" );
    g_Game.PrecacheOther( "ammo_bts_m4" );
    g_Game.PrecacheOther( "ammo_bts_556mag" );
    g_Game.PrecacheOther( "ammo_bts_m4sd" );
    g_Game.PrecacheOther( "ammo_bts_m16" );
    g_Game.PrecacheOther( "ammo_bts_556round" );
    g_Game.PrecacheOther( "ammo_bts_m16_grenade" );
    g_Game.PrecacheOther( "ammo_bts_m79" );
    g_Game.PrecacheOther( "ammo_bts_mp5gl" );
    g_Game.PrecacheOther( "ammo_bts_9mmbox" );
    g_Game.PrecacheOther( "ammo_bts_mp5gl_grenade" );
    g_Game.PrecacheOther( "ammo_bts_mp5" );
    g_Game.PrecacheOther( "ammo_bts_dmp5" );
    g_Game.PrecacheOther( "ammo_bts_python" );
    g_Game.PrecacheOther( "ammo_bts_357cyl" );
    g_Game.PrecacheOther( "ammo_bts_shotgun" );
    g_Game.PrecacheOther( "ammo_bts_shotshell" );
    g_Game.PrecacheOther( "ammo_bts_uzi" );
    g_Game.PrecacheOther( "ammo_bts_saw" );
    g_Game.PrecacheOther( "ammo_bts_dsaw" );
    g_Game.PrecacheOther( "ammo_bts_sbshotgun" );
    g_Game.PrecacheOther( "ammo_bts_sbshotgun_battery" );
#if MAP_HAS
    g_Game.PrecacheOther( "monster_headcrab" );
#endif
    /*==========================================================================
    *   - End
    ==========================================================================*/

    /*==========================================================================
    *   - Start of hooks
    ==========================================================================*/
    g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @player_think );
    g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @player_takedamage );
    g_Hooks.RegisterHook( Hooks::Monster::MonsterKilled, @monster_killed );
    g_Hooks.RegisterHook( Hooks::Monster::MonsterTakeDamage, @monster_takedamage );

    // Remove this shit in 5.27.
    if( g_Game.GetGameVersion() == 526 )
    {
        g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @notice_assets::player_connect );
    }
    /*==========================================================================
    *   - End
    ==========================================================================*/
}

// Model indexes
namespace models
{
    int WXplo1;
    int zerogxplode;
    int steam1;
    int laserbeam;
    int shell;
    int saw_shell;
    int shotgunshell;
}

//sven only has 8192 edicts at any given time
//so assume each player carries exactly 16 weapons, and then leave 100 slots free for various temporary things. -Zode
bool freeedicts( int overhead = 1 )
{
    return ( g_EngineFuncs.NumberOfEntities() < g_Engine.maxEntities - ( 16 * g_Engine.maxClients ) - 100 - overhead );
}

#if SERVER
// Should we display info of aiming entity?
void whatsthat( CBasePlayer@ player )
{
    if( player !is null && player.IsConnected() )
    {
        TraceResult tr;
        Math.MakeVectors( player.pev.v_angle );
        g_Utility.TraceLine( player.EyePosition(), player.EyePosition() + player.GetAutoaimVector( 1.0 ) * 500.0f, dont_ignore_monsters, player.edict(), tr );

        if( g_EntityFuncs.IsValidEntity( tr.pHit ) )
        {
            CBaseEntity@ hit = g_EntityFuncs.Instance( tr.pHit );

            if( hit !is null && hit.GetCustomKeyvalues().HasKeyvalue( "$s_message" ) )
            {
                g_PlayerFuncs.ClientPrint( player, HUD_PRINTCENTER, hit.GetCustomKeyvalues().GetKeyvalue( "$s_message" ).GetString() + "\n" );
            }
        }
    }
}
#endif

/*
    Author: Mikk
*/

enum PM
{
    UNSET = -1,
    BARNEY = 0,
    SCIENTIST = 1,
    CONSTRUCTION = 2,
    BSCIENTIST = 3,
    HELMET = 4,
    CLSUIT = 5
};

final class PlayerClass
{
#if SERVER
    CLogger@ m_Logger = CLogger( "Player Class System" );
#endif

    // Index of the last used model so we give each player a different one instead of a random one.
    private uint mdl_scientist_last = Math.RandomLong( 0, 4 );
    private array<string> mdl_scientist = {
        "bts_scientist",
        "bts_scientist3",
        "bts_scientist4",
        "bts_scientist5",
        "bts_scientist6"
    };
    private uint mdl_barney_last = Math.RandomLong( 0, 3 );
    private array<string> mdl_barney = {
        "bts_barney",
        "bts_barney2",
        "bts_barney3",
        "bts_otis"
    };

    const PM opIndex( CBasePlayer@ player, bool DontSet = false )
    {
        if( player !is null )
        {
            dictionary@ data = player.GetUserData();

            if( !data.exists( "class" ) )
            {
                if( DontSet )
                {
                    return PM::UNSET;
                }

#if SERVER
                m_Logger.info( "Unseted class for {}. Setting as operator", { player.pev.netname } );
#endif

                set_class( player, PM( Math.RandomLong( PM::BARNEY, PM::CONSTRUCTION ) ) );
            }

            return PM( data[ "class" ] );
        }

        return PM::SCIENTIST;
    }

    bool is_trained_personal( CBasePlayer@ player )
    {
        return ( g_PlayerClass[player] == PM::BARNEY || g_PlayerClass[player] == PM::HELMET );
    }

    void set_class( CBasePlayer@ player, PM player_class )
    {
        const string model = this.model( player_class );

        // Update class for bodygroups of view models n
        if( model == "bts_scientist3" )
        {
            player_class = PM::BSCIENTIST;
        }

        player.GetUserData()[ "pm" ] = model;
        player.GetUserData()[ "class" ] = player_class;

        // Hide flashlight icon.
        player.m_iHideHUD &= ~HIDEHUD_FLASHLIGHT;

        player.pev.armortype = ( player_class == PM::HELMET ? 100 : 50 );

#if SERVER
        m_Logger.debug( "Asigned model \"{}\" to player {} at class {}", { model, player.pev.netname, player_class } );
#endif
    }

    // Return a player model for the given class
    const string& model( const PM player_class )
    {
        switch( player_class )
        {
            case PM::CONSTRUCTION:
            {
                return "bts_construction";
            }
            case PM::BARNEY:
            {
                mdl_barney_last = ( mdl_barney_last >= mdl_barney.length() -1 ) ? 0 : mdl_barney_last + 1;
                return mdl_barney[ mdl_barney_last ];
            }
            case PM::CLSUIT:
            {
                return "bts_cleansuit";
            }
            case PM::HELMET:
            {
                return "bts_helmet";
            }
        }
        mdl_scientist_last = ( mdl_scientist_last >= mdl_scientist.length() -1 ) ? 0 : mdl_scientist_last + 1;
        return mdl_scientist[ mdl_scientist_last ];
    }
}

PlayerClass g_PlayerClass;

namespace item_tracker
{
#if SERVER
    CLogger@ m_Logger = CLogger( "Item Tracker" );
#endif
    // Last frame we did an operation.
    float time;
    // String containing all the information.
    string buffer;
}

//================================================================================================
//  Shows a MOTD message to the player
//  Code by Giegue. Taken from: https://github.com/JulianR0/TPvP/blob/master/src/plugins/TPvP.as#L7375
//================================================================================================
namespace motd
{
    void open( CBasePlayer@ player, const string &in buffer )
    {
        if( player !is null && player.IsConnected() )
        {
            uint iChars = 0;

            string szSplitMsg = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

            for( uint uChars = 0; uChars < item_tracker::buffer.Length(); uChars++ )
            {
                szSplitMsg.SetCharAt( iChars, char( item_tracker::buffer[ uChars ] ) );
                iChars++;

                if( iChars == 32 )
                {
                    NetworkMessage motd_append( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict() );
                        motd_append.WriteByte( 0 );
                        motd_append.WriteString( szSplitMsg );
                    motd_append.End();

                    iChars = 0;
                }
            }

            // If we reached the end, send the last letters of the message
            if( iChars > 0 )
            {
                szSplitMsg.Truncate( iChars );

                NetworkMessage motd_fix( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict() );
                    motd_fix.WriteByte( 0 );
                    motd_fix.WriteString( szSplitMsg );
                motd_fix.End();
            }

            NetworkMessage motd_open( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict() );
                motd_open.WriteByte( 1 );
                motd_open.WriteString( "\n" );
            motd_open.End(); 
        }
    }
}