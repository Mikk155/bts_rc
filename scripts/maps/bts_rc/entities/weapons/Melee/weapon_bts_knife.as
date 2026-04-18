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
*   Credits: SamVanheer and the collaborators of
*   https://github.com/twhl-community/halflife-unified-sdk
*   https://github.com/twhl-community/halflife-op4-updated
*   Credit to KernCore for secondary attack functions
*   Rewrited by Rizulix for bts_rc (january 2025)
*   Rewrited by mikk 16/4/26
*/

enum WeaponKnifeAnim
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
    Charge,
    Stab
};

class CWeaponKnifeConfig : ASMeleeWeaponConfig
{
    string GetName() override
    {
        return "weapon_bts_knife";
    }

    const string& get_player_model() override {
        return "models/opfor/p_knife.mdl";
    }

    const string& get_world_model() override {
        return "models/opfor/w_knife.mdl";
    }

    const string& get_view_model() override {
        return "models/bts_rc/weapons/v_knife.mdl";
    }

    const string& get_animation_extension() override {
        return "crowbar";
    }

    uint8 get_animation_draw() override {
        return WeaponKnifeAnim::Draw;
    }

    uint8 get_hands_group() override {
        return 0;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "weapons/knife1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/knife2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/knife3.wav" );
        g_SoundSystem.PrecacheSound( "weapons/knife_hit_wall1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/knife_hit_wall2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/knife_hit_flesh1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/knife_hit_flesh2.wav" );
        ASMeleeWeaponConfig::Precache();
    }
}

CWeaponKnifeConfig gpWeaponKnifeConfig;

class weapon_bts_knife : BTS_MeleeCharge
{
    ASWeaponConfig@ get_config() {
        return @gpWeaponKnifeConfig;
    }

    float Idle()
    {
        switch( RandomUint(2) )
        {
            case 0: this.PlayAnim( WeaponKnifeAnim::Idle1, false ); return 2.69f;
            case 1: this.PlayAnim( WeaponKnifeAnim::Idle2, false ); return 5.33f;
        }

        this.PlayAnim( WeaponKnifeAnim::Idle3, false );
        return 5.33f;
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
                        case 0: this.PlayAnim( WeaponKnifeAnim::Attack1Miss ); break;
                        case 1: this.PlayAnim( WeaponKnifeAnim::Attack2Miss ); break;
                        case 2: this.PlayAnim( WeaponKnifeAnim::Attack3Miss ); break;
                    }
                }
                else
                {
                    switch( RandomUint(2) )
                    {
                        case 0: this.PlayAnim( WeaponKnifeAnim::Attack1Hit ); break;
                        case 1: this.PlayAnim( WeaponKnifeAnim::Attack2Hit ); break;
                        case 2: this.PlayAnim( WeaponKnifeAnim::Attack3Hit ); break;
                    }
                }
                break;
            }
            case AttackType::Secondary:
            {
                // We just started charging
                if( m_WhackState == WhackState::Holding )
                {
                    this.PlayAnim( WeaponKnifeAnim::Charge );
                    return;
                }
                miss = this.Hit( tr, AttackType::Secondary, hit );
                this.PlayAnim( WeaponKnifeAnim::Stab );
                break;
            }
            case AttackType::Tertriary:
            {
                return;
            }
        }

        this.SetCooldown( is_trained_personal, miss, type );

        if( miss )
        {
            switch( RandomUint(2) )
            {
                case 0: this.PlaySound( "weapons/knife1.wav" ); break;
                case 1: this.PlaySound( "weapons/knife2.wav" ); break;
                case 2: this.PlaySound( "weapons/knife3.wav" ); break;
            }
        }
        else
        {
            TraceEffects( tr, Bullet::BULLET_PLAYER_CROWBAR );

            if( this.IsFlesh(hit) )
            {
                switch( RandomUint(1) )
                {
                    case 0: this.PlaySound( "weapons/knife_hit_flesh1.wav" ); break;
                    case 1: this.PlaySound( "weapons/knife_hit_flesh2.wav" ); break;
                }
            }
            else if( this.IsBrush(hit) )
            {
                switch( RandomUint(1) )
                {
                    case 0: this.PlaySound( "weapons/knife_hit_wall1.wav" ); break;
                    case 1: this.PlaySound( "weapons/knife_hit_wall2.wav" ); break;
                }
            }
        }
    }
}
