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
*   Rewrited by Rizulix for bts_rc (december 2024)
*   Rewrited by mikk 5/5/26
*/

enum WeaponFlashlightAnim
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
    Flashlight
};

final class ASWeaponFlashlightConfig : ASWeaponConfig
{
    const string& GetName() const override {
        return "weapon_bts_flashlight";
    }

    const string& get_player_model() override {
        return "models/bts_rc/weapons/p_flashlight.mdl";
    }

    const string& get_flashlight_model()
    {
        return "models/bts_rc/weapons/p_flashlight_cone.mdl";
    }

    const string& get_world_model() override {
        return "models/bts_rc/weapons/w_flashlight.mdl";
    }

    const string& get_view_model() override {
        return "models/bts_rc/weapons/v_flashlight.mdl";
    }

    const string& get_animation_extension() override {
        return "crowbar";
    }

    const string& get_secondary_ammo() override
    {
        return "bts_battery";
    }

    const string& get_secondary_ammoentity() override
    {
        return "ammo_bts_flashlight";
    }

    const uint8 get_animation_draw() override {
        return WeaponFlashlightAnim::Draw;
    }

    void PlayerThink( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        Flashlight::Think( player, weapon, character, this, this.flashlight_model );
        ASWeaponConfig::PlayerThink( player, weapon, character );
    }

    void Precache() override
    {
        g_Game.PrecacheModel( this.flashlight_model );
        ASWeaponConfig::Precache();
    }

    void WeaponSecondaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        WeaponFlashlight( player, weapon, character );
    }

    void WeaponFlashlight( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        switch( Flashlight::Toggle( player, weapon, 5 ) )
        {
            case Flashlight::State::NoAmmo:
            {
                // Find another weapon with flashlight if this has no ammo
                ASWeaponConfig::WeaponFlashlight( player, weapon, character );
               break;
            }
            case Flashlight::State::Reloading:
            {
                weapon.SendWeaponAnim( WeaponFlashlightAnim::Holster, 0, weapon.pev.body );
                break;
            }
            case Flashlight::State::TurnedOn:
            case Flashlight::State::TurnedOff:
            default:
            {
                weapon.SendWeaponAnim( WeaponFlashlightAnim::Flashlight, 0, weapon.pev.body );
                weapons::SetCooldown( weapon, player, this.GetCooldown( util::IsTrainedPersonal(player), AttackType::Secondary ) );
                break;
            }
        }
    }
}

ASWeaponFlashlightConfig gpWeaponFlashlight;

final class weapon_bts_flashlight : BTS_MeleeWeapon
{
    ASWeaponConfig@ get_config() override
    {
        return @gpWeaponFlashlight;
    }

    void Spawn() override
    {
        self.m_iDefaultAmmo = Math.RandomLong( 0, 2 );
        BTS_MeleeWeapon::Spawn();
    }

    void Holster( int skiplocal = 0 ) override
    {
        Flashlight::Holster( this.owner, self, null );
        BTS_MeleeWeapon::Holster( skiplocal );
    }

    float Idle() override
    {
        switch( RandomUint(2) )
        {
            case 0: PlayAnim( WeaponFlashlightAnim::Idle1 ); break;
            case 1: PlayAnim( WeaponFlashlightAnim::Idle2 ); break;
            case 2: PlayAnim( WeaponAxeAnim::Idle3 ); break;
        }

        return Math.RandomFloat( 6.0f, 8.0f );
    }

    void Attack( CBasePlayer@ player, AttackType type ) override
    {
        if( type != AttackType::Primary )
            return;

        if( player.FlashlightIsOn() )
            player.FlashlightTurnOff();

        TraceResult tr;
        CBaseEntity@ hit = null;

        bool miss = this.Hit( tr, type, hit );

        this.SetCooldown( util::IsTrainedPersonal( player ), miss, type );

        switch( ( m_iSwing++ ) % 3 )
        {
            case 0: PlayAnim( miss ? WeaponFlashlightAnim::Attack1Miss : WeaponFlashlightAnim::Attack1Hit ); break;
            case 1: PlayAnim( miss ? WeaponFlashlightAnim::Attack2Miss : WeaponFlashlightAnim::Attack2Hit ); break;
            case 2: PlayAnim( miss ? WeaponFlashlightAnim::Attack3Miss : WeaponFlashlightAnim::Attack3Hit ); break;
        }

        if( miss )
        {
            PlaySound( "bts_rc/weapons/flashlight_miss1.wav", 1.0f, 94 + Math.RandomLong( 0, 0xF ) );
            return;
        }

        TraceEffects( tr, Bullet::BULLET_PLAYER_CROWBAR );

        if( this.IsFlesh( hit ) )
        {
            switch( RandomUint( 2 ) )
            {
                case 0: PlaySound( "bts_rc/weapons/flashlight_hitbod1.wav" ); break;
                case 1: PlaySound( "bts_rc/weapons/flashlight_hitbod2.wav" ); break;
                case 2: PlaySound( "bts_rc/weapons/flashlight_hitbod3.wav" ); break;
            }
        }
        else if( this.IsBrush( hit ) )
        {
            switch( RandomUint( 1 ) )
            {
                case 0: PlaySound( "bts_rc/weapons/flashlight_hit1.wav", 1.0f, 98 + Math.RandomLong( 0, 3 ) ); break;
                case 1: PlaySound( "bts_rc/weapons/flashlight_hit2.wav", 1.0f, 98 + Math.RandomLong( 0, 3 ) ); break;
            }
        }
    }
}
