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

enum WeaponPipeAnim
{
    Idle1 = 0,
    idle2,
    idle3,
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

class CWeaponPipeConfig : ASMeleeWeaponConfig
{
    const string& get_Name() override {
        return "weapon_bts_pipe";
    }

    const string& get_player_model() override {
        return "models/bts_rc/weapons/p_pipe.mdl";
    }

    const string& get_world_model() override {
        return "models/bts_rc/weapons/w_pipe.mdl";
    }

    const string& get_view_model() override {
        return "models/bts_rc/weapons/v_pipe.mdl";
    }

    const string& get_animation_extension() override {
        return "crowbar";
    }

    const uint8 get_animation_draw() override {
        return WeaponPipeAnim::Draw;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_miss1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_hitbod1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_hitbod2.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_hitbod3.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_hit1.wav" );
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/pipe_hit2.wav" );
        ASMeleeWeaponConfig::Precache();
    }
}

CWeaponPipeConfig gpWeaponPipeConfig;

class weapon_bts_pipe : BTS_MeleeCharge
{
    ASWeaponConfig@ get_config() {
        return @gpWeaponPipeConfig;
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
                    switch( RandomUint(2) )
                    {
                        case 0: this.PlayAnim( WeaponPipeAnim::Attack1Miss ); break;
                        case 1: this.PlayAnim( WeaponPipeAnim::Attack2Miss ); break;
                        case 2: this.PlayAnim( WeaponPipeAnim::Attack3Miss ); break;
                    }
                }
                else
                {
                    switch( RandomUint(2) )
                    {
                        case 0: this.PlayAnim( WeaponPipeAnim::Attack1Hit ); break;
                        case 1: this.PlayAnim( WeaponPipeAnim::Attack2Hit ); break;
                        case 2: this.PlayAnim( WeaponPipeAnim::Attack3Hit ); break;
                    }
                }
                break;
            }
            case AttackType::Secondary:
            {
                // We just started charging
                if( m_WhackState == WhackState::Holding )
                {
                    this.PlayAnim( WeaponPipeAnim::AttackBigWind );
                    return;
                }
                miss = this.Hit( tr, AttackType::Secondary, hit );
                this.PlayAnim( ( miss ? WeaponPipeAnim::AttackBigMiss : WeaponPipeAnim::AttackBigHit ) );
                break;
            }
            case AttackType::Tertiary:
            {
                return;
            }
        }

        this.SetCooldown( is_trained_personal, miss, type );

        if( miss )
        {
            this.PlaySound( "bts_rc/weapons/pipe_miss1.wav" );
        }
        else
        {
            TraceEffects( tr, Bullet::BULLET_PLAYER_CROWBAR );

            if( this.IsFlesh(hit) )
            {
                switch( RandomUint(2) )
                {
                    case 0: this.PlaySound( "bts_rc/weapons/pipe_hitbod1.wav" ); break;
                    case 1: this.PlaySound( "bts_rc/weapons/pipe_hitbod2.wav" ); break;
                    case 2: this.PlaySound( "bts_rc/weapons/pipe_hitbod3.wav" ); break;
                }
            }
            else if( this.IsBrush(hit) )
            {
                switch( RandomUint(1) )
                {
                    case 0: this.PlaySound( "bts_rc/weapons/pipe_hit1.wav" ); break;
                    case 1: this.PlaySound( "bts_rc/weapons/pipe_hit2.wav" ); break;
                }
            }
        }
    }

    float Idle()
    {
        switch( RandomUint(2) )
        {
            case 0: this.PlayAnim( WeaponPipeAnim::Idle1, false ); return 2.69f;
            case 1: this.PlayAnim( WeaponPipeAnim::idle2, false ); return 5.33f;
            case 2: default: break;
        }

        this.PlayAnim( WeaponPipeAnim::idle3, false );
        return 5.33f;
    }
}
