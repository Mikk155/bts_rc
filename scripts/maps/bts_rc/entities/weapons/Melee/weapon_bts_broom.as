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

final class ASWeaponBroomConfig : ASMeleeWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_broom";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_broom.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_broom.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_broom.mdl";
    }

    const string& get_animation_extension() override
    {
        return "crowbar";
    }

    const uint8 get_animation_draw() override
    {
        return WeaponBroomAnim::Draw;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "weapons/cbar_miss1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/cbar_hitbod1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/cbar_hitbod2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/cbar_hitbod3.wav" );
        g_SoundSystem.PrecacheSound( "debris/wood1.wav" );
        g_SoundSystem.PrecacheSound( "debris/wood2.wav" );
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
        this.position = 12;
        this.deploy_time = 0.6;
        this.primary_distance = 56;
        this.primary_cooldown = 0.42;
        this.primary_trained_cooldown = 0.26;
        this.primary_miss_cooldown = 0.67;
        this.primary_miss_trained_cooldown = 0.52;
        this.subsequent_hits_deduction = 0.5;
        this.primary_damage = 12;

        return ASMeleeWeaponConfig::Register( json );
    }
}

ASWeaponBroomConfig gpWeaponBroomConfig;

enum WeaponBroomAnim
{
    Idle = 0,
    Draw,
    Holster,
    Attack1Hit,
    Attack1Miss,
    Attack2Miss,
    Attack2Hit,
    Attack3Miss,
    Attack3Hit
};

class weapon_bts_broom : BTS_MeleeWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponBroomConfig;
    }

    float Idle() override
    {
        PlayAnim( WeaponBroomAnim::Idle );
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
            switch( ( m_iSwing++ ) % 3 )
            {
                case 0:
                {
                    PlayAnim( WeaponBroomAnim::Attack1Miss );
                    break;
                }
                case 1:
                {
                    PlayAnim( WeaponBroomAnim::Attack2Miss );
                    break;
                }
                case 2:
                {
                    PlayAnim( WeaponBroomAnim::Attack3Miss );
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
                    PlayAnim( WeaponBroomAnim::Attack1Hit );
                    break;
                }
                case 1:
                {
                    PlayAnim( WeaponBroomAnim::Attack2Hit );
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
                        PlaySound( "debris/wood1.wav" );
                        break;
                    }
                    case 1:
                    {
                        PlaySound( "debris/wood2.wav" );
                        break;
                    }
                }
            }
        }
    }
}
