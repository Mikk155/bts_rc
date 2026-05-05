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

final class ASBloodPuddleConfig : IConfigurable
{
    array<float> DefaultSize;
    dictionary CustomSizes;
    bool persistent;

    const string& get_Name() override
    {
        return "bloodpuddle";
    }

    void Register( BTSJson@ json ) override
    {
        if( this.IsActive() )
        {
            CustomEntity( "env_bloodpuddle", true );
            this.persistent = json.FirstOrDefault( "persistent", true );

            auto defaultSize = json.FirstOrDefault( "default_size" );
            this.DefaultSize.insertLast( Math.max( 0.1f, defaultSize.FirstOrDefault( "0", 1.5f ) ) );
            this.DefaultSize.insertLast( Math.max( 0.1f, defaultSize.FirstOrDefault( "1", 2.5f ) ) );

            dictionary@ custom_size = cast<dictionary@>( json.data[ "custom_size" ] );

            array<float> temp(2);

            if( custom_size is null || custom_size.isEmpty() )
            {
                temp[0] = 0.5f; temp[1] = 1.5f;
                CustomSizes[ "monster_headcrab" ] = temp;
                temp[0] = 1.0f; temp[1] = 2.0f;
                CustomSizes[ "monster_houndeye" ] = temp;
                temp[0] = 0.3f; temp[1] = 0.8f;
                CustomSizes[ "monster_babycrab" ] = temp;

#if I_HATE_WARNINGS
                CustomSizes[ "monster_headcrab" ] = array<float>( 0.5f, 1.5f );
                CustomSizes[ "monster_houndeye" ] = array<float>( 1.0f, 2.0f );
                CustomSizes[ "monster_babycrab" ] = array<float>( 0.3f, 0.8f );
#endif
            }
            else
            {
                array<string>@ monsterNames = custom_size.getKeys();
                uint monsterSize = monsterNames.length();
                for( uint ui = 0; ui < monsterSize; ui++ )
                {
                    string name = monsterNames[ui];
                    dictionary@ dict = cast<dictionary@>( custom_size[ name ] );

                    temp[0] = Math.max( 0.1f, float(dict["0"])); temp[1] = Math.max( 0.1f, float(dict["1"]));
                    CustomSizes[ name ] = temp;

#if I_HATE_WARNINGS
                    CustomSizes[ name ] = array<float>(
                        Math.max( 0.1f, float(dict["0"])),
                        Math.max( 0.1f, float(dict["1"]))
                    );
#endif
                }
            }
        }
    }

    env_bloodpuddle@ Create( CBaseMonster@ monster, int gib )
    {
        if( !this.IsActive() || monster.m_bloodColor == DONT_BLEED || !FreeEdicts(1) )
            return null;

        CBaseEntity@ entity = g_EntityFuncs.Create( "env_bloodpuddle", monster.pev.origin, g_vecZero, true, monster.edict() );

        if( entity is null )
            return null;

        auto bloodpuddle = cast<env_bloodpuddle@>( CastToScriptClass( entity ) );

        if( bloodpuddle is null )
        {
            entity.pev.flags |= FL_KILLME;
            return null;
        }

        if( monster.m_bloodColor == ( BLOOD_COLOR_GREEN | BLOOD_COLOR_YELLOW ) )
            bloodpuddle.pev.skin = 1;

        array<float> sizes;

        if( !gpBloodPuddle.CustomSizes.get( string( monster.pev.classname ), sizes ) || sizes.length() < 2 )
            sizes = gpBloodPuddle.DefaultSize;

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

        return @bloodpuddle;
    }
}

ASBloodPuddleConfig gpBloodPuddle;

class env_bloodpuddle : ScriptBaseAnimating
{
    uint8 state = 0;
    private float last_time = 0;
    private uint uisize = 0;

    void Precache()
    {
        g_Game.PrecacheModel( "models/mikk/misc/bloodpuddle.mdl" );
    }

    void Spawn()
    {
        Precache();

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
                if( gpBloodPuddle.persistent )
                {
                    self.pev.nextthink = g_Engine.time + 30.0;
                    if( !FreeEdicts( 100 ) )
                        g_EntityFuncs.Remove( self ); // Right away so other puddle entities knows
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
