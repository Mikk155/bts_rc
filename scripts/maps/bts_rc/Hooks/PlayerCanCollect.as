/**
*   Copyright (c) 2026 Mikk155 and contributors of bts_rc
*
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software to use, copy, modify, merge, publish, distribute, sublicense,
*   and/or sell copies of the Software under the following conditions:
*
*   A reference to the original project must be included in all copies or substantial
*   portions of the Software. This must include, at minimum, a URL to:
*   https://github.com/Mikk155/bts_rc
*
*   The above copyright notice and this permission notice shall be included in all
*   copies of the Software when distributed as a whole.
*
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
**/

namespace Hooks
{
    HookReturnCode PlayerCanCollect( CBaseEntity@ pickup, CBaseEntity@ other, bool &out result )
    {
        CBasePlayer@ player;

        if( pickup is null || other is null || !other.IsPlayer() || ( @player = cast<CBasePlayer@>( other ) ) is null )
            return HOOK_CONTINUE;

        string classname = pickup.GetClassname();
        dictionary@ data = player.GetUserData();

        if( classname.StartsWith( "weapon_" ) )
        {
            CBasePlayerWeapon@ weapon = cast<CBasePlayerWeapon@>(pickup);

            if( weapon !is null )
            {
                ASWeaponConfig@ weaponConfig = cast<ASWeaponConfig@>( g_WeaponsConfig.Interfaces[ classname ] );

                if( weaponConfig !is null )
                {
                    if( ( weapon.pev.flags & EdictFlags::FL_ONGROUND ) != 0 && string( weapon.pev.targetname ).IsEmpty() )
                    {
                        string message;
                        bool canPickup = false;

                        if( float( data[ "pickup_current_frame" ] ) != g_Engine.time )
                        {
                            message = "\n";
                            data[ "pickup_current_frame" ] = g_Engine.time;

                            if( bool( data[ "pickup_button_released" ] ) && util::IsFacing( player, weapon, 0.8f ) )
                            {
                                if( ( player.pev.button & IN_USE ) == 0 )
                                {
                                    snprintf( message, "+use Pickup %1\n", weaponConfig.name );
                                }
                                else
                                {
                                    canPickup = true;
                                }
                            }

                            data[ "pickup_button_released" ] = ( ( player.pev.button & IN_USE ) == 0 );
                        }

                        if( !message.IsEmpty() )
                        {
                            g_PlayerFuncs.PrintKeyBindingString( player, message );
                        }

                        if( !canPickup )
                        {
                            result = false;
                            return HOOK_CONTINUE;
                        }
                    }
                }
            }
            else if( classname == "weapon_shockrifle" )
            {
                result = false;

                if( gpGameVersion == 526 )
                {
                    CBaseEntity@ roach = g_EntityFuncs.FindEntityInSphere( null, player.pev.origin, 512, "monster_shockroach", "classname" );

                    if( roach !is null )
                    {
                        auto newRoach = g_EntityFuncs.Create( "monster_shockroach", roach.pev.origin, roach.pev.angles, false, null );

                        if( newRoach !is null )
                        {
                            newRoach.Killed( player.pev, GIB_NEVER );
                        }
                    }
                }

                return HOOK_CONTINUE;
            }
        }

        if( !gpDynamicEquipment.PlayerCanCollect( player, pickup ) )
        {
            result = false;
            return HOOK_CONTINUE;
        }

        return HOOK_CONTINUE;
    }
}
