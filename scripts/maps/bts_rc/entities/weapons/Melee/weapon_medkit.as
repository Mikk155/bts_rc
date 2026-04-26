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

    uint8 get_animation_draw() override {
        return WeaponMedkitAnim::Draw;
    }

    const string& get_animation_extension() override {
        return "trip";
    }

    float SELF_HEAL_AMMOUNT = 10;
    float SELF_HEAL_HP_GAIN = 10;
    float SELF_HEAL_AMMO_COST = 30;
    uint VOLUME = 128;

    void WeaponDeploy( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        weapons::Deploy( weapon, player, gpWeaponMedkitConfig );
    }

    void WeaponTertiaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        int iAmmoLeft = player.m_rgAmmo( weapon.m_iPrimaryAmmoType );

        if( iAmmoLeft <= 0 )
        {
            g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_ITEM, "items/medshotno1.wav", 1.0f, ATTN_NORM );
            weapons::SetCooldown( weapon, player, gpWeaponMedkitConfig.GetCooldown( util::IsTrainedPersonal(player), AttackType::Secondary ) );
            return;
        }

        float flMissingHP = player.pev.max_health - player.pev.health;

        if( flMissingHP <= 0 )
            return;

        // Clamp desired heal to missing HP
        float flDesiredHealHP = Math.min( this.SELF_HEAL_HP_GAIN, flMissingHP );

        // Convert HP → ammo (3 ammo per 1 HP)
        float flAmmoNeeded = ( flDesiredHealHP / this.SELF_HEAL_HP_GAIN ) * float( SELF_HEAL_AMMO_COST );

        // Clamp by available ammo
        float flAmmoUsed = Math.min( flAmmoNeeded, float( iAmmoLeft ) );

        // Convert back ammo → actual heal
        float flHealAmount = ( flAmmoUsed / float( SELF_HEAL_AMMO_COST ) ) * this.SELF_HEAL_HP_GAIN;

        // Apply same diminishing behavior as normal heal
        if( iAmmoLeft <= SELF_HEAL_AMMOUNT * 0.75f )
            flHealAmount = Math.min( SELF_HEAL_AMMOUNT * 0.2f, flHealAmount );
        else if( iAmmoLeft < SELF_HEAL_AMMOUNT * 1.5f )
            flHealAmount = Math.min( SELF_HEAL_AMMOUNT * 0.2f, flHealAmount );
        else if( iAmmoLeft < SELF_HEAL_AMMOUNT * 6 )
            flHealAmount = Math.min( SELF_HEAL_AMMOUNT * 0.5f, flHealAmount );

        flHealAmount = int( Math.Ceil( flHealAmount ) );
        flAmmoUsed = int( Math.Ceil( ( flHealAmount / this.SELF_HEAL_HP_GAIN ) * SELF_HEAL_AMMO_COST ) );

        if( flHealAmount <= 0 || flAmmoUsed <= 0 )
            return;

        // Execute heal
        player.SetAnimation( PLAYER_ATTACK1 );
        weapon.SendWeaponAnim( WeaponMedkitAnim::Heal, 0, weapon.pev.body );
        player.m_iWeaponVolume = VOLUME;

        player.TakeHealth( flHealAmount, DMG_MEDKITHEAL );
        player.m_rgAmmo(
            weapon.m_iPrimaryAmmoType,
            iAmmoLeft - int( flAmmoUsed ) );

        int pitch = Math.RandomLong( 50, 60 );
        if( iAmmoLeft < SELF_HEAL_AMMOUNT * 13 )
            pitch += int( float( iAmmoLeft ) / 1.25f );

        g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "items/medshot4.wav", 1.0f, ATTN_NORM, 0, pitch );

        weapon.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
        weapon.m_flNextTertiaryAttack = g_Engine.time + 2.0f;
        weapons::SetCooldown( weapon, player, gpWeaponMedkitConfig.GetCooldown( util::IsTrainedPersonal(player), AttackType::Tertiary ) );
    }

    void Parse( dictionary@ json ) override
    {
        ASWeaponConfig::Parse( json );
    }
}

CWeaponMedkitConfig gpWeaponMedkitConfig;
