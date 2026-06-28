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

final class CWeaponScrewDriverConfig : ASMeleeWeaponConfig
{
    const string& GetName() const override {
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

    const uint8 get_animation_draw() override {
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
        ASMeleeWeaponConfig::Precache();
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        this.slot = 0;
        this.position = 8;
        this.weight = 10;
        this.deploy_time = 0.3;
        this.primary_distance = 32;
        this.primary_damage = 9;
        this.primary_cooldown = 0.35;
        this.primary_trained_cooldown = 0.25;
        this.primary_miss_cooldown = 0.6;
        this.primary_miss_trained_cooldown = 0.5;
        this.subsequent_hits_deduction = 0.5;

        return ASMeleeWeaponConfig::Register( json );
    }
}

CWeaponScrewDriverConfig gpWeaponScrewDriverConfig;

final class weapon_bts_screwdriver : BTS_MeleeWeapon
{
    ASWeaponConfig@ get_config()
    {
        return @gpWeaponScrewDriverConfig;
    }

    void Attack( CBasePlayer@ player, AttackType type )
    {
        switch( type )
        {
            case AttackType::Tertiary:
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
