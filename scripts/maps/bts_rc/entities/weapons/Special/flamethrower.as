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
    int m_iFlameSprite;

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
        this.m_iFlameSprite = g_ModelFuncs.ModelIndex( "sprites/bts_rc/fthrow.spr" );

        g_Game.PrecacheGeneric( "sprites/bts_rc/weapons/weapon_bts_flamethrower.txt" );

        ASWeaponConfig::Precache();
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        if( g_MapConfig.MapLoading )
        {
            g_CustomEntityFuncs.RegisterCustomEntity( "flame_proj", "flame_proj" );
            g_CustomEntityFuncs.RegisterCustomEntity( "ASBurningMonster", "bts_burning_monster" );
        }

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
const Vector FLAME_OFFSET = Vector( 34.333031f, 12.009664f, -5.616758f );

final class ASBurningMonster : ScriptBaseEntity
{
    private EHandle m_Target;
    private EHandle m_Attacker;
    private float m_Damage;
    private float m_EndTime;

    void Spawn()
    {
        self.pev.effects |= EF_NODRAW;
        self.pev.solid = SOLID_NOT;
        self.pev.movetype = MOVETYPE_NONE;
    }

    void Ignite( CBaseEntity@ target, CBaseEntity@ attacker, float damage, float duration )
    {
        m_Target = EHandle( target );
        m_Attacker = EHandle( attacker );
        m_Damage = damage;
        m_EndTime = Math.max( m_EndTime, g_Engine.time + duration );
        self.pev.nextthink = g_Engine.time + 0.5f;
        SetThink( ThinkFunction( this.BurnThink ) );
    }

    void Refresh( CBaseEntity@ attacker, float damage, float duration )
    {
        m_Attacker = EHandle( attacker );
        m_Damage = Math.max( m_Damage, damage );
        m_EndTime = Math.max( m_EndTime, g_Engine.time + duration );
    }

    void BurnThink()
    {
        CBaseEntity@ target = m_Target.GetEntity();
        CBaseEntity@ attacker = m_Attacker.GetEntity();

        if( target is null || !target.IsAlive() || g_Engine.time >= m_EndTime )
        {
            if( target !is null )
                target.GetUserData().delete( "bts_burning_monster" );
            g_EntityFuncs.Remove( self );
            return;
        }

        entvars_t@ attackerVars = attacker is null ? self.pev : attacker.pev;
        target.TakeDamage( self.pev, attackerVars, m_Damage, DMG_BURN | DMG_SLOWBURN | DMG_NEVERGIB );

        NetworkMessage flame( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, target.Center() );
            flame.WriteByte( TE_EXPLOSION );
            flame.WriteCoord( target.Center().x );
            flame.WriteCoord( target.Center().y );
            flame.WriteCoord( target.Center().z );
            flame.WriteShort( gpWeaponFlamethrowerConfig.m_iFlameSprite );
            flame.WriteByte( 6 );
            flame.WriteByte( 12 );
            flame.WriteByte( TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
        flame.End();

        self.pev.nextthink = g_Engine.time + 0.5f;
    }
}

namespace BurningMonster
{
    void Ignite( CBaseEntity@ target, CBaseEntity@ attacker, float damage, float duration = 4.0f )
    {
        if( target is null || !target.IsMonster() || target.IsMachine() || !target.IsAlive() )
            return;

        dictionary@ data = target.GetUserData();
        ASBurningMonster@ burning;

        if( data.get( "bts_burning_monster", @burning ) && burning !is null )
        {
            burning.Refresh( attacker, damage, duration );
            return;
        }

        CBaseEntity@ entity = g_EntityFuncs.CreateEntity( "bts_burning_monster", null, false );
        @burning = cast<ASBurningMonster@>( CastToScriptClass( entity ) );

        if( burning is null )
            return;

        g_EntityFuncs.DispatchSpawn( entity.edict() );
        @data[ "bts_burning_monster" ] = burning;
        burning.Ignite( target, attacker, damage, duration );
    }
}

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
        m1.WriteShort( gpWeaponFlamethrowerConfig.m_iFlameSprite );
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
        if( pOther is null || pOther.GetClassname() == "flame_proj" )
            return;

        TraceResult tr = g_Utility.GetGlobalTrace();

        entvars_t@ pevOwner;
        if( self.pev.owner !is null )
            @pevOwner = @self.pev.owner.vars;
        else
            @pevOwner = self.pev;

        string szClassname = pOther.GetClassname();

        if( pOther.pev.takedamage != DAMAGE_NO && pOther.IsAlive() )
        {
            g_WeaponFuncs.ClearMultiDamage();

            if( szClassname == "monster_cleansuit_scientist" || pOther.IsMachine() )
                pOther.TraceAttack( pevOwner, self.pev.dmg * 0.50, self.pev.velocity.Normalize(), tr, DMG_SLOWBURN | DMG_NEVERGIB );
            else if( szClassname == "monster_gargantua" || szClassname == "monster_babygarg" )
                pOther.TraceAttack( pevOwner, self.pev.dmg * 0.45, self.pev.velocity.Normalize(), tr, DMG_BURN | DMG_SLOWBURN | DMG_NEVERGIB );
            else if( pOther.pev.model == "models/bts_rc/monsters/zombie_hev.mdl" )
                pOther.TraceAttack( pevOwner, self.pev.dmg * 0.40, self.pev.velocity.Normalize(), tr, DMG_SLOWBURN | DMG_NEVERGIB );
            else
                pOther.TraceAttack( pevOwner, self.pev.dmg, self.pev.velocity.Normalize(), tr, DMG_BURN | DMG_SLOWBURN | DMG_NEVERGIB | DMG_POISON );

            g_WeaponFuncs.ApplyMultiDamage( self.pev, pevOwner );
            BurningMonster::Ignite( pOther, g_EntityFuncs.Instance( pevOwner.pContainingEntity ), self.pev.dmg * 0.15f );
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

        PlayAnim( WeaponFlamethrowerAnim::FLTHRW_FIRE1 + RandomUint(3) );

        bool is_trained_personal = util::IsTrainedPersonal( player );

        player.pev.punchangle.x -= is_trained_personal ? Math.RandomLong( -2, 2 ) : Math.RandomLong( -6, 6 );
        player.pev.punchangle.y -= is_trained_personal ? Math.RandomLong( -2, 2 ) : Math.RandomLong( -6, 6 );

        Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );
        Vector vecSrc = player.GetGunPosition() + g_Engine.v_forward * FLAME_OFFSET.x
            + g_Engine.v_right * FLAME_OFFSET.y + g_Engine.v_up * FLAME_OFFSET.z;
        Vector vecDir = player.pev.v_angle * Vector( -1, 1, 1 );

        CBaseEntity@ preFlame = g_EntityFuncs.Create( "flame_proj", vecSrc, vecDir, false, player.edict() );
        if( preFlame !is null )
        {
            preFlame.pev.velocity = g_Engine.v_forward * FLAME_SPEED;
            preFlame.pev.angles = Math.VecToAngles( preFlame.pev.velocity.Normalize() );
            preFlame.pev.avelocity.z = 10;
        }

        self.m_flNextPrimaryAttack = g_Engine.time + gpWeaponFlamethrowerConfig.GetCooldown( is_trained_personal, AttackType::Primary );
        self.m_flTimeWeaponIdle = g_Engine.time + 0.5;
    }

    float Idle() override
    {
        self.ResetEmptySound();

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
        if( pOther.GiveAmmo( 40, "fuel", gpWeaponFlamethrowerConfig.primary_maxammo ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/weapons/g_bounce3.wav", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}
