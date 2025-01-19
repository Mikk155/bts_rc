mixin class bts_ammo_base
{
    void Spawn( const string &in model )
    {
        g_EntityFuncs.SetModel( self, model );
        BaseClass.Spawn();
    }

    bool AddAmmo( CBaseEntity@ other, const int give, const string&in type, const int max, const string &in sound = "hlclassic/items/9mmclip1.wav" )
    {
        if( other !is null && other.GiveAmmo( give, type, max ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, sound, 1.0f, ATTN_NORM );
            return true;
        }
        return false;
    }
};

class ammo_bts_beretta : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_9mmclip.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, HL_BERETTA::AMMO_GIVE, "9mm", HL_BERETTA::MAX_CARRY);
    }
}

class ammo_bts_beretta_battery : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/furniture/w_flashlightbattery.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, HL_BERETTA::AMMO_GIVE2, "bts:battery", HL_BERETTA::MAX_CARRY2, "bts_rc/items/battery_pickup1.wav");
    }
}

class ammo_bts_eagle : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_9mmclip.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_dreagle" == pev.classname ? Math.RandomLong( 1, 4 ) : BTS_DEAGLE::AMMO_GIVE ), "357", BTS_DEAGLE::MAX_CARRY);
    }
}

class ammo_bts_eagle_battery : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/furniture/w_flashlightbattery.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, BTS_DEAGLE::AMMO_GIVE2, "bts:battery", BTS_DEAGLE::MAX_CARRY2, "bts_rc/items/battery_pickup1.wav");
    }
}

class ammo_bts_flarebox : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/weapons/w_flaregun_clip.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, BTS_FLAREGUN::AMMO_GIVE, "bts:flare", BTS_FLAREGUN::MAX_CARRY, "bts_rc/weapons/flare_pickup.wav");
    }
}

class ammo_bts_battery : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/furniture/w_flashlightbattery.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? BTS_FLASHLIGHT::AMMO_DROP : BTS_FLASHLIGHT::AMMO_GIVE, "bts:battery", BTS_FLASHLIGHT::MAX_CARRY, "bts_rc/items/battery_pickup1.wav");
    }
}

class ammo_bts_glock : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_9mmclip.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, HL_GLOCK::AMMO_GIVE, "9mm", HL_GLOCK::MAX_CARRY);
    }
}

class ammo_bts_glock17f : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_9mmclip.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, BTS_GLOCK17F::AMMO_GIVE, "9mm", BTS_GLOCK17F::MAX_CARRY);
    }
}

class ammo_bts_glock17f_battery : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/furniture/w_flashlightbattery.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, BTS_GLOCK17F::AMMO_GIVE2, "bts:battery", BTS_GLOCK17F::MAX_CARRY2, "bts_rc/items/battery_pickup1.wav");
    }
}

class ammo_bts_glock18 : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_9mmclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, BTS_GLOCK18::AMMO_GIVE, "9mm", BTS_GLOCK18::MAX_CARRY );
     }
}

class ammo_bts_glocksd : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_9mmclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_dglocksd" == pev.classname ? Math.RandomLong( 8, 13 ) : HL_GLOCKSD::AMMO_GIVE ), "9mm", HL_GLOCKSD::MAX_CARRY );
    }
}

class ammo_bts_m4 : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/weapons/w_9mmarclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_556mag" == pev.classname ? Math.RandomLong( 6, 12 ) : BTS_M4::AMMO_GIVE ), "556", BTS_M4::MAX_CARRY );
    }
}

class ammo_bts_m4sd : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/weapons/w_556nato.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, BTS_M4SD::AMMO_GIVE, "556", BTS_M4SD::MAX_CARRY );
    }
}

class ammo_bts_m16 : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/weapons/w_9mmarclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_556round" == pev.classname ? Math.RandomLong( 9, 23 ) : BTS_M16A3::AMMO_GIVE ), "556", BTS_M16A3::MAX_CARRY );
    }
}

class ammo_bts_m16_grenade : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_argrenade.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? BTS_M16A3::AMMO_DROP2 : BTS_M16A3::AMMO_GIVE2, "ARgrenades", BTS_M16A3::MAX_CARRY2 );
    }
}

class ammo_bts_m79 : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/w_argrenade.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? HL_M79::AMMO_DROP : HL_M79::AMMO_GIVE, "ARgrenades", HL_M79::MAX_CARRY );
    }
}

class ammo_bts_mp5 : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_9mmarclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_dmp5" == pev.classname ? Math.RandomLong( 9, 21 ) : HL_MP5::AMMO_GIVE ), "9mm", HL_MP5::MAX_CARRY );
    }
}

class ammo_bts_mp5gl : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_9mmarclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_9mmbox" == pev.classname ? Math.RandomLong( 17, 20 ) : HL_MP5GL::AMMO_GIVE ), "9mm", HL_MP5GL::MAX_CARRY );
    }
}

class ammo_bts_mp5gl_grenade : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_argrenade.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? HL_MP5GL::AMMO_DROP2 : HL_MP5GL::AMMO_GIVE2, "ARgrenades", HL_MP5GL::MAX_CARRY2 );
    }
}

class ammo_bts_python : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn(( "ammo_bts_357cyl" == pev.classname ? "models/hlclassic/w_357ammo.mdl" : "models/hlclassic/w_357ammobox.mdl" ) );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_357cyl" == pev.classname ? Math.RandomLong( 2, 4 ) : CPython::AMMO_GIVE ), "357", CPython::MAX_CARRY );
    }
}

class ammo_bts_saw : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/w_saw_clip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_dsaw" == pev.classname ? Math.RandomLong( 25, 30 ) : CM249::AMMO_GIVE ), "556", CM249::MAX_CARRY );
    }
}

class ammo_bts_sbshotgun : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_shotbox.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, HL_SBSHOTGUN::AMMO_GIVE, "buckshot", HL_SBSHOTGUN::MAX_CARRY );
    }
}

class ammo_bts_sbshotgun_battery : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/furniture/w_flashlightbattery.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, HL_SBSHOTGUN::AMMO_GIVE2, "bts:battery", HL_SBSHOTGUN::MAX_CARRY2, "bts_rc/items/battery_pickup1.wav" );
    }
}

class ammo_bts_shotgun : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn(( "ammo_bts_shotshell" == pev.classname ? "models/w_shotshell.mdl" : "models/hlclassic/w_shotbox.mdl" ) );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_shotshell" == pev.classname ? 3 : HL_SHOTGUN::AMMO_GIVE ), "buckshot", HL_SHOTGUN::MAX_CARRY );
    }
}

class ammo_bts_uzi : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/weapons/w_uzi_clip.mdl" );
    }

    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, BTS_UZI::AMMO_GIVE, "9mm", BTS_UZI::MAX_CARRY );
    }
}
