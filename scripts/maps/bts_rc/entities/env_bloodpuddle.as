/*
    Author: Mikk
    Original Code: Gaftherman
    Original Idea: EdgarBarney (Trinity Rendering)
*/

namespace env_bloodpuddle
{
    enum BLOOD_STATE
    {
        IDLE = 0,
        EXPANDING,
        EXPANDED
    };

    class env_bloodpuddle : ScriptBaseAnimating
    {
        BLOOD_STATE state = BLOOD_STATE::IDLE;
        private float last_time = 0;
        private uint uisize = 0;

        void Spawn()
        {
            self.pev.movetype = MOVETYPE_TOSS;
            self.pev.solid = SOLID_NOT;
            g_EntityFuncs.SetSize( self.pev, Vector( -12, -12, -1 ), Vector( 12, 12, 1 ) );

            SetThink( ThinkFunction( this.think ) );

            g_EntityFuncs.SetModel( self, "models/mikk/misc/bloodpuddle.mdl" );

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
                    self.pev.nextthink = g_Engine.time + 4.0;
                    break;
                }

                    /*  case BLOOD_STATE::EXPANDED:
                        {
                            // Puddle stays forever instead.
                            self.pev.nextthink = g_Engine.time + 1.0;
                            break;
                        }*/

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
    }
}
