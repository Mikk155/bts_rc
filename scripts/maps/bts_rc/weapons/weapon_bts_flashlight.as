// Flashlight/Torchlight
// Original Code: Mikk
// Models: Valve Software, Gearbox Software, dydwk747, ruMpel ( Battery model )
// Sprites: Patofan05
// Thanks Mikk for scripting full support
// Rewrited by Rizulix for bts_rc (december 2024)

#include "../utils/player_class"

namespace BTS_FLASHLIGHT
{

enum btsflashlight_e
{
    IDLE = 0,
    DRAW,
    HOLSTER,
    ATTACK1HIT,
    ATTACK1MISS,
    ATTACK2MISS,
    ATTACK2HIT,
    ATTACK3MISS,
    ATTACK3HIT,
    IDLE2,
    IDLE3
};

enum bodygroups_e
{
    STUDIO = 0,
    HANDS
};

// Models
string W_MODEL = "models/bts_rc/weapons/w_flashlight.mdl";
string V_MODEL = "models/bts_rc/weapons/v_flashlight.mdl";
string P_MODEL = "models/bts_rc/weapons/p_flashlight.mdl";
string A_MODEL = "models/bts_rc/furniture/w_flashlightbattery.mdl";
// Sounds
string EMPTY_SND = "hlclassic/weapons/357_cock1.wav";
string MISS_SND = "bts_rc/weapons/flashlight_miss1.wav";
array<string> HITWORLD_SND = {
    "bts_rc/weapons/flashlight_hit1.wav",
    "bts_rc/weapons/flashlight_hit2.wav"
};
array<string> HITFLESH_SND = {
    "bts_rc/weapons/flashlight_hitbod1.wav",
    "bts_rc/weapons/flashlight_hitbod2.wav",
    "bts_rc/weapons/flashlight_hitbod3.wav"
};
string SWITCH_SND = "bts_rc/items/flashlight1.wav";
string RELOAD_SND = "bts_rc/items/battery_reload.wav";
// Weapon info
int MAX_CARRY = 10;
int MAX_CLIP = WEAPON_NOCLIP;
// int DEFAULT_GIVE = 10;
int AMMO_GIVE = 5;
int AMMO_DROP = 1;
int WEIGHT = 10;
int FLAGS = ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY;
int ID; // assigned on register
string AMMO_TYPE = "bts:battery";
// Weapon HUD
int SLOT = 4;
int POSITION = 4;
// Vars
float RANGE = 32.0f;
float DAMAGE = 7.0f;
float DRAIN_TIME = 0.8f;
string BATTERY_KV = "$i_flashlightBattery";

class weapon_bts_flashlight : ScriptBasePlayerWeaponEntity
{
    private CBasePlayer@ m_pPlayer
    {
        get const { return cast<CBasePlayer>( self.m_hPlayer.GetEntity() ); }
        set       { self.m_hPlayer = EHandle( @value ); }
    }
    // private bool m_fHasHEV
    // {
    //     get const { return g_PlayerClass[m_pPlayer] == HELMET; }
    // }
    private int m_iFlashBattery
    {
        get const { return int( m_pPlayer.GetUserData()[ BATTERY_KV ] ); }
        set       { m_pPlayer.GetUserData()[ BATTERY_KV ] = value; }
    }
    private float m_flFlashLightTime;
    private int m_iCurrentBaterry;
    private TraceResult m_trHit;
    private int m_iSwing;

    int GetBodygroup()
    {
        pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( V_MODEL ), pev.body, HANDS, g_PlayerClass[m_pPlayer] );
        return pev.body;
    }

    void Spawn()
    {
        Precache();
        self.m_flCustomDmg = pev.dmg;
        g_EntityFuncs.SetModel( self, self.GetW_Model( W_MODEL ) );
        self.m_iDefaultAmmo = Math.RandomLong( 0, 2 );
        self.FallInit();

        m_iSwing = 0;
    }

    void Precache()
    {
        self.PrecacheCustomModels();
        g_Game.PrecacheModel( W_MODEL );
        g_Game.PrecacheModel( V_MODEL );
        g_Game.PrecacheModel( P_MODEL );
        g_Game.PrecacheModel( A_MODEL );

        g_Game.PrecacheOther( GetAmmoName() );

        g_SoundSystem.PrecacheSound( EMPTY_SND );
        g_SoundSystem.PrecacheSound( MISS_SND );

        for( uint i = 0; i < HITWORLD_SND.length(); i++ )
            g_SoundSystem.PrecacheSound( HITWORLD_SND[i] );

        for( uint j = 0; j < HITFLESH_SND.length(); j++ )
            g_SoundSystem.PrecacheSound( HITFLESH_SND[j] );

        g_SoundSystem.PrecacheSound( SWITCH_SND );
        g_SoundSystem.PrecacheSound( RELOAD_SND );

        g_Game.PrecacheGeneric( "sprites/bts_rc/wepspr.spr" );
        g_Game.PrecacheGeneric( "sprites/bts_rc/ammo_battery.spr" );
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

    bool CanDeploy()
    {
        return true;
    }

    bool Deploy()
    {
        m_iCurrentBaterry = m_iFlashBattery;
        m_pPlayer.pev.effects &= ~EF_DIMLIGHT; // just to be sure
        m_pPlayer.m_iHideHUD &= ~HIDEHUD_FLASHLIGHT;

        NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, m_pPlayer.edict() );
            msg.WriteByte( 0 );
            msg.WriteByte( m_iCurrentBaterry );
        msg.End();

        self.DefaultDeploy( self.GetV_Model( V_MODEL ), self.GetP_Model( P_MODEL ), DRAW, "crowbar", 0, GetBodygroup() );
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
        return true;
    }

    void Holster( int skiplocal = 0 )
    {
        SetThink( null );
        g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, RELOAD_SND );

        if ( m_pPlayer.FlashlightIsOn() )
            FlashlightTurnOff();

        m_iFlashBattery = m_iCurrentBaterry;
        m_pPlayer.m_iHideHUD |= HIDEHUD_FLASHLIGHT;
        BaseClass.Holster( skiplocal );
    }

    void ItemPostFrame()
    {
        if( m_flFlashLightTime != 0.0f && m_flFlashLightTime <= g_Engine.time )
        {
            if( m_pPlayer.FlashlightIsOn() )
            {
                if( m_iCurrentBaterry != 0 )
                {
                    m_flFlashLightTime = g_Engine.time + DRAIN_TIME;
                    --m_iCurrentBaterry;

                    if( m_iCurrentBaterry == 0 )
                        FlashlightTurnOff();
                }
            }
            else
            {
                m_flFlashLightTime = 0.0f;
            }

            NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::FlashBat, m_pPlayer.edict() );
                msg.WriteByte( m_iCurrentBaterry );
            msg.End();
        }
        BaseClass.ItemPostFrame();
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
        if( !Swing( true ) )
        {
            SetThink( ThinkFunction( this.SwingAgain ) );
            pev.nextthink = g_Engine.time + 0.1f;
        }
    }

    void SecondaryAttack()
    {
        if( m_iCurrentBaterry == 0 )
        {
            self.PlayEmptySound();
            self.m_flNextSecondaryAttack = g_Engine.time + 0.3f;
            return;
        }

        if( m_pPlayer.FlashlightIsOn() )
            FlashlightTurnOff();
        else
            FlashlightTurnOn();

        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.3f;
    }

    void TertiaryAttack()
    {
        if( m_iCurrentBaterry != 0 || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        SetThink( null );
        m_flFlashLightTime = 0.0f;

        SetThink( ThinkFunction( BaterryRechargeStart ) );
        pev.nextthink = g_Engine.time + ( 5.0f / 25.0f );

        self.SendWeaponAnim( HOLSTER, 0, GetBodygroup() );
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 20.0f; // just block
    }

    void WeaponIdle()
    {
        self.ResetEmptySound();
        m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

        if( self.m_flTimeWeaponIdle > g_Engine.time )
            return;

        switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 3 ) )
        {
            case 0: self.SendWeaponAnim( IDLE3, 0, GetBodygroup() ); break; 
            case 1: self.SendWeaponAnim( IDLE2, 0, GetBodygroup() ); break; 
            default: self.SendWeaponAnim( IDLE, 0, GetBodygroup() ); break;
        }

        self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 6.0f, 8.0f );
    }

    private void BaterryRechargeStart()
    {
        SetThink( ThinkFunction( BaterryRechargeEnd ) );
        pev.nextthink = g_Engine.time + 4.0f;

        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, RELOAD_SND, 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
    }

    private void BaterryRechargeEnd()
    {
        SetThink( null );

        self.SendWeaponAnim( DRAW, 0, GetBodygroup() );
        m_iFlashBattery = m_iCurrentBaterry = 100;

        NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::FlashBat, m_pPlayer.edict() );
            msg.WriteByte( m_iCurrentBaterry );
        msg.End();

        m_pPlayer.m_flNextAttack = 0.5f;
        m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + ( 14.0f / 25.0f );
    }

    private void FlashlightTurnOn()
    {
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SWITCH_SND, 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
        m_pPlayer.pev.effects |= EF_DIMLIGHT;

        NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, m_pPlayer.edict() );
            msg.WriteByte( 1 );
            msg.WriteByte( m_iCurrentBaterry );
        msg.End();

        m_flFlashLightTime = g_Engine.time + DRAIN_TIME;
    }

    private void FlashlightTurnOff()
    {
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, SWITCH_SND, 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
        m_pPlayer.pev.effects &= ~EF_DIMLIGHT;

        NetworkMessage msg( MSG_ONE_UNRELIABLE, NetworkMessages::Flashlight, m_pPlayer.edict() );
            msg.WriteByte( 0 );
            msg.WriteByte( m_iCurrentBaterry );
        msg.End();

        m_flFlashLightTime = 0.0f;
    }

    // -TODO Store if flashlight was on and turn off momentarly til the swing ends
    private bool Swing( bool fFirst )
    {
        TraceResult tr;
        bool fDidHit = false;

        Math.MakeVectors( m_pPlayer.pev.v_angle );
        Vector vecSrc   = m_pPlayer.GetGunPosition();
        Vector vecEnd   = vecSrc + g_Engine.v_forward * RANGE;

        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

        if( tr.flFraction >= 1.0f )
        {
            g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
            if( tr.flFraction < 1.0f )
            {
                // Calculate the point of intersection of the line (or hull) and the object we hit
                // This is and approximation of the "best" intersection
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if( pHit is null || pHit.IsBSPModel() )
                    g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
                vecEnd = tr.vecEndPos; // This is the point on the actual surface (the hull could have hit space)
            }
        }

        if( tr.flFraction >= 1.0f )
        {
            if( fFirst )
            {
                // miss
                switch( ( m_iSwing++ ) % 3 )
                {
                    case 0: self.SendWeaponAnim( ATTACK1MISS, 0, GetBodygroup() ); break;
                    case 1: self.SendWeaponAnim( ATTACK2MISS, 0, GetBodygroup() ); break;
                    case 2: self.SendWeaponAnim( ATTACK3MISS, 0, GetBodygroup() ); break;
                }
                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.625f;
                self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

                // play wiff or swish sound
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, MISS_SND, 1.0f, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 0xF ) );

                // player "shoot" animation
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
            }
        }
        else
        {
            // hit
            fDidHit = true;

            CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

            switch( ( ( m_iSwing++ ) % 2 ) + 1 )
            {
                case 0: self.SendWeaponAnim( ATTACK1HIT, 0, GetBodygroup() ); break;
                case 1: self.SendWeaponAnim( ATTACK2HIT, 0, GetBodygroup() ); break;
                case 2: self.SendWeaponAnim( ATTACK3HIT, 0, GetBodygroup() ); break;
            }

            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.375f;
            self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

            // player "shoot" animation
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

            // AdamR: Custom damage option
            float flDamage = DAMAGE;
            if( self.m_flCustomDmg > 0.0f )
                flDamage = self.m_flCustomDmg;
            // AdamR: End

            g_WeaponFuncs.ClearMultiDamage();

            if( self.m_flNextPrimaryAttack + 1.0f < g_Engine.time )
                pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB ); // first swing does full damage
            else
                pEntity.TraceAttack( m_pPlayer.pev, flDamage * 0.5f, g_Engine.v_forward, tr, DMG_CLUB ); // subsequent swings do 50% (Changed -Sniper) (Half)

            g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

            // play thwack, smack, or dong sound
            float flVol = 1.0f;
            bool fHitWorld = true;

            // for monsters or breakable entity smacking speed function
            if( pEntity !is null )
            {
                if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
                {
                    // aone
                    if( pEntity.IsPlayer() ) // lets pull them
                        pEntity.pev.velocity = pEntity.pev.velocity + ( pev.origin - pEntity.pev.origin ).Normalize() * 120.0f;
                    // end aone

                    // play thwack or smack sound
                    g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, HITFLESH_SND[Math.RandomLong( 0, HITFLESH_SND.length() - 1 )], 1.0f, ATTN_NORM );
                    m_pPlayer.m_iWeaponVolume = 128;

                    if( !pEntity.IsAlive() )
                        return true;
                    else
                        flVol = 0.1f;

                    fHitWorld = false;
                }
            }

            // play texture hit sound
            // UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

            if( fHitWorld )
            {
                g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2.0f, BULLET_PLAYER_CROWBAR );

                // also play crowbar strike
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, HITWORLD_SND[Math.RandomLong( 0, HITWORLD_SND.length() - 1 )], 1.0f, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
            }

            // delay the decal a bit
            m_trHit = tr;
            SetThink( ThinkFunction( this.Smack ) );
            pev.nextthink = g_Engine.time + 0.2f;

            m_pPlayer.m_iWeaponVolume = int( flVol * 512 );
        }
        return fDidHit;
    }

    private void SwingAgain()
    {
        Swing( false );
    }

    private void Smack()
    {
        g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
    }
}

class ammo_bts_battery : ScriptBasePlayerAmmoEntity
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
        g_SoundSystem.PrecacheSound( "bts_rc/items/battery_pickup1.wav" );
    }

    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? AMMO_DROP : AMMO_GIVE, AMMO_TYPE, MAX_CARRY ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "bts_rc/items/battery_pickup1.wav", 1.0f, ATTN_NORM );
            return true;
        }
        return false;
    }
}

string GetName()
{
    return "weapon_bts_flashlight";
}

string GetAmmoName()
{
    return "ammo_bts_battery";
}

void Register()
{
#if SERVER
    weapons.insertLast( GetName() );
#endif

    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLASHLIGHT::weapon_bts_flashlight", GetName() );
    g_CustomEntityFuncs.RegisterCustomEntity( "BTS_FLASHLIGHT::ammo_bts_battery", GetAmmoName() );
    ID = g_ItemRegistry.RegisterWeapon( GetName(), "bts_rc/weapons", AMMO_TYPE, "", GetAmmoName(), "" );
}

}
// End namespace BTS_FLASHLIGHT
// if you wanna use this as a sample, go ahead and make sure credit the rightful owner.
// whoever tryna steal this original work and claimed it to be their own is a fucktard.