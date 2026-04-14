/*
*   Author: AraseFiq
*   Rewrited by Rizulix for bts_rc (january 2025)
*   Rewrited by mikk 27/3/26
*/

enum WeaponAxeAnim
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
    Idle3,
    Shove,
    ShoveAlt,
    ShoveMiss,
    ShoveMissAlt
};

class CWeaponAxeConfig : IConfigContext
{
    CBaseWeaponConfig@ data;

    CWeaponAxeConfig()
    {
        ConfigContext::Register( this );
    }

    string GetName()
    {
        return "weapon_axe";
    }

    void Parse( dictionary@ json )
    {
        @data = CBaseWeaponConfig( json );

        data.world_model = "models/bts_rc/weapons/w_axe.mdl";
        data.player_model = "models/bts_rc/weapons/p_axe.mdl";
        data.view_model = "models/bts_rc/weapons/v_axe.mdl";
        data.animation_extension = "crowbar";
        data.animation_draw = WeaponAxeAnim::Draw;

        weapons::Register( "weapon_bts_axe", @data );

        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hit1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hit2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hitbod1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hitbod2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hitbod3.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_miss1.wav" );
    }
}

CWeaponAxeConfig gpWeaponAxeConfig;

class weapon_bts_axe : BTS_MeleeWeapon
{
    CBaseWeaponConfig@ get_DefaultConfig() override {
        return @gpWeaponAxeConfig.data;
    }

    void WeaponIdle()
    {
        if( g_Engine.time > self.m_flTimeWeaponIdle )
        {
            switch( RandomUint(2) )
            {
                case 0: self.SendWeaponAnim( WeaponAxeAnim::Idle1, 0, pev.body ); break;
                case 1: self.SendWeaponAnim( WeaponAxeAnim::Idle2, 0, pev.body ); break;
                case 2: self.SendWeaponAnim( WeaponAxeAnim::Idle3, 0, pev.body ); break;
            }

            self.m_flTimeWeaponIdle = g_Engine.time + 5.5f;
        }
    }

    void Attack( CBasePlayer@ player, AttackType type )
    {
        if( type == AttackType::Tertriary )
            return;

        TraceResult tr;
        CBaseEntity@ hit = null;

        bool miss = this.Hit(tr, type, hit);

        bool is_trained_personal = util::IsTrainedPersonal( player );

        this.SetCooldown( is_trained_personal, miss, type );

        switch( type )
        {
            case AttackType::Primary:
            {
                switch( RandomUint(2) )
                {
                    case 0: self.SendWeaponAnim( ( miss ? WeaponAxeAnim::Attack1Miss : WeaponAxeAnim::Attack1Hit ), 0, pev.body ); break;
                    case 1: self.SendWeaponAnim( ( miss ? WeaponAxeAnim::Attack2Miss : WeaponAxeAnim::Attack2Hit ), 0, pev.body ); break;
                    case 2: self.SendWeaponAnim( ( miss ? WeaponAxeAnim::Attack3Miss : WeaponAxeAnim::Attack3Hit ), 0, pev.body ); break;
                }
                break;
            }
            case AttackType::Secondary:
            {
                switch( RandomUint(2) )
                {
                    case 0: self.SendWeaponAnim( ( miss ? WeaponAxeAnim::ShoveMiss : WeaponAxeAnim::Shove ), 0, pev.body ); break;
                    case 1: self.SendWeaponAnim( ( miss ? WeaponAxeAnim::ShoveMissAlt : WeaponAxeAnim::ShoveAlt ), 0, pev.body ); break;
                    case 2: self.SendWeaponAnim( ( miss ? WeaponAxeAnim::ShoveMiss : WeaponAxeAnim::Shove ), 0, pev.body ); break;
                }
                break;
            }
        }

        if( miss )
        {
            PlaySound( "bts_rc/weapons/axe_miss1.wav" );
        }
        else
        {
            TraceEffects( tr, Bullet::BULLET_PLAYER_CROWBAR );

            if( this.IsFlesh(hit) )
            {
                switch( RandomUint(2) )
                {
                    case 0: PlaySound( "bts_rc/weapons/axe_hitbod3.wav" ); break;
                    case 1: PlaySound( "bts_rc/weapons/axe_hitbod2.wav" ); break;
                    case 2: PlaySound( "bts_rc/weapons/axe_hitbod1.wav" ); break;
                }
            }
            else if( this.IsBrush(hit) )
            {
                switch( RandomUint(1) )
                {
                    case 0: PlaySound( "bts_rc/weapons/axe_hit2.wav" ); break;
                    case 1: PlaySound( "bts_rc/weapons/axe_hit1.wav" ); break;
                }
            }
        }

        // player "shoot" animation
        player.SetAnimation( PLAYER_ATTACK1 );

        // Slower player anim so it looks "heavier" for not trained personal
        if( !is_trained_personal )
            player.pev.framerate = 0.6f;
    }
}
