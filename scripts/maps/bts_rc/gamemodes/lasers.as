/*
    Author: Mikk
*/

class CLasers
{
    int beam_index = g_Game.PrecacheModel( CONST_LASERS_BEAM );
    int model_index = g_Game.PrecacheModel( CONST_LASERS_MODEL );

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
            @this.scheduler = g_Scheduler.SetInterval( this, "think", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES );
        }
    }

    CSprite@ sprite( Vector&in VecPos )
    {
        CSprite@ spr = g_EntityFuncs.CreateSprite( CONST_LASERS_MODEL, VecPos, true );

        if( spr !is null )
        {
            spr.AnimateAndDie( 10.0f );
            return @spr;
        }
        return null;
    }

    void think()
    {
        for( uint ui = 0; ui < CONST_LASERS_MONSTERS.length(); ui++ )
        {
            CBaseEntity@ entity = null;

            while( ( @entity = g_EntityFuncs.FindEntityByClassname( entity, CONST_LASERS_MONSTERS[ui] ) ) !is null )
            {
                if( !freeedicts( 3 ) )
                    return; // Return to avoid more iterations through the array

                CBaseMonster@ sentry = cast<CBaseMonster>( entity );

                if( sentry is null || !sentry.IsAlive() || !sentry.m_hEnemy.IsValid() )
                    continue;

                Vector VecStart = sentry.EyePosition();

                TraceResult tr;
                g_Utility.TraceLine( VecStart, sentry.m_hEnemy.GetEntity().EyePosition() - Vector( 0, 0, CONST_LASERS_TARGET_OFFSET ), dont_ignore_monsters, sentry.edict(), tr );

                CSprite@ spr_1 = this.sprite( VecStart );
                if( spr_1 !is null )
                {
                    spr_1.pev.rendermode = kRenderGlow;
                    spr_1.pev.renderamt = CONST_LASERS_GRENDERAMT;
                }

                CSprite@ spr_2 = this.sprite( tr.vecEndPos );
                if( spr_2 !is null )
                {
                    spr_2.pev.rendermode = kRenderTransAdd;
                    spr_2.pev.renderamt = CONST_LASERS_SRENDERAMT;
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
                    m.WriteByte( 1 ); // noise amplitude in 0.01's
                    m.WriteByte( 255 ); // R
                    m.WriteByte( 0 ); // G
                    m.WriteByte( 0 ); // B
                    m.WriteByte( 255 ); // brightness
                    m.WriteByte( 1 ); // scrol speed in 0.1's
                m.End();
            }
        }
    }
}

CLasers g_sentry_laser;

CCVar@ cvar_sentry_laser = CCVar( "bts_rc_disable_sentry_laser", 0, String::EMPTY_STRING, ConCommandFlag::AdminOnly, @CSentryCallback );

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
