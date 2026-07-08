/**
*   Copyright (c) 2026 Mikk155 and contributors of bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software to use, copy, modify, merge, publish, distribute, sublicense,
*   and/or sell copies of the Software under the following conditions:
*   
*   A reference to the original project must be included in all copies or substantial
*   portions of the Software. This must include, at minimum, a URL to:
*   https://github.com/Mikk155/bts_rc
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies of the Software when distributed as a whole.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
**/

final class ASWeaponSpannerConfig : ASMeleeWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_spanner";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_spanner.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_spanner.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_spanner.mdl";
    }

    const string& get_animation_extension() override
    {
        return "crowbar";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponSpannerAnim::Draw;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "weapons/cbar_miss1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/cbar_hitbod1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/cbar_hitbod2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/cbar_hitbod3.wav" );
        g_SoundSystem.PrecacheSound( "weapons/cbar_hit1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/cbar_hit2.wav" );
        ASMeleeWeaponConfig::Precache();
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Weapon config",
            "description": "weapon-related gameplay modifiers.",
            "allOf":
            [
                "ASWeaponConfig",
                "ASMeleeWeaponConfig"
            ],
            "properties":
            {
            }
        }""";
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        this.slot = 0;
        this.position = 11;
        this.deploy_time = 0.5;
        this.primary_distance = 32;
        this.primary_cooldown = 0.3;
        this.primary_trained_cooldown = 0.2;
        this.primary_miss_cooldown = 0.4;
        this.primary_miss_trained_cooldown = 0.3;
        this.subsequent_hits_deduction = 0.5;
        this.primary_damage = 9;

        return ASMeleeWeaponConfig::Register( json );
    }
}

ASWeaponSpannerConfig gpWeaponSpannerConfig;

enum WeaponSpannerAnim
{
    Idle = 0,
    Attack1,
    Attack2,
    Use,
    Draw,
    Holster
};

class weapon_bts_spanner : BTS_MeleeWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponSpannerConfig;
    }

    float Idle() override
    {
        PlayAnim( WeaponSpannerAnim::Idle );
        return 2.0f;
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        switch( type )
        {
            case AttackType::Tertiary:
            case AttackType::Secondary:
                return;
        }

        TraceResult tr;
        CBaseEntity@ hit = null;

        bool miss = this.Hit( tr, type, hit, false );

        bool isTrainedPersonal = util::IsTrainedPersonal( player );

        this.SetCooldown( isTrainedPersonal, miss, type );

        if( miss )
        {
            switch( ( m_iSwing++ ) % 2 )
            {
                case 0:
                {
                    PlayAnim( WeaponSpannerAnim::Attack1 );
                    break;
                }
                case 1:
                {
                    PlayAnim( WeaponSpannerAnim::Attack2 );
                    break;
                }
            }

            PlaySound( "weapons/cbar_miss1.wav" );
        }
        else
        {
            switch( ( m_iSwing++ ) % 2 )
            {
                case 0:
                {
                    PlayAnim( WeaponSpannerAnim::Attack1 );
                    break;
                }
                case 1:
                {
                    PlayAnim( WeaponSpannerAnim::Attack2 );
                    break;
                }
            }

            TraceEffects( tr, Bullet::BULLET_PLAYER_CROWBAR );

            if( this.IsFlesh( hit ) )
            {
                if( hit.IsPlayer() )
                {
                    hit.pev.velocity = hit.pev.velocity + ( self.pev.origin - hit.pev.origin ).Normalize() * 120.0f;
                }

                switch( RandomUint( 2 ) )
                {
                    case 0:
                    {
                        PlaySound( "weapons/cbar_hitbod1.wav" );
                        break;
                    }
                    case 1:
                    {
                        PlaySound( "weapons/cbar_hitbod2.wav" );
                        break;
                    }
                    case 2:
                    {
                        PlaySound( "weapons/cbar_hitbod3.wav" );
                        break;
                    }
                }
            }
            else if( this.IsBrush( hit ) )
            {
                switch( RandomUint( 1 ) )
                {
                    case 0:
                    {
                        PlaySound( "weapons/cbar_hit1.wav" );
                        break;
                    }
                    case 1:
                    {
                        PlaySound( "weapons/cbar_hit2.wav" );
                        break;
                    }
                }
            }
        }
    }
}
