/*
*   Author: AraseFiq
*   Rewrited by Rizulix for bts_rc (january 2025)
*   Rewrited by mikk 14/4/26
*/

enum WeaponScrewDriverAnim
{
    Idle1 = 0,
    Draw,
    Holster,
    Attack1Hit,
    Attack1Miss,
    Attack2Miss,
    Attack2Hit,
    Attack3Miss,
    Attack3Hit,
    Idle2,
    Idle3
};

class CWeaponScrewDriverConfig : ASMeleeWeaponConfig
{
    string GetName() override
    {
        return "weapon_bts_screwdriver";
    }

    const string& get_player_model() override {
        return "models/bts_rc/weapons/p_screwdriver.mdl";
    }

    const string& get_world_model() override {
        return "models/bts_rc/weapons/w_screwdriver.mdl";
    }

    const string& get_view_model() override {
        return "models/bts_rc/weapons/v_screwdriver.mdl";
    }

    const string& get_animation_extension() override {
        return "crowbar";
    }

    uint8 get_animation_draw() override {
        return WeaponScrewDriverAnim::Draw;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/sd_miss1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/sd_hitbod1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/sd_hitbod2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/sd_hitbod3.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/sd_hit1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/sd_hit2.wav" );
    }
}

CWeaponScrewDriverConfig gpWeaponScrewDriverConfig;

class weapon_bts_screwdriver : BTS_MeleeWeapon
{
    ASWeaponConfig@ get_config() {
        return @gpWeaponScrewDriverConfig;
    }

    void Attack( CBasePlayer@ player, AttackType type )
    {
        switch( type )
        {
            case AttackType::Tertriary:
            case AttackType::Secondary:
                return;
            case AttackType::Primary:
            default:
                break;
        }

        TraceResult tr;
        CBaseEntity@ hit = null;

        bool miss = this.Hit(tr, type, hit);

        bool is_trained_personal = util::IsTrainedPersonal( player );

        this.SetCooldown( is_trained_personal, miss, type );

        switch( RandomUint(2) )
        {
            case 0: PlayAnim( ( miss ? WeaponScrewDriverAnim::Attack1Miss : WeaponScrewDriverAnim::Attack1Hit ) ); break;
            case 1: PlayAnim( ( miss ? WeaponScrewDriverAnim::Attack2Miss : WeaponScrewDriverAnim::Attack2Hit ) ); break;
            case 2: PlayAnim( ( miss ? WeaponScrewDriverAnim::Attack3Miss : WeaponScrewDriverAnim::Attack3Hit ) ); break;
        }

        if( miss )
        {
            this.PlaySound( "bts_rc/weapons/sd_miss1.wav" );
        }
        else
        {
            TraceEffects( tr, Bullet::BULLET_PLAYER_CROWBAR );

            if( this.IsFlesh(hit) )
            {
                switch( RandomUint(2) )
                {
                    case 0: PlaySound( "bts_rc/weapons/sd_hitbod3.wav" ); break;
                    case 1: PlaySound( "bts_rc/weapons/sd_hitbod2.wav" ); break;
                    case 2: PlaySound( "bts_rc/weapons/sd_hitbod1.wav" ); break;
                }
            }
            else if( this.IsBrush(hit) )
            {
                switch( RandomUint(1) )
                {
                    case 0: PlaySound( "bts_rc/weapons/sd_hit2.wav" ); break;
                    case 1: PlaySound( "bts_rc/weapons/sd_hit1.wav" ); break;
                }
            }
        }
    }
}
