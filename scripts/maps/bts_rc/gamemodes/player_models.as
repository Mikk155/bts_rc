/*
    Author: Mikk
*/
namespace player_models
{
    void Precache( const string&in name )
    {
        string model;
        snprintf( model, "models/player/%1/%1.mdl", name, name );
        g_Game.PrecacheModel( model );

        string thumbnail;
        snprintf( thumbnail, "models/player/%1/%1.bmp", name, name );
        g_Game.PrecacheGeneric( thumbnail );
    }

    void Register( dictionary@ config )
    {
        bool register;

        if( !config.get( "force_playermodels", register ) || !register )
            return;

        Precache( "bts_barney" );
        Precache( "bts_barney2" );
        Precache( "bts_barney3" );
        Precache( "bts_cleansuit" );
        Precache( "bts_construction" );
        Precache( "bts_construction2" );
        Precache( "bts_construction3" );
        Precache( "bts_op" );
        Precache( "bts_op2" );
        Precache( "bts_op3" );
        Precache( "bts_op4" );
        Precache( "bts_op6" );
        Precache( "bts_op_band" );
        Precache( "bts_op_free" );
        Precache( "bts_op_hurt" );
        Precache( "bts_otis" );
        Precache( "bts_otis2" );
        Precache( "bts_otis_blk" );
        Precache( "bts_scientist" );
        Precache( "bts_scientist2" );
        Precache( "bts_scientist3" );
        Precache( "bts_scientist4" );
        Precache( "bts_scientist5" );
        Precache( "bts_scientist6" );
        Precache( "bts_helmet" );
        Precache( "bts_op_back" );
        Precache( "bts_op_demo" );
        Precache( "bts_op_dual" );
        Precache( "bts_op_medic" );
        Precache( "bts_op_otis" );
        Precache( "bts_op_pissed" );
        Precache( "bts_op_signal" );
        Precache( "bts_op_vet" );

        g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @player_models::player_think );
    }

    HookReturnCode player_think( CBasePlayer@ player )
    {
        if( player !is null && player.IsConnected() )
        {
            dictionary@ data = player.GetUserData();

            string model;

            if( data.get( "pm", model ) )
                player.SetOverriddenPlayerModel( model );
        }

        return HOOK_CONTINUE;
    }
}
