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
        g_Game.PrecacheModel( this.world_model );
        g_Game.PrecacheModel( this.player_model );
        this.viewmodelIndex = g_Game.PrecacheModel( this.view_model );
    }

    uint viewmodelIndex;

    void Parse( dictionary@ json ) override
    {
        this.Precache();

        this.viewmodelIndex = g_ModelFuncs.ModelIndex( gpWeaponCrowbarConfig.view_model );

        this.ParseDefaultVariables( json );

        g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, PlayerPostThinkHook( function( CBasePlayer@ player )
        {
            if( player is null || !player.m_hActiveItem.IsValid() )
                return HOOK_CONTINUE;

            auto weapon = cast<CBasePlayerWeapon@>( player.m_hActiveItem.GetEntity() );

            if( weapon is null || weapon.GetClassname() != "weapon_crowbar" )
                return HOOK_CONTINUE;

            auto character = GetCharacter(player);

            if( player.pev.viewmodel != gpWeaponCrowbarConfig.view_model )
            {
                player.pev.viewmodel = gpWeaponCrowbarConfig.view_model;
                weapon.pev.body = g_ModelFuncs.SetBodygroup( gpWeaponCrowbarConfig.viewmodelIndex, weapon.pev.body, 0, ( character !is null ? character.HandsGroup : Hands::Gray ) );
                weapon.SendWeaponAnim( player.pev.weaponanim, 0, weapon.pev.body ); // Resend the current animation to update the bodygroup
            }

            return HOOK_CONTINUE;
        } ) );
    }
}

CWeaponCrowbarConfig gpWeaponCrowbarConfig;
