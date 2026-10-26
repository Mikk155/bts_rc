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

// Creates a flame that lives until pev->dmgtime
// Set the EHandle Target to a entity to follow, Requires SOLID_NOT.
final class env_flame : ScriptBaseEntity
{
    private
        EHandle m_hTarget;

    private
        EHandle m_hOwner;

    private
        EHandle m_Sprite;

    private
        float m_NextBurnEffect;

    private
        float m_NextBurnDamage;

    void Spawn()
    {
        self.pev.scale = 1.0f;
        self.pev.effects |= EF_NODRAW;
        self.pev.movetype = MOVETYPE_FLY;
        self.pev.solid = SOLID_TRIGGER;

        g_EntityFuncs.SetSize( self.pev, Vector( -8, -8, -8 ), Vector( 8, 8, 8 ) );

        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        CSprite@ sprite = g_EntityFuncs.CreateSprite( "sprites/bts_rc/fthrow.spr", g_vecZero, true );
        sprite.SetTransparency( RenderModes::kRenderTransAdd, 255, 255, 255, 100, RenderFX::kRenderFxNone );
        g_EntityFuncs.DispatchKeyValue( sprite.edict(), "vp_type", 1 );

        this.m_Sprite.opAssign( sprite );
        this.m_hOwner.opAssign( g_EntityFuncs.Instance( self.pev.owner ) );

        g_SoundSystem.PlaySound( self.edict(), SOUND_CHANNEL::CHAN_AUTO, "bts_rc/player/pl_burn.wav", VOL_NORM, ATTN_NORM, 0 );

        self.pev.dmg = g_WeaponsConfig.fire_damage;

        self.pev.nextthink = g_Engine.time;

        SetTouch( TouchFunction( this.FlameTouch ) );
        SetThink( ThinkFunction( this.FlameThink ) );
    }

    void FlameTouch( CBaseEntity@ other )
    {
        if( other is null || other.edict() is self.pev.owner || other.GetClassname() == self.GetClassname() )
            return;

        if( self.pev.owner !is null )
        {
            @self.pev.owner = null;
            self.pev.velocity.x = Math.RandomLong( -100, 100 );
            self.pev.velocity.y = Math.RandomLong( -100, 100 );
        }

        if( other.IsBSPModel() || other.GetClassname() == "worldspawn" )
        {
            float entSize = ( self.pev.mins - self.pev.maxs ).Length();

            if( ( env_flame::g_LastDecal - self.pev.origin ).Length() > entSize + 1 )
            {
                TraceResult tr;
                Math.MakeVectors( self.pev.angles );
                g_Utility.TraceLine( self.pev.origin, self.pev.origin + ( g_Engine.v_forward * entSize ), IGNORE_MONSTERS::ignore_monsters, self.edict(), tr );
                g_Utility.DecalTrace( tr, DECAL_SMALLSCORCH1 + Math.RandomLong( 0, 2 ) );
                env_flame::g_LastDecal = tr.vecEndPos;
            }
        }
        else
        {
            DamageEntity( other );
            env_flame::Ignite( other, m_hOwner.GetEntity() );
        }
    }

    void AnimateFlame( float x, float y, float z, int size )
    {
        NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, self.pev.origin );
            m.WriteByte( TE_EXPLOSION );
            m.WriteCoord( x );
            m.WriteCoord( y );
            m.WriteCoord( z - 16 );
            m.WriteShort( models::fthrow );
            m.WriteByte( int( Math.Ceil( size * self.pev.scale ) ) );
            m.WriteByte( 12 );
            m.WriteByte( ( TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES ) );
        m.End();
    }

    void SetDuration( float duration )
    {
        self.pev.dmgtime = Math.max( self.pev.dmgtime, g_Engine.time + duration );
    }

    void SetTarget( CBaseEntity@ target, float duration )
    {
        self.pev.solid = SOLID_NOT;
        self.pev.movetype = MOVETYPE_NONE;
        this.m_hTarget.opAssign( target );
        target.GetUserData()[ "env_flame" ] = EHandle( self );
        this.SetDuration( duration );
    }

    void DamageEntity( CBaseEntity@ victim )
    {
        if( victim !is null && this.m_NextBurnDamage <= g_Engine.time )
        {
            this.m_NextBurnDamage = g_Engine.time + 0.3f;

            victim.TakeDamage(
                self.pev,
                ( m_hOwner.IsValid() ? m_hOwner.GetEntity().pev : self.pev ),
                ( self.pev.dmg * env_flame::GetResistance( victim ) ),
                ( DMG_SLOWBURN | DMG_BURN | DMG_NEVERGIB )
            );
        }
    }

    void FlameThink()
    {
        CBaseEntity@ target = m_hTarget.GetEntity();

        DamageEntity( target );

        if( g_Engine.time >= self.pev.dmgtime || ( self.pev.solid == SOLID_NOT && ( target is null ) ) )
        {
            UpdateOnRemove();
            self.pev.flags |= EdictFlags::FL_KILLME;
            return;
        }

        if( target !is null )
        {
            if( target.IsAlive() )
            {
                g_EntityFuncs.SetOrigin( self, target.Center() );
            }
        }
        else
        {
            float newScale = Math.min( 1.0f, self.pev.scale + 0.05f );

            if( newScale != self.pev.scale )
            {
                float sizeScaled = 8 * newScale;
                g_EntityFuncs.SetSize( self.pev, Vector( -sizeScaled, -sizeScaled, -sizeScaled ), Vector( sizeScaled, sizeScaled, sizeScaled ) );
                self.pev.scale = newScale;
            }

            self.pev.velocity = self.pev.velocity * 0.8f;
            self.pev.velocity.z = Math.RandomLong( 30, 60 );
        }

        if( this.m_NextBurnEffect <= g_Engine.time )
        {
            if( target !is null )
            {
                this.AnimateFlame(
                    Math.RandomFloat( target.pev.absmin.x + ( target.pev.mins.x / 2 ), target.pev.absmax.x - ( target.pev.maxs.x / 2 ) ),
                    Math.RandomFloat( target.pev.absmin.y + ( target.pev.mins.y / 2 ), target.pev.absmax.y - ( target.pev.maxs.y / 2 ) ),
                    Math.RandomFloat( target.pev.absmin.z + ( target.pev.mins.z / 2 ), target.pev.absmax.z - ( target.pev.maxs.z / 2 ) ),
                    Math.RandomLong( 4, 7 )
                );
            }
            else
            {
                this.AnimateFlame( self.pev.origin.x, self.pev.origin.y, self.pev.origin.z, 6 );
            }

            g_SoundSystem.PlaySound( self.edict(), SOUND_CHANNEL::CHAN_AUTO, "bts_rc/player/pl_burn.wav", VOL_NORM, ATTN_NORM, 0 );

            this.m_NextBurnEffect = g_Engine.time + 0.08f;
        }

        if( this.m_Sprite.IsValid() )
        {
            auto sprite = this.m_Sprite.GetEntity();

            if( sprite !is null )
            {
                sprite.pev.scale = self.pev.scale;
                g_EntityFuncs.SetOrigin( sprite, self.pev.origin );
            }
        }

        self.pev.nextthink = g_Engine.time + 0.1f;
    }

    void UpdateOnRemove()
    {
        if( this.m_hTarget.IsValid() )
        {
            auto target = this.m_hTarget.GetEntity();

            if( target !is null )
            {
                dictionary@ data = target.GetUserData();
                data.delete( "env_flame" );
            }
        }

        if( this.m_Sprite.IsValid() )
        {
            auto sprite = this.m_Sprite.GetEntity();

            if( sprite !is null )
            {
                sprite.pev.flags |= EdictFlags::FL_KILLME;
            }
        }
    }
}

namespace env_flame
{
    // Last decal was placed here. used to not draw too many decals in the same place.
    Vector g_LastDecal;

    // Set resistance (multiplier 0.0/1.0) for the given entity.
    void SetResistance( CBaseEntity@ entity, float percent = 1.0f )
    {
        g_EntityFuncs.DispatchKeyValue( entity.edict(), "$f_flame_inmune", percent );
    }

    float GetResistance( CBaseEntity@ entity )
    {
        auto ckv = entity.GetCustomKeyvalues();

        if( !ckv.HasKeyvalue( "$f_flame_inmune" ) )
            return 1.0f;

        return ckv.GetKeyvalue( "$f_flame_inmune" ).GetFloat();
    }

    // Get the env_flame that is incinerating the given target. null otherwise.
    env_flame@ GetFlame( CBaseEntity@ target )
    {
        return cast<env_flame@>( CastToScriptClass( EHandle( target.GetUserData()[ "env_flame" ] ).GetEntity() ) );
    }

    env_flame@ Factory( CBaseEntity@ owner )
    {
        CBaseEntity@ entity = g_EntityFuncs.Create( "env_flame", g_vecZero, g_vecZero, false, owner.edict() );

        auto flame = cast<env_flame@>( CastToScriptClass( entity ) );

        return flame;
    }

    // Ignite the given target
    env_flame@ Ignite( CBaseEntity@ target, CBaseEntity@ attacker )
    {
        if( attacker is null
        || target is null
        || !target.IsMonster()
        || target.pev.takedamage == DAMAGE_NO )
            return null;

        env_flame@ flame = env_flame::GetFlame( target );

        if( flame is null )
        {
            @flame = env_flame::Factory( attacker );
        }

        float duration = g_WeaponsConfig.fire_duration;

        int bonus = Difficulty::Level() + 1;

        // Attack from player, invert difficulty bonus
        if( attacker.IsPlayer() && attacker.IRelationship( target ) != R_AL )
        {
            bonus = Difficulty::__Size__ - bonus;
        }

        flame.SetTarget( target, duration * bonus );

        return flame;
    }

    // Check for DMG_BURN bit and set victim on flames if it's not already burning.
    void IgniteCheck( DamageInfo@ info )
    {
        if( info is null || info.pVictim is null || ( info.bitsDamageType & DMG_BURN ) == 0 )
            return;

        if( info.pAttacker !is null && info.pAttacker.GetClassname() == "env_flame" )
            return;

        if( info.pInflictor !is null && info.pInflictor.GetClassname() == "env_flame" )
            return;

        env_flame::Ignite( info.pVictim, ( info.pAttacker !is null ? info.pAttacker : info.pInflictor ) );
    }
}
