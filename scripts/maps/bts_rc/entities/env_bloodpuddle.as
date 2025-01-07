/*
    Author: Mikk
    Original Code: Gaftherman
    Original Idea: EdgarBarney (Trinity Rendering)
*/

CCVar@ cvar_bloodpuddles = CCVar( "bts_rc_disable_bloodpuddles", 0 );

namespace env_bloodpuddle
{
    #if SERVER
        CLogger@ m_Logger = CLogger( "Blood Puddle" );
    #endif

    int model_index = g_Game.PrecacheModel( CONST_BLOODPUDDLE );

    int register = LINK_ENTITY_TO_CLASS( "env_bloodpuddle", "env_bloodpuddle" );

    enum BLOOD_STATE
    {
        IDLE = 0,
        EXPANDING,
        EXPANDED
    };

    // Create a blood puddle if possible.
    void create( CBaseMonster@ monster, dictionary@ user_data, int gib )
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
                m_Logger.info( "Failed to create a blood puddle. Saving edicts for more important stuff." );
            #endif

            return;
        }

        CBaseEntity@ entity = g_EntityFuncs.Create( "env_bloodpuddle", monster.pev.origin, g_vecZero, true, monster.edict() );

        if( entity is null )
        {
            #if SERVER
                m_Logger.info( "Failed to create a blood puddle for monster {} at {}", { monster.pev.classname, monster.pev.origin.ToString() } );
            #endif

            return;
        }

        env_bloodpuddle@ bloodpuddle = cast<env_bloodpuddle@>( CastToScriptClass( entity ) );

        if( bloodpuddle is null )
        {
            #if SERVER
                m_Logger.info( "Failed to cast blood puddle, Liberating edict." );
            #endif

            entity.pev.flags |= FL_KILLME;

            return;
        }

        if( monster.m_bloodColor == ( BLOOD_COLOR_GREEN | BLOOD_COLOR_YELLOW ) )
        {
            bloodpuddle.pev.skin = 1;
        }

        if( small_monsters.find( monster.pev.classname ) > 0 )
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

        #if SERVER
            m_Logger.info( "Created blood puddle for {} at {}", { monster.pev.classname, monster.pev.origin.ToString() } );
        #endif

        user_data[ "bloodpuddle" ] = true;
    }

    // small size monsters for puddle's scale
    array<string> small_monsters = {
        "moster_headcrab",
        "monster_houndeye",
        "monster_babycrab"
    };

    class env_bloodpuddle : ScriptBaseAnimating
    {
        BLOOD_STATE state = BLOOD_STATE::IDLE;

        void Spawn()
        {
            self.pev.movetype = MOVETYPE_TOSS;
            self.pev.solid = SOLID_BBOX;
            g_EntityFuncs.SetSize( self.pev, Vector( -12, -12, -1 ), Vector( 12, 12, 1 ) );

            SetTouch( TouchFunction( this.touch ) );
            SetThink( ThinkFunction( this.think ) );

            g_EntityFuncs.SetModel( self, CONST_BLOODPUDDLE );

            #if SERVER
                m_Logger.info( "Scale of \"{}\"", { self.pev.scale } );
            #endif

            switch( state )
            {
                case BLOOD_STATE::EXPANDED:
                {
                    self.pev.renderamt = 255;
                    self.pev.rendermode = kRenderTransTexture;
                    self.pev.sequence = 0;
                    break;
                }

                case BLOOD_STATE::IDLE:
                default:
                {
                    self.pev.sequence = 1;
                    self.pev.framerate = Math.RandomFloat( 0.3, 0.6 );  
                    self.pev.frame = 0;

                    #if SERVER
                        m_Logger.info( "Expadig at a framerate of \"{}\"", { self.pev.framerate } );
                    #endif
                }
                break;
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
                    if( g_EntityFuncs.IsValidEntity( self.pev.owner ) && g_EntityFuncs.Instance( self.pev.owner ) !is null )
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

        // Idk why this is not working x[
        void touch( CBaseEntity@ other )
        {
            if( other !is null && other.edict() !is self.pev.owner )
            {
                uint uisize = CONST_BLOODPUDDLE_SND.length();

                if( uisize > 0 )
                {
                    const string sound = CONST_BLOODPUDDLE_SND[ Math.RandomLong( 0, uisize - 1 ) ];
                    g_SoundSystem.PlaySound( self.edict(), CHAN_BODY, sound, 0.5, ATTN_NORM, 0, PITCH_NORM, 0, true, self.GetOrigin() );
                }
            }
        }
    }
}
