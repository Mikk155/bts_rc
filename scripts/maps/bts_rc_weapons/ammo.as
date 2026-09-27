mixin class bts_ammo_base
{
#if EDITOR_ONLY
    BaseEntity@ BaseClass = null;
    CBasePlayerAmmo@ self = null;
#endif

    void Spawn( const string &in model )
    {
        g_EntityFuncs.SetModel( self, model );
        BaseClass.Spawn();
    }

    bool AddAmmo( CBaseEntity@ other, const int give, const string &in type, const int max, const string &in sound = "hlclassic/items/9mmclip1.wav" )
    {
        int finalGive = ( gpDynamicAmmo !is null ? gpDynamicAmmo.GetAmmoGive( pev.classname, give ) : give );

        if( other !is null && other.GiveAmmo( finalGive, type, max ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, sound, 1.0f, ATTN_NORM );
            return true;
        }
        return false;
    }
};

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
