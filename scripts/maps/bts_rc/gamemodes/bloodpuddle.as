/*
*   Author: Mikk
*   Original Code: Gaftherman
*   Original Idea: EdgarBarney (Trinity Rendering)
*/

namespace bloodpuddle
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

    void Register( dictionary@ config )
    {
        bool register;

        if( config.get( "blood_puddles", register ) && register )
        {
            g_Hooks.RegisterHook( Hooks::Monster::MonsterKilled, @bloodpuddle::monster_killed );
            g_CustomEntityFuncs.RegisterCustomEntity( "bloodpuddle::env_bloodpuddle", "env_bloodpuddle" );
            g_Game.PrecacheModel( "models/mikk/misc/bloodpuddle.mdl" );
        }
    }

    HookReturnCode monster_killed( CBaseMonster@ monster, CBaseEntity@ attacker, int gib )
    {
        if( monster is null || !freeedicts( 30 ) || monster.m_bloodColor == DONT_BLEED )
            return HOOK_CONTINUE;

        dictionary@ user_data = monster.GetUserData();

        CBaseEntity@ entity = g_EntityFuncs.Create( "env_bloodpuddle", monster.pev.origin, g_vecZero, true, monster.edict() );

        if( entity is null )
            return HOOK_CONTINUE;

        auto bloodpuddle = cast<env_bloodpuddle@>( CastToScriptClass( entity ) );

        if( bloodpuddle is null )
        {
            entity.pev.flags |= FL_KILLME;
            return HOOK_CONTINUE;
        }

        if( monster.m_bloodColor == ( BLOOD_COLOR_GREEN | BLOOD_COLOR_YELLOW ) )
            bloodpuddle.pev.skin = 1;

        // Small monsters
        if(monster.pev.classname == "monster_headcrab"
        ||  monster.pev.classname == "monster_houndeye"
        ||  monster.pev.classname == "monster_babycrab"
        ) {
            bloodpuddle.pev.scale = Math.RandomFloat( 0.5, 1.5 );
        }
        else {
            bloodpuddle.pev.scale = Math.RandomFloat( 1.5, 2.5 );
        }

        /* Monster gibed? Set it to full gib */
        if( monster.ShouldGibMonster( gib ) )
        {
            bloodpuddle.state = BLOOD_STATE::EXPANDED;
            bloodpuddle.pev.nextthink = g_Engine.time + 0.1f;
        }
        else
        {
            bloodpuddle.pev.nextthink = g_Engine.time + 0.8f;
        }

        bloodpuddle.Spawn();

        return HOOK_CONTINUE;
    }
}
