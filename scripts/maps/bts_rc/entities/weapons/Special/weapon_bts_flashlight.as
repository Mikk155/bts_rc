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

class CWeaponFlashlightConfig : ASMeleeWeaponConfig
{
    const string& get_Name() override {
        return "weapon_bts_flashlight";
    }

    const string& get_player_model() override {
        return "models/bts_rc/weapons/p_flashlight.mdl";
    }

    const string& get_flashlight_model() {
        return "models/p_crowbar.mdl";
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

    const string& get_primary_ammo() override
    {
        return "bts:battery";
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
        ASMeleeWeaponConfig::Precache();
    }

    void WeaponFlashlight( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        if( player.FlashlightIsOn() )
            player.FlashlightTurnOff();
        else
            player.FlashlightTurnOn();
    }

    void Register( BTSJson@ json ) override
    {
        this.deploy_time = 0.5;
        this.primary_maxammo = 10;
        this.slot = 4;
        this.position = 4;
        this.primary_distance = 32;
        this.primary_damage = 7;

        ASMeleeWeaponConfig::Register( json );
    }
}

CWeaponFlashlightConfig gpWeaponFlashlight;

class weapon_bts_flashlight : BTS_MeleeWeapon
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
