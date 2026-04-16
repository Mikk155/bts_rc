/*
*   Author: AraseFiq
*   Rewrited by Rizulix for bts_rc (january 2025)
*   Rewrited by mikk 14/4/26
*/

enum WeaponPoolstickAnim
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
    Idle2
};

class CWeaponPoolstickConfig : IConfigContext
{
    CBaseWeaponConfig@ data;

    CWeaponPoolstickConfig()
    {
        ConfigContext::Register( this );
    }

    string GetName()
    {
        return "weapon_poolstick";
    }

    void Parse( dictionary@ json )
    {
        @data = CBaseWeaponConfig( json );

        data.world_model = "models/bts_rc/weapons/w_poolstick.mdl";
        data.player_model = "models/bts_rc/weapons/p_poolstick.mdl";
        data.view_model = "models/bts_rc/weapons/v_poolstick.mdl";
        data.animation_extension = "crowbar";
        data.animation_draw = WeaponPoolstickAnim::Draw;

        weapons::Register( "weapon_bts_poolstick", @data );

        g_SoundSystem.PrecacheSound( "weapons/cbar_miss1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/cbar_hitbod1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/cbar_hitbod2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/cbar_hitbod3.wav" );
        g_SoundSystem.PrecacheSound( "debris/wood1.wav" );
        g_SoundSystem.PrecacheSound( "debris/wood2.wav" );
    }
}

CWeaponPoolstickConfig gpWeaponPoolstickConfig;

class weapon_bts_poolstick : BTS_MeleeWeapon
{
    CBaseWeaponConfig@ get_DefaultConfig() override {
        return @gpWeaponPoolstickConfig.data;
    }

    float Idle() override
    {
        auto player = this.owner;

        float flRand = g_PlayerFuncs.SharedRandomFloat( player.random_seed, 0, 1 );

        if( flRand <= 0.99 )
        {
            PlayAnim( WeaponPoolstickAnim::Idle1, false );
            return g_PlayerFuncs.SharedRandomFloat( player.random_seed, 10, 15 );
        }

        PlayAnim( WeaponPoolstickAnim::Idle2, false );
        return 5.0f;
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
            case AttackType::Secondary:
            {
                PlayAnim( ( miss ? WeaponPoolstickAnim::Attack3Miss : WeaponPoolstickAnim::Attack3Hit ) );
                break;
            }
            case AttackType::Primary:
            {
                if( miss )
                {
                    PlayAnim( WeaponPoolstickAnim::Attack2Miss );
                }
                else
                {
                    switch( RandomUint(1) )
                    {
                        case 0: PlayAnim( WeaponPoolstickAnim::Attack1Hit ); break;
                        case 1: PlayAnim( WeaponPoolstickAnim::Attack2Hit ); break;
                    }
                }
                break;
            }
        }

        if( miss )
        {
            this.PlaySound( "weapons/cbar_miss1.wav" );
        }
        else
        {
            TraceEffects( tr, Bullet::BULLET_PLAYER_CROWBAR );

            if( this.IsFlesh(hit) )
            {
                switch( RandomUint(2) )
                {
                    case 0: PlaySound( "bts_rc/weapons/cbar_hitbod3.wav" ); break;
                    case 1: PlaySound( "bts_rc/weapons/cbar_hitbod2.wav" ); break;
                    case 2: PlaySound( "bts_rc/weapons/cbar_hitbod1.wav" ); break;
                }
            }
            else if( this.IsBrush(hit) )
            {
                switch( RandomUint(1) )
                {
                    case 0: PlaySound( "debris/wood2.wav" ); break;
                    case 1: PlaySound( "debris/wood1.wav" ); break;
                }
            }
        }
    }
}
