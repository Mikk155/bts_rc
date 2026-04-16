#include "BTS_Weapon"

#include "BTS_MeleeWeapon"
#include "BTS_MeleeCharge"

#include "BTS_FireWeapon"

#include "Melee/weapon_bts_axe"
#include "Melee/weapon_bts_knife"
#include "Melee/weapon_bts_pipe"
#include "Melee/weapon_bts_poolstick"
#include "Melee/weapon_bts_screwdriver"

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
    float deploy_time;
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
        if( !json.get( "deploy_time", deploy_time ) )
            deploy_time = 1.0f;

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
