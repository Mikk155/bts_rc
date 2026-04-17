/*
    Author: Mikk
*/

namespace lasers
{
    CScheduledFunction@ __think__ = null;

    void Register( dictionary@ config )
    {
        bool register;

        if( config.get( "turret_lasers", register ) && register )
        {
            @__think__ = g_Scheduler.SetInterval( "__lasers_think__", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES );
            g_Game.PrecacheModel( "sprites/glow01.spr" );

            RegisterCommand( "turret_lasers", "", "toggle turret lasers state", 
                CommandCallback( function( CBasePlayer@ player, array<string>@ arguments )
                {
                    if( __think__ is null )
                    {
                        @__think__ = g_Scheduler.SetInterval( "__lasers_think__", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES );
                        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Enabled laser turrets\n" );
                    }
                    else
                    {
                        g_Scheduler.RemoveTimer( @__think__ );
                        @__think__ = null;
                        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Disabled laser turrets\n" );
                    }
                }
            ), true );
        }
    }

    array<EHandle>@ handles = {};

    CSprite@ sprite( Vector &in VecPos )
    {
        NetworkMessage m2( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
        m2.WriteByte( TE_DLIGHT );
        m2.WriteCoord( VecPos.x );
        m2.WriteCoord( VecPos.y );
        m2.WriteCoord( VecPos.z );
        m2.WriteByte( 8 );   // radius
        m2.WriteByte( 100 ); // R
        m2.WriteByte( 0 );   // G
        m2.WriteByte( 0 );   // B
        m2.WriteByte( 1 );   // life in 0.1's
        m2.WriteByte( 1 );   // decay in 0.1's
        m2.End();

        CSprite@ spr = g_EntityFuncs.CreateSprite( "sprites/glow01.spr", VecPos, true );

        if( spr !is null )
        {
            spr.AnimateAndDie( 10.0f );
            return @spr;
        }
        return null;
    }

    const array<string> turrets = {
        "monster_sentry",
        "monster_turret",
        "monster_miniturret"
    };

    void MapActivate()
    {
        auto chrono = Server::chrono();

        for( uint ui = 0; ui < turrets.length(); ui++ )
        {
            CBaseEntity@ entity = null;

            while( ( @entity = g_EntityFuncs.FindEntityByClassname( entity, turrets[ui] ) ) !is null )
            {
                handles.insertLast( EHandle( entity ) );
            }
        }

        if( g_Logger.info )
        {
            chrono.Stop();
            g_Logger.info = snprintf( glog, "Done configurating sentry lasers. time elapsed: %1.%2 seconds.\n", chrono.Seconds, chrono.Miliseconds );
        }
    }
}

void __lasers_think__()
{
    for( int i = lasers::handles.length() - 1; i >= 0; i-- )
    {
        auto handle = lasers::handles[i];

        if( !handle.IsValid() )
        {
            if( g_Logger.warning )
                g_Logger.warning = snprintf( glog, "Got an invalid handle for laser turrets at index %1 removing...", i );

            lasers::handles.removeAt( i );
            continue;
        }

        CBaseEntity@ entity = handle.GetEntity();

        if( entity is null || !entity.IsAlive() )
        {
            if( g_Logger.trace )
                g_Logger.trace = snprintf( glog, "Got an invalid/dead entity for laser turrets at index %1 removing...", i );

            lasers::handles.removeAt( i );
            continue;
        }

        // 2 sprites 3 temporary entity
        if( !freeedicts( 5 ) )
            return;

        CBaseMonster@ sentry = cast<CBaseMonster>( entity );

        if( sentry is null || sentry.pev.sequence == 0 || !sentry.IsAlive() )
            continue;

        if( !sentry.m_hEnemy.IsValid() )
            continue;

        TraceResult tr;
        Vector VecStart;
        Vector VecAngles;

        if( "monster_sentry" == sentry.pev.classname )
            sentry.GetBonePosition( 5, VecStart, VecAngles );
        else if( "monster_turret" == sentry.pev.classname )
            sentry.GetBonePosition( 9, VecStart, VecAngles );
        else if( "monster_miniturret" == sentry.pev.classname )
            sentry.GetBonePosition( 3, VecStart, VecAngles );

        // Offset of 10 units bellow the eye position
        g_Utility.TraceLine( VecStart, sentry.m_hEnemy.GetEntity().EyePosition() - Vector( 0, 0, 10 ), dont_ignore_monsters, sentry.edict(), tr );

        CSprite@ spr_1 = lasers::sprite( VecStart );
        if( spr_1 !is null )
        {
            spr_1.pev.rendermode = kRenderGlow;          // Glow
            spr_1.pev.renderamt = 255;                   // Amt of glow
            spr_1.pev.rendercolor = Vector( 255, 0, 0 ); // Color of glow
        }

        CSprite@ spr_2 = lasers::sprite( tr.vecEndPos );
        if( spr_2 !is null )
        {
            spr_2.pev.rendermode = kRenderTransAdd;      // Additive
            spr_2.pev.renderamt = 80;                    // Amt of target's sprite
            spr_2.pev.rendercolor = Vector( 255, 0, 0 ); // Color of target's sprite
        }

        NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
        m.WriteByte( TE_BEAMPOINTS );
        m.WriteCoord( VecStart.x );
        m.WriteCoord( VecStart.y );
        m.WriteCoord( VecStart.z );
        m.WriteCoord( tr.vecEndPos.x );
        m.WriteCoord( tr.vecEndPos.y );
        m.WriteCoord( tr.vecEndPos.z );
        m.WriteShort( models::laserbeam );
        m.WriteByte( 0 );   // starting frame
        m.WriteByte( 0 );   // frame rate in 0.1's
        m.WriteByte( 1 );   // life in 0.1's
        m.WriteByte( 1 );   // line width in 0.1's
        m.WriteByte( 0 );   // noise amplitude in 0.01's
        m.WriteByte( 255 ); // R
        m.WriteByte( 0 );   // G
        m.WriteByte( 0 );   // B
        m.WriteByte( 255 ); // brightness
        m.WriteByte( 0 );   // scrol speed in 0.1's
        m.End();
    }
}
