//Black Mesa Emergency Flare
/* Model Credits
/ Model: Valve
/ Textures: Valve
/ Animations: Valve
/ Sounds: Valve
/ Sprites: Valve
/ Misc: Valve, D.N.I.O. 071 ( Player Model Fix )
/ Script: Solokiller, KernCore, original base from Nero
*/
// Rewrited by Rizulix for bts_rc (december 2024)

#include "../proj/flare"
#include "../utils/player_class"

namespace BTS_FLARE
{

// Animations
enum btsflare_e
{
    IDLE = 0,
    PULLPIN,
    THROW,
    DRAW
};

enum bodygroups_e
{
    HANDS = 0 // STUDIO
};

// Models
string W_MODEL = "models/bts_rc/weapons/w_flare.mdl";
string V_MODEL = "models/bts_rc/weapons/v_flare.mdl";
string P_MODEL = "models/bts_rc/weapons/p_flare.mdl";
string PRJ_MDL = "models/bts_rc/weapons/flare.mdl";
// Sounds
array<string> SOUNDS = {
    "bts_rc/weapons/flare_pinpull.wav",
    "bts_rc/weapons/flare_deploy.wav"
};
// Weapon info
int MAX_CARRY = 5;
int MAX_CLIP = WEAPON_NOCLIP;
int DEFAULT_GIVE = 1;
int AMMO_GIVE = DEFAULT_GIVE;
int AMMO_DROP = AMMO_GIVE;
int WEIGHT = 5;
int FLAGS = ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE;
int ID; // assigned on register
string AMMO_TYPE = GetName();
// Weapon HUD
uint SLOT = 4;
uint POSITION = 5;
// Vars
float TIMER = 1.5f;
float DAMAGE = 1.0f;
float DURATION = 180.0f;
Vector OFFSET( 16.0f, 0.0f, 0.0f ); // for projectile

class weapon_bts_flare : ScriptBasePlayerWeaponEntity
{
    private CBasePlayer@ m_pPlayer
    {
        get const { return cast<CBasePlayer>( self.m_hPlayer.GetEntity() ); }
        set       { self.m_hPlayer = EHandle( @value ); }
    }
    // private bool m_fHasHEV
    // {
    //  get const { return g_PlayerClass[m_pPlayer] == HELMET; }
    // }
    private float m_fAttackStart, m_flStartThrow;
    private bool m_bInAttack, m_bThrown;
    private int m_iAmmoSave;

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
        self.FallInit(); // get ready to fall
    }

    void Precache()
    {
        self.PrecacheCustomModels();
        g_Game.PrecacheModel( W_MODEL );
        g_Game.PrecacheModel( V_MODEL );
        g_Game.PrecacheModel( P_MODEL );
        g_Game.PrecacheModel( PRJ_MDL );

        g_Game.PrecacheOther( FLARE::GetName() );

        // g_SoundSystem.PrecacheSound( SHOOT_SND );
        // g_SoundSystem.PrecacheSound( EMPTY_SND );

        for( uint i = 0; i < SOUNDS.length(); i++ )
            g_SoundSystem.PrecacheSound( SOUNDS[i] );

        g_Game.PrecacheGeneric( "sprites/bts_rc/flare_selection.spr" );
        g_Game.PrecacheGeneric( "sprites/bts_rc/ammo_flare.spr" );
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

    // Better ammo extraction --- Anggara_nothing
    bool CanHaveDuplicates()
    {
        return true;
    }

    bool Deploy()
    {
        m_iAmmoSave = 0; // Zero out the ammo save
        self.DefaultDeploy( self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), DRAW, "gren", 0, GetBodygroup() );
        self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + ( 30.0f / 40.0f );
        return true;
    }

    bool CanHolster()
    {
        return m_fAttackStart == 0.0f;
    }

    bool CanDeploy()
    {
        return m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0;
    }

    CBasePlayerItem@ DropItem()
    {
        m_iAmmoSave = m_pPlayer.AmmoInventory( self.m_iPrimaryAmmoType ); // Save the player"s ammo pool in case it has any in DropItem
        return self;
    }

    void Holster( int skiplocal = 0 )
    {
        m_bThrown = false;
        m_bInAttack = false;
        m_fAttackStart = 0.0f;
        m_flStartThrow = 0.0f;

        SetThink( null );

        if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 ) // Save the player"s ammo pool in case it has any in Holster
        {
            m_iAmmoSave = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
        }

        if( m_iAmmoSave <= 0 )
        {
            SetThink( ThinkFunction( this.DestroyThink ) );
            pev.nextthink = g_Engine.time + 0.1f;
        }

        BaseClass.Holster( skiplocal );
    }

    void PrimaryAttack()
    {
        if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        if( m_fAttackStart < 0.0f || m_fAttackStart > 0.0f )
            return;

        self.m_flNextPrimaryAttack = g_Engine.time + ( 25.0f / 30.0f );
        self.SendWeaponAnim( PULLPIN, 0, GetBodygroup() );

        m_bInAttack = true;
        m_fAttackStart = g_Engine.time + ( 25.0f / 30.0f );

        self.m_flTimeWeaponIdle = g_Engine.time + ( 25.0f / 30.0f ) + ( 23.0f / 30.0f ); // ( 1.0f / 40.0f );
    }

    private void LaunchThink()
    {
        // g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_VOICE, SHOOT_S, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
        Vector angThrow = m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle;

        if( angThrow.x < 0.0f )
            angThrow.x = -10.0f + angThrow.x * ( ( 90.0f - 10.0f ) / 90.0f );
        else
            angThrow.x = -10.0f + angThrow.x * ( ( 90.0f + 10.0f ) / 90.0f );

        float flVel = ( 90.0f - angThrow.x ) * 6.0f;

        if( flVel > 750.0f )
            flVel = 750.0f;

        Math.MakeVectors( angThrow );
        Vector vecSrc = m_pPlayer.GetGunPosition() + g_Engine.v_forward * OFFSET.x + g_Engine.v_right * OFFSET.y + g_Engine.v_up * OFFSET.z;
        Vector vecThrow = g_Engine.v_forward * flVel + m_pPlayer.pev.velocity;

        FLARE::Toss( m_pPlayer.pev, vecSrc, vecThrow, DAMAGE, DURATION, TIMER, PRJ_MDL );

        m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
        m_fAttackStart = 0.0f;
    }

    void ItemPreFrame()
    {
        if( m_fAttackStart == 0 && m_bThrown == true && m_bInAttack == false && self.m_flTimeWeaponIdle - 0.1f < g_Engine.time )
        {
            if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
            {
                self.Holster();
            }
            else
            {
                self.Deploy();
                m_bThrown = false;
                m_bInAttack = false;
                m_fAttackStart = 0.0f;
                m_flStartThrow = 0.0f;
            }
        }

        if( !m_bInAttack || CheckButton() || g_Engine.time < m_fAttackStart )
            return;

        self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + ( 22.0f / 30.0f ); // ( 0.0f / 40.0f );
        self.SendWeaponAnim( THROW, 0, GetBodygroup() );
        m_bThrown = true;
        m_bInAttack = false;
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

        SetThink( ThinkFunction( this.LaunchThink ) );
        pev.nextthink = g_Engine.time + 0.2f;

        BaseClass.ItemPreFrame();
    }

    void WeaponIdle()
    {
        if( self.m_flTimeWeaponIdle > g_Engine.time )
            return;

        self.SendWeaponAnim( IDLE, 0, GetBodygroup() );
        self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5.0f, 7.0f );
    }

    private bool CheckButton() // returns which key the player is pressing (that might interrupt the reload)
    {
        return m_pPlayer.pev.button & ( IN_ATTACK | IN_ATTACK2 | IN_ALT1 ) != 0;
    }

    private void DestroyThink() // destroys the item
    {
        SetThink( null );
        self.DestroyItem();
        //g_Game.AlertMessage( at_console, "Item Destroyed.\n" );
    }
}

string GetName()
{
    return "weapon_bts_flare";
}

void Register()
{
#if DEVELOP
    weapons.insertLast( GetName() );
#endif

    FLARE::Register();
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLARE::weapon_bts_flare", GetName() );
    ID = g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", AMMO_TYPE, "", GetName(), "" );
}

}