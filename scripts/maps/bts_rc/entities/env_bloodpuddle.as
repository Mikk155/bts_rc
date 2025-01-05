namespace env_bloodpuddle
{
    int register = LINK_ENTITY_TO_CLASS( "env_bloodpuddle", "env_bloodpuddle" );

    class env_bloodpuddle : ScriptBaseAnimating
    {
        void Spawn()
        {
            self.pev.movetype = MOVETYPE_NONE;
            self.pev.solid = SOLID_NOT;
            self.pev.scale = Math.RandomFloat( 1.5, 2.5 );

            g_EntityFuncs.SetModel( self, CONST_BLOODPUDDLE );
            g_EntityFuncs.SetOrigin( self, self.pev.origin );
            self.pev.sequence = 2;

            SetThink( ThinkFunction( this.init ) );
            self.pev.nextthink = g_Engine.time + 0.8f;
        }

        void init()
        {
            self.pev.sequence = 1;
            self.pev.frame = 0;
            self.ResetSequenceInfo();
            self.pev.framerate = Math.RandomFloat( 0.3, 0.6 );  

            SetThink( ThinkFunction( this.animate ) );
            self.pev.nextthink = g_Engine.time + 0.1f;
        }

        void fade()
        {
            if( self.pev.renderamt <= 0 )
            {
                self.pev.flags |= FL_KILLME;
                return;
            }

            self.pev.renderamt -= 1;
            self.pev.nextthink = g_Engine.time + 0.1;
        }

        void animate()
        {
            CBaseEntity@ pOwner = g_EntityFuncs.Instance( self.pev.owner );

            if( pOwner !is null && self != pOwner && pOwner.IsMonster() )
            {
                self.pev.origin = pOwner.pev.origin;
            }
            else
            {
                self.pev.renderamt = 255;
                self.pev.rendermode = kRenderTransTexture;
                SetThink( ThinkFunction( this.fade ) );
            }

            self.StudioFrameAdvance();
            self.pev.nextthink = g_Engine.time + 0.1;
        }
    }
}
