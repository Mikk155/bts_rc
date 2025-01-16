/*
 * Emergency Flare Gun
 * Credits: Nero0, KernCore, Mikk, RaptorSKA
*/
// Rewrited by Rizulix for bts_rc (december 2024)

namespace BTS_FLAREGUN
{

enum btsflaregun_e
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
    HANDS
};

// Models
string W_MODEL = "models/bts_rc/weapons/w_flaregun.mdl";
string V_MODEL = "models/bts_rc/weapons/v_flaregun.mdl";
string P_MODEL = "models/bts_rc/weapons/p_flaregun.mdl";
string A_MODEL = "models/bts_rc/weapons/w_flaregun_clip.mdl";
// string PRJ_MDL = "models/hlclassic/shotgunshell.mdl";
string PRJ_MDL = "models/bts_rc/weapons/flare.mdl";
// Sounds
string SHOOT_SND = "bts_rc/weapons/flaregun_shot1.wav";
// string SHOOT_SND2 = "bts_rc/weapons/flaregun_shot2.wav";
string EMPTY_SND = "hlclassic/weapons/357_cock1.wav";
array<string> SOUNDS = {
    "bts_rc/weapons/flaregun_draw.wav"
};
string RELOAD_SND1 = "bts_rc/weapons/flaregun_reload1.wav";
string RELOAD_SND2 = "bts_rc/weapons/flaregun_reload2.wav";
// Weapon info
int MAX_CARRY = 6;
int MAX_CLIP = 1;
int DEFAULT_GIVE = 3;
int AMMO_GIVE = MAX_CLIP;
int AMMO_DROP = AMMO_GIVE;
int WEIGHT = 15;
int FLAGS = 0;
int ID; // assigned on register
string AMMO_TYPE = "bts:flare";
// Weapon HUD
int SLOT = 1;
int POSITION = 13;
// Vars
float DAMAGE = 20.0f;
float DURATION = 180.0f;
float VELOCITY = 1500.0f;
Vector OFFSET( 8.0f, 4.0f, -2.0f ); // for projectile

// const Vector MUZZLE_ORIGIN       = Vector( 16.0, 4.0, -4.0 ); //forward, right, up
// const string SPRITE_MUZZLE_GRENADE   = "sprites/bts_rc/muzzleflash12.spr";

class weapon_bts_flaregun : ScriptBasePlayerWeaponEntity
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
    private int m_iSpecialReload;
    private int m_fInAttack;

    int GetBodygroup()
    {
        pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), pev.body, HANDS, g_PlayerClass[m_pPlayer] );
        return pev.body;
    }

    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, self.GetW_Model( W_MODEL ) );
        self.m_iDefaultAmmo = DEFAULT_GIVE;
        self.FallInit();
    }

    void Precache()
    {
        self.PrecacheCustomModels();
        g_Game.PrecacheModel( W_MODEL );
        g_Game.PrecacheModel( V_MODEL );
        g_Game.PrecacheModel( P_MODEL );
        g_Game.PrecacheModel( A_MODEL );
        g_Game.PrecacheModel( PRJ_MDL );

        g_Game.PrecacheOther( "ammo_bts_flarebox" );

        g_SoundSystem.PrecacheSound( SHOOT_SND );
        // g_SoundSystem.PrecacheSound( SHOOT_SND2 );
        g_SoundSystem.PrecacheSound( EMPTY_SND );

        for( uint i = 0; i < SOUNDS.length(); i++ )
            g_SoundSystem.PrecacheSound( SOUNDS[i] );

        g_SoundSystem.PrecacheSound( RELOAD_SND1 );
        g_SoundSystem.PrecacheSound( RELOAD_SND2 );

        g_Game.PrecacheGeneric( "sprites/bts_rc/muzzleflash12.spr" );
        // g_Game.PrecacheGeneric( "events/ .txt" );
        g_Game.PrecacheGeneric( "sprites/bts_rc/w_flare.spr" );
        g_Game.PrecacheGeneric( "sprites/bts_rc/wepspr.spr" );
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
        SetThink( null );
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
        // don't fire underwater/without having ammo loaded
        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;
            return;
        }

        m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

        // Notify the monsters about the grenade
        m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
        m_pPlayer.m_flStopExtraSoundTime = g_Engine.time + 0.2f;

        --self.m_iClip;

        m_pPlayer.pev.effects |= EF_MUZZLEFLASH; // Add muzzleflash
        pev.effects |= EF_MUZZLEFLASH;

        // player "shoot" animation
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

        Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
        Vector vecSrc = m_pPlayer.GetGunPosition() + g_Engine.v_forward * OFFSET.x + g_Engine.v_right * OFFSET.y + g_Engine.v_up * OFFSET.z;
        Vector vecVelocity = g_Engine.v_forward * VELOCITY;

        auto flare = FLARE::Shoot( m_pPlayer.pev, vecSrc, vecVelocity, DAMAGE, DURATION, PRJ_MDL );
        flare.pev.scale = 0.5f;
        // CreateMuzzleflash( SPRITE_MUZZLE_GRENADE, MUZZLE_ORIGIN.x, MUZZLE_ORIGIN.y, MUZZLE_ORIGIN.z, 0.05, 128, 20.0 );

        // View model animation
        self.SendWeaponAnim( SHOOT, 0, GetBodygroup() );
        // Custom Volume and Pitch
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SHOOT_SND, Math.RandomFloat( 0.95f, 1.0f ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
        // m_pPlayer.pev.punchangle.x = -10.0; // Recoil
        m_pPlayer.pev.punchangle.x = Math.RandomFloat( -2.0f, -3.0f );

        if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && m_fHasHEV )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;
        self.m_flTimeWeaponIdle = g_Engine.time + 5.0f; //Idle pretty soon after shooting.
    }

    void Reload()
    {
        if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        if( self.m_flNextPrimaryAttack > g_Engine.time )
            return;

        self.DefaultReload( MAX_CLIP, HOLSTER, 2.5f, GetBodygroup() );
        self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 2.75f;
        SetThink( ThinkFunction( this.FinishAnim ) );
        pev.nextthink = g_Engine.time + 1.5f;
    }

    void WeaponIdle()
    {
        self.ResetEmptySound();
        m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

        if( self.m_flTimeWeaponIdle > g_Engine.time )
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

    private void FinishAnim()
    {
        SetThink( null );
        self.SendWeaponAnim( DRAW, 0, GetBodygroup() );
        BaseClass.Reload();

        switch( Math.RandomLong( 0, 1 ) )
        {
            case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, RELOAD_SND1, 1.0f, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) ); break;
            case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, RELOAD_SND2, 1.0f, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) ); break;
        }
    }
}

// Ammo class
class ammo_bts_flarebox : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, A_MODEL );
        BaseClass.Spawn();
    }

    void Precache()
    {
        g_Game.PrecacheModel( A_MODEL );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/flare_pickup.wav" );
    }

    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( AMMO_GIVE, AMMO_TYPE, MAX_CARRY ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "bts_rc/weapons/flare_pickup.wav", 1.0f, ATTN_NORM );
            return true;
        }
        return false;
    }
}

void Register()
{
#if SERVER
    weapons.insertLast( "weapon_bts_flaregun" );
#endif

    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLAREGUN::weapon_bts_flaregun", "weapon_bts_flaregun" );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLAREGUN::ammo_bts_flarebox", "ammo_bts_flarebox" );
    ID = g_ItemRegistry.RegisterWeapon( "weapon_bts_flaregun", "bts_rc/weapons", AMMO_TYPE, "", "ammo_bts_flarebox", "" );
}

}
