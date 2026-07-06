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

class CWeaponFlareConfig : ASWeaponConfig
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
        return "Emergency Flare";
    }

    const string& get_primary_ammoentity() override
    {
        return "weapon_bts_flare";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponFlareAnim::DRAW;
    }

    void Precache() override
    {
        g_Game.PrecacheModel( "models/bts_rc/weapons/v_flare.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/p_flare.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/w_flare.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/flare.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/w_flaregun_clip.mdl" );

        g_SoundSystem.PrecacheSound( "bts_rc/weapons/flare_deploy.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/flare_bounce.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/flare_on.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/flarehit1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/flarehitbod1.wav" );

        ASWeaponConfig::Precache();
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        this.slot = 4;
        this.position = 5;
        this.weight = 5;
        this.deploy_time = 0.75;
        this.primary_maxammo = 5;
        this.primary_dropammo = 1;
        this.max_clip = WEAPON_NOCLIP;
        this.primary_damage = 1;

        g_CustomEntityFuncs.RegisterCustomEntity( "CFlare", "flare" );

        return ASWeaponConfig::Register( json );
    }
}

CWeaponFlareConfig gpWeaponFlareConfig;

enum WeaponFlareAnim
{
    IDLE = 0,
    PULLPIN,
    THROW,
    DRAW,
    TOSS
};

class CFlare : ScriptBaseEntity
{
    private float m_flBounceTime = 0.0f;
    private float m_flNextAttack = 0.0f;
    private int m_iBounces = 0;

    bool m_fRemoveAfterHit = false;
    bool m_fAttachToWorld = false;

    void Spawn()
    {
        g_EntityFuncs.SetSize( pev, Vector( -2, -2, -2 ), Vector( 2, 2, 2 ) );

        pev.solid = SOLID_BBOX;
        pev.movetype = MOVETYPE_NONE;
        pev.friction = 0.6f;
        pev.gravity = 0.5f;

        pev.dmg = 1.0f;
        pev.dmgtime = g_Engine.time + 30.0f;
        pev.effects |= EF_NOSHADOW;

        IgniteSound();
    }

    void FlareThink()
    {
        if( pev.dmgtime != -1.0f )
        {
            if( pev.dmgtime < g_Engine.time )
            {
                FlareLight( 2, 64 );
                g_EntityFuncs.Remove( self );
                return;
            }
        }

        if( pev.waterlevel > WATERLEVEL_FEET )
        {
            g_Utility.Bubbles( pev.absmin, pev.absmax, 1 );
        }
        else
        {
            if( Math.RandomLong( 0, 8 ) == 1 )
            {
                g_Utility.Sparks( pev.origin );
            }
        }

        FlareLight( 1, 1 );
        pev.nextthink = g_Engine.time + 0.1f;
    }

    void FlareTouch( CBaseEntity@ pOther )
    {
        if( @pOther.edict() == @pev.owner )
            return;

        if( ( m_iBounces < 10 ) && pev.waterlevel < WATERLEVEL_FEET )
        {
            g_Utility.Sparks( pev.origin );
        }

        TraceResult tr = g_Utility.GetGlobalTrace();
        Vector vecDir = pev.velocity.Normalize();
        Vector vecNewDir = vecDir - 2.0f * tr.vecPlaneNormal * DotProduct( tr.vecPlaneNormal, vecDir );
        pev.angles = Math.VecToAngles( vecNewDir );

        if( pOther.pev.takedamage != DAMAGE_NO )
        {
            entvars_t@ pevOwner = pev;
            if( pev.owner !is null )
                @pevOwner = pev.owner.vars;

            g_WeaponFuncs.ClearMultiDamage();

            if( pOther.IsPlayer() )
                pOther.TraceAttack( pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_BURN | DMG_NEVERGIB );
            else
                pOther.TraceAttack( pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_POISON | DMG_NEVERGIB );

            g_WeaponFuncs.ApplyMultiDamage( pev, pevOwner );

            g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "bts_rc/weapons/flarehitbod1.wav", VOL_NORM, ATTN_NORM );

            if( m_fRemoveAfterHit )
            {
                pev.velocity = pev.velocity * 0.1f;
                pev.gravity = 1.0f;
                g_EntityFuncs.Remove( self );
                return;
            }
        }
        else
        {
            if( m_iBounces == 0 )
            {
                if( pOther.pev.ClassNameIs( "worldspawn" ) )
                {
                    float flSurfDot = DotProduct( tr.vecPlaneNormal, vecDir );
                    if( m_fAttachToWorld && !( tr.vecPlaneNormal.z < -0.5f && flSurfDot > -0.9f ) )
                    {
                        pev.velocity = g_vecZero;
                        pev.avelocity = g_vecZero;
                        pev.angles = Math.VecToAngles( vecDir );
                        pev.movetype = MOVETYPE_NONE;
                        pev.effects |= EF_NODRAW;

                        SetTouch( TouchFunction( this.FlareBurnTouch ) );
                        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "bts_rc/weapons/flarehit1.wav", Math.RandomFloat( 0.95f, 1.0f ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 7 ) );
                        return;
                    }
                }
            }

            pev.gravity = 0.8f;

            m_iBounces++;
            if( ( pev.flags & FL_ONGROUND ) == 0 )
                BounceSounds();

            pev.velocity.x *= 0.8f;
            pev.velocity.y *= 0.8f;

            if( pev.velocity.Length() < 64.0f )
            {
                pev.velocity = g_vecZero;
                pev.angles.x = 0.0f;
                pev.angles.z = 0.0f;
                pev.movetype = MOVETYPE_NONE;

                SetTouch( TouchFunction( this.FlareBurnTouch ) );
            }
        }
    }

    void FlareBurnTouch( CBaseEntity@ pOther )
    {
        if( pOther.pev.takedamage != DAMAGE_NO )
        {
            if( m_flNextAttack < g_Engine.time )
            {
                entvars_t@ pevOwner = pev;
                if( pev.owner !is null )
                    @pevOwner = pev.owner.vars;

                TraceResult tr = g_Utility.GetGlobalTrace();

                g_WeaponFuncs.ClearMultiDamage();
                pOther.TraceAttack( pevOwner, 1.0f, g_Engine.v_forward, tr, DMG_BURN | DMG_NEVERGIB );
                g_WeaponFuncs.ApplyMultiDamage( pev, pevOwner );

                m_flNextAttack = g_Engine.time + 1.0f;
            }
        }
    }

    void Start( float flLifeTime )
    {
        IgniteSound();

        if( flLifeTime > 0.0f )
            pev.dmgtime = g_Engine.time + flLifeTime;
        else
            pev.dmgtime = -1.0f;

        pev.effects &= ~EF_NODRAW;

        SetThink( ThinkFunction( this.FlareThink ) );
        pev.nextthink = g_Engine.time + 0.1f;
    }

    void BounceSounds()
    {
        if( g_Engine.time < m_flBounceTime )
            return;

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

    void FlareTrail()
    {
        NetworkMessage msg( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
        msg.WriteByte( TE_BEAMFOLLOW );
        msg.WriteShort( self.entindex() );
        msg.WriteShort( models::laserbeam );
        msg.WriteByte( 20 );
        msg.WriteByte( 4 );
        msg.WriteByte( 180 );
        msg.WriteByte( 10 );
        msg.WriteByte( 10 );
        msg.WriteByte( 200 );
        msg.End();
    }

    void FlareLight( uint8 life, uint8 decayRate )
    {
        NetworkMessage msg( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
        msg.WriteByte( TE_DLIGHT );
        msg.WriteCoord( pev.origin.x );
        msg.WriteCoord( pev.origin.y );
        msg.WriteCoord( pev.origin.z );
        msg.WriteByte( pev.waterlevel > WATERLEVEL_FEET ? 9 : 18 );
        msg.WriteByte( 255 );
        msg.WriteByte( 21 );
        msg.WriteByte( 18 );
        msg.WriteByte( life );
        msg.WriteByte( decayRate );
        msg.End();
    }

    void IgniteSound()
    {
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "bts_rc/weapons/flare_on.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
    }
}

namespace FLARE
{
    CFlare@ Toss( entvars_t@ pevOwner, const Vector& in vecStart, const Vector& in vecVelocity, float flDmg, float flDuration, float flSparkAfter )
    {
        CBaseEntity@ preFlare = g_EntityFuncs.CreateEntity( "flare", null, false );
        CFlare@ pFlare = cast<CFlare@>( CastToScriptClass( preFlare ) );
        if( pFlare is null )
            return null;

        g_EntityFuncs.SetModel( pFlare.self, "models/bts_rc/weapons/flare.mdl" );
        g_EntityFuncs.SetOrigin( pFlare.self, vecStart );
        g_EntityFuncs.DispatchSpawn( pFlare.self.edict() );

        pFlare.pev.dmg = flDmg;
        pFlare.pev.movetype = MOVETYPE_BOUNCE;

        pFlare.pev.velocity = vecVelocity;
        pFlare.pev.angles = Math.VecToAngles( pFlare.pev.velocity );
        @pFlare.pev.owner = pevOwner.pContainingEntity;

        pFlare.Start( flDuration );
        pFlare.pev.dmgtime = g_Engine.time + flDuration;

        pFlare.SetThink( ThinkFunction( pFlare.FlareThink ) );
        pFlare.pev.nextthink = g_Engine.time + flSparkAfter;
        pFlare.SetTouch( TouchFunction( pFlare.FlareTouch ) );

        return pFlare;
    }

    CFlare@ Shoot( entvars_t@ pevOwner, const Vector& in vecStart, const Vector& in vecVelocity, float flDmg, float flDuration )
    {
        CBaseEntity@ preFlare = g_EntityFuncs.CreateEntity( "flare", null, false );
        CFlare@ pFlare = cast<CFlare@>( CastToScriptClass( preFlare ) );
        if( pFlare is null )
            return null;

        g_EntityFuncs.SetModel( pFlare.self, "models/bts_rc/weapons/w_flaregun_clip.mdl" );
        g_EntityFuncs.SetOrigin( pFlare.self, vecStart );
        g_EntityFuncs.DispatchSpawn( pFlare.self.edict() );

        pFlare.FlareTrail();
        pFlare.m_fAttachToWorld = true;
        pFlare.m_fRemoveAfterHit = true;

        pFlare.pev.dmg = flDmg;
        pFlare.pev.movetype = MOVETYPE_BOUNCE;

        pFlare.pev.velocity = vecVelocity;
        pFlare.pev.angles = Math.VecToAngles( pFlare.pev.velocity );
        @pFlare.pev.owner = pevOwner.pContainingEntity;

        pFlare.Start( flDuration );
        pFlare.pev.dmgtime = g_Engine.time + flDuration;

        pFlare.SetThink( ThinkFunction( pFlare.FlareThink ) );
        pFlare.pev.nextthink = g_Engine.time + 0.5f;
        pFlare.SetTouch( TouchFunction( pFlare.FlareTouch ) );

        return pFlare;
    }
}

class weapon_bts_flare : BTS_Weapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponFlareConfig;
    }

    private int throw = 0;
    private float m_fAttackStart = 0.0f;
    private bool m_bInAttack = false;
    private bool m_bThrown = false;
    private int m_iAmmoSave = 0;

    void Spawn() override
    {
        g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/w_flare.mdl" );
        self.m_iDefaultAmmo = 1;
        self.FallInit();
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

    void Holster( int skiplocal = 0 )
    {
        m_bThrown = false;
        m_bInAttack = false;
        m_fAttackStart = 0.0f;

        SetThink( null );

        if( this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
        {
            m_iAmmoSave = this.owner.m_rgAmmo( self.m_iPrimaryAmmoType );
        }

        if( m_iAmmoSave <= 0 )
        {
            SetThink( ThinkFunction( this.DestroyThink ) );
            pev.nextthink = g_Engine.time + 0.1f;
        }

        BaseClass.Holster( skiplocal );
    }

    void PrimaryAttack() override
    {
        if( this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        if( m_fAttackStart < 0.0f || m_fAttackStart > 0.0f )
            return;

        self.m_flNextPrimaryAttack = g_Engine.time + ( 25.0f / 30.0f );
        PlayAnim( WeaponFlareAnim::PULLPIN );
        throw = 0;

        m_bInAttack = true;
        m_fAttackStart = g_Engine.time + ( 25.0f / 30.0f );

        self.m_flTimeWeaponIdle = g_Engine.time + ( 25.0f / 30.0f ) + ( 23.0f / 30.0f );
    }

    void SecondaryAttack() override
    {
        if( this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        if( m_fAttackStart < 0.0f || m_fAttackStart > 0.0f )
            return;

        self.m_flNextSecondaryAttack = g_Engine.time + ( 25.0f / 30.0f );
        PlayAnim( WeaponFlareAnim::PULLPIN );
        throw = 1;

        m_bInAttack = true;
        m_fAttackStart = g_Engine.time + ( 25.0f / 25.0f );

        self.m_flTimeWeaponIdle = g_Engine.time + ( 25.0f / 30.0f ) + ( 23.0f / 30.0f );
    }

    private void LaunchThink()
    {
        Vector angThrow = this.owner.pev.v_angle + this.owner.pev.punchangle;

        if( angThrow.x < 0.0f )
            angThrow.x = -10.0f + angThrow.x * ( ( 90.0f - 10.0f ) / 90.0f );
        else
            angThrow.x = -10.0f + angThrow.x * ( ( 90.0f + 10.0f ) / 90.0f );

        float flVel = ( 90.0f - angThrow.x ) * 6.0f;

        if( flVel > 750.0f )
            flVel = 750.0f;

        if( throw == 1 )
            flVel = flVel / 2.0f;

        Math.MakeVectors( angThrow );
        Vector offset = Vector( 16.0f, 0.0f, 0.0f );
        Vector vecSrc = this.owner.GetGunPosition() + g_Engine.v_forward * offset.x + g_Engine.v_right * offset.y + g_Engine.v_up * offset.z;
        Vector vecThrow = g_Engine.v_forward * flVel + this.owner.pev.velocity;

        FLARE::Toss( this.owner.pev, vecSrc, vecThrow, 1.0f, 180.0f, 1.5f );

        this.owner.m_rgAmmo( self.m_iPrimaryAmmoType, this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
        m_fAttackStart = 0.0f;
    }

    void ItemPreFrame()
    {
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

        self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + ( 22.0f / 30.0f );
        if( throw == 0 )
            PlayAnim( WeaponFlareAnim::THROW );
        if( throw == 1 )
            PlayAnim( WeaponFlareAnim::TOSS );
        m_bThrown = true;
        m_bInAttack = false;
        this.owner.SetAnimation( PLAYER_ATTACK1 );

        SetThink( ThinkFunction( this.LaunchThink ) );
        pev.nextthink = g_Engine.time + 0.2f;

        BaseClass.ItemPreFrame();
    }

    float Idle() override
    {
        PlayAnim( WeaponFlareAnim::IDLE );
        return Math.RandomFloat( 5.0f, 7.0f );
    }

    private bool CheckButton()
    {
        return ( this.owner.pev.button & ( IN_ATTACK | IN_ATTACK2 | IN_ALT1 ) ) != 0;
    }

    private void DestroyThink()
    {
        SetThink( null );
        self.DestroyItem();
    }
}
