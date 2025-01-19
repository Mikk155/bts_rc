/*
* M16A3 Full Auto
*/
// Rewrited by Rizulix for bts_rc (december 2024)

namespace BTS_M16A3
{

enum m16a3_e
{
    DRAW = 0,
    HOLSTER,
    IDLE,
    FIDGET,
    SHOOT1,
    SHOOT2,
    RELOAD,
    LAUNCH,
    RELOAD2 // m203 reload
};

enum bodygroups_e
{
    STUDIO0 = 0,
    STUDIO1,
    HANDS
};

// Weapon info
int MAX_CARRY = 150;
int MAX_CARRY2 = 10;
int MAX_CLIP = 30;
int MAX_CLIP2 = WEAPON_NOCLIP;
// int DEFAULT_GIVE = Math.RandomLong( 15, 30 );
// int DEFAULT_GIVE2 = Math.RandomLong( 0, 1 );
int AMMO_GIVE = MAX_CLIP;
int AMMO_GIVE2 = 2;
int AMMO_DROP = AMMO_GIVE;
int AMMO_DROP2 = 1;
int WEIGHT = 5;
// Weapon HUD
int SLOT = 2;
int POSITION = 10;
// Vars
int DAMAGE = 15;
float DAMAGE2 = 100.0f;
Vector CROUCH_CONE( 0.01f, 0.01f, 0.01f );
Vector SHELL( 32.0f, 6.0f, -12.0f );

class weapon_bts_m16 : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon
{
    private CBasePlayer@ m_pPlayer { get const { return get_player(); } }

    private int m_iTracerCount;

    void Spawn()
    {
        g_EntityFuncs.SetModel( self, self.GetW_Model( "models/bts_rc/weapons/w_m16.mdl" ) );
        self.m_iDefaultAmmo = Math.RandomLong( 15, MAX_CLIP );
        self.m_iDefaultSecAmmo = Math.RandomLong( 0, 1 );
        self.FallInit();

        m_iTracerCount = 0;
    }

    bool GetItemInfo( ItemInfo& out info )
    {
        info.iMaxAmmo1 = MAX_CARRY;
        info.iAmmo1Drop = AMMO_DROP;
        info.iMaxAmmo2 = MAX_CARRY2;
        info.iAmmo2Drop = AMMO_DROP2;
        info.iMaxClip = MAX_CLIP;
        info.iSlot = SLOT;
        info.iPosition = POSITION;
        info.iId = g_ItemRegistry.GetIdForName( pev.classname );
        info.iFlags = m_flags;
        info.iWeight = WEIGHT;
        return true;
    }

    bool Deploy()
    {
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
        return bts_deploy( "models/bts_rc/weapons/v_m16a2.mdl", "models/bts_rc/weapons/p_m16.mdl", DRAW, "m16", HANDS );
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
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/357_cock1.wav", 0.8f, ATTN_NORM, 0, PITCH_NORM );
        }
        return false;
    }

    void PrimaryAttack()
    {
        // don't fire underwater
        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.13f;
            return;
        }

        m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

        --self.m_iClip;

        m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
        pev.effects |= EF_MUZZLEFLASH;

        // player "shoot" animation
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

        Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
        Vector vecSrc = m_pPlayer.GetGunPosition();
        Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
        Vector vecSpread = m_pPlayer.pev.FlagBitSet( FL_DUCKING ) ? CROUCH_CONE : VECTOR_CONE_3DEGREES;

        {
            float x, y;
            g_Utility.GetCircularGaussianSpread( x, y );

            Vector vecDir = vecAiming + x * vecSpread.x * g_Engine.v_right + y * vecSpread.y * g_Engine.v_up;
            Vector vecEnd = vecSrc + vecDir * 8192.0f;

            TraceResult tr;
            g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
            self.FireBullets( 1, vecSrc, vecDir, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, DAMAGE, m_pPlayer.pev );
            bts_post_attack(tr);

            // each 4 bullets
            if( ( m_iTracerCount++ % 4 ) == 0 )
            {
                Vector vecTracerSrc = vecSrc + Vector( 0.0f, 0.0f, -4.0f ) + g_Engine.v_right * 2.0f + g_Engine.v_forward * 16.0f;
                NetworkMessage tracer( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecTracerSrc );
                    tracer.WriteByte( TE_TRACER );
                    tracer.WriteCoord( vecTracerSrc.x );
                    tracer.WriteCoord( vecTracerSrc.y );
                    tracer.WriteCoord( vecTracerSrc.z );
                    tracer.WriteCoord( tr.vecEndPos.x );
                    tracer.WriteCoord( tr.vecEndPos.y );
                    tracer.WriteCoord( tr.vecEndPos.z );
                tracer.End();
            }

            if( tr.flFraction < 1.0f && tr.pHit !is null )
            {
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if( ( pHit is null || pHit.IsBSPModel() ) && !pHit.pev.FlagBitSet( FL_WORLDBRUSH ) )
                    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
            }
        }

        switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
        {
            case 0: self.SendWeaponAnim( SHOOT1, 0, pev.body ); break;
            case 1: self.SendWeaponAnim( SHOOT2, 0, pev.body ); break;
            case 2: self.SendWeaponAnim( SHOOT1, 0, pev.body ); break;
        }

        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/m16_fire1.wav", 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

        bool is_trained_personal = g_PlayerClass.is_trained_personal(m_pPlayer);

        if( is_trained_personal )
            m_pPlayer.pev.punchangle.x = -3.0f;
        else
            m_pPlayer.pev.punchangle.x = m_pPlayer.pev.FlagBitSet( FL_DUCKING ) ? float( Math.RandomLong( -3, 2 )) : float( Math.RandomLong( -8, 3 ) );

        Vector vecForward, vecRight, vecUp;
        g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
        Vector vecOrigin = m_pPlayer.GetGunPosition() + vecForward * SHELL.x + vecRight * SHELL.y + vecUp * SHELL.z;
        Vector vecVelocity = m_pPlayer.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat( 50.0f, 70.0f ) + vecUp * Math.RandomFloat( 100.0f, 150.0f );
        g_EntityFuncs.EjectBrass( vecOrigin, vecVelocity, m_pPlayer.pev.v_angle.y, models::saw_shell, TE_BOUNCE_SHELL );

        if( self.m_iClip <= 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 && g_PlayerClass[m_pPlayer] == PM::HELMET )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        self.m_flNextPrimaryAttack = g_Engine.time + 0.142f;
        self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0f, 15.0f );
    }

    void SecondaryAttack()
    {
        // don't fire underwater
        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0 )
        {
            self.PlayEmptySound();
            self.m_flNextSecondaryAttack = g_Engine.time + 0.15f;
            return;
        }

        m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

        m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
        m_pPlayer.m_flStopExtraSoundTime = g_Engine.time + 0.2f;

        m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );

        // player "shoot" animation
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

        Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
        Vector vecSrc = m_pPlayer.pev.origin + g_Engine.v_forward * 16.0f + g_Engine.v_right * 6.0f;
        vecSrc = vecSrc + ( ( ( m_pPlayer.pev.button & IN_DUCK ) != 0 ) ? g_vecZero : ( m_pPlayer.pev.view_ofs * 0.5f ) );

        // we don't add in player velocity anymore.
        CGrenade@ pGrenade = g_EntityFuncs.ShootContact( m_pPlayer.pev, vecSrc, g_Engine.v_forward * 900.0f );
        if( pGrenade !is null )
        {
            g_EntityFuncs.SetModel( pGrenade, "models/hlclassic/grenade.mdl" );
            pGrenade.pev.dmg = DAMAGE2;
        }

        self.SendWeaponAnim( LAUNCH, 0, pev.body );

        if( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) != 0 )
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/glauncher.wav", 0.8f, ATTN_NORM, 0, PITCH_NORM );
        else
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/glauncher2.wav", 0.8f, ATTN_NORM, 0, PITCH_NORM );

        m_pPlayer.pev.punchangle.x = -11.0f;

        if( m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) <= 0 && g_PlayerClass[m_pPlayer] == PM::HELMET )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.25f;
        self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;
    }

    void Reload()
    {
        if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
            return;

        self.DefaultReload( MAX_CLIP, RELOAD, 3.25f, pev.body );
        self.m_flTimeWeaponIdle = g_Engine.time + 3.25f;
        BaseClass.Reload();
    }

    void WeaponIdle()
    {
        self.ResetEmptySound();
        m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

        if( self.m_flTimeWeaponIdle > g_Engine.time )
            return;

        switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) )
        {
            case 0: self.SendWeaponAnim( IDLE, 0, pev.body ); break;
            case 1: self.SendWeaponAnim( FIDGET, 0, pev.body ); break;
        }

        self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10.0f, 15.0f );
    }
}

class ammo_bts_m16 : ScriptBasePlayerAmmoEntity
{
    private int m_iAmount = AMMO_GIVE;

    void Spawn()
    {
        if( pev.ClassNameIs( "ammo_bts_556round" ) )
            m_iAmount = Math.RandomLong( 9, 23 );

        g_EntityFuncs.SetModel( self, "models/bts_rc/weapons/w_9mmarclip.mdl" );
        BaseClass.Spawn();
    }

    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( m_iAmount, "556", MAX_CARRY ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1.0f, ATTN_NORM );
            return true;
        }
        return false;
    }
}

class ammo_bts_m16_grenade : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/hlclassic/w_argrenade.mdl" );
        BaseClass.Spawn();
    }

    bool AddAmmo( CBaseEntity@ pOther )
    {
        if( pOther.GiveAmmo( pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? AMMO_DROP2 : AMMO_GIVE2, "ARgrenades", MAX_CARRY2 ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hlclassic/items/9mmclip1.wav", 1.0f, ATTN_NORM );
            return true;
        }
        return false;
    }
}
}
