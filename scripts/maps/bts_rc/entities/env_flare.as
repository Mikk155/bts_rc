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


array<EHandle> gpLivingFlares(0);

const RGBA ASFlareColor( 255, 21, 18, 100 );
// https://github.com/baso88/SC_AngelScript/wiki/images/engine_palette_2.png
array<int> ASFlareSparksColours = { 0, 1, 4, 5, 6, 8, 9, 10, 11 };

final class ASFlare : ScriptBaseAnimating
{
    private EHandle m_hOwner;
    private array<EHandle> m_Sprites;
    private float m_flBounceTime;

    CSprite@ AllocSprite( const string&in spriteModel )
    {
        CSprite@ sprite = g_EntityFuncs.CreateSprite( spriteModel, self.pev.origin, true );

        sprite.pev.rendercolor[0] = ASFlareColor.r;
        sprite.pev.rendercolor[1] = ASFlareColor.g;
        sprite.pev.rendercolor[2] = ASFlareColor.b;
        sprite.pev.renderamt = ASFlareColor.a;

        this.m_Sprites.insertLast( EHandle( sprite ) );

        return sprite;
    }

    void Activate()
    {
        self.pev.solid = SOLID::SOLID_BBOX;
        self.pev.movetype = MOVETYPE::MOVETYPE_BOUNCE;
        self.pev.effects |= EFFECTS::EF_FULLBRIGHT;

        self.pev.nextthink = g_Engine.time;

        SetThink( ThinkFunction( this.Think ) );
        SetTouch( TouchFunction( this.Touch ) );

        edict_t@ edict = self.edict();

        g_SoundSystem.EmitSoundDyn( edict, SOUND_CHANNEL::CHAN_AUTO, "bts_rc/weapons/flare_on.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

        // Play fire loop
        g_SoundSystem.PlaySound( edict, SOUND_CHANNEL::CHAN_ITEM, "bts_rc/weapons/flare_on.wav", VOL_NORM, ATTN_NONE, 0 );

        if( FreeEdicts(3) )
        {
            CSprite@ sprite;

            @sprite = this.AllocSprite( "sprites/glow01.spr" );
            sprite.SetAttachment( edict, 1 );
            sprite.pev.rendermode = RenderModes::kRenderGlow;
            sprite.pev.renderamt = 255;

            @sprite = this.AllocSprite( "sprites/glow01.spr" );
            sprite.SetAttachment( edict, 1 );
            sprite.pev.rendermode = RenderModes::kRenderGlow;
            sprite.pev.renderamt = 100;
            sprite.pev.scale = 2.5;

            // This sprite is deleted at index 3 when HitFloor is called
            @sprite = this.AllocSprite( "sprites/glow01.spr" );
            sprite.SetAttachment( edict, 1 );
            sprite.pev.rendermode = RenderModes::kRenderTransAdd;
            sprite.pev.renderamt = 100;
        }
    }

    void SetOwner( edict_t@ owner )
    {
        if( owner !is null )
            this.m_hOwner = EHandle( g_EntityFuncs.Instance( owner ) );
    }

    // Get real owner or self if invalid.
    CBaseEntity@ get_Owner() property
    {
        if( this.m_hOwner.IsValid() && this.m_hOwner.GetEntity() !is null )
            return this.m_hOwner.GetEntity();
        return self;
    }

    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/w_flare.mdl" );
        g_EntityFuncs.SetSize( pev, g_vecZero, g_vecZero );
        self.pev.friction = 0.6f;
        gpLivingFlares.insertLast( EHandle( self ) );
        this.SetOwner( self.pev.owner );
        this.Activate();
    }

    void Shutdown()
    {
        SetThink( null );
        SetTouch( null );
        self.pev.nextthink = 0;

        // Stop fire loop
        g_SoundSystem.StopSound( self.edict(), SOUND_CHANNEL::CHAN_ITEM, "bts_rc/weapons/flare_on.wav", false );

        // Kill sprites
        const uint length = this.m_Sprites.length();
        for( uint ui = 0; ui < length; ui++ )
        {
            EHandle handle = this.m_Sprites[ui];
            CBaseEntity@ sprite;

            if( handle.IsValid() && ( @sprite = handle.GetEntity() ) !is null )
                sprite.pev.flags |= FL_KILLME;
        }

        this.m_Sprites.resize(0);

        self.pev.effects &= ~EFFECTS::EF_FULLBRIGHT;
    }

    void UpdateOnRemove()
    {
        this.Shutdown();
    }

    float m_flLastSmoke;
    float m_flLastSpark;

    void Think()
    {
        Vector origin;
        Vector angles;
        self.GetAttachment( 0, origin, angles );

        {
            NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin );
                m.WriteByte( TE_DLIGHT );
                m.WriteCoord( origin.x );
                m.WriteCoord( origin.y );
                m.WriteCoord( origin.z );
                if( self.pev.waterlevel > WATERLEVEL_FEET ) {
                    m.WriteByte( 9 );
                }
                else {
                    m.WriteByte( 18 );
                }
                m.WriteByte( ASFlareColor.r );
                m.WriteByte( ASFlareColor.g );
                m.WriteByte( ASFlareColor.b );
                m.WriteByte( 1 );
                if( g_Engine.time > self.pev.dmgtime ) {
                    m.WriteByte( 64 );
                }
                else {
                    m.WriteByte( 1 );
                }
            m.End();
        }

        if( self.pev.waterlevel > WATERLEVEL_FEET )
        {
            g_Utility.Bubbles( self.pev.absmin, self.pev.absmax, 1 );
        }
        else
        {
            if( this.m_flLastSmoke < g_Engine.time )
            {
                NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin );
                    m.WriteByte( TE_SMOKE );
                    m.WriteCoord( origin.x );
                    m.WriteCoord( origin.y );
                    m.WriteCoord( origin.z - 10 );
                    m.WriteShort( models::steam1 );
                    m.WriteByte( Math.RandomLong( 1, 9 ) );
                    m.WriteByte( 12 );
                m.End();

                this.m_flLastSmoke = 0.8f;
            }
        }

        if( this.m_flLastSpark < g_Engine.time )
        {
            NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin );
                m.WriteByte( TE_STREAK_SPLASH );
                m.WriteCoord( origin.x );
                m.WriteCoord( origin.y );
                m.WriteCoord( origin.z );
                m.WriteCoord( angles[0] );
                m.WriteCoord( angles[1] );
                m.WriteCoord( angles[2] );
                m.WriteByte( ASFlareSparksColours[ Math.RandomLong( 0, ASFlareSparksColours.length() - 1 ) ] );
                m.WriteShort( 10 ); // Count
                m.WriteShort( 128 ); // Base speed
                m.WriteShort( 100 ); // Random velocity
            m.End();

            this.m_flLastSpark = 0.8f;
        }

        self.pev.nextthink = g_Engine.time + 0.1f;

        if( this.m_PlaceScorch )
        {
            TraceResult tr;
            Vector vecEnd = origin;
            vecEnd.z -= 32;
            g_Utility.TraceLine( origin, vecEnd, ignore_monsters, self.edict(), tr );
//            snprintf( smscorch, "smscorch%1", Math.RandomLong( 1, 3 ) );
            g_Utility.DecalTrace( tr, Math.RandomLong( decal_e::DECAL_SMALLSCORCH1, decal_e::DECAL_SMALLSCORCH3 ) );

            this.m_PlaceScorch = false;
        }

        if( g_Engine.time > self.pev.dmgtime )
        {
            this.Shutdown();
        }

        // Stupid ass engine
        if( self.pev.movetype == MOVETYPE::MOVETYPE_BOUNCE && self.pev.velocity.Length() <= 16 )
        {
            TraceResult tr;
            Vector vecEnd = self.pev.origin;
            vecEnd.z -= 200;
            g_Utility.TraceLine( self.pev.origin, vecEnd, ignore_monsters, self.edict(), tr );
            g_EntityFuncs.SetOrigin( self, tr.vecEndPos );
            this.HitFloor();
        }
    }

    bool m_PlaceScorch;

    void HitFloor()
    {
        self.pev.velocity = g_vecZero;
        self.pev.solid = SOLID::SOLID_TRIGGER;
        self.pev.movetype = MOVETYPE::MOVETYPE_NONE;
        g_EntityFuncs.SetSize( pev, Vector( -2, -2, -2 ), Vector( 2, 2, 2 ) );

        // Kill non glow sprite after it hits the floor
        if( m_Sprites.length() >= 3 )
        {
            EHandle handle = m_Sprites[2];
            m_Sprites.removeAt(2);

            if( handle.IsValid() && handle.GetEntity() !is null )
                handle.GetEntity().pev.flags |= FL_KILLME;
        }

        this.m_PlaceScorch = true;
    }

    void Touch( CBaseEntity@ other )
    {
        if( self.pev.owner !is null )
            @self.pev.owner = null;

        if( other is null )
            return;

        BurningMonster::Ignite( other, this.Owner, self.pev.armorvalue, self.pev.armortype );

        if( self.pev.movetype != MOVETYPE::MOVETYPE_BOUNCE )
            return;

        if( self.pev.fuser1 > 0.0 )
        {
            self.pev.velocity.x *= self.pev.fuser1;
            self.pev.velocity.y *= self.pev.fuser1;
        }

        TraceResult tr = g_Utility.GetGlobalTrace();
        Vector vecDir = self.pev.velocity.Normalize();
        Vector vecNewDir = vecDir - 2.0f * tr.vecPlaneNormal * DotProduct( tr.vecPlaneNormal, vecDir );
        self.pev.angles = Math.VecToAngles( vecNewDir );
        self.pev.angles.z -= 90;
        self.pev.angles.y += 90;

        if( other.pev.takedamage != DAMAGE_NO )
        {
            other.TraceAttack( ( self.pev.owner !is null ? self.pev.owner.vars : self.pev ), self.pev.dmg, self.pev.velocity.Normalize(), tr, DMG_SLOWBURN | DMG_NEVERGIB );
            g_SoundSystem.EmitSound( self.edict(), SOUND_CHANNEL::CHAN_AUTO, "bts_rc/weapons/flarehitbod1.wav", VOL_NORM, ATTN_NORM );
        }
        else
        {
            if( ( self.pev.flags & FL_ONGROUND ) == 0 )
            {
                if( g_Engine.time >= m_flBounceTime )
                {
                    m_flBounceTime = g_Engine.time + Math.RandomFloat( 0.2f, 0.3f );

                    if( tr.flFraction < 1.0f )
                    {
                        if( tr.pHit !is null )
                        {
                            CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                            if( pHit.IsBSPModel() )
                            {
                                g_SoundSystem.EmitSoundDyn( self.edict(), SOUND_CHANNEL::CHAN_AUTO, "bts_rc/weapons/flare_bounce.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
                            }
                        }
                    }
                }
            }
        }

        // Touch the floor or is stuck in a monster
        if( ( self.pev.flags & EdictFlags::FL_ONGROUND ) != 0 )
            this.HitFloor();
    }
}

namespace util
{
    float __FlaresCurrentFrame__;
    array<ASFlare@> __FlaresCurrentArray__;

    // Get an array of living env_flare entities
    // Handle to util::__FlaresCurrentArray__ never return null.
    array<ASFlare@>@ GetLivingFlares()
    {
        if( __FlaresCurrentFrame__ == g_Engine.time )
            return @__FlaresCurrentArray__;

        __FlaresCurrentFrame__ = g_Engine.time;
        __FlaresCurrentArray__.resize(0);

        uint length = gpLivingFlares.length();

        for( uint ui = 0; ui < length; ui++ )
        {
            EHandle handle = gpLivingFlares[ui];

            if( !handle.IsValid() || handle.GetEntity() is null )
            {
                gpLivingFlares.removeAt(ui);
                ui--; length--;
                continue;
            }

            __FlaresCurrentArray__.insertLast( cast<ASFlare@>( CastToScriptClass( handle.GetEntity() ) ) );
        }

        return @__FlaresCurrentArray__;
    }
}

bool ASMFlareConfigSchema = g_MapConfig.RegisterSchemaDefinition( "ASMFlareConfigSchema",
"""{
    "flare_duration":
    {
        "type": "integer",
        "minimum": 1,
        "description": "Flare duration"
    },
    "flare_gravity":
    {
        "type": "number",
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "Flare gravity"
    },
    "flare_damage":
    {
        "type": "integer",
        "minimum": 0,
        "description": "Flare damage hitting enemies"
    },
    "flare_burn_damage":
    {
        "type": "integer",
        "minimum": 0,
        "description": "Flare damage when burning enemies"
    },
    "flare_burn_time":
    {
        "type": "number",
        "minimum": 0.1,
        "description": "Flare duration when burning enemies"
    },
    "flare_bounce_resistance":
    {
        "type": "number",
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "X/Y velocity deduction multiplier every time the flare hits something"
    }
}""" );

// mixin for throwing flares
mixin class ASMFlareConfig
{
    const string& get_flare_classname() const property final {
        return "env_flare";
    }

    int flare_duration;
    float flare_gravity;
    int flare_damage;
    int flare_burn_damage;
    float flare_burn_time;
    float flare_bounce_resistance;

    void flare_register( btson@ json ) final
    {
        this.flare_duration = int( json[ "flare_duration" ] );
        this.flare_gravity = float( json[ "flare_gravity" ] );
        this.flare_damage = int( json[ "flare_damage" ] );
        this.flare_burn_damage = int( json[ "flare_burn_damage" ] );
        this.flare_burn_time = float( json[ "flare_burn_time" ] );
        this.flare_bounce_resistance = float( json[ "flare_bounce_resistance" ] );

        if( !g_MapConfig.MapLoading || g_CustomEntityFuncs.IsCustomEntity( this.flare_classname ) )
            return;

        g_CustomEntityFuncs.RegisterCustomEntity( "ASFlare", this.flare_classname );

        g_SoundSystem.PrecacheSound( "bts_rc/weapons/flare_on.wav" );
    }

    ASFlare@ flare_create( CBaseEntity@ owner, Vector&in origin, Vector&in velocity ) const
    {
        if( owner is null )
        {
            g_Logger.error.print( "Null owner at ASMFlareConfig::flare_create(CBaseEntity@, Vector&in, Vector&in)" );
            return null;
        }

        CBaseEntity@ entity = g_EntityFuncs.Create( this.flare_classname, origin, g_vecZero, true, owner.edict() );

        if( entity is null )
            return null;

        ASFlare@ flare = cast<ASFlare@>( CastToScriptClass( entity ) );

        if( flare is null )
        {
            g_EntityFuncs.Remove( entity );
            return null;
        }

        g_EntityFuncs.DispatchSpawn( entity.edict() );

        flare.pev.velocity = velocity;
        flare.pev.gravity = this.flare_gravity;
        flare.pev.angles = Math.VecToAngles( velocity );
        flare.pev.dmg = this.flare_damage;
        flare.pev.armorvalue = this.flare_burn_damage;
        flare.pev.armortype = this.flare_burn_time;
        flare.pev.fuser1 = this.flare_bounce_resistance;
        flare.pev.dmgtime = g_Engine.time + this.flare_duration;

        NetworkMessage msg( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, flare.pev.origin );
            msg.WriteByte( TE_BEAMFOLLOW );
            msg.WriteShort( flare.self.entindex() );
            msg.WriteShort( models::laserbeam );
            msg.WriteByte( 20 );
            msg.WriteByte( 4 );
            msg.WriteByte( 180 );
            msg.WriteByte( 10 );
            msg.WriteByte( 10 );
            msg.WriteByte( 200 );
        msg.End();

        return flare;
    }
}
