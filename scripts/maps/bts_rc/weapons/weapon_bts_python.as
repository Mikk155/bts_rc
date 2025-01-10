/*
 * Colt Python 357 Magnum
 * Author: Rizulix
*/
// Rewrited by Rizulix for bts_rc (december 2024)

#include "../utils/player_class"

namespace CPython
{

enum python_e
{
    IDLE1 = 0,
    FIDGET,
    SHOOT,
    RELOAD,
    HOLSTER,
    DRAW,
    IDLE2,
    IDLE3
};

enum bodygroups_e
{
    GUN = 0,
    BULLETS,
    SPEEDLOAD,
    HANDS,
    SCOPE
};

// Models
string W_MODEL = "models/hlclassic/w_357.mdl";
string V_MODEL = "models/bts_rc/weapons/v_357.mdl";
string P_MODEL = "models/hlclassic/p_357.mdl";
string A_MODEL = "models/hlclassic/w_357ammobox.mdl";
string D_MODEL = "models/hlclassic/w_357ammo.mdl";
// Sounds
string SHOOT_SND1 = "hlclassic/weapons/357_shot1.wav";
string SHOOT_SND2 = "hlclassic/weapons/357_shot2.wav";
string EMPTY_SND = "hlclassic/weapons/357_cock1.wav";
array<string> SOUNDS = {
    "hlclassic/weapons/357_reload1.wav"
};
// Weapon info
int MAX_CARRY = 18;
int MAX_CLIP = 6;
// int DEFAULT_GIVE = Math.RandomLong( 3, 6 );
int AMMO_GIVE = MAX_CLIP;
int AMMO_DROP = AMMO_GIVE;
int WEIGHT = 10;
int FLAGS = 0;
int ID; // assigned on register
string AMMO_TYPE = "357";
// Weapon HUD
int SLOT = 1;
int POSITION = 8;
// Vars
int DAMAGE = 66;
Vector CONE( 0.01f, 0.01f, 0.01f );

class weapon_bts_python : ScriptBasePlayerWeaponEntity
{
    private CBasePlayer@ m_pPlayer
    {
        get const { return cast<CBasePlayer>( self.m_hPlayer.GetEntity() ); }
        set       { self.m_hPlayer = EHandle( @value ); }
    }
    private bool m_fHasHEV
    {
        get const { return g_PlayerClass[m_pPlayer] == HELMET; }
    }

    int GetBodygroup()
    {
        pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), pev.body, HANDS, g_PlayerClass[m_pPlayer] );
        return pev.body;
    }

    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, self.GetW_Model( W_MODEL ) );
        self.m_iDefaultAmmo = Math.RandomLong( 3, MAX_CLIP );
        self.FallInit();
    }

    void Precache()
    {
        self.PrecacheCustomModels();
        g_Game.PrecacheModel( W_MODEL );
        g_Game.PrecacheModel( V_MODEL );
        g_Game.PrecacheModel( P_MODEL );
        g_Game.PrecacheModel( A_MODEL );
        g_Game.PrecacheModel( D_MODEL );

        g_Game.PrecacheOther( GetAmmoName() );
        g_Game.PrecacheOther( GetDAmmoName() );

        g_SoundSystem.PrecacheSound( SHOOT_SND1 );
        g_SoundSystem.PrecacheSound( SHOOT_SND2 );
        g_SoundSystem.PrecacheSound( EMPTY_SND );

        for( uint i = 0; i < SOUNDS.length(); i++ )
            g_SoundSystem.PrecacheSound( SOUNDS[i] );

        g_Game.PrecacheGeneric( "sprites/bts_rc/weapons/" + pev.classname + ".txt" );
    }

    bool AddToPlayer( CBasePlayer@ pPlayer )
    {
        if( !BaseClass.AddToPlayer( pPlayer ) )
            return false;

        NetworkMessage weapon( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
            weapon.WriteLong( g_ItemRegistry.GetIdForName( pev.classname ) );
        weapon.End();
        return true;
    }

    bool GetItemInfo( ItemInfo& out info )
    {
        info.iMaxAmmo1 = MAX_CARRY;
        info.iAmmo1Drop = AMMO_DROP;
        info.iMaxAmmo2 = -1;
        info.iAmmo2Drop = -1;
        info.iMaxClip = MAX_CLIP;
        info.iSlot = SLOT;
        info.iPosition = POSITION;
        info.iId = g_ItemRegistry.GetIdForName( pev.classname );
        info.iFlags = FLAGS;
        info.iWeight = WEIGHT;
        return true;
    }

    bool Deploy()
    {
        self.DefaultDeploy( self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), DRAW, "python", 0, GetBodygroup() );
        self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
        return true;
    }

    void Holster( int skiplocal = 0 )
    {
        BaseClass.Holster( skiplocal );
    }

    bool PlayEmptySound()
    {
        if( self.m_bPlayEmptySound )
        {
            self.m_bPlayEmptySound = false;
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, EMPTY_SND, 0.8f, ATTN_NORM, 0, PITCH_NORM );
        }
        return false;
    }

    void PrimaryAttack()
    {
        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
            return;
        }

        m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

        --self.m_iClip;

        m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
        pev.effects |= EF_MUZZLEFLASH;

        // player "shoot" animation
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

        Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
        Vector vecSrc = m_pPlayer.GetGunPosition();
        Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

        {
            float x, y;
            g_Utility.GetCircularGaussianSpread( x, y );

            Vector vecDir = vecAiming + x * CONE.x * g_Engine.v_right + y * CONE.y * g_Engine.v_up;
            Vector vecEnd = vecSrc + vecDir * 8192.0f;

            TraceResult tr;
            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
            self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, DAMAGE, m_pPlayer.pev );
            Sparks::Sparks( tr.pHit, tr.iHitgroup, tr.vecEndPos );
            BloodSplash::Create( tr.pHit, tr.iHitgroup, tr.vecEndPos );

            if( tr.flFraction < 1.0f && tr.pHit !is null )
            {
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if( ( pHit is null || pHit.IsBSPModel() ) && !pHit.pev.FlagBitSet( FL_WORLDBRUSH ) )
                    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
            }
        }

        self.SendWeaponAnim( SHOOT, 0, GetBodygroup() );
        switch ( Math.RandomLong( 0, 1 ) )
        {
            case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SHOOT_SND1, Math.RandomFloat( 0.8f, 0.9f ), ATTN_NORM, 0, PITCH_NORM ); break;
            case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SHOOT_SND2, Math.RandomFloat( 0.8f, 0.9f ), ATTN_NORM, 0, PITCH_NORM ); break;
        }
        m_pPlayer.pev.punchangle.x = m_fHasHEV ? -10.0f : -16.0f;

        if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && m_fHasHEV )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        self.m_flNextPrimaryAttack = g_Engine.time + 0.75f;
        self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0f, 15.0f );
    }

    void Reload()
    {
        if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        self.DefaultReload( MAX_CLIP, RELOAD, 2.0f, GetBodygroup() );
        self.m_flTimeWeaponIdle = g_Engine.time + 3.0f;
        BaseClass.Reload();
    }

    void WeaponIdle()
    {
        self.ResetEmptySound();
        m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

        if( self.m_flTimeWeaponIdle > g_Engine.time || self.m_iClip <= 0 )
            return;

        float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0.0f, 1.0f );
        if( flRand <= 0.5f )
        {
            self.SendWeaponAnim( IDLE1, 0, GetBodygroup() );
            self.m_flTimeWeaponIdle = g_Engine.time + 2.33f; // ( 70.0f / 30.0f );
        }
        else if( flRand <= 0.7f )
        {
            self.SendWeaponAnim( IDLE2, 0, GetBodygroup() );
            self.m_flTimeWeaponIdle = g_Engine.time + 2.0f; // ( 60.0f / 30.0f );
        }
        else if( flRand <= 0.9f )
        {
            self.SendWeaponAnim( IDLE3, 0, GetBodygroup() );
            self.m_flTimeWeaponIdle = g_Engine.time + 2.93f; // ( 88.0f / 30.0f );
        }
        else
        {
            self.SendWeaponAnim( FIDGET, 0, GetBodygroup() );
            self.m_flTimeWeaponIdle = g_Engine.time + 5.66f; // ( 170.0f / 30.0f );
        }
    }
}

class ammo_bts_python : ScriptBasePlayerAmmoEntity
{
    private string m_szModel = A_MODEL;
    private int m_iAmount = AMMO_GIVE;

    void Spawn()
    {
        if( pev.ClassNameIs( GetDAmmoName() ) )
        {
            m_szModel = D_MODEL;
            m_iAmount = Math.RandomLong( 2, 4 );
        }

        Precache();
        g_EntityFuncs.SetModel( self, m_szModel );
        BaseClass.Spawn();
    }

    void Precache()
    {
        g_Game.PrecacheModel( m_szModel );
        g_SoundSystem.PrecacheSound( "hlclassic/items/9mmclip1.wav" );
    }

    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( m_iAmount, AMMO_TYPE, MAX_CARRY ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1.0f, ATTN_NORM );
            return true;
        }
        return false;
    }
}

string GetName()
{
    return "weapon_bts_python";
}

string GetAmmoName()
{
    return "ammo_bts_python";
}

string GetDAmmoName()
{
    return "ammo_bts_357cyl";
}

void Register()
{
#if DEVELOP
    weapons.insertLast( GetName() );
#endif

    g_CustomEntityFuncs.RegisterCustomEntity( "CPython::weapon_bts_python", GetName() ); // 357 Colt Python Revolver
    g_CustomEntityFuncs.RegisterCustomEntity( "CPython::ammo_bts_python", GetAmmoName() ); // 357 Ammo Rounds
    g_CustomEntityFuncs.RegisterCustomEntity( "CPython::ammo_bts_python", GetDAmmoName() ); // 357 Ammo Drop by NPCs
    ID = g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", AMMO_TYPE, "", GetAmmoName(), "" ); // Register all of them here
}

}
