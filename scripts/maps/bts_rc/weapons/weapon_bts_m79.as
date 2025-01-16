/**
>>>Credits<<<

->Model: Hellspike
->Textures: klla_syc3/flamshmizer
->Animations: Michael65
->Compile, Edits: Norman the Loli Pirate
->Colored Model: D.N.I.O. 071
->Sprites: Der Graue Fuchs
->Script author: KernCore, Nero0 ( CSO Grenade Projectile )
->Sounds: Resident Evil Cold Blood Team

* This script is a sample to be used in: https://github.com/baso88/SC_AngelScript/
* You're free to use this sample in any way you would like to
* Just remember to credit the people who worked to provide you this

**/
// Rewrited by Rizulix for bts_rc (december 2024)

namespace HL_M79
{

enum hlm79_e
{
    IDLE = 0,
    SHOOT,
    RELOAD,
    DRAW,
    HOLSTER
};

enum bodygroups_e
{
    M79 = 0,
    HANDS
};

//Models
string W_MODEL = "models/bts_rc/weapons/w_m79.mdl"; // World
string V_MODEL = "models/bts_rc/weapons/v_m79.mdl"; // View
string P_MODEL = "models/bts_rc/weapons/p_m79.mdl"; // Player
string A_MODEL = "models/w_argrenade.mdl"; // Ammo
string PRJ_MDL = "models/grenade.mdl"; // Grenade
// Sounds
string SHOOT_SND = "bts_rc/weapons/m79_fire.wav";
string EMPTY_SND = "hlclassic/weapons/357_cock1.wav";
array<string> SOUNDS = {
    "bts_rc/weapons/m79_open.wav",
    "bts_rc/weapons/m79_shellout.wav",
    "bts_rc/weapons/m79_shellin.wav",
    "bts_rc/weapons/m79_close.wav",
    "bts_rc/weapons/m79_aimon.wav"
};
// Weapon info
int MAX_CARRY = 10;
int MAX_CLIP = 1;
// int DEFAULT_GIVE = Math.RandomLong( 0, 3 );
int AMMO_GIVE = 2;
int AMMO_DROP = 1;
int WEIGHT = 20;
int FLAGS = 0;
int ID; // assigned on register
string AMMO_TYPE = "ARgrenades";
// Weapon HUD
int SLOT = 3;
int POSITION = 4;
// Vars
float DAMAGE = 125.0f;
float RADIUS = 240.0f;
float VELOCITY = 1200.0f;
Vector OFFSET( 8.0f, 4.0f, -2.0f ); // for projectile

// string SPRITE_MUZZLE_GRENADE = "sprites/bts_rc/muzzleflash12.spr";
// Vector MUZZLE_ORIGIN = Vector( 16.0, 4.0, -4.0 ); // forward, right, up

class weapon_bts_m79 : ScriptBasePlayerWeaponEntity
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
        self.m_iDefaultAmmo = Math.RandomLong( 0, 3 );
        self.FallInit(); // get ready to fall
    }

    // Always precache the stuff you're going to use
    void Precache()
    {
        self.PrecacheCustomModels();
        g_Game.PrecacheModel( W_MODEL );
        g_Game.PrecacheModel( V_MODEL );
        g_Game.PrecacheModel( P_MODEL );
        g_Game.PrecacheModel( A_MODEL );
        g_Game.PrecacheModel( PRJ_MDL );

        g_Game.PrecacheOther( "ammo_bts_m79" );

        // Precaches the sound for the engine to use
        g_SoundSystem.PrecacheSound( SHOOT_SND );
        g_SoundSystem.PrecacheSound( EMPTY_SND );

        for( uint i = 0; i < SOUNDS.length(); i++ )
            g_SoundSystem.PrecacheSound( SOUNDS[i] );

        // Precaches the stuff for download
        g_Game.PrecacheGeneric( "sprites/bts_rc/muzzleflash12.spr" );
        // g_Game.PrecacheGeneric( "events/ .txt" );
        g_Game.PrecacheGeneric( "sprites/bts_rc/weapon_M79.spr" );
        g_Game.PrecacheGeneric( "sprites/bts_rc/M79_crosshair.spr" );
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
        self.DefaultDeploy( self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), DRAW, "bow", 0, GetBodygroup() );
        self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.03f;
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

        M79_ROCKET::Shoot( m_pPlayer.pev, vecSrc, vecVelocity, DAMAGE, RADIUS, PRJ_MDL );
        // CreateMuzzleflash( SPRITE_MUZZLE_GRENADE, MUZZLE_ORIGIN.x, MUZZLE_ORIGIN.y, MUZZLE_ORIGIN.z, 0.05, 128, 20.0 );

        // View model animation
        self.SendWeaponAnim( SHOOT, 0, GetBodygroup() );
        // Custom Volume and Pitch
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SHOOT_SND, Math.RandomFloat( 0.95f, 1.0f ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
        // m_pPlayer.pev.punchangle.x = -10.0; // Recoil
        m_pPlayer.pev.punchangle.x = Math.RandomFloat( -2.0, -3.0 );

        if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && m_fHasHEV )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;
        self.m_flTimeWeaponIdle = g_Engine.time + 5.0f; // Idle pretty soon after shooting.
    }

    void Reload()
    {
        // if the mag = the max mag, return
        if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        self.DefaultReload( MAX_CLIP, RELOAD, 3.88f, GetBodygroup() );
        // Set 3rd person reloading animation -Sniper
        BaseClass.Reload();
    }

    void WeaponIdle()
    {
        self.ResetEmptySound();
        m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

        if( self.m_flTimeWeaponIdle > g_Engine.time )
            return;

        self.SendWeaponAnim( IDLE, 0, GetBodygroup() );
        self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5.0f, 6.0f ); // How much time to idle again
    }
}

class ammo_bts_m79 : ScriptBasePlayerAmmoEntity
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
        g_SoundSystem.PrecacheSound( "hlclassic/items/9mmclip1.wav" );
    }

    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? AMMO_DROP : AMMO_GIVE, AMMO_TYPE, MAX_CARRY ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1.0f, ATTN_NORM );
            return true;
        }
        return false;
    }
}

void Register()
{
#if SERVER
    weapons.insertLast( "weapon_bts_m79" );
#endif

    M79_ROCKET::Register();
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_M79::weapon_bts_m79", "weapon_bts_m79" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL_M79::ammo_bts_m79", "ammo_bts_m79" );
    ID = g_ItemRegistry.RegisterWeapon( "weapon_bts_m79", "bts_rc/weapons", AMMO_TYPE, "", "ammo_bts_m79", "" );
}

} // Namespace end