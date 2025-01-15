//#include "constdef"

#if SERVER
#include "Logger"
#endif

#include "player_class"

//sven only has 8192 edicts at any given time
//so assume each player carries exactly 16 weapons, and then leave 100 slots free for various temporary things. -Zode
bool freeedicts( int overhead = 1 )
{
    return ( g_EngineFuncs.NumberOfEntities() < g_Engine.maxEntities - ( 16 * g_Engine.maxClients ) - 100 - overhead );
}

// For normal entities as i don't like to call 50 functions -Mikk
int LINK_ENTITY_TO_CLASS( const string classname, const string Namespace = String::EMPTY_STRING )
{
    if( Namespace != String::EMPTY_STRING )
    {
        string ClassSpace;
        snprintf( ClassSpace, "%1::%2", Namespace, classname );
        g_CustomEntityFuncs.RegisterCustomEntity( ClassSpace, classname );
    }

    if( !g_CustomEntityFuncs.IsCustomEntity( classname ) )
    {
        g_CustomEntityFuncs.RegisterCustomEntity( classname, classname );
    }

    return 0;
}

#if SERVER
// All the weapons used in the map. These are Inserted in the weapon's Register functions -Mikk
array<string> weapons = {
    "weapon_medkit"
};

void pass_impulse_101( CBasePlayer@ player )
{
    if( player !is null && player.IsConnected() )
    {
        for( uint ui = 0; ui < weapons.length(); ui++ )
        {
            const string weapon_name = weapons[ui];

            player.GiveNamedItem( weapon_name );

            CBasePlayerItem@ item = player.HasNamedPlayerItem( weapon_name );
            
            if( item !is null )
            {
                CBasePlayerWeapon@ weapon = cast<CBasePlayerWeapon@>( item );

                if( weapon !is null )
                {
                    if( weapon.m_iPrimaryAmmoType > 0 )
                        player.m_rgAmmo( weapon.m_iPrimaryAmmoType, weapon.iMaxAmmo1() );
                    if( weapon.m_iSecondaryAmmoType > 0 )
                        player.m_rgAmmo( weapon.m_iSecondaryAmmoType, weapon.iMaxAmmo2() );
                }
            }
        }
    }
}

void trigger_impulse_101( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
    if( pActivator !is null && pActivator.IsPlayer() )
    {
        pass_impulse_101(cast<CBasePlayer@>(pActivator));
    }
}

void check_impulse_101( CBasePlayer@ player )
{
    if( player !is null && player.IsConnected() && player.pev.impulse == 101 && g_EngineFuncs.CVarGetFloat( "sv_cheats" ) > 0 && g_PlayerFuncs.AdminLevel( player ) >= ADMIN_YES )
    {
        pass_impulse_101(player);
        player.pev.impulse = 0;
    }
}

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