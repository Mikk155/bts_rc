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

    const string& get_player_model() override {
        return "models/hlclassic/p_crowbar.mdl";
    }

    const string& get_animation_extension() override {
        return "crowbar";
    }

    const uint8 get_hands_group() override {
        return 0;
    }

    void Precache() override
    {
        g_SoundSystem.PrecacheSound( "bts_rc/weapons/cbar_draw.wav" );
        ASMeleeWeaponConfig::Precache();
    }

    void WeaponDeploy( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        g_SoundSystem.EmitSoundDyn( weapon.edict(), CHAN_WEAPON, "bts_rc/weapons/cbar_draw.wav", 1.0f, ATTN_NONE );
        weapons::Deploy( weapon, player, gpWeaponCrowbarConfig );
    }

    void WeaponPrimaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        TraceResult tr;
        float prevCooldown = weapon.m_flNextPrimaryAttack;
        weapon.PrimaryAttack();
        weapon.m_flNextPrimaryAttack = prevCooldown;

        bool miss = weapons::Hit( weapon, player, tr, AttackType::Primary, void, gpWeaponCrowbarConfig );

        if( !miss )
            weapons::TraceEffects( weapon, player, gpWeaponCrowbarConfig, tr, Bullet::BULLET_PLAYER_CROWBAR );

        weapons::SetCooldown( weapon, player, gpWeaponCrowbarConfig.GetCooldown( util::IsTrainedPersonal(player), AttackType::Primary, miss ) );
    }

    void WeaponSecondaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        TraceResult tr;
        float prevCooldown = weapon.m_flNextSecondaryAttack;
        weapon.PrimaryAttack();
        weapon.m_flNextSecondaryAttack = weapon.m_flNextPrimaryAttack = prevCooldown;

        bool miss = weapons::Hit( weapon, player, tr, AttackType::Secondary, void, gpWeaponCrowbarConfig, true );

        if( miss )
        {
            switch( RandomUint( 2, player ) )
            {
                case 0: weapon.SendWeaponAnim( WeaponCrowbarAnim::ShoveMiss, 0, weapon.pev.body ); break;
                case 1: weapon.SendWeaponAnim( WeaponCrowbarAnim::ShoveAltMiss, 0, weapon.pev.body ); break;
                case 2: weapon.SendWeaponAnim( WeaponCrowbarAnim::ShoveMiss, 0, weapon.pev.body ); break;
            }
        }
        else
        {
            switch( RandomUint( 2, player ) )
            {
                case 0: weapon.SendWeaponAnim( WeaponCrowbarAnim::Shove, 0, weapon.pev.body ); break;
                case 1: weapon.SendWeaponAnim( WeaponCrowbarAnim::ShoveAlt, 0, weapon.pev.body ); break;
                case 2: weapon.SendWeaponAnim( WeaponCrowbarAnim::Shove, 0, weapon.pev.body ); break;
            }

            weapons::TraceEffects( weapon, player, gpWeaponCrowbarConfig, tr, Bullet::BULLET_PLAYER_CROWBAR );
        }

        weapons::SetCooldown( weapon, player, gpWeaponCrowbarConfig.GetCooldown( util::IsTrainedPersonal( player ), AttackType::Secondary, miss ) );
    }

    void WeaponTertiaryAttack( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character ) override
    {
        weapon.GetUserData()[ "thrown" ] = true;
        weapon.TertiaryAttack();
    }

    void Parse( dictionary@ json ) override
    {
        ASMeleeWeaponConfig::Parse( json );

        g_Hooks.RegisterHook( Hooks::Monster::MonsterTakeDamage,
        MonsterTakeDamageHook( function( DamageInfo@ info )
        {
            if( info.pInflictor !is null && info.pAttacker !is null && ( info.bitsDamageType & DMG_BTS_WEAPON ) == 0 )
            {
                dictionary@ data = info.pInflictor.GetUserData();
                
                if( bool( data[ "thrown" ] ) )
                {
                    data[ "thrown" ] = false;
                    info.flDamage = gpWeaponCrowbarConfig.tertiary_damage;
                    int lastHitgroup = g_Engine.trace_hitgroup;
                    Vector endPos = g_Engine.trace_endpos;
                    TraceResult tr; // Effects
                    g_Utility.TraceLine( info.pInflictor.pev.origin, info.pInflictor.pev.origin, dont_ignore_monsters, info.pInflictor.edict(), tr );
                    tr.vecEndPos = endPos;
                    @tr.pHit = info.pVictim.edict();
                    //tr.iHitgroup = cast<CBaseMonster@>( info.pVictim ).m_LastHitGroup;
                    tr.iHitgroup = lastHitgroup;
                    weapons::TraceEffects( null, null, gpWeaponCrowbarConfig, tr, Bullet::BULLET_PLAYER_CROWBAR );
                }
            }
            return HOOK_CONTINUE;
        } ) );
    }
}

CWeaponCrowbarConfig gpWeaponCrowbarConfig;
