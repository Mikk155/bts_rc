/*
*   Author: AraseFiq
*   Rewrited by Rizulix for bts_rc (january 2025)
*   Rewrited by mikk 14/4/26
*/

enum WeaponCrowbarAnim
{
    Idle = 0,
    Draw,
    Holster,
    Attack1Hit,
    Attack1Miss,
    Attack2Miss,
    Attack2Hit,
    Attack3Miss,
    Attack3Hit,
    Idle2,
    Idle3,
    Shove,
    ShoveMiss,
    ShoveAlt,
    ShoveAltMiss
};

class CWeaponCrowbarConfig : ASMeleeWeaponConfig
{
    string GetName() override
    {
        return "weapon_crowbar";
    }

    const string& get_view_model() override {
        return "models/bts_rc/weapons/v_crowbar.mdl";
    }

    void Precache() override
    {
        g_Game.PrecacheModel( this.view_model );
        g_Game.PrecacheModel( this.world_model );
        g_Game.PrecacheModel( this.player_model );
    }

    void Parse( dictionary@ json ) override
    {
        this.Precache();

        this.ParseDefaultVariables( json );

        g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, PlayerPostThinkHook( function( CBasePlayer@ player )
        {
            if( player is null || !player.m_hActiveItem.IsValid() )
                return HOOK_CONTINUE;

            auto weapon = cast<CBasePlayerWeapon@>( player.m_hActiveItem.GetEntity() );

            if( weapon is null || weapon.GetClassname() != "weapon_crowbar" )
                return HOOK_CONTINUE;

            auto character = GetCharacter(player);

            dictionary@ data = player.GetUserData();

            if( player.pev.viewmodel != gpWeaponCrowbarConfig.view_model )
            {
                player.pev.viewmodel = gpWeaponCrowbarConfig.view_model;
                data.delete( "crowbar_seq" );
            }

            int crowbar_seq;
            if( !data.get( "crowbar_seq", crowbar_seq ) || crowbar_seq != player.pev.weaponanim )
            {
                Hands handGroup = ( character !is null ? character.HandsGroup : Hands::Gray );
                weapon.pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( gpWeaponCrowbarConfig.view_model ), weapon.pev.body, 0, handGroup );
                weapon.SendWeaponAnim( player.pev.weaponanim, 0, weapon.pev.body );
                data[ "crowbar_seq" ] = player.pev.weaponanim;
            }

            return HOOK_CONTINUE;
        } ) );
    }
}

CWeaponCrowbarConfig gpWeaponCrowbarConfig;
