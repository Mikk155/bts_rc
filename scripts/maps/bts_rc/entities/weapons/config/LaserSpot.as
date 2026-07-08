// Access weapon laser spotlight modifiers
namespace LaserSpot
{
    enum State
    {
        // Starts off. this happens only once when pickup the weapon
        Undefined = 0,
        // This is idle inactive, the method listens for +use & +reload input. to call TurnOn
        Inactive,
        // Laser just turned on
        TurnOn,
        // Laser is active and being updated
        Active,
        // Laser just turned off
        TurnOff
    };

    final class ASPlayerLaserSpot : ScriptBaseEntity
    {
        private EHandle m_hEntity;

        CBaseEntity@ get_Entity()
        {
            if( this.m_hEntity.IsValid() )
                return this.m_hEntity.GetEntity();

            CBaseEntity@ laser = g_EntityFuncs.CreateEntity( "info_target", null, false );

            laser.pev.movetype = MOVETYPE_NONE;
            laser.pev.solid = SOLID_NOT;
            laser.pev.rendermode = kRenderGlow;
            laser.pev.renderamt = 255.0f;
            laser.pev.renderfx = kRenderFxNoDissipation;
            laser.pev.effects |= EF_NODRAW;

            g_EntityFuncs.DispatchSpawn( laser.edict() );

            this.m_hEntity = EHandle( laser );

            return laser;
        }

        ASPlayerLaserSpot@ SetScale( float scale  ) {
            this.Entity.pev.scale = scale;
            return @this;
        }

        ASPlayerLaserSpot@ SetModel( const string&in model ) {
            g_EntityFuncs.SetModel( this.Entity, model );
            return @this;
        }

        uint m_Distance;

        ASPlayerLaserSpot@ SetDistance( uint distance ) {
            this.m_Distance = distance;
            return @this;
        }

        CBasePlayer@ player;

        // Update laser
        void Update( const State&in newState, State&out nextState = void )
        {
            if( player is null )
                return;

            switch( newState )
            {
                case State::Undefined:
                {
                    nextState = State::Inactive;

                    g_PlayerFuncs.PrintKeyBindingString( player, "+use & +reload toggle laser spot\n" );

                    break;
                }
                case State::Inactive:
                {
                    nextState = State::Inactive;

                    if( ( player.pev.button & IN_USE ) != 0 && ( player.pev.button & IN_RELOAD ) != 0 )
                    {
                        nextState = State::TurnOn;
                    }

                    break;
                }
                case State::TurnOn:
                {
                    nextState = State::Active;

                    this.Entity.pev.effects &= ~EF_NODRAW;

                    break;
                }
                case State::Active:
                {
                    nextState = State::Active;

                    Math.MakeVectors( player.pev.v_angle );
                    Vector vecSrc = player.GetGunPosition();
                    Vector vecEnd = vecSrc + ( g_Engine.v_forward * this.m_Distance );
                    // -TODO Fade renderamt based on how far away we are from hitting something solid?

                    TraceResult tr;
                    g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, player.edict(), tr );
                    g_EntityFuncs.SetOrigin( this.Entity, tr.vecEndPos );

                    if( ( player.pev.button & IN_USE ) != 0 && ( player.pev.button & IN_RELOAD ) != 0 )
                    {
                        nextState = State::TurnOff;
                    }

                    break;
                }
                case State::TurnOff:
                {
                    nextState = State::Inactive;

                    this.Entity.pev.effects |= EF_NODRAW;

                    break;
                }
            }
        }
    }

    array<ASPlayerLaserSpot> gpLaserSpots( g_Engine.maxClients );

    ASPlayerLaserSpot@ Get( CBasePlayer@ player )
    {
        ASPlayerLaserSpot@ laser = null;

        if( player !is null )
        {
            @laser = gpLaserSpots[ player.entindex() - 1 ];
            @laser.player = player;
        }

        return @laser;
    }
}
