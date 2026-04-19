/**   MIT License
*   
*   Copyright (c) 2025 Mikk155 https://github.com/Mikk155/bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies or substantial portions of the Software.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*   SOFTWARE.
*/

/*
*   Author: Mikk
*   Original Code: Gaftherman
*   Original Idea: EdgarBarney (Trinity Rendering)
*/

namespace bloodpuddle
{
    class CConfig : IConfigContext
    {
        array<float> DefaultSize;
        dictionary CustomSizes;
        bool Persistent;

        CConfig()
        {
            ConfigContext::Register( this );
        }

        const string& get_Name() override {
            return "bloodpuddle";
        }

        array<float> GetSize( dictionaryValue@ data )
        {
            dictionary@ dict = cast<dictionary@>(data);
            array<float> list(2);
            dict.get( "0", list[0] );
            dict.get( "1", list[1] );
            return list;
        }

        void Parse( dictionary@ json )
        {
            bool register;

            if( json.get( "active", register ) && register )
            {
                g_Hooks.RegisterHook( Hooks::Monster::MonsterKilled, @bloodpuddle::monster_killed );
                g_CustomEntityFuncs.RegisterCustomEntity( "bloodpuddle::env_bloodpuddle", "env_bloodpuddle" );
                g_Game.PrecacheModel( "models/mikk/misc/bloodpuddle.mdl" );

                DefaultSize = GetSize( json[ "default_size" ] );

                json.get( "persistent", Persistent );

                dictionary@ custom_size = cast<dictionary@>( json[ "custom_size" ] );
                array<string>@ monsterNames = custom_size.getKeys();
                uint monsterSize = monsterNames.length();
                for( uint ui = 0; ui < monsterSize; ui++ )
                {
                    string name = monsterNames[ui];
                    CustomSizes[ name ] = GetSize( custom_size[ name ] );
                }
            }
        }
    }

    CConfig gpConfig;

    class env_bloodpuddle : ScriptBaseAnimating
    {
        uint8 state = 0;
        private float last_time = 0;
        private uint uisize = 0;

        void Spawn()
        {
            self.pev.movetype = MOVETYPE_TOSS;
            self.pev.solid = SOLID_NOT;
            g_EntityFuncs.SetSize( self.pev, Vector( -12, -12, -1 ), Vector( 12, 12, 1 ) );
            self.pev.angles.y = Math.RandomFloat( 0, 359 );

            SetThink( ThinkFunction( this.think ) );
            self.pev.nextthink = g_Engine.time + 0.1;

            g_EntityFuncs.SetModel( self, "models/mikk/misc/bloodpuddle.mdl" );

            switch( state )
            {
                case 2: // Expanded
                {
                    self.pev.renderamt = 255;
                    self.pev.rendermode = kRenderTransTexture;
                    self.pev.sequence = 0;
                    break;
                }

                case 0: // Idle
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
                case 2: // Expanded
                {
                    if( gpConfig.Persistent )
                    {
                        SetThink( null );
                        return;
                    }

                    if( self.pev.renderamt <= 1 )
                    {
                        self.pev.flags |= FL_KILLME;
                        SetThink( null );
                        return;
                    }

                    self.pev.renderamt -= 1;
                    break;
                }
                case 0: // Idle
                case 1: // Expanding
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
                        state = 2; // Set to expanded if the owner has disapear or anything
                    }
                    break;
                }
            }

            self.pev.nextthink = g_Engine.time + 0.1;
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

        array<float> sizes;

        if( !gpConfig.CustomSizes.get( string( monster.pev.classname ), sizes ) || sizes.length() < 2 )
            sizes = gpConfig.DefaultSize;

        bloodpuddle.pev.scale = Math.RandomFloat( sizes[0], sizes[1] );

        /* Monster gibed? Set it to full gib */
        if( monster.ShouldGibMonster( gib ) )
        {
            bloodpuddle.state = 2; // Epanded
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
