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

final class ASWeaponFlareConfig : ASWeaponConfig, ASMFlareConfig
{
    const string& GetName() const override
    {
        return "weapon_bts_flare";
    }

    const string& get_player_model() override
    {
        return "models/bts_rc/weapons/p_flare.mdl";
    }

    const string& get_world_model() override
    {
        return "models/bts_rc/weapons/w_flare.mdl";
    }

    const string& get_view_model() override
    {
        return "models/bts_rc/weapons/v_flare.mdl";
    }

    const string& get_animation_extension() override
    {
        return "gren";
    }

    const string& get_primary_ammo() override
    {
        return "Trip Mine";
    }

    const string& get_primary_ammoentity() override
    {
        return "weapon_bts_flare";
    }

    const int get_flags() property override
    {
        return ( ASWeaponConfig::get_flags() | ITEM_FLAG_EXHAUSTIBLE );
    }

    const uint8 get_animation_draw() override
    {
        return WeaponFlareAnim::Draw;
    }

    const uint8 get_hands_group() override
    {
        return 0;
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
                "ASMFlareConfigSchema"
            ]
        }""";
    }

    bool Register( meta_api::json::v2::json@ json ) override
    {
        flare_register(json);
        return ASWeaponConfig::Register( json );
    }
}

ASWeaponFlareConfig gpWeaponFlareConfig;

enum WeaponFlareAnim
{
    Idle = 0,
    PullPin,
    Throw,
    Draw,
    Toss,
    PullHold,
    Hold
};

class weapon_bts_flare : BTS_ThrowableWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponFlareConfig;
    }

    private ASFlare@ m_FlareOnHold;

    bool Deploy() override
    {
        PlaySound( "bts_rc/weapons/flare_deploy.wav", 0.6f, PITCH_NORM, CHAN_ITEM );
        return BTS_ThrowableWeapon::Deploy();
    }

    void DropHoldingFlare()
    {
        if( this.m_FlareOnHold !is null )
        {
            this.owner.m_rgAmmo( self.m_iPrimaryAmmoType, this.owner.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
            this.m_FlareOnHold.self.pev.effects &= ~EF_NODRAW;
            this.m_FlareOnHold.self.pev.velocity.z = -90;
            this.m_FlareOnHold.self.pev.movetype = MOVETYPE_TOSS;
            @this.m_FlareOnHold = null;
        }
    }

    void Holster( int skiplocal = 0 ) override
    {
        this.DropHoldingFlare();
        BTS_ThrowableWeapon::Holster( skiplocal );
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        this.DropHoldingFlare();

        switch( type )
        {
            case AttackType::Primary:
            {
                if( this.ThrowStart( type, 0.83 ) )
                {
                    PlayAnim( WeaponFlareAnim::PullPin );
                }
                break;
            }
            case AttackType::Secondary:
            {
                if( this.ThrowStart( type, 1.0 ) )
                {
                    PlayAnim( WeaponFlareAnim::PullPin );
                }
                break;
            }
            case AttackType::Tertiary:
            {
                if( this.ThrowStart( type, 0.83 ) )
                {
                    PlayAnim( WeaponFlareAnim::PullHold );
                }
                break;
            }
        }
    }

    void ThrowCreate( const Vector&in source, const Vector&in velocity ) override
    {
        gpWeaponFlareConfig.flare_create( this.owner, source, velocity );
    }

    float ThrowEnd( AttackType&in type, const Vector&in source, const Vector&in velocity ) override
    {
        switch( type )
        {
            case AttackType::Primary:
            {
                PlayAnim( WeaponFlareAnim::Throw, PLAYER_ANIM::PLAYER_ATTACK1 );
                break;
            }
            case AttackType::Secondary:
            {
                PlayAnim( WeaponFlareAnim::Toss, PLAYER_ANIM::PLAYER_ATTACK1 );
                break;
            }
        }

        ThrowCreate( source, velocity );

        return 0.2;
    }

    void ItemPreFrame() override
    {
        if( this.m_FlareOnHold !is null )
        {
            Vector origin;
            g_EngineFuncs.GetAttachment( this.owner.edict(), 1, origin, void );
            g_EntityFuncs.SetOrigin( this.m_FlareOnHold.self, origin );
            this.m_FlareOnHold.self.pev.effects |= EF_NODRAW;
            return;
        }

        if( this.m_FlareOnHold !is null )
        {
            Vector origin;
            g_EngineFuncs.GetAttachment( this.owner.edict(), 1, origin, void );
            g_EntityFuncs.SetOrigin( this.m_FlareOnHold.self, origin );
            this.m_FlareOnHold.self.pev.effects |= EF_NODRAW;
            return;
        }

        BTS_ThrowableWeapon::ItemPreFrame();
    }

    float Idle() override
    {
        if( this.m_FlareOnHold !is null )
        {
           PlayAnim( WeaponFlareAnim::Hold );
        }
        else
        {
            PlayAnim( WeaponFlareAnim::Idle );
        }

        return Math.RandomFloat( 5.0f, 7.0f );
    }
}
