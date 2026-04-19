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
*   Rewrited by Rizulix for bts_rc (january 2025)
*   Rewrited by mikk 14/4/26
*/

enum WeaponCrowbarAnim
{
    Idle = 0,
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
    Shove,
    ShoveMiss,
    ShoveAlt,
    ShoveAltMiss
};

class CWeaponCrowbarConfig : ASMeleeWeaponConfig
{
    const string& get_Name() override {
        return "weapon_crowbar";
    }

    const string& get_view_model() override {
        return "models/bts_rc/weapons/v_crowbar.mdl";
    }

    uint viewmodelIndex;

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/cbar_draw.wav" );
        this.viewmodelIndex = g_Game.PrecacheModel( this.view_model );
        ASMeleeWeaponConfig::Precache();
    }

    void PlayerThink( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character )
    {
        if( player.pev.viewmodel != gpWeaponCrowbarConfig.view_model )
        {
            g_SoundSystem.EmitSoundDyn( weapon.edict(), CHAN_WEAPON, "bts_rc/weapons/cbar_draw.wav", 1.0f, ATTN_NONE );

            player.pev.viewmodel = gpWeaponCrowbarConfig.view_model;
            weapon.pev.body = g_ModelFuncs.SetBodygroup( gpWeaponCrowbarConfig.viewmodelIndex, weapon.pev.body, 0, ( character !is null ? character.HandsGroup : Hands::Gray ) );
            weapon.SendWeaponAnim( player.pev.weaponanim, 0, weapon.pev.body ); // Resend the current animation to update the bodygroup
        }
    }

    WeaponOverrider@ overrider;

    void Parse( dictionary@ json ) override
    {
        this.Precache();

        this.viewmodelIndex = g_ModelFuncs.ModelIndex( gpWeaponCrowbarConfig.view_model );

        this.ParseDefaultVariables( json );

        @this.overrider = WeaponOverrider( this )
            .SetPlayerThink( WeaponOverriderCallback( @this.PlayerThink ) );


        g_EngineFuncs.CVarSetFloat( "sk_plr_crowbar", this.primary_damage );
    }
}

CWeaponCrowbarConfig gpWeaponCrowbarConfig;
