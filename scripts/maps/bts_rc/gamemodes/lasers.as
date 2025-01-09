/*
    Author: Mikk
*/

CCVar@ cvar_sentry_laser = CCVar( "bts_rc_disable_sentry_laser", -1, String::EMPTY_STRING, ConCommandFlag::AdminOnly, @CSentryCallback );

class CLasers
{
    array<EHandle>@ handles = {};

    int beam_index = g_Game.PrecacheModel( "sprites/laserbeam.spr" );
    int model_index = g_Game.PrecacheModel( "sprites/glow01.spr" );

    CScheduledFunction@ scheduler;

    void map_activate()
    {
        const array<string> turrets = {
#if SERVER
                "monster_sentry",
#endif
            "monster_turret",
            "monster_miniturret"
        };

        for( uint ui = 0; ui < turrets.length(); ui++ )
        {
            CBaseEntity@ entity = null;

            while( ( @entity = g_EntityFuncs.FindEntityByClassname( entity, turrets[ui] ) ) !is null )
            {
                this.handles.insertLast( EHandle( entity ) );
            }
        }
    }

    void turn_off()
    {
        if( this.scheduler !is null )
        {
            g_Scheduler.RemoveTimer( this.scheduler );
            @this.scheduler = null;
        }
    }

    void turn_on()
    {
        if( this.scheduler is null )
        {
            @this.scheduler = g_Scheduler.SetInterval( this, "think", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES );
        }
    }

    CSprite@ sprite( Vector&in VecPos )
    {
        NetworkMessage m2( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
            m2.WriteByte( TE_DLIGHT );
            m2.WriteCoord( VecPos.x );
            m2.WriteCoord( VecPos.y );
            m2.WriteCoord( VecPos.z );
            m2.WriteByte( 8 ); // radius
            m2.WriteByte( 100 ); // R
            m2.WriteByte( 0 ); // G
            m2.WriteByte( 0 ); // B
            m2.WriteByte( 1 ); // life in 0.1's
            m2.WriteByte( 1 ); // decay in 0.1's
        m2.End();

        CSprite@ spr = g_EntityFuncs.CreateSprite( "sprites/glow01.spr", VecPos, true );

        if( spr !is null )
        {
            spr.AnimateAndDie( 10.0f );
            return @spr;
        }
        return null;
    }

    void think()
    {
        for( int i = this.handles.length() - 1; i >= 0; i-- )
        {
            if( !this.handles[i].IsValid() )
            {
                this.handles.removeAt(i);
                continue;
            }

            CBaseEntity@ entity = this.handles[i].GetEntity();

            if( entity is null || !entity.IsAlive() )
            {
                this.handles.removeAt(i);
                continue;
            }

            // 2 sprites 3 temporary entity
            if( !freeedicts( 5 ) )
                return;

            CBaseMonster@ sentry = cast<CBaseMonster>( entity );

            if( sentry is null || !sentry.IsAlive() || !sentry.m_hEnemy.IsValid() )
                continue;

            Vector VecStart = sentry.EyePosition();

            TraceResult tr;
            // Offset of 10 units bellow the eye position
            g_Utility.TraceLine( VecStart, sentry.m_hEnemy.GetEntity().EyePosition() - Vector( 0, 0, 10 ), dont_ignore_monsters, sentry.edict(), tr );

            CSprite@ spr_1 = this.sprite( VecStart );
            if( spr_1 !is null )
            {
                spr_1.pev.rendermode = kRenderGlow; // Glow
                spr_1.pev.renderamt = 255; // Amt of glow
                spr_1.pev.rendercolor = Vector( 255, 0, 0 ); // Color of glow
            }

            CSprite@ spr_2 = this.sprite( tr.vecEndPos );
            if( spr_2 !is null )
            {
                spr_2.pev.rendermode = kRenderTransAdd; // Additive
                spr_2.pev.renderamt = 80;   // Amt of target's sprite
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
                m.WriteShort( beam_index );
                m.WriteByte( 0 ); // starting frame
                m.WriteByte( 0 ); // frame rate in 0.1's
                m.WriteByte( 1 ); // life in 0.1's
                m.WriteByte( 1 ); // line width in 0.1's
                m.WriteByte( 0 ); // noise amplitude in 0.01's
                m.WriteByte( 255 ); // R
                m.WriteByte( 0 ); // G
                m.WriteByte( 0 ); // B
                m.WriteByte( 255 ); // brightness
                m.WriteByte( 0 ); // scrol speed in 0.1's
            m.End();
        }
    }
}

CLasers g_sentry_laser;

void CSentryCallback( CCVar@ cvar, const string& in szOldValue, float flOldValue )
{
    if( g_sentry_laser !is null )
    {
        switch( cvar_sentry_laser.GetInt() )
        {
            case 1:
            {
                g_sentry_laser.turn_off();
                break;
            }
            default:
            {
                g_sentry_laser.turn_on();
                break;
            }
        }
    }
}
