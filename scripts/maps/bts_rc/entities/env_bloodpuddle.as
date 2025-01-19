/*
    Author: Mikk
    Original Code: Gaftherman
    Original Idea: EdgarBarney (Trinity Rendering)
*/

namespace env_bloodpuddle
{
#if SERVER
    CLogger@ m_Logger = CLogger( "Blood Puddle" );
#endif

    int model_index = g_Game.PrecacheModel( "models/mikk/misc/bloodpuddle.mdl" );

    enum BLOOD_STATE
    {
        IDLE = 0,
        EXPANDING,
        EXPANDED
    };

    // Create a blood puddle if possible.
    void create( CBaseMonster@ monster, dictionary@ user_data, const int &in gib )
    {
        if( monster is null )
            return;

        /* Do not create for non-bleedable npcs */
        if( monster.m_bloodColor == DONT_BLEED )
            return;

        /* I'm sure Kern fixed this but just in case of a future update, we wouldn't want a bunch of puddles overflow x[ */
        if( user_data.exists( "bloodpuddle" ) )
            return;

        /* Do not create if there's not at least these free slot, let's save them for more important stuff. */
        if( !freeedicts( 30 ) )
        {
#if SERVER
            m_Logger.warn( "Failed to create. Saving edicts for more important stuff." );
#endif
            return;
        }

        CBaseEntity@ entity = g_EntityFuncs.Create( "env_bloodpuddle", monster.pev.origin, g_vecZero, true, monster.edict() );

        if( entity is null )
        {
#if SERVER
            m_Logger.error( "Failed to create for monster \"{}\" at \"{}\"", { monster.pev.classname, monster.pev.origin.ToString() } );
#endif
            return;
        }

        env_bloodpuddle@ bloodpuddle = cast<env_bloodpuddle@>( CastToScriptClass( entity ) );

        if( bloodpuddle is null )
        {
#if SERVER
            m_Logger.error( "Failed to cast to class, Liberating edict." );
#endif
            entity.pev.flags |= FL_KILLME;

            return;
        }

        if( monster.m_bloodColor == ( BLOOD_COLOR_GREEN | BLOOD_COLOR_YELLOW ) )
        {
            bloodpuddle.pev.skin = 1;
        }

        if( monster.pev.classname == "moster_headcrab" || monster.pev.classname == "monster_houndeye" || monster.pev.classname == "monster_babycrab" )
        {
            bloodpuddle.pev.scale = Math.RandomFloat( 0.5, 1.5 );
        }
        else
        {
            bloodpuddle.pev.scale = Math.RandomFloat( 1.5, 2.5 );
        }

        /* Monster gibed? Set it to full gib */
        if( monster.ShouldGibMonster( gib ) )
        {
            bloodpuddle.state = BLOOD_STATE::EXPANDED;
            // Think right away
            bloodpuddle.pev.nextthink = g_Engine.time + 0.1f;
        }
        else
        {
            bloodpuddle.pev.nextthink = g_Engine.time + 0.8f;
        }

        bloodpuddle.Spawn();

        user_data[ "bloodpuddle" ] = true;
    }

    class env_bloodpuddle : ScriptBaseAnimating
    {
        BLOOD_STATE state = BLOOD_STATE::IDLE;
        private float last_time = 0;
        private uint uisize = 0;

        void Spawn()
        {
            self.pev.movetype = MOVETYPE_TOSS;
            self.pev.solid = SOLID_BBOX;
            g_EntityFuncs.SetSize( self.pev, Vector( -12, -12, -1 ), Vector( 12, 12, 1 ) );

#if DISCARDED
            uisize = CONST_BLOODPUDDLE_SND.length();

            if( uisize > 0 )
            {
                SetTouch( TouchFunction( this.touch ) );
            }
#endif
            SetThink( ThinkFunction( this.think ) );

            g_EntityFuncs.SetModel( self, "models/mikk/misc/bloodpuddle.mdl" );

            switch( state )
            {
                case BLOOD_STATE::EXPANDED:
                {
                    self.pev.renderamt = 255;
                    self.pev.rendermode = kRenderTransTexture;
                    self.pev.sequence = 0;
#if SERVER
                    m_Logger.info( "Created for \"{}\" at \"{}\" with scale of \"{}\"", { self.pev.owner.vars.classname, self.pev.origin.ToString(), self.pev.scale } );
#endif
                    break;
                }

                case BLOOD_STATE::IDLE:
                default:
                {
                    self.pev.sequence = 1;
                    self.pev.framerate = Math.RandomFloat( 0.3, 0.6 );  
                    self.pev.frame = 0;
#if SERVER
                    m_Logger.info( "Created for \"{}\" at \"{}\" with scale of \"{}\" at framerate of \"{}\"", { self.pev.owner.vars.classname, self.pev.origin.ToString(), self.pev.scale, self.pev.framerate } );
#endif
                    break;
                }
            }

            self.ResetSequenceInfo();
        }

        void think()
        {
            switch( state )
            {
                case BLOOD_STATE::EXPANDED:
                {
                    if( self.pev.renderamt <= 1 )
                    {
                        self.pev.flags |= FL_KILLME;
                        return;
                    }

                    self.pev.renderamt -= 1;
                    self.pev.nextthink = g_Engine.time + 0.1;
                    break;
                }

                case BLOOD_STATE::IDLE:
                case BLOOD_STATE::EXPANDING:
                default:
                {
                    if( g_EntityFuncs.IsValidEntity( self.pev.owner ) )
                    {
                        self.StudioFrameAdvance();
                    }
                    else
                    {
                        self.pev.renderamt = 255;
                        self.pev.rendermode = kRenderTransTexture;
                        state = BLOOD_STATE::EXPANDED;
                    }
                    self.pev.nextthink = g_Engine.time + 0.1;
                    break;
                }
            }
        }

#if DISCARDED
        void touch( CBaseEntity@ other )
        {
            if( g_Engine.time > last_time && other !is null && other.IsPlayer() )
            {
                g_SoundSystem.PlaySound( self.edict(), CHAN_BODY, CONST_BLOODPUDDLE_SND[ Math.RandomLong( 0, uisize - 1 ) ], 0.5, ATTN_NORM, 0, PITCH_NORM, 0, true, self.GetOrigin() );

                last_time = g_Engine.time + 0.3f;
            }
        }
#endif
    }
}
