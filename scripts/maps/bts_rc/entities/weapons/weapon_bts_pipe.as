/*
*   Author: AraseFiq
*   Rewrited by Rizulix for bts_rc (january 2025)
*   Rewrited by mikk 14/4/26
*/

enum WeaponPipeAnim
{
    Idle1 = 0,
    idle2,
    idle3,
    Draw,
    Holster,
    Attack1Hit,
    Attack1Miss,
    Attack2Hit,
    Attack2Miss,
    Attack3Hit,
    Attack3Miss,
    AttackBigWind,
    AttackBigHit,
    AttackBigMiss,
    AttackBigLoop
};

class CWeaponPipeConfig : IConfigContext
{
    CBaseWeaponConfig@ data;

    CWeaponPipeConfig()
    {
        ConfigContext::Register( this );
    }

    string GetName()
    {
        return "weapon_pipe";
    }

    void Parse( dictionary@ json )
    {
        @data = CBaseWeaponConfig( json );

        data.world_model = "models/bts_rc/weapons/w_pipe.mdl";
        data.player_model = "models/bts_rc/weapons/p_pipe.mdl";
        data.view_model = "models/bts_rc/weapons/v_pipe.mdl";
        data.animation_extension = "crowbar";
        data.animation_draw = WeaponPipeAnim::Draw;

        weapons::Register( "weapon_bts_pipe", @data );

        g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_miss1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_hitbod1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_hitbod2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_hitbod3.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_hit1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_hit2.wav" );
    }
}

CWeaponPipeConfig gpWeaponPipeConfig;

class weapon_bts_pipe : BTS_MeleeCharge
{
    CBaseWeaponConfig@ get_DefaultConfig() override {
        return @gpWeaponPipeConfig.data;
    }

    void Attack( CBasePlayer@ player, AttackType type )
    {
        bool miss;
        TraceResult tr;
        CBaseEntity@ hit;

        bool is_trained_personal = util::IsTrainedPersonal( player );

        switch( type )
        {
            case AttackType::Primary:
            {
                miss = this.Hit( tr, AttackType::Secondary, hit );

                if( miss )
                {
                    switch( RandomUint(2) )
                    {
                        case 0: this.PlayAnim( WeaponPipeAnim::Attack1Miss ); break;
                        case 1: this.PlayAnim( WeaponPipeAnim::Attack2Miss ); break;
                        case 2: this.PlayAnim( WeaponPipeAnim::Attack3Miss ); break;
                    }
                }
                else
                {
                    switch( RandomUint(2) )
                    {
                        case 0: this.PlayAnim( WeaponPipeAnim::Attack1Hit ); break;
                        case 1: this.PlayAnim( WeaponPipeAnim::Attack2Hit ); break;
                        case 2: this.PlayAnim( WeaponPipeAnim::Attack3Hit ); break;
                    }
                }
                break;
            }
            case AttackType::Secondary:
            {
                // We just started charging
                if( m_WhackState == WhackState::Holding )
                {
                    this.PlayAnim( WeaponPipeAnim::AttackBigWind );
                    return;
                }
                miss = this.Hit( tr, AttackType::Secondary, hit );
                this.PlayAnim( ( miss ? WeaponPipeAnim::AttackBigMiss : WeaponPipeAnim::AttackBigHit ) );
                break;
            }
            case AttackType::Tertriary:
            {
                return;
            }
        }

        this.SetCooldown( is_trained_personal, miss, type );

        if( miss )
        {
            this.PlaySound( "bts_rc/weapons/pipe_miss1.wav" );
        }
        else
        {
            TraceEffects( tr, Bullet::BULLET_PLAYER_CROWBAR );

            if( this.IsFlesh(hit) )
            {
                switch( RandomUint(2) )
                {
                    case 0: this.PlaySound( "bts_rc/weapons/pipe_hitbod1.wav" ); break;
                    case 1: this.PlaySound( "bts_rc/weapons/pipe_hitbod2.wav" ); break;
                    case 2: this.PlaySound( "bts_rc/weapons/pipe_hitbod3.wav" ); break;
                }
            }
            else if( this.IsBrush(hit) )
            {
                switch( RandomUint(1) )
                {
                    case 0: this.PlaySound( "bts_rc/weapons/pipe_hit1.wav" ); break;
                    case 1: this.PlaySound( "bts_rc/weapons/pipe_hit2.wav" ); break;
                }
            }
        }
    }

    float Idle()
    {
        switch( RandomUint(2) )
        {
            case 0: this.PlayAnim( WeaponPipeAnim::Idle1, false ); return 2.69f;
            case 1: this.PlayAnim( WeaponPipeAnim::idle2, false ); return 5.33f;
            case 2: default: break;
        }

        this.PlayAnim( WeaponPipeAnim::idle3, false );
        return 5.33f;
    }
}
