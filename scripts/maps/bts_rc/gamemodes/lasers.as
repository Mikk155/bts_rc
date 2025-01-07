/*
    Author: Mikk
*/

class Csentry_laser
{
    CScheduledFunction@ scheduler = null;

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
            @this.scheduler = g_Scheduler.SetInterval( this, "think", 0.05f, g_Scheduler.REPEAT_INFINITE_TIMES );
        }
    }

    void think()
    {
        for( uint ui = 0; ui < CONST_LASERS_MONSTERS.length(); ui++ )
        {
            CBaseEntity@ entity = null;

            while( ( @entity = g_EntityFuncs.FindEntityByClassname( entity, CONST_LASERS_MONSTERS[ui] ) ) !is null )
            {
                if( !freeedicts( 10 ) ) // Ask for at least 10 x[
                    return; // Return to avoid more iterations through the array

                CBaseMonster@ sentry = cast<CBaseMonster>( entity );

                if( sentry is null || !sentry.m_hEnemy.IsValid() )
                    continue;

                Vector VecStart = sentry.EyePosition();

                TraceResult tr;
                g_Utility.TraceLine( VecStart, sentry.m_hEnemy.GetEntity().EyePosition() - Vector(0,0,10), dont_ignore_monsters, sentry.edict(), tr );

                NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
                    m.WriteByte( TE_BEAMPOINTS );
                    m.WriteCoord( VecStart.x );
                    m.WriteCoord( VecStart.y );
                    m.WriteCoord( VecStart.z );
                    m.WriteCoord( tr.vecEndPos.x );
                    m.WriteCoord( tr.vecEndPos.y );
                    m.WriteCoord( tr.vecEndPos.z );
                    m.WriteShort( g_ModelFuncs.ModelIndex( CONST_LASERS_BEAM ) );
                    m.WriteByte( 0 ); // starting frame
                    m.WriteByte( 0 ); // frame rate in 0.1's
                    m.WriteByte( 1 ); // life in 0.1's
                    m.WriteByte( 1 ); // line width in 0.1's
                    m.WriteByte( 1 ); // noise amplitude in 0.01's
                    m.WriteByte( 255 ); // R
                    m.WriteByte( 0 ); // G
                    m.WriteByte( 0 ); // B
                    m.WriteByte( 255 ); // brightness
                    m.WriteByte( 1 ); // scrol speed in 0.1's
                m.End();

                CSprite@ sprite = g_EntityFuncs.CreateSprite( CONST_LASERS_MODEL, tr.vecEndPos, true );

                if( sprite !is null )
                {
                    sprite.pev.rendermode = kRenderTransAdd;
                    sprite.pev.renderamt = 50;
                    sprite.AnimateAndDie( 10.0f );
                }
            }
        }
    }
}

Csentry_laser g_sentry_laser;

CCVar@ cvar_sentry_laser = CCVar( "bts_rc_disable_sentry_laser", 0, String::EMPTY_STRING, ConCommandFlag::AdminOnly, @CSentryCallback );

void CSentryCallback( CCVar@ cvar, const string& in szOldValue, float flOldValue )
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
