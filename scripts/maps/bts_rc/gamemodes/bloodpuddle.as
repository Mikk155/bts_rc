/**
*   Copyright (c) 2026 Mikk155 and contributors of bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software to use, copy, modify, merge, publish, distribute, sublicense,
*   and/or sell copies of the Software under the following conditions:
*   
*   A reference to the original project must be included in all copies or substantial
*   portions of the Software. This must include, at minimum, a URL to:
*   https://github.com/Mikk155/bts_rc
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies of the Software when distributed as a whole.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
**/

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

    void Register( meta_api::json::v2::json@ json ) override
    {
        if( this.IsActive() )
        {
            CustomEntity( "env_bloodpuddle", true );
            this.persistent = json.ValueOrDefault( "persistent", true );

            auto defaultSize = json.ValueOrDefault( "default_size" );
            this.DefaultSize.insertLast( Math.max( 0.1f, defaultSize.ValueOrDefault( "0", 1.5f ) ) );
            this.DefaultSize.insertLast( Math.max( 0.1f, defaultSize.ValueOrDefault( "1", 2.5f ) ) );

            meta_api::json::v2::json@ custom_size = json[ "custom_size" ];

            if( custom_size !is null )
            {
                const auto monsterNames = custom_size.Keys;
                uint monsterSize = monsterNames.length();

                for( uint ui = 0; ui < monsterSize; ui++ )
                {
                    string name = monsterNames[ui];
                    array<float>@ custom_size_array;
                    if( meta_api::json::v2::fmt::ToArray( custom_size[ name ], custom_size_array, false ) )
                        @CustomSizes[ name ] = custom_size_array;
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

        self.pev.solid = SOLID_NOT;
        g_EntityFuncs.SetSize( self.pev, Vector( -12, -12, -1 ), Vector( 12, 12, 1 ) );
        self.pev.angles.y = Math.RandomFloat( 0, 359 );

        if( g_EntityFuncs.IsValidEntity( self.pev.owner ) )
        {
            CBaseEntity@ owner = g_EntityFuncs.Instance( self.pev.owner );
            if( owner !is null )
            {
                self.pev.movetype = owner.pev.movetype;
                self.pev.velocity = owner.pev.velocity;
            }
        }
        else
        {
            self.pev.movetype = MOVETYPE_TOSS;
        }

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
