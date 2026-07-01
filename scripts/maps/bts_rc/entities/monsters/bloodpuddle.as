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
    array<float> m_DefaultSize;
    dictionary m_CustomSizes;
    bool m_persistent;

    const string& GetName() const override {
        return "bloodpuddle";
    }

    const string GetSchema() const override {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Blood puddles",
            "description": "Controls blood puddle behavior and appearance.",
            "allOf":
            [
                "IConfigurable"
            ],
            "properties":
            {
                "persistent":
                {
                    "type": "boolean",
                    "default": true,
                    "description": "If true, puddles remain indefinitely until the map is about at 100 free entity slots. Otherwise they fade out as soon as the monster owner disappears."
                },
                "default_size":
                {
                    "type": "array",
                    "minItems": 2,
                    "maxItems": 2,
                    "items":
                    {
                        "minimum": 0.1,
                        "type": "number"
                    },
                    "default": [ 1.5, 2.5 ],
                    "description": "Random size range for puddles (min, max)."
                },
                "custom_size":
                {
                    "type": "object",
                    "default": 
                    {
                        "monster_headcrab": [ 0.5, 1.5 ],
                        "monster_houndeye": [ 1, 2 ],
                        "monster_babycrab": [ 0.3, 0.8 ],
                        "monster_snark": [ 0.25, 0.75 ]
                    },
                    "additionalProperties":
                    {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items":
                        {
                            "minimum": 0.1,
                            "type": "number"
                        },
                        "prefixItems":
                        [
                            { "description": "Minimun scale size for randomization" },
                            { "description": "Maximun scale size for randomization" }
                        ]
                    },
                    "description": "Per-monster custom puddle size overrides."
                }
            }
        }""";
    }

    bool Register( meta_api::json::v2::json@ config ) override
    {
        if( !bool( config[ "active" ] ) )
            return false;

        @gpBloodPuddle = this;

        CustomEntity( "env_bloodpuddle", false );
        g_Game.PrecacheModel( "models/mikk/misc/bloodpuddle.mdl" );

        this.m_persistent = bool( config[ "persistent" ] );

        array<float>@ arr;

        if( !meta_api::json::v2::fmt::ToArray( config[ "default_size" ], arr, false ) )
        {
            @arr = { 1.5f, 2.5f };
        }
        else if( arr[0] > arr[1] )
        {
            g_Logger.error.print( "Blood puddle default size for \"default_size\" has inverted values! first number should be lesser than the second!" );
            float temp = arr[0];
            arr[0] = arr[1];
            arr[1] = temp;
        }

        if( g_Logger.info.active )
            g_Logger.info.print( "Set blood puddle default size to min: {} max: {}", { arr[0], arr[1] } );

        this.m_DefaultSize = arr;

        meta_api::json::v2::json@ custom_size = config[ "custom_size" ];

        if( custom_size is null )
            return true;

        const auto monsterNames = custom_size.Keys;
        uint monsterSize = monsterNames.length();

        for( uint ui = 0; ui < monsterSize; ui++ )
        {
            string name = monsterNames[ui];

            if( !meta_api::json::v2::fmt::ToArray( custom_size[ name ], arr, false ) )
            {
                g_Logger.error.print( "Blood puddle custom size for {} is an invalid array of two values!", { name } );
                continue;
            }

            if( arr[0] > arr[1] )
            {
                g_Logger.error.print( "Blood puddle custom size for {} has inverted values! first number should be lesser than the second!", { name } );
                float temp = arr[0];
                arr[0] = arr[1];
                arr[1] = temp;
            }

            @this.m_CustomSizes[ name ] = arr;

            if( g_Logger.info.active )
                g_Logger.info.print( "Set blood puddle for {} min: {} max: {}", { name, arr[0], arr[1] } );
        }
        return true;
    }

    env_bloodpuddle@ Create( CBaseMonster@ monster, int gib )
    {
        if( monster.m_bloodColor == DONT_BLEED || !FreeEdicts(1) )
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

        if( !gpBloodPuddle.m_CustomSizes.get( string( monster.pev.classname ), sizes ) || sizes.length() < 2 )
            sizes = gpBloodPuddle.m_DefaultSize;

        bloodpuddle.pev.scale = Math.RandomFloat( sizes[0], sizes[1] );

        if( g_Logger.trace.active )
            g_Logger.trace.print( "Generated {} blood puddle with scale {} for {} at {}", {
                ( bloodpuddle.pev.skin == 1 ? "yellow" : "red" ),
                bloodpuddle.pev.scale,
                monster.pev.classname,
                monster.pev.origin.ToString()
            } );

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

ASBloodPuddleConfig@ gpBloodPuddle = null;

class env_bloodpuddle : ScriptBaseAnimating
{
    uint8 state = 0;
    private float last_time = 0;
    private uint uisize = 0;

    private bool IsOwnerGibbed( CBaseEntity@ owner )
    {
        if( owner is null )
        {
            return true;
        }

        if( ( owner.pev.effects & EF_NODRAW ) != 0 )
        {
            return true;
        }

        if( owner.pev.modelindex == 0 )
        {
            return true;
        }

        if( ( owner.pev.flags & FL_KILLME ) != 0 )
        {
            return true;
        }

        return false;
    }

    void Spawn()
    {
        self.pev.solid = SOLID_NOT;
        g_EntityFuncs.SetSize( self.pev, Vector( -12, -12, -1 ), Vector( 12, 12, 1 ) );
        self.pev.angles.y = Math.RandomFloat( 0, 359 );

        CBaseEntity@ owner = null;
        if( g_EntityFuncs.IsValidEntity( self.pev.owner ) )
        {
            @owner = g_EntityFuncs.Instance( self.pev.owner );
        }

        if( state != 2 && owner !is null && !IsOwnerGibbed( owner ) )
        {
            if( owner.pev.movetype == MOVETYPE_BOUNCE )
            {
                self.pev.movetype = MOVETYPE_TOSS;
            }
            else
            {
                self.pev.movetype = owner.pev.movetype;
            }
            self.pev.velocity = owner.pev.velocity;
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
                if( gpBloodPuddle.m_persistent )
                {
                    self.pev.nextthink = g_Engine.time + 30.0;
                    if( !FreeEdicts( 100 ) )
                    {
                        g_EntityFuncs.Remove( self ); // Right away so other puddle entities knows
                    }
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
                CBaseEntity@ owner = null;
                if( g_EntityFuncs.IsValidEntity( self.pev.owner ) )
                {
                    @owner = g_EntityFuncs.Instance( self.pev.owner );
                }

                if( owner !is null && !IsOwnerGibbed( owner ) )
                {
                    self.StudioFrameAdvance();
                }
                else
                {
                    self.pev.renderamt = 255;
                    self.pev.rendermode = kRenderTransTexture;
                    self.pev.movetype = MOVETYPE_TOSS;
                    state = 2; // Set to expanded if the owner has disapear or anything
                }
                break;
            }
        }

        self.pev.nextthink = g_Engine.time + 0.1;
    }
}
