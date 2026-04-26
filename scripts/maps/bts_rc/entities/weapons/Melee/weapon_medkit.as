/**   MIT License
*   
*   Copyright (c) 2025 Mikk155 https://github.com/Mikk155/bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies or substantial portions of the Software.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*   SOFTWARE.
*/

/*
*   Author: mikk
*/

enum WeaponMedkitAnim
{
    Idle = 0,
    LongIdle,
    LongUse,
    ShortUse,
    Holster,
    Draw,
    Heal,
    IDK
};

class CWeaponMedkitConfig : ASWeaponConfig
{
    const string& get_Name() override {
        return "weapon_medkit";
    }

    const string& get_view_model() override {
        return "models/bts_rc/weapons/v_medkit.mdl";
    }

    const string& get_player_model() override {
        return "models/bts_rc/weapons/p_medkit.mdl";
    }

    const uint8 get_animation_draw() override {
        return WeaponMedkitAnim::Draw;
    }

    const string& get_animation_extension() override {
        return "trip";
    }

    void WeaponDeploy( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        weapons::Deploy( weapon, player, gpWeaponMedkitConfig );
    }

    void WeaponPrimaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        weapon.PrimaryAttack();

        if( player.pev.weaponanim == WeaponMedkitAnim::Idle )
            g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_ITEM, "items/medshotno1.wav", 1.0f, ATTN_NORM );

        weapons::SetCooldown( weapon, player, this.GetCooldown( false, AttackType::Primary ) );
    }

    void WeaponSecondaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        weapon.SecondaryAttack();
        weapons::SetCooldown( weapon, player, this.GetCooldown( false, AttackType::Secondary ) );
    }

    void WeaponTertiaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        weapons::SetCooldown( weapon, player, this.GetCooldown( false, AttackType::Tertiary ) );

        int iAmmoLeft = player.m_rgAmmo( weapon.m_iPrimaryAmmoType );

        float flMissingHP = player.pev.max_health - player.pev.health;

        if( iAmmoLeft <= 0 || flMissingHP <= 0 )
        {
            g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_ITEM, "items/medshotno1.wav", 1.0f, ATTN_NORM );
            return;
        }

        // Clamp desired heal to missing HP
        float flDesiredHealHP = Math.min( this.health_gain, flMissingHP );

        // Convert HP → ammo (3 ammo per 1 HP)
        float flAmmoNeeded = ( flDesiredHealHP / this.health_gain ) * float( health_cost );

        // Clamp by available ammo
        float flAmmoUsed = Math.min( flAmmoNeeded, float( iAmmoLeft ) );

        // Convert back ammo → actual heal
        float flHealAmount = ( flAmmoUsed / float( health_cost ) ) * this.health_gain;

        // Apply same diminishing behavior as normal heal
        if( iAmmoLeft <= health_ammount * 0.75f )
            flHealAmount = Math.min( health_ammount * 0.2f, flHealAmount );
        else if( iAmmoLeft < health_ammount * 1.5f )
            flHealAmount = Math.min( health_ammount * 0.2f, flHealAmount );
        else if( iAmmoLeft < health_ammount * 6 )
            flHealAmount = Math.min( health_ammount * 0.5f, flHealAmount );

        flHealAmount = int( Math.Ceil( flHealAmount ) );
        flAmmoUsed = int( Math.Ceil( ( flHealAmount / this.health_gain ) * health_cost ) );

        if( flHealAmount <= 0 || flAmmoUsed <= 0 )
            return;

        // Execute heal
        player.SetAnimation( PLAYER_ATTACK1 );
        weapon.SendWeaponAnim( WeaponMedkitAnim::Heal, 0, weapon.pev.body );

        player.TakeHealth( flHealAmount, DMG_MEDKITHEAL );
        player.m_rgAmmo( weapon.m_iPrimaryAmmoType, iAmmoLeft - int( flAmmoUsed ) );

        int pitch = Math.RandomLong( 50, 60 );

        if( iAmmoLeft < health_ammount * 13 )
            pitch += int( float( iAmmoLeft ) / 1.25f );

        g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "items/medshot4.wav", 1.0f, ATTN_NORM, 0, pitch );
    }

    float health_ammount;
    float health_gain;
    float health_cost;

    void Parse( dictionary@ json ) override
    {
        this.health_ammount = int( this.Get( @json, "health_ammount", 10 ) );
        this.health_gain = int( this.Get( @json, "health_gain", 10 ) );
        this.health_cost = int( this.Get( @json, "health_cost", 30 ) );

        ASWeaponConfig::Parse( json );
    }
}

CWeaponMedkitConfig gpWeaponMedkitConfig;
