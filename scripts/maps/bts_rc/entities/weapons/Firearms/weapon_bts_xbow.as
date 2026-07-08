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

final class ASWeaponXBowConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_xbow";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_crossbow.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_crossbow.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_crossbow.mdl";
    }

    const string& get_animation_extension() override
    {
        return "bow";
    }

    const string& get_primary_ammo() override
    {
        return "bolts";
    }

    const string& get_primary_ammoentity() override
    {
        return "ammo_bts_xbow";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponXBowAnim::CROSSBOW_DRAW1;
    }

    void Precache() override
    {
        g_Game.PrecacheModel( "models/bts_rc/weapons/v_crossbow.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/w_crossbow.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/p_crossbow.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/w_crossbow_clip.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/electro_bolt.mdl" );

        g_SoundSystem.PrecacheSound( "hlclassic/items/9mmclip1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_fire1.ogg" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_fire1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_bolt.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_fidget2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_hit1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_hitbod1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_hitbod2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_magin.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_magready.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/xbow_draw2.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/sniper_zoom.wav" );

        ASWeaponConfig::Precache();
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        this.slot = 2;
        this.position = 11;
        this.weight = 10;
        this.deploy_time = 1.0;
        this.primary_maxammo = 15;
        this.primary_dropammo = 5;
        this.max_clip = 5;
        this.primary_damage = 48;
        this.primary_cooldown = 1.8;
        this.primary_trained_cooldown = 1.8;

        g_CustomEntityFuncs.RegisterCustomEntity( "electro_bolt", "electro_bolt" );

        return ASWeaponConfig::Register( json );
    }
}

ASWeaponXBowConfig gpWeaponXBowConfig;

enum WeaponXBowAnim
{
    CROSSBOW_IDLE1 = 0,
    CROSSBOW_IDLE2,
    CROSSBOW_FIDGET1,
    CROSSBOW_FIDGET2,
    CROSSBOW_FIRE1,
    CROSSBOW_FIRE2,
    CROSSBOW_FIRE3,
    CROSSBOW_RELOAD,
    CROSSBOW_DRAW1,
    CROSSBOW_DRAW2,
    CROSSBOW_HOLSTER1,
    CROSSBOW_HOLSTER2
};

const int BOLT_AIR_VELOCITY = 2000;
const int BOLT_WATER_VELOCITY = 1000;

class electro_bolt : ScriptBaseEntity
{
    void Spawn()
    {
        pev.movetype = MOVETYPE_FLY;
        pev.solid = SOLID_BBOX;
        pev.gravity = 0.5;
        self.SetClassification( CLASS_NONE );

        g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/electro_bolt.mdl" );
        g_EntityFuncs.SetOrigin( self, pev.origin );
        g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );

        NetworkMessage m2( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
        m2.WriteByte( TE_BEAMFOLLOW );
        m2.WriteShort( self.entindex() );
        m2.WriteShort( models::laserbeam );
        m2.WriteByte( 1 );
        m2.WriteByte( 1 );
        m2.WriteByte( 76 );
        m2.WriteByte( 167 );
        m2.WriteByte( 195 );
        m2.WriteByte( 200 );
        m2.End();

        SetTouch( TouchFunction( this.BoltTouch ) );
        SetThink( ThinkFunction( this.BubbleThink ) );
        pev.nextthink = g_Engine.time + 0.2;
    }

    void BoltTouch( CBaseEntity@ pOther )
    {
        if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
        {
            g_EntityFuncs.Remove( self );
            return;
        }

        SetTouch( null );
        SetThink( null );

        if( pOther.pev.takedamage != DAMAGE_NO )
        {
            TraceResult tr = g_Utility.GetGlobalTrace();
            entvars_t@ pevOwner = pev.owner.vars;

            g_WeaponFuncs.ClearMultiDamage();

            if( pOther.IsPlayer() )
                pOther.TraceAttack( pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_NEVERGIB );
            else
                pOther.TraceAttack( pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_NERVEGAS | DMG_NEVERGIB );

            g_WeaponFuncs.ApplyMultiDamage( pev, pevOwner );

            pev.velocity = g_vecZero;

            g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "bts_rc/weapons/xbow_hitbod1.wav", 1, ATTN_NORM );

            self.Killed( pev, GIB_NEVER );
        }
        else
        {
            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "bts_rc/weapons/xbow_hit1.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 7 ) );

            SetThink( ThinkFunction( this.SUB_Remove ) );
            pev.nextthink = g_Engine.time;

            if( pOther.pev.ClassNameIs( "worldspawn" ) )
            {
                Vector vecDir = pev.velocity.Normalize() * 10;
                g_EntityFuncs.SetOrigin( self, pev.origin - vecDir );
                pev.angles = Math.VecToAngles( vecDir );
                pev.solid = SOLID_NOT;
                pev.movetype = MOVETYPE_FLY;
                pev.velocity = Vector( 0, 0, 0 );
                pev.avelocity.z = 0;
                pev.angles.z = Math.RandomLong( 0, 360 );
                pev.nextthink = g_Engine.time + 10.0;
            }

            if( g_EngineFuncs.PointContents( pev.origin ) != CONTENTS_WATER )
                g_Utility.Sparks( pev.origin );
        }
    }

    void BubbleThink()
    {
        pev.nextthink = g_Engine.time + 0.1;

        if( pev.waterlevel == WATERLEVEL_DRY )
            return;

        g_Utility.BubbleTrail( pev.origin - pev.velocity * 0.1, pev.origin, 1 );
    }

    void SUB_Remove()
    {
        g_EntityFuncs.Remove( self );
    }
}

class weapon_bts_xbow : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponXBowConfig;
    }

    void Spawn() override
    {
        self.m_iDefaultAmmo = 5;
        BTS_FireWeapon::Spawn();
        pev.scale = 0.8;
    }

    bool Deploy() override
    {
        bool bResult = BTS_Weapon::Deploy();
        if( bResult )
        {
            if( self.m_iClip > 0 )
                self.SendWeaponAnim( WeaponXBowAnim::CROSSBOW_DRAW1, 0, pev.body );
            else
                self.SendWeaponAnim( WeaponXBowAnim::CROSSBOW_DRAW2, 0, pev.body );
        }
        return bResult;
    }

    void Holster( int skipLocal = 0 )
    {
        self.m_fInReload = false;

        if( self.m_fInZoom )
        {
            SecondaryAttack();
        }

        self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
        if( self.m_iClip > 0 )
            PlayAnim( WeaponXBowAnim::CROSSBOW_HOLSTER1 );
        else
            PlayAnim( WeaponXBowAnim::CROSSBOW_HOLSTER2 );

        BaseClass.Holster( skipLocal );
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        switch( type )
        {
            case AttackType::Tertiary:
                return;
            case AttackType::Secondary:
            {
                SecondaryAttack();
                return;
            }
        }

        if( self.m_iClip == 0 )
        {
            this.PlayEmptySound();
            return;
        }

        player.m_iWeaponVolume = QUIET_GUN_VOLUME;
        self.m_iClip--;

        if( self.m_iClip > 0 )
        {
            PlayAnim( WeaponXBowAnim::CROSSBOW_FIRE1 );
            PlaySound( "bts_rc/weapons/xbow_fire1.ogg", 1.0, 93 + Math.RandomLong( 0, 0xF ) );
            g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_BODY, "bts_rc/weapons/xbow_magin.wav", 0.25, ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xF ) );
        }
        else
        {
            PlayAnim( WeaponXBowAnim::CROSSBOW_FIRE3 );
            PlaySound( "bts_rc/weapons/xbow_fire1.ogg", 1.1, 93 + Math.RandomLong( 0, 0xF ) );
        }

        player.SetAnimation( PLAYER_ATTACK1 );

        Vector anglesAim = player.pev.v_angle + player.pev.punchangle;
        g_EngineFuncs.MakeVectors( anglesAim );

        Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );
        anglesAim.x = -anglesAim.x;
        Vector vecSrc = player.GetGunPosition() - g_Engine.v_up * 2;
        Vector vecDir = g_Engine.v_forward;

        float flDamage = gpWeaponXBowConfig.primary_damage;
        if( self.m_flCustomDmg > 0 )
            flDamage = self.m_flCustomDmg;

        CBaseEntity@ preBolt = g_EntityFuncs.CreateEntity( "electro_bolt", null, false );
        electro_bolt@ pBolt = cast<electro_bolt@>( CastToScriptClass( preBolt ) );
        pBolt.Spawn();

        pBolt.pev.origin = vecSrc;
        pBolt.pev.angles = anglesAim;
        pBolt.pev.dmg = flDamage;
        @pBolt.pev.owner = player.edict();

        if( player.pev.waterlevel == 3 )
        {
            pBolt.pev.velocity = vecDir * BOLT_WATER_VELOCITY;
            pBolt.pev.speed = BOLT_WATER_VELOCITY;
        }
        else
        {
            pBolt.pev.velocity = vecDir * BOLT_AIR_VELOCITY;
            pBolt.pev.speed = BOLT_AIR_VELOCITY;
        }
        pBolt.pev.avelocity.z = 10;

        player.pev.punchangle.x = -3.0f;

        self.m_flNextPrimaryAttack = g_Engine.time + 1.8;
        self.m_flNextSecondaryAttack = g_Engine.time + 1.8;

        if( self.m_iClip != 0 )
            self.m_flTimeWeaponIdle = g_Engine.time + 5.0;
        else
            self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
    }

    void SecondaryAttack()
    {
        g_SoundSystem.EmitSoundDyn( this.owner.edict(), CHAN_ITEM, "weapons/sniper_zoom.wav", 30, ATTN_NORM, 0, 125 );
        if( this.owner.pev.fov != 0 )
        {
            this.owner.pev.fov = this.owner.m_iFOV = 0;
            this.owner.m_szAnimExtension = "bow";
            self.m_fInZoom = false;
        }
        else if( this.owner.pev.fov != 20 )
        {
            this.owner.pev.fov = this.owner.m_iFOV = 20;
            this.owner.m_szAnimExtension = "bowscope";
            self.m_fInZoom = true;
        }

        self.pev.nextthink = g_Engine.time + 0.1;
        self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
    }

    void Reload()
    {
        if( this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        if( self.m_iClip == gpWeaponXBowConfig.max_clip )
            return;

        if( this.owner.pev.fov != 0 )
        {
            SecondaryAttack();
        }

        if( self.DefaultReload( gpWeaponXBowConfig.max_clip, WeaponXBowAnim::CROSSBOW_RELOAD, 4.5, pev.body ) )
        {
            PlaySound( "bts_rc/weapons/xbow_magready.wav", 1.0, 93 + Math.RandomLong( 0, 0xF ) );
        }

        BaseClass.Reload();
    }

    float Idle() override
    {
        self.ResetEmptySound();

        float flRand = Math.RandomFloat( 0, 1 );
        if( flRand <= 0.75 )
        {
            if( self.m_iClip > 0 )
                PlayAnim( WeaponXBowAnim::CROSSBOW_IDLE1 );
            else
                PlayAnim( WeaponXBowAnim::CROSSBOW_IDLE2 );
            return Math.RandomFloat( 10, 15 );
        }
        else
        {
            if( self.m_iClip > 0 )
            {
                PlayAnim( WeaponXBowAnim::CROSSBOW_FIDGET1 );
                return 3.0f;
            }
            else
            {
                PlayAnim( WeaponXBowAnim::CROSSBOW_FIDGET2 );
                return 2.66f;
            }
        }
    }
}

class ammo_bts_xbow : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/w_crossbow_clip.mdl" );
        pev.scale = 0.8;
        BaseClass.Spawn();
    }

    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( 5, "bolts", 15 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}
