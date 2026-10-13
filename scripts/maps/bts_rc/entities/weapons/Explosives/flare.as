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
    }
}""" );

// mixin for throwing flares
mixin class ASMFlareConfig
{
    const string& get_flare_classname() const property final {
        return "bts_flare";
    }

    int flare_duration;
    float flare_gravity;
    int flare_damage;
    int flare_burn_damage;
    float flare_burn_time;

    void flare_register( btson@ json ) final
    {
        this.flare_duration = int( json[ "flare_duration" ] );
        this.flare_gravity = float( json[ "flare_gravity" ] );
        this.flare_damage = int( json[ "flare_damage" ] );
        this.flare_burn_damage = int( json[ "flare_burn_damage" ] );
        this.flare_burn_time = float( json[ "flare_burn_time" ] );

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

        flare.pev.nextthink = g_Engine.time;

        return flare;
    }
}

final class ASWeaponFlareConfig : ASWeaponConfig, ASMFlareConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_flare";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_flare.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_flare.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_flare.mdl";
    }

    const string& get_animation_extension() override
    {
        return "gren";
    }

    const string& get_primary_ammo() override
    {
        return "Trip Mine";
    }

    const string& get_primary_ammoentity() override
    {
        return "weapon_bts_flare";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponFlareAnim::Draw;
    }

    const uint8 get_hands_group() override
    {
        return 0;
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapon config",
            "description": "weapon-related gameplay modifiers.",
            "allOf":
            [
                "ASWeaponConfig",
                "ASMFlareConfigSchema"
            ]
        }""";
    }

    bool Register( btson@ json ) override
    {
        flare_register(json);
        return ASWeaponConfig::Register( json );
    }
}

ASWeaponFlareConfig gpWeaponFlareConfig;

enum WeaponFlareAnim
{
    Idle = 0,
    PullPin,
    Throw,
    Draw,
    Toss,
    PullHold,
    Hold
};

final class ASFlare : ScriptBaseEntity
{
//================
    private float m_flBounceTime;
    private int m_iBounces = 0;

    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/w_flare.mdl" );
        g_EntityFuncs.SetSize( pev, Vector( -2, -2, -2 ), Vector( 2, 2, 2 ) );

        self.pev.friction = 0.6f;
        self.pev.solid = SOLID::SOLID_BBOX;
        self.pev.movetype = MOVETYPE::MOVETYPE_BOUNCE;
        self.pev.effects |= EFFECTS::EF_FULLBRIGHT;

        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "bts_rc/weapons/flare_on.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
    }

    void Think()
    {
        NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, self.pev.origin );
            m.WriteByte( TE_DLIGHT );
            m.WriteCoord( self.pev.origin.x );
            m.WriteCoord( self.pev.origin.y );
            m.WriteCoord( self.pev.origin.z );
            if( self.pev.waterlevel > WATERLEVEL_FEET ) {
                m.WriteByte( 9 );
            }
            else {
                m.WriteByte( 18 );
            }
            m.WriteByte( 255 );
            m.WriteByte( 21 );
            m.WriteByte( 18 );
            m.WriteByte( 1 );
            if( g_Engine.time > self.pev.dmgtime ) {
                m.WriteByte( 64 );
            }
            else {
                m.WriteByte( 1 );
            }
        m.End();

        if( self.pev.waterlevel > WATERLEVEL_FEET )
        {
            g_Utility.Bubbles( self.pev.absmin, self.pev.absmax, 1 );
        }
        else
        {
            if( Math.RandomLong( 0, 8 ) == 1 )
            {
                // -TODO TE_ something?
                g_Utility.Sparks( self.pev.origin );
            }
        }

        if( g_Engine.time > self.pev.dmgtime )
        {
            self.pev.flags |= FL_KILLME;
        }

        self.pev.nextthink = g_Engine.time + 0.1f;
    }

    void Touch( CBaseEntity@ pOther )
    {
        BurningMonster::Ignite( pOther, g_EntityFuncs.Instance( self.pev.owner ), self.pev.armorvalue, self.pev.armortype );

        if( ( m_iBounces < 10 ) && self.pev.waterlevel < WATERLEVEL_FEET )
        {
            g_Utility.Sparks( self.pev.origin );
        }

        TraceResult tr = g_Utility.GetGlobalTrace();
        Vector vecDir = self.pev.velocity.Normalize();
        Vector vecNewDir = vecDir - 2.0f * tr.vecPlaneNormal * DotProduct( tr.vecPlaneNormal, vecDir );
        self.pev.angles = Math.VecToAngles( vecNewDir );
        self.pev.angles.z -= 90;
        self.pev.angles.y += 90;

        if( pOther.pev.takedamage != DAMAGE_NO )
        {
            pOther.TraceAttack( ( self.pev.owner !is null ? self.pev.owner.vars : self.pev ), self.pev.dmg, self.pev.velocity.Normalize(), tr, DMG_BURN | DMG_NEVERGIB );
            g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "bts_rc/weapons/flarehitbod1.wav", VOL_NORM, ATTN_NORM );
        }
        else
        {
            m_iBounces++;
            if( ( self.pev.flags & FL_ONGROUND ) == 0 )
            {
                if( g_Engine.time >= m_flBounceTime )
                {
                    m_flBounceTime = g_Engine.time + Math.RandomFloat( 0.2f, 0.3f );

                    if( g_Utility.GetGlobalTrace().flFraction < 1.0f )
                    {
                        if( g_Utility.GetGlobalTrace().pHit !is null )
                        {
                            CBaseEntity@ pHit = g_EntityFuncs.Instance( g_Utility.GetGlobalTrace().pHit );
                            if( pHit.IsBSPModel() )
                            {
                                g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "bts_rc/weapons/flare_bounce.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
                            }
                        }
                    }
                }
            }

            self.pev.velocity.x *= 0.8f;
            self.pev.velocity.y *= 0.8f;

            if( self.pev.velocity.Length() < 64.0f )
            {
                self.pev.velocity = g_vecZero;
                self.pev.movetype = MOVETYPE_NONE;
            }
        }
    }
}

class weapon_bts_flare : BTS_Weapon, IThrowable
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponFlareConfig;
    }

    private int throw = 0;
    private float m_fAttackStart = 0.0f;
    private ASFlare@ m_FlareOnHold;
    private bool m_bInAttack = false;
    private bool m_bThrown = false;
    private int m_iAmmoSave = 0;

    CBasePlayer@ get_Thrower() property { return this.owner; }
    CBasePlayerWeapon@ get_ThrowableWeapon() property { return self; }
    ASWeaponConfig@ get_ThrowableConfig() property { return this.config; }
    AttackType get_ThrowAttackType() property { return throw == 1 ? AttackType::Secondary : AttackType::Primary; }
    bool get_Rolling() property { return throw == 1; }

    void SpawnThrowable( const Vector&in source, const Vector&in velocity, float damage )
    {
        gpWeaponFlareConfig.flare_create( this.owner, source, velocity );
    }

    void Spawn() override
    {
        BTS_Weapon::Spawn();
    }

    bool CanHaveDuplicates()
    {
        return true;
    }

    bool Deploy() override
    {
        PlaySound( "bts_rc/weapons/flare_deploy.wav", 0.6f, PITCH_NORM, CHAN_ITEM );
        m_iAmmoSave = 0;
        return BTS_Weapon::Deploy();
    }

    bool CanHolster()
    {
        return m_fAttackStart == 0.0f;
    }

    bool CanDeploy()
    {
        return this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0;
    }

    CBasePlayerItem@ DropItem()
    {
        m_iAmmoSave = this.owner.AmmoInventory( self.m_iPrimaryAmmoType );
        return self;
    }

    void DropHoldingFlare()
    {
        if( this.m_FlareOnHold !is null )
        {
            this.owner.m_rgAmmo( self.m_iPrimaryAmmoType, this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
            this.m_FlareOnHold.self.pev.effects &= ~EF_NODRAW;
            this.m_FlareOnHold.self.pev.velocity.z = -90;
            this.m_FlareOnHold.self.pev.movetype = MOVETYPE_TOSS;
            @this.m_FlareOnHold = null;
        }
    }

    void Holster( int skiplocal = 0 )
    {
        m_bThrown = false;
        m_bInAttack = false;
        m_fAttackStart = 0.0f;

        ClearTimerList();

        if( this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
        {
            m_iAmmoSave = this.owner.m_rgAmmo( self.m_iPrimaryAmmoType );
        }

        if( m_iAmmoSave <= 0 )
        {
            g_Scheduler.SetTimeout( "DestroyThrowableWeapon", 0.1f, EHandle( self ) );
        }

        this.DropHoldingFlare();

        BaseClass.Holster( skiplocal );
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        this.DropHoldingFlare();

        if( this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        if( m_fAttackStart < 0.0f || m_fAttackStart > 0.0f )
            return;

        this.SetCooldown( util::IsTrainedPersonal( this.owner ), type );

        switch( type )
        {
            case AttackType::Primary:
            {
                throw = 0;
                m_bInAttack = true;
                m_fAttackStart = g_Engine.time + ( 25.0f / 30.0f );
                PlayAnim( WeaponFlareAnim::PullPin );
                break;
            }
            case AttackType::Secondary:
            {
                throw = 1;
                m_bInAttack = true;
                m_fAttackStart = g_Engine.time + ( 25.0f / 25.0f );
                PlayAnim( WeaponFlareAnim::PullPin );
                break;
            }
            case AttackType::Tertiary:
            {
                PlayAnim( WeaponFlareAnim::PullHold );
//                @this.m_FlareOnHold = FLARE::Toss( this.owner.pev, g_vecZero, g_vecZero, 0 );
//                this.m_FlareOnHold.self.pev.nextthink = self.m_flNextTertiaryAttack;
                break;
            }
        }

        self.m_flTimeWeaponIdle = g_Engine.time + ( 25.0f / 30.0f ) + ( 23.0f / 30.0f );
    }

    void LaunchThink()
    {
        weapons::Throw( this );

        this.owner.m_rgAmmo( self.m_iPrimaryAmmoType, this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
        m_fAttackStart = 0.0f;
    }

    void ItemPreFrame()
    {
        BaseClass.ItemPreFrame();

        if( this.m_FlareOnHold !is null )
        {
            Vector origin;
            g_EngineFuncs.GetAttachment( this.owner.edict(), 1, origin, void );
            g_EntityFuncs.SetOrigin( this.m_FlareOnHold.self, origin );
            this.m_FlareOnHold.self.pev.effects |= EF_NODRAW;
            return;
        }

        if( m_fAttackStart == 0.0f && m_bThrown == true && m_bInAttack == false && self.m_flTimeWeaponIdle - 0.1f < g_Engine.time )
        {
            if( this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
            {
                self.Holster();
            }
            else
            {
                self.Deploy();
                m_bThrown = false;
                m_bInAttack = false;
                m_fAttackStart = 0.0f;
            }
        }

        if( !m_bInAttack || CheckButton() || g_Engine.time < m_fAttackStart )
            return;

        self.m_flTimeWeaponIdle = weapons::SetCooldown( self, this.owner, ( 22.0f / 30.0f ) );

        if( throw == 0 )
            PlayAnim( WeaponFlareAnim::Throw, PLAYER_ANIM::PLAYER_ATTACK1 );
        else if( throw == 1 )
            PlayAnim( WeaponFlareAnim::Toss, PLAYER_ANIM::PLAYER_ATTACK1 );
        m_bThrown = true;
        m_bInAttack = false;

        StartSchedule( g_Scheduler.SetTimeout( @this, "LaunchThink", 0.2f ) );
    }

    float Idle() override
    {
        if( this.m_FlareOnHold !is null )
        {
           PlayAnim( WeaponFlareAnim::Hold );
        }
        else
        {
            PlayAnim( WeaponFlareAnim::Idle );
        }

        return Math.RandomFloat( 5.0f, 7.0f );
    }

    private bool CheckButton()
    {
        return ( this.owner.pev.button & ( IN_ATTACK | IN_ATTACK2 | IN_ALT1 ) ) != 0;
    }
}
