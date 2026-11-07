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

final class ASWeaponHandGrenadeConfig : ASWeaponConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_handgrenade";
    }

    const string& get_player_model() override
    {
        return "models/hlclassic/p_grenade.mdl";
    }

    const string& get_world_model() override
    {
        return "models/hlclassic/w_grenade.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_grenade.mdl";
    }

    const string& get_animation_extension() override
    {
        return "gren";
    }

    const string& get_primary_ammo() override
    {
        return "Hand Grenade";
    }

    const string& get_primary_ammoentity() override
    {
        return "weapon_bts_handgrenade";
    }

    const int get_flags() property override
    {
        return ( ASWeaponConfig::get_flags() | ITEM_FLAG_EXHAUSTIBLE );
    }

    const uint8 get_animation_draw() override
    {
        return WeaponHandGrenadeAnim::Draw;
    }
}

ASWeaponHandGrenadeConfig gpWeaponHandGrenadeConfig;

enum WeaponHandGrenadeAnim
{
    Idle = 0,
    Fidget,
    PullPin,
    Throw1,
    Throw2,
    Throw3,
    Holster,
    Draw
};

class weapon_bts_handgrenade : BTS_ThrowableWeapon // disable-line W119, W120
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponHandGrenadeConfig;
    }

    bool Deploy() override
    {
        PlaySound( "bts_rc/weapons/grenade_draw.wav", 0.6f, PITCH_NORM, CHAN_ITEM );
        return BTS_Weapon::Deploy();
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        switch( type )
        {
            case AttackType::Primary:
            case AttackType::Secondary:
            {
                if( this.ThrowStart( type, 0.83 ) )
                {
                    PlayAnim( WeaponHandGrenadeAnim::PullPin );
                }
                break;
            }
        }
    }

    void ThrowCreate( const Vector&in source, const Vector&in velocity ) override
    {
        CGrenade@ grenade = g_EntityFuncs.ShootTimed( this.owner.pev, source, velocity, 3.0f );

        if( grenade !is null )
        {
            g_EntityFuncs.SetModel( grenade, this.config.world_model );
            grenade.pev.dmg = gpWeaponHandGrenadeConfig.primary_damage;
        }
    }

    float ThrowEnd( AttackType&in type, const Vector&in source, const Vector&in velocity ) override
    {
        if( RandomUint( 1 ) == 0 )
        {
            PlaySound( "bts_rc/weapons/grenade_throw1.wav", 1.0f, PITCH_NORM, CHAN_ITEM );
        }
        else
        {
            PlaySound( "bts_rc/weapons/grenade_throw2.wav", 1.0f, PITCH_NORM, CHAN_ITEM );
        }

        PlayAnim( WeaponHandGrenadeAnim::Throw1, PLAYER_ANIM::PLAYER_ATTACK1 );

        ThrowCreate( source, velocity );

        return 0.2;
    }

    float Idle() override
    {
        float flRand = Math.RandomFloat( 0.0f, 1.0f );
        if( flRand <= 0.75f )
        {
            PlayAnim( WeaponHandGrenadeAnim::Idle );
            return Math.RandomFloat( 10.0f, 15.0f );
        }
        else
        {
            PlayAnim( WeaponHandGrenadeAnim::Fidget );
            return 2.33f;
        }
    }
}
