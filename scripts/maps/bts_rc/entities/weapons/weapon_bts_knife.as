/*
*   Credits: SamVanheer and the collaborators of
*   https://github.com/twhl-community/halflife-unified-sdk
*   https://github.com/twhl-community/halflife-op4-updated
*   Credit to KernCore for secondary attack functions
*   Rewrited by Rizulix for bts_rc (january 2025)
*   Rewrited by mikk 16/4/26
*/

enum WeaponKnifeAnim
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
    Charge,
    Stab
};

class CWeaponKnifeConfig : IConfigContext
{
    CBaseWeaponConfig@ data;

    CWeaponKnifeConfig()
    {
        ConfigContext::Register( this );
    }

    string GetName()
    {
        return "weapon_knife";
    }

    void Parse( dictionary@ json )
    {
        @data = CBaseWeaponConfig( json );

        data.world_model = "models/opfor/w_knife.mdl";
        data.player_model = "models/opfor/p_knife.mdl";
        data.view_model = "models/bts_rc/weapons/v_knife.mdl";
        data.animation_extension = "crowbar";
        data.animation_draw = WeaponKnifeAnim::Draw;
        data.hands_group = 0;

        weapons::Register( "weapon_bts_knife", @data );

        g_SoundSystem.PrecacheSound( "weapons/knife1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/knife2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/knife3.wav" );
        g_SoundSystem.PrecacheSound( "weapons/knife_hit_wall1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/knife_hit_wall2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/knife_hit_flesh1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/knife_hit_flesh2.wav" );
    }
}

CWeaponKnifeConfig gpWeaponKnifeConfig;

class weapon_bts_knife : BTS_MeleeCharge
{
    CBaseWeaponConfig@ get_DefaultConfig() override {
        return @gpWeaponKnifeConfig.data;
    }

    float Idle()
    {
        switch( RandomUint(2) )
        {
            case 0: this.PlayAnim( WeaponKnifeAnim::Idle1, false ); return 2.69f;
            case 1: this.PlayAnim( WeaponKnifeAnim::Idle2, false ); return 5.33f;
        }

        this.PlayAnim( WeaponKnifeAnim::Idle3, false );
        return 5.33f;
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
                        case 0: this.PlayAnim( WeaponKnifeAnim::Attack1Miss ); break;
                        case 1: this.PlayAnim( WeaponKnifeAnim::Attack2Miss ); break;
                        case 2: this.PlayAnim( WeaponKnifeAnim::Attack3Miss ); break;
                    }
                }
                else
                {
                    switch( RandomUint(2) )
                    {
                        case 0: this.PlayAnim( WeaponKnifeAnim::Attack1Hit ); break;
                        case 1: this.PlayAnim( WeaponKnifeAnim::Attack2Hit ); break;
                        case 2: this.PlayAnim( WeaponKnifeAnim::Attack3Hit ); break;
                    }
                }
                break;
            }
            case AttackType::Secondary:
            {
                // We just started charging
                if( m_WhackState == WhackState::Holding )
                {
                    this.PlayAnim( WeaponKnifeAnim::Charge );
                    return;
                }
                miss = this.Hit( tr, AttackType::Secondary, hit );
                this.PlayAnim( WeaponKnifeAnim::Stab );
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
            switch( RandomUint(2) )
            {
                case 0: this.PlaySound( "weapons/knife1.wav" ); break;
                case 1: this.PlaySound( "weapons/knife2.wav" ); break;
                case 2: this.PlaySound( "weapons/knife3.wav" ); break;
            }
        }
        else
        {
            TraceEffects( tr, Bullet::BULLET_PLAYER_CROWBAR );

            if( this.IsFlesh(hit) )
            {
                switch( RandomUint(1) )
                {
                    case 0: this.PlaySound( "weapons/knife_hit_flesh1.wav" ); break;
                    case 1: this.PlaySound( "weapons/knife_hit_flesh2.wav" ); break;
                }
            }
            else if( this.IsBrush(hit) )
            {
                switch( RandomUint(1) )
                {
                    case 0: this.PlaySound( "weapons/knife_hit_wall1.wav" ); break;
                    case 1: this.PlaySound( "weapons/knife_hit_wall2.wav" ); break;
                }
            }
        }
    }
}
