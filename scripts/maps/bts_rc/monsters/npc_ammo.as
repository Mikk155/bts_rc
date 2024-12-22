// NPC drop ammo
// Author: KernCore, Mikk

// Ammo type drop (random)
const array<string> ZHECUAmmoDrop =
{
    HL_MP5::GetHLMP5DAmmoName(),
    HL_SHOTGUN::GetHLShotgunDAmmoName(),
    BTS_M16A3::GetAmmoDropName(),
    CPython::GetAmmoDropName(),
    BTS_DEAGLE::GetBTSDeagleDAmmoName(),
    HL_GLOCKSD::GetHLGlockSDDAmmoName(),
    HL_SHOTGUN::GetHLShotgunAmmoName(),
    "item_null",
    "item_null2",
    "item_null3",
    "item_null4",
    "item_null5",
    BTS_M4::GetAmmoDropName(),
    BTS_HEVBATTERY::GetName()
    //HL_SBSHOTGUN::GetSBShotgunAmmoName(),
    //BTS_HANDGRENADE::GetName(),
    //"ammo_9mmclip",
    //"ammo_357",
    //"ammo_buckshot",
    //"ammo_crossbow"
};

const array<string> ZBarnAmmoDrop =
{
    HL_GLOCKSD::GetHLGlockSDDAmmoName(),
    BTS_DEAGLE::GetBTSDeagleDAmmoName(),
    HL_SHOTGUN::GetHLShotgunDAmmoName(),
    HL_BERETTA::GetHLBerettaAmmoName(),
    "item_null",
    "item_null2",
    "item_null3"
};

const array<string> ZNormalAmmoDrop =
{
    BTS_FLASHLIGHT::GetFlashlightAmmoName(),
    BTS_FLARE::GetFlareName(),
    HL_GLOCKSD::GetHLGlockSDDAmmoName(),
    BTS_SPRAYAID::GetItemName(),
    "item_null",
    "item_null2",
    "item_null3"
};

const array<string> SentryAmmoDrop =
{
    HL_MP5GL::GetAmmoDropName(),
    "item_null"
};

dictionary gNPCType = 
{
    { "monster_zombie_soldier", ZHECUAmmoDrop },
    { "monster_zombie_barney", ZBarnAmmoDrop },
    { "monster_zombie", ZNormalAmmoDrop },
    { "monster_sentry", SentryAmmoDrop }
};

namespace NPC_DROPAMMO
{
    // Mikk and KernCore's codes
    HookReturnCode BTSRC_MonsterKilled( CBaseMonster@ pMonster, CBaseEntity@ pAttacker, int iGib )
    {
        if( gNPCType.exists( pMonster.GetClassname() ) )
        {
            array<string> asAmmo = array<string>( gNPCType[ pMonster.GetClassname() ] );
            CBaseEntity@ ammo = null;
            string RANDOM_AMMO_DROP = asAmmo[ Math.RandomLong( 0, asAmmo.length() - 1 ) ];

            Vector vecAmmoDrop = pMonster.pev.origin + g_Engine.v_forward * 6 + g_Engine.v_right * 3 + g_Engine.v_up * 48;

            if( pMonster.GetClassname() == "monster_zombie_soldier" && Math.RandomFloat( 0.0, 1.0 ) <= 0.10 ) // Zombie soldier will drop active grenade (10% chance) - Mikk
            {
                CGrenade@ pGrenade = g_EntityFuncs.ShootTimed( pMonster.pev, vecAmmoDrop, Vector(0,0,-90), 3.0); // Active grenade logic - Mikk

                if( ( @ammo = g_EntityFuncs.Create( RANDOM_AMMO_DROP, vecAmmoDrop, pMonster.pev.angles, false ) ) !is null )
                    ammo.pev.spawnflags |= 1024; // no more respawn
            }
            else if( gNPCType.exists( pMonster.GetClassname() ) )
            {
                if( ( @ammo = g_EntityFuncs.Create( RANDOM_AMMO_DROP, vecAmmoDrop, pMonster.pev.angles, false ) ) !is null )
                    ammo.pev.spawnflags |= 1024; // no more respawn
            }
        }
        return HOOK_CONTINUE;
    }
}