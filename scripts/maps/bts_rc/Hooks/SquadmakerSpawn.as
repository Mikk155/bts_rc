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

namespace Hooks
{
void SquadmakerSpawn( CBaseMonster@ squad, CBaseEntity@ entity )
{
    if( entity is null )
        return;

    string classname = entity.GetClassname();

    auto ckv = squad.GetCustomKeyvalues();

    CBaseMonster@ monster = null;

    if( entity.IsMonster() )
        @monster = cast<CBaseMonster@>(entity);

    uint length = gpEntityOverriden.length();

    for( uint ui = 0; ui < length; ui++ )
    {
        EntityOverriden@ overrider = gpEntityOverriden[ui];

        if( overrider !is null )
            overrider.AddEntity( entity.entindex(), entity, ckv, monster );
    }

    // Swap a specific squadmaker to a random location.
    if( ckv.GetKeyvalue( "$i_randomize_squad" ).GetInteger() == 1 )
    {
        if( squad !is null || !g_EntityFuncs.IsValidEntity( squad.pev.owner ) )
        {
            if( g_Logger.error )
                g_Logger.error = snprintf( glog, "Failed to swap squad at %1 Null squadmaker", entity.pev.origin.ToString() );
            return;
        }

        CBaseEntity@ owner_spot = g_EntityFuncs.Instance( squad.pev.owner );

        if( owner_spot is null )
        {
            if( g_Logger.error )
                g_Logger.error = snprintf( glog, "Failed to swap squad at %1 Null squadmaker's owner (randomizer entity)", entity.pev.origin.ToString() );
            return;
        }

        owner_spot.Use( null, null, USE_TOGGLE ); // Do not change USE_TYPE input.
    }
}
}