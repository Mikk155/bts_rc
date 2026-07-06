mixin class bts_ammo_base
{
    void Spawn( const string &in model )
    {
        g_EntityFuncs.SetModel( self, model );
        BaseClass.Spawn();
    }

    bool AddAmmo( CBaseEntity@ other, const int give, const string &in type, const int max, const string &in sound = "hlclassic/items/9mmclip1.wav" )
    {
        int finalGive = ( gpDynamicAmmo !is null ? gpDynamicAmmo.GetAmmoGive( type, give ) : give );

        if( other !is null && other.GiveAmmo( finalGive, type, max ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, sound, 1.0f, ATTN_NORM );
            return true;
        }
        return false;
    }
};

class ammo_bts_eagle : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/weapons/w_357ammobox.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 3, "357", 18, "hlclassic/weapons/357_reload1.wav" );
    }
}

class ammo_bts_eagle_battery : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/furniture/w_flashlightbattery.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 1, "bts_battery", 10, "bts_rc/items/battery_pickup1.wav" );
    }
}

/*
class ammo_bts_flarebox : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/weapons/w_flaregun_clip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, weapon_bts_flaregun::AMMO_GIVE, "bts_flare", weapon_bts_flaregun::MAX_CARRY, "bts_rc/weapons/flare_pickup.wav" );
    }
}
*/

class ammo_bts_glock : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/hlclassic/w_9mmclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 17, "9mm", 120 );
    }
}

class ammo_bts_glock17f : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/hlclassic/w_9mmclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 17, "9mm", 120 );
    }
}

class ammo_bts_glock17f_battery : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/furniture/w_flashlightbattery.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 1, "bts_battery", 10, "bts_rc/items/battery_pickup1.wav" );
    }
}

class ammo_bts_glocksd_battery : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/furniture/w_flashlightbattery.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 1, "bts_battery", 10, "bts_rc/items/battery_pickup1.wav" );
    }
}

class ammo_bts_glock18 : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/hlclassic/w_9mmclip.mdl" );
        pev.scale = 1.1;
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 19, "9mm", 120 );
    }
}

class ammo_bts_glocksd : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/hlclassic/w_9mmclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 17, "9mm", 120 );
    }
}

class ammo_bts_m4 : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/weapons/w_9mmarclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 30, "556", 150, "hlclassic/weapons/reload2.wav" );
    }
}

class ammo_bts_m4sd : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/weapons/w_556nato.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 30, "556", 150, "hlclassic/weapons/reload2.wav" );
    }
}

class ammo_bts_m16sd : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/weapons/w_556nato.mdl" );
        pev.scale = 0.9;
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 20, "556", 150, "hlclassic/weapons/reload2.wav" );
    }
}

class ammo_bts_m16 : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/weapons/w_9mmarclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 30, "556", 150, "hlclassic/weapons/reload2.wav" );
    }
}

// i stepped on a minefield known as trying to respawn a non-weapon/ammo entity resulting in all hell breaking loose
class ammo_bts_dummy : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/furniture/w_flashlightbattery.mdl" );
        pev.scale = 0.1;
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 1, "uranium", 1, "bts_rc/weapons/m79_close.wav" );
    }
}

class ammo_bts_m16_grenade : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/weapons/w_argrenade_solo.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? 1 : 2, "ARgrenades", 10, "bts_rc/weapons/m79_close.wav" );
    }
}

class ammo_bts_m16sd_grenade : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/weapons/w_argrenade_solo.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? 1 : 2, "ARgrenades", 10, "bts_rc/weapons/m79_close.wav" );
    }
}

class ammo_bts_m79 : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/weapons/w_argrenade_solo.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? 1 : 2, "ARgrenades", 10, "bts_rc/weapons/m79_close.wav" );
    }
}

class ammo_bts_mp5 : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/hlclassic/w_9mmarclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 30, "9mm", 120, "bts_rc/weapons/mp5_clip.wav" );
    }
}

class ammo_bts_mp5gl : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/hlclassic/w_9mmarclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 30, "9mm", 120, "bts_rc/weapons/mp5_clip.wav" );
    }
}

class ammo_bts_mp5gl_grenade : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/weapons/w_argrenade_solo.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? 1 : 2, "ARgrenades", 10, "bts_rc/weapons/m79_close.wav" );
    }
}

class ammo_bts_python : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( ( "ammo_bts_357cyl" == pev.classname ? "models/bts_rc/weapons/w_357ammo.mdl" : "models/hlclassic/w_357ammobox.mdl" ) );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 3, "357", 18, "hlclassic/weapons/357_reload1.wav" );
    }
}

class ammo_bts_saw : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/w_saw_clip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 50, "556", 150, "bts_rc/weapons/saw_reload2.wav" );
    }
} class ammo_bts_sawsd : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/w_saw_clip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 50, "556", 150, "bts_rc/weapons/saw_reload2.wav" );
    }
}
/*
class ammo_bts_fuel : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn("models/w_weaponbox.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo(other, ( "ammo_bts_fuel" == pev.classname ? Math.RandomLong( 20, 80 ) : 40 ), "fuel", 120 );
    }
}
*/

class ammo_bts_sbshotgun : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/hlclassic/w_shotshell.mdl" );
        pev.scale = 0.9;
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 3, "buckshot", 30, "hlclassic/weapons/reload1.wav" );
    }
}

class ammo_bts_sbshotgun_battery : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/furniture/w_flashlightbattery.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 1, "bts_battery", 10, "bts_rc/items/battery_pickup1.wav" );
    }
}

class ammo_bts_shotgun : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( ( "ammo_bts_shotshell" == pev.classname ? "models/w_shotshell.mdl" : "models/hlclassic/w_shotshell.mdl" ) );
    }
    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 3, "buckshot", 30, "hlclassic/weapons/reload1.wav" );
    }
}

class ammo_bts_uzi : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/weapons/w_uzi_clip.mdl" );
    }

    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 20, "9mm", 120, "hlclassic/weapons/reload2.wav" );
    }
}

class ammo_bts_uzisd : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/weapons/w_uzi_clip.mdl" );
    }

    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, 20, "9mm", 120, "hlclassic/weapons/reload2.wav" );
    }
}

/*
class ammo_bts_sw637 : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn()
    {
        Spawn( "models/bts_rc/weapons/w_sw637_ammobox.mdl" );
    }

    bool AddAmmo( CBaseEntity@ other )
    {
        return AddAmmo( other, weapon_bts_sw637::AMMO_GIVE, "38", weapon_bts_sw637::MAX_CARRY, "bts_rc/weapons/sw_cylinder_close.wav" );
    }
}
*/
