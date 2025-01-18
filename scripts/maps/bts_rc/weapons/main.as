#include "proj/dart"
#include "proj/flare"
#include "proj/m79_rocket"

#include "weapon_bts_axe"
#include "weapon_bts_beretta"
#include "weapon_bts_crowbar"
#include "weapon_bts_eagle"
#include "weapon_bts_flare"
#include "weapon_bts_flaregun"
#include "weapon_bts_flashlight"
#include "weapon_bts_glock"
#include "weapon_bts_glock17f"
#include "weapon_bts_glock18"
#include "weapon_bts_glocksd"
#include "weapon_bts_handgrenade"
#include "weapon_bts_knife"
#include "weapon_bts_m4"
#include "weapon_bts_m4sd"
#include "weapon_bts_m16"
#include "weapon_bts_m79"
#include "weapon_bts_medkit"
#include "weapon_bts_mp5"
#include "weapon_bts_mp5gl"
#include "weapon_bts_pipe"
#include "weapon_bts_poolstick"
#include "weapon_bts_python"
#include "weapon_bts_saw"
#include "weapon_bts_sbshotgun"
#include "weapon_bts_screwdriver"
#include "weapon_bts_shotgun"
#include "weapon_bts_uzi"

array<ItemMapping@> g_AmmoReplacement =
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
};

const int WEAPON_DEFAULT_FLAGS = ( ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_NOAUTORELOAD );

mixin class bts_rc_base_weapon
{
    // To not cast repeatedly
    private CBasePlayer@ player = null;
    protected CBasePlayer@ get_player()
    {
        if( player is null || player !is self.m_hPlayer.GetEntity() )
            @player = cast<CBasePlayer>( self.m_hPlayer.GetEntity() );
        return @player;
    }

    bool bts_deploy( const string &in viewmodel, const string &in playermodel, int animation, const string &in animation_ext, int hands_group = 1 )
    {
        m_pPlayer.pev.viewmodel = self.GetV_Model( viewmodel );
        m_pPlayer.pev.weaponmodel = self.GetP_Model( playermodel );
        m_pPlayer.set_m_szAnimExtension( animation_ext );
        pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( viewmodel ), pev.body, hands_group, g_PlayerClass[ m_pPlayer ] );
        self.SendWeaponAnim( animation, 0, pev.body );
        return true;
    }
};
