#include "weapon_bts_axe"
#include "weapon_bts_screwdriver"

namespace weapons
{
    array<ItemMapping@> gpItemMapping(0);
    array<string> gpWeaponNames(0);

    bool gpAllowMeleePush;
    bool gpAllowMeleePull;
    bool gpTraceBlood;
    bool gpTraceSparks;

    void Register( dictionary@ data )
    {
        data.get( "melee_weapons_push", gpAllowMeleePush );
        data.get( "melee_weapons_pull", gpAllowMeleePull );
        data.get( "blood_splash", gpTraceBlood );
        data.get( "sparks_splash", gpTraceSparks );
    }

    
    void Register(
        const string& in szName,
        const CBaseWeaponConfig@ pData = null,
        const string& in szPrimaryAmmoName = String::EMPTY_STRING,
        const string& in szSecondaryAmmoName = String::EMPTY_STRING,
        const string& in szPrimaryAmmoClass = String::EMPTY_STRING,
        const string& in szSecondaryAmmoClass = String::EMPTY_STRING,
        const string& in remapEntity = String::EMPTY_STRING
    )
    {
        if( !remapEntity.IsEmpty() )
        {
            auto remap = ItemMapping( remapEntity, szName );
            gpItemMapping.insertLast( @remap );
        }

        if( pData !is null )
        {
            g_Game.PrecacheModel( pData.view_model );
            g_Game.PrecacheModel( pData.world_model );
            g_Game.PrecacheModel( pData.player_model );
        }

        g_CustomEntityFuncs.RegisterCustomEntity( szName, szName );

        g_ItemRegistry.RegisterWeapon( szName, "bts_rc/weapons" );

        string szSpriteDir; // Precache HUD text definition
        snprintf( szSpriteDir, "sprites/bts_rc/weapons/%1.txt", szName );
        g_Game.PrecacheGeneric( szSpriteDir );

        gpWeaponNames.insertLast( szName );
    }

}

// General shared configuration for weapons
class CBaseWeaponConfig
{
    // Weapon view model. automatically precached in BTS_Weapon::Precache and set in BTS_Weapon::Deploy
    string view_model;
    // Weapon player model. automatically precached in BTS_Weapon::Precache and set in BTS_Weapon::Deploy
    string player_model;
    // Weapon world model. automatically precached in BTS_Weapon::Precache and set in BTS_Weapon::Deploy
    string world_model;
    // Weapon deploy extension. automatically set in BTS_Weapon::Deploy
    string animation_extension;
    // Weapon deploy bodygroup value. some models has their hands bodgroup on a different value. automatically set in BTS_Weapon::Deploy
    uint8 hands_group = 1;
    // Weapon deploy animation index. automatically set in BTS_Weapon::Deploy
    uint8 animation_draw;
    // Weapon deploy time cooldown for attacking. automatically set in BTS_Weapon::Deploy
    float deploy_time = 1.0f;
    // Weapon primary max ammo capacity. automatically set in BTS_Weapon::GetItemInfo
    int iMaxAmmo1 = WEAPON_NOCLIP;
    // Weapon primary max ammo drop. automatically set in BTS_Weapon::GetItemInfo
    int iAmmo1Drop = WEAPON_NOCLIP;
    // Weapon secondary max ammo capacity. automatically set in BTS_Weapon::GetItemInfo
    int iMaxAmmo2 = WEAPON_NOCLIP;
    // Weapon secondary max ammo drop. automatically set in BTS_Weapon::GetItemInfo
    int iAmmo2Drop = WEAPON_NOCLIP;
    // Weapon primary max ammo clip capacity. automatically set in BTS_Weapon::GetItemInfo
    int iMaxClip = WEAPON_NOCLIP;
    // Weapon hud slot. automatically set in BTS_Weapon::GetItemInfo
    uint8 iSlot = 0;
    // Weapon hud position. automatically set in BTS_Weapon::GetItemInfo
    uint8 iPosition = 0;
    // Weapon heigth. automatically set in BTS_Weapon::GetItemInfo
    uint8 iWeight = 0;
    // Weapon damage for primary attack
    float PrimaryDamage;
    // Weapon damage for secondary attack
    float SecondaryDamage;
    // Weapon cooldown for primary attack
    float PrimaryCooldown;
    // Weapon cooldown for primary attack for trained personal
    float PrimaryTrainedCooldown;
    // Weapon cooldown for secondary attack
    float SecondaryCooldown;
    // Weapon cooldown for secondary attack for trained personal
    float SecondaryTrainedCooldown;
    // Weapon cooldown for tertriary attack
    float TertriaryCooldown;
    // Weapon cooldown for tertriary attack for trained personal
    float TertriaryTrainedCooldown;

    /// Melee weapon attack distance
    float PrimaryDistance;
    float SecondaryDistance;
    float TertriaryDistance;
    // Melee weapon subsequent hits damage deduction
    float SubsequentDeduction = 0.5f;
    float PrimaryMissCooldown;
    float SecondaryMissCooldown;
    float PrimaryMissTrainedCooldown;
    float SecondaryMissTrainedCooldown;

    CBaseWeaponConfig() {}

    CBaseWeaponConfig( dictionary@ json )
    {
        json.get( "primary_maxammo", iMaxAmmo1 );
        json.get( "primary_dropammo", iAmmo1Drop );
        json.get( "secondary_maxammo", iMaxAmmo2 );
        json.get( "secondary_dropammo", iAmmo2Drop );
        json.get( "max_clip", iMaxClip );
        json.get( "slot", iSlot );
        json.get( "position", iPosition );
        json.get( "weight", iWeight );

        json.get( "primary_distance", PrimaryDistance );
        if( !json.get( "secondary_distance", SecondaryDistance ) )
            SecondaryDistance = PrimaryDistance;
        if( !json.get( "tertriary_distance", TertriaryDistance ) )
            TertriaryDistance = PrimaryDistance;
        json.get( "subsequent_hits_deduction", SubsequentDeduction );
        json.get( "primary_damage", PrimaryDamage );
        json.get( "secondary_damage", SecondaryDamage );

        json.get( "primary_cooldown", PrimaryCooldown );
        json.get( "primary_miss_cooldown", PrimaryMissCooldown );
        json.get( "primary_trained_cooldown", PrimaryTrainedCooldown );
        json.get( "primary_miss_trained_cooldown", PrimaryMissTrainedCooldown );

        json.get( "secondary_cooldown", SecondaryCooldown );
        json.get( "secondary_miss_cooldown", SecondaryMissCooldown );
        json.get( "secondary_trained_cooldown", SecondaryTrainedCooldown );
        json.get( "secondary_miss_trained_cooldown", SecondaryMissTrainedCooldown );
    }
}

const int gpDefaultWeaponFlags = ( ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_NOAUTORELOAD );

CBaseWeaponConfig@ gpDefaultWeaponData = CBaseWeaponConfig();

class BTS_Weapon : ScriptBasePlayerWeaponEntity
{
    CBaseWeaponConfig@ get_DefaultConfig() {
        return @gpDefaultWeaponData;
    }

    CBasePlayer@ m_owner = null;

    /// Get the player owning this weapon
    CBasePlayer@ get_owner()
    {
        if( m_owner is null || m_owner !is self.m_hPlayer.GetEntity() )
        {
            @m_owner = cast<CBasePlayer>( self.m_hPlayer.GetEntity() );
        }

        return @m_owner;
    }

    void Spawn()
    {
        g_EntityFuncs.SetModel( self, this.DefaultConfig.world_model );

        self.FallInit();
    }

    bool Deploy()
    {
        auto config = this.DefaultConfig;
        auto player = this.owner;

        player.pev.viewmodel = config.view_model;
        player.pev.weaponmodel = config.player_model;

        player.set_m_szAnimExtension( config.animation_extension );

        auto character = GetCharacter(player);
        Hands handGroup = ( character !is null ? character.HandsGroup : Hands::Gray );

        // Set the correct bodygroup for character hands in the given hands_group, most of the weapons has it in the bodygroup 1s
        self.pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( config.view_model ), self.pev.body, config.hands_group, handGroup );

        self.SendWeaponAnim( config.animation_draw, 0, self.pev.body );

        player.m_flNextAttack = config.deploy_time;
        float globalized_deploy = config.deploy_time + g_Engine.time;

        if( self.m_flNextPrimaryAttack < globalized_deploy )
            self.m_flNextPrimaryAttack = globalized_deploy;

        if( self.m_flTimeWeaponIdle < globalized_deploy )
            self.m_flTimeWeaponIdle = globalized_deploy;

        if( self.m_flNextSecondaryAttack < globalized_deploy )
            self.m_flNextSecondaryAttack = globalized_deploy;

        return true;
    }

    bool GetItemInfo( ItemInfo& out info )
    {
        auto config = this.DefaultConfig;

        info.iMaxAmmo1 = config.iMaxAmmo1;
        info.iAmmo1Drop = config.iAmmo1Drop;
        info.iMaxAmmo2 = config.iMaxAmmo2;
        info.iAmmo2Drop = config.iAmmo2Drop;
        info.iMaxClip = config.iMaxClip;
        info.iSlot = config.iSlot;
        info.iPosition = config.iPosition;
        info.iId = g_ItemRegistry.GetIdForName( self.pev.classname );
        info.iFlags = gpDefaultWeaponFlags;

        return true;
    }

    bool AddToPlayer( CBasePlayer@ player )
    {
        if( !BaseClass.AddToPlayer( player ) )
            return false;

        NetworkMessage msg( MSG_ONE, NetworkMessages::WeapPickup, player.edict() );
            msg.WriteLong( g_ItemRegistry.GetIdForName( self.pev.classname ) );
        msg.End();

        return true;
    }

    protected array<CScheduledFunction@> m_Callbacks;

    // Use g_Scheduler.SetTimeout as value and the resulting callback object will be stored in the weapon base and cleared if the weapon is removed or holstered
    void StartSchedule( CScheduledFunction@ value )
    {
        m_Callbacks.insertLast( @value );
    }

    void ClearTimerList()
    {
        uint length = m_Callbacks.length();

        for( uint ui = 0; ui < length; ui++ )
        {
            auto callback = m_Callbacks[ui];

            if( callback !is null )
            {
                g_Scheduler.RemoveTimer( @callback );
            }
        }

        m_Callbacks.resize(0);
    }

    void UpdateOnRemove()
    {
        ClearTimerList();
        BaseClass.UpdateOnRemove();
    }

    void Holster( int skiplocal = 0 )
    {
        ClearTimerList();
        BaseClass.Holster( skiplocal );
    }

    float GetCooldown( bool is_trained_personal, AttackType type )
    {
        switch( type )
        {
            case AttackType::Primary:
                return ( is_trained_personal ? this.DefaultConfig.PrimaryTrainedCooldown : this.DefaultConfig.PrimaryCooldown );
            case AttackType::Secondary:
            {
                return ( is_trained_personal ? this.DefaultConfig.SecondaryTrainedCooldown : this.DefaultConfig.SecondaryCooldown );
            }
            case AttackType::Tertriary:
            default:
            {
                return ( is_trained_personal ? this.DefaultConfig.TertriaryTrainedCooldown : this.DefaultConfig.TertriaryCooldown );
            }
        }
    }

    // Set weapon cooldown
    void SetCooldown( bool is_trained_personal, AttackType type )
    {
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle =
            g_Engine.time + this.GetCooldown( is_trained_personal, type );
    }

    void TraceEffects( TraceResult &in tr, Bullet bullet = Bullet::BULLET_NONE )
    {
        auto player = this.owner;

        if( bullet != Bullet::BULLET_NONE )
        {
            g_WeaponFuncs.DecalGunshot( tr, bullet );
            g_SoundSystem.PlayHitSound( tr, player.GetGunPosition(), tr.vecEndPos, bullet );

            switch( bullet )
            {
                case Bullet::BULLET_PLAYER_9MM:
                case Bullet::BULLET_PLAYER_MP5:
                case Bullet::BULLET_PLAYER_SAW:
                case Bullet::BULLET_PLAYER_SNIPER:
                case Bullet::BULLET_PLAYER_357:
                case Bullet::BULLET_PLAYER_EAGLE:
                case Bullet::BULLET_PLAYER_BUCKSHOT:
                {
                    player.pev.effects |= EF_MUZZLEFLASH;
                    break;
                }
                case Bullet::BULLET_PLAYER_CROWBAR:
                case Bullet::BULLET_NONE:
                default:
                    break;
            }
        }

        CBaseEntity@ hit = null;
        CBaseMonster@ monster = null;

        if( !freeedicts( 5 )
        || !g_EntityFuncs.IsValidEntity( tr.pHit )
        || ( @hit = g_EntityFuncs.Instance( tr.pHit ) ) is null
        || !hit.IsMonster()
        || ( @monster = cast<CBaseMonster@>(hit) ) is null )
            return;

        if( weapons::gpTraceBlood && monster.m_bloodColor != DONT_BLEED )
        {
            CSprite@ spr = null;

            if( monster.m_bloodColor == BLOOD_COLOR_RED )
            {
                switch( Math.RandomLong( 0, 2 ) )
                {
                    case 0: @spr = g_EntityFuncs.CreateSprite( "sprites/bts_rc/hblood_1.spr", tr.vecEndPos, true ); break;
                    case 1: @spr = g_EntityFuncs.CreateSprite( "sprites/bts_rc/hblood_2.spr", tr.vecEndPos, true ); break;
                    case 2: @spr = g_EntityFuncs.CreateSprite( "sprites/bts_rc/hblood_3.spr", tr.vecEndPos, true ); break;
                }
            }
            else if( monster.m_bloodColor == BLOOD_COLOR_GREEN || monster.m_bloodColor == BLOOD_COLOR_YELLOW )
            {
                switch( Math.RandomLong( 0, 4 ) )
                {
                    case 0: @spr = g_EntityFuncs.CreateSprite( "sprites/bts_rc/ablood_1.spr", tr.vecEndPos, true ); break;
                    case 1: @spr = g_EntityFuncs.CreateSprite( "sprites/bts_rc/ablood_2.spr", tr.vecEndPos, true ); break;
                    case 2: @spr = g_EntityFuncs.CreateSprite( "sprites/bts_rc/ablood_3.spr", tr.vecEndPos, true ); break;
                    case 3: @spr = g_EntityFuncs.CreateSprite( "sprites/bts_rc/ablood_4.spr", tr.vecEndPos, true ); break;
                    case 4: @spr = g_EntityFuncs.CreateSprite( "sprites/bts_rc/ablood_5.spr", tr.vecEndPos, true ); break;
                }
            }

            if( spr !is null )
            {
                spr.AnimateAndDie( 60.0f );
                spr.pev.scale = Math.RandomFloat( 0.05, 0.25 );
            }
        }

        if( weapons::gpTraceSparks )
        {
            bool should_sparks = true;

            int sparks_color = -1;

            string classname = monster.GetClassname();
            string model = string( monster.pev.model );

            if( "monster_robogrunt" == classname )
            {
                sparks_color = 5;
            }
            else if( "monster_sentry" == classname || "monster_turret" == classname || "monster_miniturret" == classname )
            {
                sparks_color = 4;
            }
            else if( tr.iHitgroup == 10 )
            {
                if( "monster_alien_grunt" == classname )
                {
                    sparks_color = 0;
                }
                else if( "models/bts_rc/monsters/zombie_hev.mdl" == model || "models/bts_rc/monsters/gonome_hev.mdl" == model || "models/bts_rc/monsters/zombie_hev2.mdl" == model )
                {
                    sparks_color = 7;
                }
            }

            if( sparks_color != -1 )
            {
                switch( Math.RandomLong( 0, 4 ) )
                {
                    case 0: g_SoundSystem.EmitSoundDyn( hit.edict(), CHAN_AUTO, "weapons/ric1.wav", 1.0, ATTN_NONE, 0, PITCH_NORM ); break;
                    case 1: g_SoundSystem.EmitSoundDyn( hit.edict(), CHAN_AUTO, "weapons/ric2.wav", 1.0, ATTN_NONE, 0, PITCH_NORM ); break;
                    case 2: g_SoundSystem.EmitSoundDyn( hit.edict(), CHAN_AUTO, "weapons/ric3.wav", 1.0, ATTN_NONE, 0, PITCH_NORM ); break;
                    case 3: g_SoundSystem.EmitSoundDyn( hit.edict(), CHAN_AUTO, "weapons/ric4.wav", 1.0, ATTN_NONE, 0, PITCH_NORM ); break;
                    case 4: g_SoundSystem.EmitSoundDyn( hit.edict(), CHAN_AUTO, "weapons/ric5.wav", 1.0, ATTN_NONE, 0, PITCH_NORM ); break;
                }

                NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
                    m.WriteByte( TE_STREAK_SPLASH );
                    m.WriteCoord( tr.vecEndPos.x );
                    m.WriteCoord( tr.vecEndPos.y );
                    m.WriteCoord( tr.vecEndPos.z );
                    m.WriteCoord( 0 );
                    m.WriteCoord( 0 );
                    m.WriteCoord( g_Engine.v_forward.z );
                    m.WriteByte( sparks_color ); // Color pallete: https://github.com/baso88/SC_AngelScript/wiki/images/engine_palette_2.png
                    m.WriteShort( 30 );          // Count
                    m.WriteShort( 128 );         // Base speed
                    m.WriteShort( 100 );         // Random velocity
                m.End();

                NetworkMessage m2( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
                    m2.WriteByte( TE_DLIGHT );
                    m2.WriteCoord( tr.vecEndPos.x );
                    m2.WriteCoord( tr.vecEndPos.y );
                    m2.WriteCoord( tr.vecEndPos.z );
                    m2.WriteByte( 5 );   // radius
                    m2.WriteByte( 150 ); // R
                    m2.WriteByte( 100 ); // G
                    m2.WriteByte( 0 );   // B
                    m2.WriteByte( 1 );   // life in 0.1's
                    m2.WriteByte( 1 );   // decay in 0.1's
                m2.End();

                g_Utility.Sparks( tr.vecEndPos );
                g_Utility.Ricochet( tr.vecEndPos, Math.RandomFloat( 0.5, 1.5 ) );
            }
        }
    }

    uint8 __last_random__ = 0;

    // Get a random number between 0 and max. if RandomUint was called before the result will be stored in __last_random__ to avoid repeating the same number in a row
    uint8 RandomUint( uint8 max )
    {
        if( max == 0 )
        {
            if( g_Logger.critical )
                g_Logger.critical = snprintf( glog, "RandomUint called with an argument of zero!" );
            return 0;
        }

        uint8 rand;

        do{ rand = Math.RandomLong( 0, max ); }
        while( rand == this.__last_random__ );

        this.__last_random__ = rand;

        return rand;
    }

    void PlaySound( const string&in soundName, float volume = 1.0f, int pitch = PITCH_NORM, float attenuation = ATTN_NORM )
    {
        g_SoundSystem.EmitSoundDyn( self.edict(), SOUND_CHANNEL::CHAN_WEAPON, soundName, volume, attenuation, 0, pitch );
    }
}

enum AttackType
{
    Primary = 0,
    Secondary,
    Tertriary
};

class BTS_MeleeWeapon : BTS_Weapon
{
    // Amount of swings in a raw
    int m_iSwing = 0;

    bool m_IsSecondary = false;

    // weapon attack
    void Attack( CBasePlayer@ player, AttackType type )
    {
    }

    // Return whatever this is a solid entity or worldspawn
    bool IsBrush( CBaseEntity@ hit )
    {
        return true;
    }

    // Return whatever this is a flesh body
    bool IsFlesh( CBaseEntity@ hit )
    {
        return ( hit !is null && hit.pev.takedamage > DAMAGE_NO && ( hit.IsMonster() || hit.IsPlayer() ) && hit.Classify() != CLASS_MACHINE );
    }

    float GetCooldown( bool is_trained_personal, bool miss, AttackType type )
    {
        switch( type )
        {
            case AttackType::Primary:
            {
                if( is_trained_personal )
                    return ( miss ? this.DefaultConfig.PrimaryMissTrainedCooldown : this.DefaultConfig.PrimaryCooldown );
                return ( miss ? this.DefaultConfig.PrimaryMissCooldown : this.DefaultConfig.PrimaryCooldown );
            }
            case AttackType::Secondary:
            {
                if( is_trained_personal )
                    return ( miss ? this.DefaultConfig.SecondaryMissTrainedCooldown : this.DefaultConfig.SecondaryTrainedCooldown );
                return ( miss ? this.DefaultConfig.SecondaryMissCooldown : this.DefaultConfig.SecondaryCooldown );
            }
            case AttackType::Tertriary:
            default:
            {
                return GetCooldown( is_trained_personal, type );
            }
        }
    }

    // Set weapon cooldown
    void SetCooldown( bool is_trained_personal, bool miss, AttackType type )
    {
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle =
            g_Engine.time + this.GetCooldown( is_trained_personal, miss, type );
    }

    // Hit ahead. return whatever it was a hit or a miss. automatically damages the target with DefaultConfig data
    bool Hit( TraceResult&out tr, AttackType type, CBaseEntity@&out hit )
    {
        auto player = this.owner;
        Math.MakeVectors( player.pev.v_angle );
        Vector vecSrc = player.GetGunPosition();
        Vector vecDirection = g_Engine.v_forward;

        switch( type )
        {
            case AttackType::Tertriary:
                vecDirection = vecDirection * this.DefaultConfig.TertriaryDistance;
            break;
            case AttackType::Secondary:
                vecDirection = vecDirection * this.DefaultConfig.SecondaryDistance;
            break;
            case AttackType::Primary:
            default:
                vecDirection = vecDirection * this.DefaultConfig.PrimaryDistance;
            break;
        }

        Vector vecEnd = vecSrc + vecDirection;

        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, player.edict(), tr );

        if( tr.flFraction >= 1.0f )
        {
            g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, player.edict(), tr );

            if( tr.flFraction < 1.0f )
            {
                // Calculate the point of intersection of the line (or hull) and the object we hit
                // This is and approximation of the "best" intersection
                if( tr.pHit !is null && ( @hit = g_EntityFuncs.Instance( tr.pHit ) ) is null || hit.IsBSPModel() )
                {
                    g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, player.edict() );
                }

                vecEnd = tr.vecEndPos; // This is the point on the actual surface (the hull could have hit space)
            }
        }

        if( hit !is null || ( tr.pHit !is null && ( @hit = g_EntityFuncs.Instance( tr.pHit ) ) !is null ) )
        {
            // Pull players just like the crowbar does
            if( weapons::gpAllowMeleePull && hit.IsPlayer() )
            {
                hit.pev.velocity = hit.pev.velocity + ( owner.pev.origin - hit.pev.origin ).Normalize() * 120.0f;
            }

            if( weapons::gpAllowMeleePush && ( hit.pev.flags & FL_ONGROUND ) == 0 && "monster_headcrab" == hit.GetClassname() )
            {
                hit.pev.velocity = ( hit.pev.origin - player.pev.origin ).Normalize() * 300.0f;
                hit.pev.velocity.z = 200.0f;
                hit.pev.nextthink = g_Engine.time + 0.2f;
            }

            g_WeaponFuncs.ClearMultiDamage();

            // subsequent swings do % less damage
            float subsequent = ( self.m_flNextPrimaryAttack + 1.0f < g_Engine.time ) ? 1.0 : this.DefaultConfig.SubsequentDeduction;

            switch( type )
            {
                case AttackType::Primary:
                    hit.TraceAttack( player.pev, this.DefaultConfig.PrimaryDamage * subsequent, g_Engine.v_forward, tr, DMG_SLASH | DMG_CLUB );
                break;
                case AttackType::Secondary:
                    hit.TraceAttack( player.pev, this.DefaultConfig.SecondaryDamage * subsequent, g_Engine.v_forward, tr, DMG_SLASH | DMG_CLUB );
                break;
            }

            g_WeaponFuncs.ApplyMultiDamage( player.pev, player.pev );
        }

        return ( tr.flFraction >= 1.0f );
    }

    private void __Attack__( AttackType type )
    {
        Attack( this.owner, type );
    }

    void PrimaryAttack()
    {
        __Attack__( AttackType::Primary );
    }

    void SecondaryAttack()
    {
        __Attack__( AttackType::Secondary );
    }
}

class BTS_FireWeapon : BTS_Weapon
{
    float Accuracy( float tr, float def, float trd, float defd )
    {
        auto player = this.owner;

        if( util::IsTrainedPersonal( player ) )
        {
            if( ( player.pev.button & IN_DUCK ) != 0 )
            {
                return trd;
            }
            return tr;
        }
        else if( ( player.pev.button & IN_DUCK ) != 0 )
        {
            return defd;
        }
        return def;
    }
}
