/*
    Author: Mikk
*/
#include "class_selector"
#include "hev_nightvision"

enum PM
{
    UNSET = -1,
    BARNEY,
    SCIENTIST,
    CONSTRUCTION,
    HELMET = 4,
    CLSUIT,
    OPERATIVE,
    HELMET_CIVIL,
    CLSUIT_CIVIL
};

enum PM_Hands
{
    Blue = 0,
    White,
    Orange,
    WhiteBlackHands,
    Hevsuit,
    Cleansuit,
    Gray,
    BlueBlackHands,
    Green,
    GrayGloves
};

namespace player_models
{
    uint scientistLast;
    array<string> scientist(0);
    uint barneyLast;
    array<string> barney(0);
    uint operativeLast;
    array<string> operative(0);
    uint constructorLast;
    array<string> constructor(0);

    void Register( const string&in name, array<string>@ list )
    {
        string model;
        snprintf( model, "models/player/%1/%1.mdl", name, name );
        g_Game.PrecacheModel( model );

        string thumbnail;
        snprintf( thumbnail, "models/player/%1/%1.bmp", name, name );
        g_Game.PrecacheGeneric( thumbnail );

        if( list !is null )
        {
            list.insertLast( name );
        }
    }

    bool IsHEV( CBasePlayer@ player )
    {
        switch( player_models::GetClass( player ) )
        {
            case PM::HELMET:
            case PM::HELMET_CIVIL:
                return true;
            default:
                return false;
        }
    }

    bool CanPickBattery( CBasePlayer@ player )
    {
        switch( player_models::GetClass( player ) )
        {
            case PM::CLSUIT:
            case PM::CLSUIT_CIVIL:
            case PM::HELMET:
            case PM::HELMET_CIVIL:
                return true;
            default:
                return false;
        }
    }

    const PM_Hands GetViewmodel( CBasePlayer@ player )
    {
        PM pm = GetClass( player );

        switch( pm )
        {
            case PM::BARNEY:
            {
                if( string( player.GetUserData()["pm"] ) == "bts_otis_blk" )
                    return PM_Hands::BlueBlackHands;
                return PM_Hands::Blue;
            }
            case PM::SCIENTIST:
            {
                if( string( player.GetUserData()["pm"] ) == "bts_scientist3" )
                    return PM_Hands::WhiteBlackHands;
                return PM_Hands::White;
            }
            case PM::CONSTRUCTION:
            {
                if( string( player.GetUserData()["pm"] ) == "bts_construction2" )
                    return PM_Hands::Green;
                return PM_Hands::Orange;
            }
            case PM::HELMET:
            case PM::HELMET_CIVIL:
            {
                return PM_Hands::Hevsuit;
            }
            case PM::CLSUIT:
            case PM::CLSUIT_CIVIL:
            {
                return PM_Hands::Cleansuit;
            }
            case PM::OPERATIVE:
            {
                if( string( player.GetUserData()["pm"] ) == "bts_op_demo" )
                    return PM_Hands::GrayGloves;
                return PM_Hands::Gray;
            }
        }

        return PM_Hands::White;
    }

    // Return a player model for the given class
    string GetModel( const PM player_class )
    {
        switch( player_class )
        {
            case PM::SCIENTIST:
            {
                scientistLast = ( scientistLast >= scientist.length() - 1 ) ? 0 : scientistLast + 1;
                return scientist[scientistLast];
            }
            case PM::CONSTRUCTION:
            {
                constructorLast = ( constructorLast >= constructor.length() - 1 ) ? 0 : constructorLast + 1;
                return constructor[constructorLast];
            }
            case PM::BARNEY:
            {
                barneyLast = ( barneyLast >= barney.length() - 1 ) ? 0 : barneyLast + 1;
                return barney[barneyLast];
            }
            case PM::OPERATIVE:
            {
                operativeLast = ( operativeLast >= operative.length() - 1 ) ? 0 : operativeLast + 1;
                return operative[operativeLast];
            }
            case PM::CLSUIT:
            case PM::CLSUIT_CIVIL:
            {
                return "bts_cleansuit";
            }
            case PM::HELMET:
            case PM::HELMET_CIVIL:
            {
                return "bts_helmet";
            }
            case PM::UNSET:
            default:
            {
                return String::EMPTY_STRING;
            }
        }
    }

    bool IsTrainedPersonal( CBasePlayer@ player )
    {
        PM pm = GetClass( player );

        switch( pm )
        {
            case PM::BARNEY:
            case PM::OPERATIVE:
            case PM::HELMET:
            case PM::CLSUIT:
                return true;
        }
        return false;
    }

    void SetClass( CBasePlayer@ player, PM player_class )
    {
        const string model = GetModel( player_class );

        dictionary@ data = player.GetUserData();

        data["pm"] = model;

        // Set appropiate class for hev/cleansuit for IsTrainedPersonal
        if( player_class == PM::HELMET || player_class == PM::CLSUIT )
        {
            auto oldClass = GetClass( player );

            if( oldClass != PM::UNSET )
            {
                switch( oldClass )
                {
                    case PM::SCIENTIST:
                    case PM::CONSTRUCTION:
                        if( player_class == PM::HELMET )
                            player_class = PM::HELMET_CIVIL;
                        if( player_class == PM::CLSUIT )
                            player_class = PM::CLSUIT_CIVIL;
                    break;
                }
            }
        }

        data["class"] = player_class;

        // Hide flashlight icon.
        player.m_iHideHUD |= HIDEHUD_FLASHLIGHT;

        // Re-Deploy weapon to update view model hands
        if( player.m_hActiveItem.IsValid() )
        {
            CBaseEntity@ active_item = player.m_hActiveItem.GetEntity();

            if( active_item !is null )
            {
                CBasePlayerItem@ weapon = cast<CBasePlayerItem@>( active_item );

                if( weapon !is null )
                {
                    weapon.Deploy();
                }
            }
        }

        switch( player_class )
        {
            case PM::HELMET:
            case PM::HELMET_CIVIL:
                player.pev.armortype = 100;
            break;
            case PM::CLSUIT:
            case PM::CLSUIT_CIVIL:
                player.pev.armortype = 75;
            break;
            default:
                player.pev.armortype = 50;
            break;
        }
    }

    const PM GetClass( CBasePlayer@ player )
    {
        if( player !is null )
        {
            dictionary@ data = player.GetUserData();

            if( data.exists( "class" ) )
                return PM( data["class"] );
        }

        return PM::UNSET;
    }

    void Register( dictionary@ config )
    {
        if( bool( config[ "force_playermodels" ] ) )
        {
            g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink,
                PlayerPostThinkHook( function( CBasePlayer@ player )
                {
                    if( player !is null && player.IsConnected() )
                    {
                        string model;
                        dictionary@ data = player.GetUserData();

                        if( data.get( "pm", model ) )
                        {
                            player.SetOverriddenPlayerModel( model );
                        }
                    }

                    return HOOK_CONTINUE;
                }
            ) );
        }

        Register( "bts_barney", barney );
        Register( "bts_barney2", barney );
        Register( "bts_barney3", barney );

        Register( "bts_otis", barney );
        Register( "bts_otis2", barney );
        Register( "bts_otis_blk", barney );

        Register( "bts_cleansuit", null );
        Register( "bts_helmet", null );

        Register( "bts_scientist", scientist );
        Register( "bts_scientist2", scientist );
        Register( "bts_scientist3", scientist );
        Register( "bts_scientist4", scientist );
        Register( "bts_scientist5", scientist );
        Register( "bts_scientist6", scientist );

        Register( "bts_construction", constructor );
        Register( "bts_construction2", constructor );
        Register( "bts_construction3", constructor );

        Register( "bts_op", operative );
        Register( "bts_op2", operative );
        Register( "bts_op3", operative );
        Register( "bts_op4", operative );
        Register( "bts_op6", operative );
        Register( "bts_op_band", operative );
        Register( "bts_op_free", operative );
        Register( "bts_op_hurt", operative );
        Register( "bts_op_back", operative );
        Register( "bts_op_demo", operative );
        Register( "bts_op_dual", operative );
        Register( "bts_op_medic", operative );
        Register( "bts_op_otis", operative );
        Register( "bts_op_pissed", operative );
        Register( "bts_op_signal", operative );
        Register( "bts_op_vet", operative );

        scientistLast = Math.RandomLong( 0, scientist.length() - 1 );
        barneyLast = Math.RandomLong( 0, barney.length() - 1 );
        operativeLast = Math.RandomLong( 0, operative.length() - 1 );
        constructorLast = Math.RandomLong( 0, constructor.length() - 1 );

        g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @player_models::OnPlayerThink );
    }

    HookReturnCode OnPlayerThink( CBasePlayer@ player )
    {
        if( player is null )
            return HOOK_CONTINUE;

        PM player_class = player_models::GetClass(player);

        dictionary@ user_data = player.GetUserData();

        if( player_class == PM::UNSET )
        {
            if( gpGameStarted ) // Allow newly join players to choose a class
                class_selector::Think( player );
            return HOOK_CONTINUE;
        }

        bool isInHEVSuit = IsHEV( player );

        if( isInHEVSuit )
        {
            hev_nightvision::Think( player );
        }

        if( player.pev.impulse == 100 )
        {
            // Not in hev? Try to activate the lantern on the active weapon if available
            if( !isInHEVSuit )
            {
                CBasePlayerWeapon@ weapon = cast<CBasePlayerWeapon@>( player.m_hActiveItem.GetEntity() );

                if( weapon !is null && ( weapon.pszAmmo2() != "bts:battery" && weapon.pszAmmo1() != "bts:battery" ) )
                    @weapon = null;

                if( weapon is null )
                {
                    for( int i = 0; i < MAX_ITEM_TYPES; i++ )
                    {
                        CBasePlayerItem@ item = player.m_rgpPlayerItems(i);

                        while( item !is null )
                        {
                            @weapon = cast<CBasePlayerWeapon@>( item );

                            if( weapon !is null && weapon.pszAmmo2() == "bts:battery" || weapon.pszAmmo1() == "bts:battery" )
                            {
                                player.SelectItem( weapon.pev.classname );
                                weapon.Deploy();
                                i = MAX_ITEM_TYPES; // Break for loop
                                break;
                            }

                            @weapon = null;
                            @item = cast<CBasePlayerWeapon@>( item.m_hNextItem.GetEntity() );
                        }
                    }
                }

                if( weapon !is null )
                {
                    weapon.m_flNextSecondaryAttack = g_Engine.time;
                    weapon.SecondaryAttack();
                }
            }

            // Deny flashlight as we use our own.
            player.pev.impulse = 0;
        }

        return HOOK_CONTINUE;
    }
}
