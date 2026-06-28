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

final class CWeaponFlashlightConfig : ASMeleeWeaponConfig
{
    const string& GetName() const override {
        return "weapon_bts_flashlight";
    }

    const string& get_player_model() override {
        return "models/bts_rc/weapons/p_flashlight.mdl";
    }

    const string& get_flashlight_model() {
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

    void WeaponHolster( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        Flashlight::Holster( player, weapon, character );
        ASMeleeWeaponConfig::WeaponHolster( player, weapon, character );
    }

    void PlayerThink( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        Flashlight::Think( player, weapon, character, this, this.flashlight_model );
        ASMeleeWeaponConfig::PlayerThink( player, weapon, character );
    }

    void Precache() override
    {
        g_Game.PrecacheModel( this.flashlight_model );
        ASMeleeWeaponConfig::Precache();
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
                ASMeleeWeaponConfig::WeaponFlashlight( player, weapon, character );
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

    bool Register( meta_api::json::v2::json@ json ) override
    {
        this.deploy_time = 0.5;
        this.slot = 4;
        this.position = 4;
        this.secondary_maxammo = 10;
        this.secondary_dropammo = 0;
        this.primary_distance = 32;
        this.primary_damage = 7;
        this.secondary_trained_cooldown = this.secondary_cooldown = 0.5;

        return ASMeleeWeaponConfig::Register( json );
    }
}

CWeaponFlashlightConfig gpWeaponFlashlight;

final class weapon_bts_flashlight : BTS_MeleeWeapon
{
    ASWeaponConfig@ get_config() {
        return @gpWeaponFlashlight;
    }

    void Spawn()
    {
        self.m_iDefaultAmmo = Math.RandomLong( 0, 2 );
        BTS_MeleeWeapon::Spawn();
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
}

#if OLD_CODE_REMAINING
final class weapon_bts_dflashlight : ScriptBasePlayerWeaponEntity, CBaseWeapon, CBaseMelee
{
    private bool Swing( bool fFirst )
    {
        if( m_pPlayer.FlashlightIsOn() )
            FlashlightTurnOff();

        TraceResult tr;
        bool fDidHit = false;

        Math.MakeVectors( m_pPlayer.pev.v_angle );
        Vector vecSrc = m_pPlayer.GetGunPosition();
        Vector vecEnd = vecSrc + g_Engine.v_forward * RANGE;

        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

        if( tr.flFraction >= 1.0f )
        {
            g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
            if( tr.flFraction < 1.0f )
            {
                // Calculate the point of intersection of the line (or hull) and the object we hit
                // This is and approximation of the "best" intersection
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if( pHit is null || pHit.IsBSPModel() )
                    g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
                vecEnd = tr.vecEndPos; // This is the point on the actual surface (the hull could have hit space)
            }
        }

        if( tr.flFraction >= 1.0f )
        {
            if( fFirst )
            {
                // miss
                switch( ( m_iSwing++ ) % 3 )
                {
                    case 0:
                        self.SendWeaponAnim( WeaponFlashlightAnim::Attack1Miss, 0, pev.body );
                        break;
                    case 1:
                        self.SendWeaponAnim( WeaponFlashlightAnim::Attack2Miss, 0, pev.body );
                        break;
                    case 2:
                        self.SendWeaponAnim( WeaponFlashlightAnim::Attack3Miss, 0, pev.body );
                        break;
                }
                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = m_bFlashLightTurnTime = g_Engine.time + 0.625f;
                self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

                // play wiff or swish sound
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_miss1.wav", 1.0f, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 0xF ) );

                // player "shoot" animation
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
            }
        }
        else
        {
            // hit
            fDidHit = true;

            CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

            switch( ( ( m_iSwing++ ) % 2 ) + 1 )
            {
                case 0:
                    self.SendWeaponAnim( WeaponFlashlightAnim::Attack1Hit, 0, pev.body );
                    break;
                case 1:
                    self.SendWeaponAnim( WeaponFlashlightAnim::Attack2Hit, 0, pev.body );
                    break;
                case 2:
                    self.SendWeaponAnim( WeaponFlashlightAnim::Attack3Hit, 0, pev.body );
                    break;
            }

            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = m_bFlashLightTurnTime = g_Engine.time + 0.375f;
            self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

            // player "shoot" animation
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

            g_WeaponFuncs.ClearMultiDamage();

            if( self.m_flNextPrimaryAttack + 1.0f < g_Engine.time )
                pEntity.TraceAttack( m_pPlayer.pev, DAMAGE, g_Engine.v_forward, tr, DMG_CLUB );        // first swing does full damage
            else
                pEntity.TraceAttack( m_pPlayer.pev, DAMAGE * 0.5f, g_Engine.v_forward, tr, DMG_CLUB ); // subsequent swings do 50% (Changed -Sniper) (Half)

            g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

            // play thwack, smack, or dong sound
            float flVol = 1.0f;
            bool fHitWorld = true;

            // for monsters or breakable entity smacking speed function
            if( pEntity !is null )
            {
                if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
                {
                    // aone
                    if( pEntity.IsPlayer() ) // lets pull them
                        pEntity.pev.velocity = pEntity.pev.velocity + ( pev.origin - pEntity.pev.origin ).Normalize() * 120.0f;
                    // end aone

                    // play thwack or smack sound
                    switch( Math.RandomLong( 1, 3 ) )
                    {
                        case 3:
                            g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_hitbod3.wav", 1.0f, ATTN_NORM );
                            break;
                        case 2:
                            g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_hitbod2.wav", 1.0f, ATTN_NORM );
                            break;
                        default:
                            g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_hitbod1.wav", 1.0f, ATTN_NORM );
                            break;
                    }

                    m_pPlayer.m_iWeaponVolume = 128;

                    if( !pEntity.IsAlive() )
                        return true;
                    else
                        flVol = 0.1f;

                    fHitWorld = false;
                }
            }

            // play texture hit sound
            // UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

            if( fHitWorld )
            {
                g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2.0f, BULLET_PLAYER_CROWBAR );

                // also play crowbar strike
                switch( Math.RandomLong( 1, 2 ) )
                {
                    case 2:
                        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_hit2.wav", 1.0f, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
                        break;
                    default:
                        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flashlight_hit1.wav", 1.0f, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
                        break;
                }
            }

            // delay the decal a bit
            m_trHit = tr;
            bts_post_attack( tr );
            SetThink( ThinkFunction( this.Smack ) );
            pev.nextthink = g_Engine.time + 0.2f;

            m_pPlayer.m_iWeaponVolume = int( flVol * 512 );
        }

        return fDidHit;
    }
}
#endif
