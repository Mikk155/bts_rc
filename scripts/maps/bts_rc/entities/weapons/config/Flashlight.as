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

namespace Flashlight
{
    float flashlight_drain;
    int flashlight_capacity;
    int flashlight_ammount;

    void Register( meta_api::json::v2::json@ json )
    {
        flashlight_drain = Math.max( 0.1f, json.FirstOrDefault( "flashlight_drain", 0.4f ) );
        flashlight_capacity = Math.max( 0, json.FirstOrDefault( "flashlight_capacity", 10 ) );
        flashlight_ammount = Math.max( 10, json.FirstOrDefault( "flashlight_ammount", 100 ) );
    }

    int ammoIndex;

    void Precache()
    {
        ammoIndex = g_PlayerFuncs.GetAmmoIndex( "bts:battery" );
    }

    int GetClip( CBasePlayer@ player, CBasePlayerWeapon@ weapon )
    {
        dictionary@ data = player.GetUserData();
        const string classname = weapon.GetClassname();

        int Battery;
        if( !data.get( classname, Battery ) )
        {
            Battery = Math.RandomLong( 0, flashlight_ammount );
            data[ classname ] = Battery;
        }

        return Battery;
    }

    // Call on holstering, turns off flashlight and cancels any reload
    void Holster( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character )
    {
        if( player.FlashlightIsOn() )
            player.FlashlightTurnOff();

        if( weapon.m_fInReload )
        {
            g_SoundSystem.StopSound( player.edict(), CHAN_WEAPON, "bts_rc/items/battery_reload.wav" );

            dictionary@ data = player.GetUserData();
            data[ weapon.GetClassname() ] = flashlight_ammount;
            weapon.m_fInReload = false;
            data.delete( "flashlight_reload" );
        }
    }

    enum State
    {
        TurnedOff = 0,
        TurnedOn,
        Reloading,
        NoAmmo
    };

    /// Call to turn on or off the flashlight, reload if needed and possible. time is the reload time
    State Toggle( CBasePlayer@ player, CBasePlayerWeapon@ weapon, float time )
    {
        if( player.FlashlightIsOn() )
        {
            player.FlashlightTurnOff();
            return State::TurnedOff;
        }

        int Battery = GetClip( player, weapon );

        if( Battery <= 0 )
        {
            if( Reload( player, weapon, time ) )
                return State::Reloading;
            return State::NoAmmo;
        }

        player.FlashlightTurnOn();

        return State::TurnedOn;
    }

    void Think( CBasePlayer@ player, CBasePlayerWeapon@ weapon, CCharacter@ character, ASWeaponConfig@ config, const string&in flashlight_model )
    {
        const string classname = weapon.GetClassname();

        dictionary@ data = player.GetUserData();

        float reloadTime;
        if( data.get( "flashlight_reload", reloadTime ) )
        {
            if( reloadTime > g_Engine.time )
            {
                player.pev.weaponmodel = config.player_model;
                player.m_iFlashBattery = 0;
                player.m_iHideHUD &= ~HideHUDFlags::HIDEHUD_FLASHLIGHT;
                return;
            }

            g_SoundSystem.StopSound( player.edict(), CHAN_WEAPON, "bts_rc/items/battery_reload.wav" );

            int ammoCount = player.m_rgAmmo( ammoIndex );

            weapon.m_fInReload = false;
            data[ classname ] = flashlight_ammount;
            player.m_rgAmmo( ammoIndex, ammoCount - 1 );
            data.delete( "flashlight_reload" );
        }

        player.pev.weaponmodel = flashlight_model;

        int Battery = GetClip( player, weapon );

        if( player.FlashlightIsOn() )
        {
            float nextDrain = float( data[ "flashlight_nextdrain" ] );

            if( nextDrain <= g_Engine.time )
            {
                data[ "flashlight_nextdrain" ] = g_Engine.time + flashlight_drain;

                Battery--;

                if( Battery <= 0 )
                {
                    Battery = 0;
                    player.FlashlightTurnOff();
                }
            }
        }
        else
        {
            player.pev.weaponmodel = config.player_model;
        }

        // Normalize to a percentaje 0-100 so flashlight_ammount can be anything else than 100.
        data[ classname ] = Battery;
        player.m_iFlashBattery = int( ( Battery * 100.0f ) / flashlight_ammount + 0.5f );

        player.m_iHideHUD &= ~HideHUDFlags::HIDEHUD_FLASHLIGHT;
    }

    bool HasClip( CBasePlayer@ player, CBasePlayerWeapon@ weapon )
    {
        return ( GetClip( player, weapon ) > 0 );
    }

    bool HasFullClip( CBasePlayer@ player, CBasePlayerWeapon@ weapon )
    {
        return ( GetClip( player, weapon ) >= flashlight_ammount );
    }

    bool HasReserves( CBasePlayer@ player )
    {
        return ( player.m_rgAmmo( ammoIndex ) > 0 );
    }

    bool HasAnyReserve( CBasePlayer@ player, CBasePlayerWeapon@ weapon )
    {
        return ( HasClip( player, weapon ) || HasReserves( player ) );
    }

    /// Return whatever we have ammo or not.
    /// Will start reloading if needed.
    /// The reload will be completed after the given "time" if the player didn't swap weapon during that time.
    bool Reload( CBasePlayer@ player, CBasePlayerWeapon@ weapon, float time )
    {
        if( HasFullClip( player, weapon ) )
            return true;

        if( !HasReserves( player ))
        {
            g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "hlclassic/weapons/357_cock1.wav", 0.8f, ATTN_NORM, 0, PITCH_NORM );
            return false;
        }

        if( player.FlashlightIsOn() )
            player.FlashlightTurnOff();

        g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "bts_rc/items/battery_reload.wav", 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

        weapons::SetCooldown( weapon, player, time );
        weapon.m_fInReload = true;
        player.GetUserData()[ "flashlight_reload" ] = weapon.m_flNextPrimaryAttack;

        return true;
    }
}
