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
*   Rewrited by mikk 27/4/26
*/

enum WeaponPipeWrenchAnim
{
    Idle1 = 0,
    Idle2,
    Idle3,
    Draw,
    Holster,
    Attack1Hit,
    Attack1Miss,
    Attack2Hit,
    Attack2Miss,
    Attack3Hit,
    Attack3Miss,
    AttackBigWind,
    AttackBigHit,
    AttackBigMiss,
    AttackBigLoop
};

class CWeaponPipeWrenchConfig : ASMeleeWeaponConfig
{
    const string& get_Name() override {
        return "weapon_bts_pipewrench";
    }

    const string& get_view_model() override {
        return "models/bts_rc/weapons/v_pipe_wrench.mdl";
    }

    const string& get_world_model() override {
        return "models/bts_rc/weapons/w_pipe_wrench.mdl";
    }

    const string& get_player_model() override {
        return "models/bts_rc/weapons/p_pipe_wrench.mdl";
    }

    const string& get_animation_extension() override {
        return "crowbar";
    }

    const uint8 get_animation_draw() override {
        return WeaponPipeWrenchAnim::Draw;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "weapons/pwrench_miss1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/pwrench_big_hitbod1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/pwrench_big_hitbod2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/pwrench_big_miss.wav" );
        g_SoundSystem.PrecacheSound( "weapons/pwrench_hit1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/pwrench_hit2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/pwrench_hitbod1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/pwrench_hitbod2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/pwrench_hitbod3.wav" );
        g_SoundSystem.PrecacheSound( "weapons/pwrench_big_hit1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/pwrench_big_hit2.wav" );

        ASMeleeWeaponConfig::Precache();
    }
}

CWeaponPipeWrenchConfig gpWeaponPipeWrenchConfig;

class weapon_bts_pipewrench : BTS_MeleeCharge
{
    ASWeaponConfig@ get_config() {
        return @gpWeaponPipeWrenchConfig;
    }

    void Attack( CBasePlayer@ player, AttackType type )
    {
        bool miss;
        TraceResult tr;
        CBaseEntity@ hit;

        bool is_trained_personal = util::IsTrainedPersonal( player );

        switch( type )
        {
            case AttackType::Primary:
            {
                miss = this.Hit( tr, AttackType::Secondary, hit );

                if( miss )
                {
                    this.PlaySound( "weapons/pwrench_miss1.wav" );

                    switch( RandomUint(2) )
                    {
                        case 0: this.PlayAnim( WeaponPipeWrenchAnim::Attack1Miss ); break;
                        case 1: this.PlayAnim( WeaponPipeWrenchAnim::Attack2Miss ); break;
                        case 2: this.PlayAnim( WeaponPipeWrenchAnim::Attack3Miss ); break;
                    }
                }
                else
                {
                    if( this.IsFlesh(hit) )
                    {
                        switch( RandomUint(2) )
                        {
                            case 0: this.PlaySound( "weapons/pwrench_hitbod1.wav" ); break;
                            case 1: this.PlaySound( "weapons/pwrench_hitbod2.wav" ); break;
                            case 2: this.PlaySound( "weapons/pwrench_hitbod3.wav" ); break;
                        }
                    }
                    else if( this.IsBrush(hit) )
                    {
                        switch( RandomUint(1) )
                        {
                            case 0: this.PlaySound( "weapons/pwrench_hit1.wav" ); break;
                            case 1: this.PlaySound( "weapons/pwrench_hit2.wav" ); break;
                        }
                    }

                    switch( RandomUint(2) )
                    {
                        case 0: this.PlayAnim( WeaponPipeWrenchAnim::Attack1Hit ); break;
                        case 1: this.PlayAnim( WeaponPipeWrenchAnim::Attack2Hit ); break;
                        case 2: this.PlayAnim( WeaponPipeWrenchAnim::Attack3Hit ); break;
                    }
                }
                break;
            }
            case AttackType::Secondary:
            {
                // We just started charging
                if( m_WhackState == WhackState::Holding )
                {
                    this.PlayAnim( WeaponPipeWrenchAnim::AttackBigWind );
                    return;
                }

                miss = this.Hit( tr, AttackType::Secondary, hit );
                this.PlayAnim( ( miss ? WeaponPipeWrenchAnim::AttackBigMiss : WeaponPipeWrenchAnim::AttackBigHit ) );

                Math.MakeVectors( player.pev.v_angle + player.pev.punchangle );
                player.pev.punchangle.x = -2.0f;

                if( miss )
                {
                    this.PlaySound( "weapons/pwrench_big_miss.wav" );
                }
                else if( this.IsFlesh(hit) )
                {
                    switch( RandomUint(1) )
                    {
                        case 0: this.PlaySound( "weapons/pwrench_big_hitbod1.wav" ); break;
                        case 1: this.PlaySound( "weapons/pwrench_big_hitbod2.wav" ); break;
                    }
                }
                else if( this.IsBrush(hit) )
                {
                    switch( RandomUint(1) )
                    {
                        case 0: this.PlaySound( "weapons/pwrench_hit1.wav" ); break;
                        case 1: this.PlaySound( "weapons/pwrench_hit2.wav" ); break;
                    }
                }

                break;
            }
            case AttackType::Tertiary:
            {
                return;
            }
        }

        this.SetCooldown( is_trained_personal, miss, type );

        if( !miss )
            TraceEffects( tr, Bullet::BULLET_PLAYER_CROWBAR );
    }

    float Idle()
    {
        switch( RandomUint(2) )
        {
            case 0: this.PlayAnim( WeaponPipeWrenchAnim::Idle1, false ); return 2.69f;
            case 1: this.PlayAnim( WeaponPipeWrenchAnim::Idle2, false ); return 5.33f;
            case 2: default: break;
        }

        this.PlayAnim( WeaponPipeWrenchAnim::Idle3, false );
        return 5.33f;
    }
}
