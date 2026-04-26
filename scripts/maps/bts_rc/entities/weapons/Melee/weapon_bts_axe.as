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
*   Rewrited by mikk 27/3/26
*/

enum WeaponAxeAnim
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
    Shove,
    ShoveAlt,
    ShoveMiss,
    ShoveMissAlt
};

class CWeaponAxeConfig : ASMeleeWeaponConfig
{
    const string& get_Name() override {
        return "weapon_bts_axe";
    }

    const string& get_player_model() override {
        return "models/bts_rc/weapons/p_axe.mdl";
    }

    const string& get_world_model() override {
        return "models/bts_rc/weapons/w_axe.mdl";
    }

    const string& get_view_model() override {
        return "models/bts_rc/weapons/v_axe.mdl";
    }

    const string& get_animation_extension() override {
        return "crowbar";
    }

    const uint8 get_animation_draw() override {
        return WeaponAxeAnim::Draw;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hit1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hit2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hitbod1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hitbod2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_hitbod3.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/axe_miss1.wav" );
        ASMeleeWeaponConfig::Precache();
    }
}

CWeaponAxeConfig gpWeaponAxeConfig;

class weapon_bts_axe : BTS_MeleeWeapon
{
    ASWeaponConfig@ get_config() {
        return @gpWeaponAxeConfig;
    }

    float Idle() override
    {
        switch( RandomUint(2) )
        {
            case 0: PlayAnim( WeaponAxeAnim::Idle1 ); break;
            case 1: PlayAnim( WeaponAxeAnim::Idle2 ); break;
            case 2: PlayAnim( WeaponAxeAnim::Idle3 ); break;
        }

        return 5.5f;
    }

    void Attack( CBasePlayer@ player, AttackType type )
    {
        if( type == AttackType::Tertiary )
            return;

        TraceResult tr;
        CBaseEntity@ hit = null;

        bool miss = this.Hit( tr, type, hit, ( type == AttackType::Secondary ) );

        bool is_trained_personal = util::IsTrainedPersonal( player );

        this.SetCooldown( is_trained_personal, miss, type );

        switch( type )
        {
            case AttackType::Primary:
            {
                switch( RandomUint(2) )
                {
                    case 0: PlayAnim( ( miss ? WeaponAxeAnim::Attack1Miss : WeaponAxeAnim::Attack1Hit ) ); break;
                    case 1: PlayAnim( ( miss ? WeaponAxeAnim::Attack2Miss : WeaponAxeAnim::Attack2Hit ) ); break;
                    case 2: PlayAnim( ( miss ? WeaponAxeAnim::Attack3Miss : WeaponAxeAnim::Attack3Hit ) ); break;
                }
                break;
            }
            case AttackType::Secondary:
            {
                switch( RandomUint(2) )
                {
                    case 0: PlayAnim( ( miss ? WeaponAxeAnim::ShoveMiss : WeaponAxeAnim::Shove ) ); break;
                    case 1: PlayAnim( ( miss ? WeaponAxeAnim::ShoveMissAlt : WeaponAxeAnim::ShoveAlt ) ); break;
                    case 2: PlayAnim( ( miss ? WeaponAxeAnim::ShoveMiss : WeaponAxeAnim::Shove ) ); break;
                }
                break;
            }
        }

        if( miss )
        {
            PlaySound( "bts_rc/weapons/axe_miss1.wav" );
        }
        else
        {
            TraceEffects( tr, Bullet::BULLET_PLAYER_CROWBAR );

            if( this.IsFlesh(hit) )
            {
                switch( RandomUint(2) )
                {
                    case 0: PlaySound( "bts_rc/weapons/axe_hitbod3.wav" ); break;
                    case 1: PlaySound( "bts_rc/weapons/axe_hitbod2.wav" ); break;
                    case 2: PlaySound( "bts_rc/weapons/axe_hitbod1.wav" ); break;
                }
            }
            else if( this.IsBrush(hit) )
            {
                switch( RandomUint(1) )
                {
                    case 0: PlaySound( "bts_rc/weapons/axe_hit2.wav" ); break;
                    case 1: PlaySound( "bts_rc/weapons/axe_hit1.wav" ); break;
                }
            }
        }

        // Slower player anim so it looks "heavier" for not trained personal
        if( !is_trained_personal )
            player.pev.framerate = 0.6f;
    }
}
