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

final class ASWeaponFlamethrowerConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_flamethrower";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_flame.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_flame.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_flame.mdl";
    }

    const string& get_animation_extension() override
    {
        return "egon";
    }

    const string& get_primary_ammo() override
    {
        return "fuel";
    }

    const string& get_primary_ammoentity() override
    {
        return "ammo_bts_flamethrower";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponFlamethrowerAnim::FLTHRW_DRAW;
    }

    void Precache() override
    {
        g_Game.PrecacheModel( "models/bts_rc/weapons/v_flame.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/p_flame.mdl" );
        g_Game.PrecacheModel( "models/bts_rc/weapons/w_flame.mdl" );
        g_Game.PrecacheModel( "models/hunger/w_gas.mdl" );
        g_Game.PrecacheModel( "sprites/bts_rc/fthrow.spr" );

        g_SoundSystem.PrecacheSound( "bts_rc/weapons/flmfire2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/flmgrexp.wav" );
        g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );

        g_Game.PrecacheGeneric( "sprites/bts_rc/weapons/weapon_bts_flamethrower.txt" );
        g_Game.PrecacheGeneric( "sprites/bts_rc/fthrow.spr" );

        ASWeaponConfig::Precache();
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapon configuration",
            "description": "Control flamethrower configuration",
            "allOf":
            [
                "ASWeaponConfig"
            ],
            "properties":
            {
            }
        }""";
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        this.slot = 5;
        this.position = 5;
        this.weight = 30;
        this.deploy_time = 0.7;
        this.primary_maxammo = 120;
        this.primary_dropammo = 40;
        this.max_clip = WEAPON_NOCLIP;
        this.primary_damage = 18;
        this.primary_cooldown = 0.1;
        this.primary_trained_cooldown = 0.1;

        g_CustomEntityFuncs.RegisterCustomEntity( "flame_proj", "flame_proj" );

        return ASWeaponConfig::Register( json );
    }
}

ASWeaponFlamethrowerConfig gpWeaponFlamethrowerConfig;

enum WeaponFlamethrowerAnim
{
    FLTHRW_IDLE1 = 0,
    FLTHRW_FIDGET1,
    FLTHRW_ALTFIREON,
    FLTHRW_ALTFIRECYCLE,
    FLTHRW_ALTFIREOFF,
    FLTHRW_FIRE1,
    FLTHRW_FIRE2,
    FLTHRW_FIRE3,
    FLTHRW_FIRE4,
    FLTHRW_DRAW,
    FLTHRW_HOLSTER
};

const float FLAME_SPEED = 800.0f;

class flame_proj : ScriptBaseEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetSize( self.pev, Vector( -1, -1, -1 ), Vector( 1, 1, 1 ) );
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        self.pev.movetype = MOVETYPE_FLY;
        self.pev.solid = SOLID_BBOX;
        self.pev.dmg = gpWeaponFlamethrowerConfig.primary_damage;

        SetTouch( TouchFunction( this.FlameTouch ) );
        SetThink( ThinkFunction( this.FlameThink ) );
        self.pev.nextthink = g_Engine.time + 0.1;
    }

    void FlameThink()
    {
        Vector vecOrigin = pev.origin - pev.velocity.Normalize();

        NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
        m1.WriteByte( TE_EXPLOSION );
        m1.WriteCoord( vecOrigin.x );
        m1.WriteCoord( vecOrigin.y );
        m1.WriteCoord( vecOrigin.z - 10 );
        m1.WriteShort( g_EngineFuncs.ModelIndex( "sprites/bts_rc/fthrow.spr" ) );
        m1.WriteByte( 8 );
        m1.WriteByte( 16 );
        m1.WriteByte( TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
        m1.End();

        self.pev.frame += 1.0f;

        if( self.pev.frame > 8 )
        {
            self.pev.frame = 0;
            g_EntityFuncs.Remove( self );
            return;
        }

        pev.nextthink = g_Engine.time + 0.08;
    }

    void FlameTouch( CBaseEntity@ pOther )
    {
        TraceResult tr = g_Utility.GetGlobalTrace();

        if( pOther.pev.modelindex == self.pev.modelindex && tr.pHit is null && self.pev.modelindex != tr.pHit.vars.modelindex )
        {
            return;
        }

        entvars_t@ pevOwner;
        if( self.pev.owner !is null )
            @pevOwner = @self.pev.owner.vars;
        else
            @pevOwner = self.pev;

        if( pOther.pev.takedamage != DAMAGE_NO && pOther.IsAlive() )
        {
            g_WeaponFuncs.ClearMultiDamage();

            if( pOther.pev.classname == "monster_cleansuit_scientist" || pOther.IsMachine() )
                pOther.TraceAttack( pevOwner, self.pev.dmg * 0.50, self.pev.velocity.Normalize(), tr, DMG_SLOWBURN | DMG_NEVERGIB );
            else if( pOther.pev.classname == "monster_gargantua" || pOther.pev.classname == "monster_babygarg" )
                pOther.TraceAttack( pevOwner, self.pev.dmg * 0.45, self.pev.velocity.Normalize(), tr, DMG_BURN | DMG_SLOWBURN | DMG_NEVERGIB );
            else if( pOther.pev.model == "models/bts_rc/monsters/zombie_hev.mdl" )
                pOther.TraceAttack( pevOwner, self.pev.dmg * 0.40, self.pev.velocity.Normalize(), tr, DMG_SLOWBURN | DMG_NEVERGIB );
            else
                pOther.TraceAttack( pevOwner, self.pev.dmg, self.pev.velocity.Normalize(), tr, DMG_BURN | DMG_SLOWBURN | DMG_NEVERGIB | DMG_POISON );

            g_WeaponFuncs.ApplyMultiDamage( self.pev, pevOwner );
        }

        if( pOther.IsBSPModel() )
        {
            g_WeaponFuncs.RadiusDamage( self.GetOrigin() + Vector( 0, 0, 4 ), self.pev, pevOwner, self.pev.dmg * 0.5, self.pev.dmg + 32, CLASS_NONE, DMG_BURN | DMG_SLOWBURN );
        }

        if( pOther is null || pOther.IsBSPModel() )
            g_Utility.DecalTrace( tr, DECAL_SMALLSCORCH1 + Math.RandomLong( 1, 2 ) );

        SetTouch( null );

        self.pev.solid = SOLID_NOT;
        self.pev.movetype = MOVETYPE_NONE;
    }
}

class weapon_bts_flamethrower : BTS_FireWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponFlamethrowerConfig;
    }

    void Spawn() override
    {
        self.m_iDefaultAmmo = 40;
        BTS_FireWeapon::Spawn();
        pev.scale = 1.5;
    }


    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        switch( type )
        {
            case AttackType::Tertiary:
            case AttackType::Secondary:
                return;
        }

        if( player.pev.waterlevel == 3 )
        {
            self.PlayEmptySound();
            self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
            return;
        }

        int ammo1 = player.m_rgAmmo( self.m_iPrimaryAmmoType );
        if( ammo1 <= 0 )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.75f;
            return;
        }

        --ammo1;
        player.m_rgAmmo( self.m_iPrimaryAmmoType, ammo1 );

        PlaySound( "bts_rc/weapons/flmfire2.wav", 1.0f, PITCH_NORM, CHAN_WEAPON );

        player.m_iWeaponVolume = LOUD_GUN_VOLUME;

        PlayAnim( Math.RandomLong( WeaponFlamethrowerAnim::FLTHRW_FIRE1, WeaponFlamethrowerAnim::FLTHRW_FIRE4 ) );

        bool is_trained_personal = util::IsTrainedPersonal( player );

        player.pev.punchangle.x -= is_trained_personal ? Math.RandomLong( -2, 2 ) : Math.RandomLong( -6, 6 );
        player.pev.punchangle.y -= is_trained_personal ? Math.RandomLong( -2, 2 ) : Math.RandomLong( -6, 6 );

        Vector vecSrc = player.GetGunPosition() + g_Engine.v_forward * 16 + g_Engine.v_right * 2 + g_Engine.v_up * -2;
        Vector vecDir = player.pev.v_angle * Vector( -1, 1, 1 );

        CBaseEntity@ preFlame = g_EntityFuncs.Create( "flame_proj", vecSrc, vecDir, false, player.edict() );
        flame_proj@ pFlame = cast<flame_proj@>( CastToScriptClass( preFlame ) );

        Vector vecVelocity = g_Engine.v_forward * FLAME_SPEED;

        pFlame.pev.velocity = vecVelocity;
        pFlame.pev.angles = Math.VecToAngles( pFlame.pev.velocity.Normalize() );
        pFlame.pev.avelocity.z = 10;

        self.m_flNextPrimaryAttack = g_Engine.time + 0.1;
        self.m_flTimeWeaponIdle = g_Engine.time + 0.5;
    }

    float Idle() override
    {
        self.ResetEmptySound();
        this.owner.GetAutoaimVector( AUTOAIM_5DEGREES );

        float flRand = Math.RandomFloat( 0.0f, 1.0f );
        if( flRand <= 0.5f )
        {
            PlayAnim( WeaponFlamethrowerAnim::FLTHRW_IDLE1 );
            return 4.2f;
        }
        else
        {
            PlayAnim( WeaponFlamethrowerAnim::FLTHRW_FIDGET1 );
            return 3.6f;
        }
    }
}

class ammo_bts_flamethrower : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/hunger/w_gas.mdl" );
        pev.scale = 1.0;
        BaseClass.Spawn();
    }

    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( 40, "fuel", 120 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/weapons/g_bounce3.wav", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}
