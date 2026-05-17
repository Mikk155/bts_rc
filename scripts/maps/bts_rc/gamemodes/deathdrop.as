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

class ASDeathDropConfig : IConfigurable
{
    dictionary m_Monsters;

    const string& get_Name() override
    {
        return "deathdrop";
    }

    void Register( meta_api::json::v2::json@ json ) override
    {
        if( this.IsActive() )
        {
            array<string>@ monsters = json.Keys;
            uint size = monsters.length();

            for( uint ui = 0; ui < size; ui++ )
            {
                string monster = monsters[ui];
                meta_api::json::v2::json@ values = json.First( monster );

                uint valuesSize = values.Length();

                dictionary dropsCountLog;

                array<string> itemNames( valuesSize );

                if( g_Logger.debug.active )
                    g_Logger.debug.print( snprintf( glog, "Adding drops for \"%1\"", monster ) );

                for( uint ui2 = 0; ui2 < valuesSize; ui2++ )
                {
                    string name = string( values[ui2] );
                    itemNames[ui2] = name;

                    if( g_Logger.trace.active )
                    {
                        g_Logger.trace.print( snprintf( glog, "Adding drop \"%1\" for \"%2\"", name, monster ) );
                    }
                
                    if( g_Logger.trace.active )
                        dropsCountLog[ name ] = int(dropsCountLog[ name ]) + 1;
                }

                if( g_Logger.trace.active )
                {
                    auto dropsCountKeys = dropsCountLog.getKeys();
                    for( uint ui2 = 0; ui2 < dropsCountKeys.length(); ui2++ ) {
                        string name = dropsCountKeys[ui2];
                        g_Logger.trace.print( snprintf( glog, "\"%1\" %2 percent of droping %3.", monster, ( 100.0f / itemNames.length() ) * int( dropsCountLog[name] ), ( name.IsEmpty() ? "nothing" : name ) ) );
                    }
                }

                m_Monsters[ monster ] = itemNames;
            }
        }
    }

    CBaseEntity@ Create( CBaseMonster@ monster )
    {
        if( monster is null || !FreeEdicts( 1 ) )
            return null;

        array<string>@ drops;

        if( !gpDeathDrop.m_Monsters.get( string( monster.pev.model ), @drops ) )
            gpDeathDrop.m_Monsters.get( monster.GetClassname(), @drops );

        if( drops is null || drops.length() <= 0 )
            return null;

        string drop = drops[ Math.RandomLong( 0, drops.length() - 1 ) ];

        if( drop.IsEmpty() )
            return null;

        if( g_Logger.debug.active )
            g_Logger.debug.print( snprintf( glog, "monster \"%1\" droping %2 at %3 ", monster.GetClassname(), drop, monster.GetOrigin().ToString() ) );

        if( drop == "grenade" )
        {
            g_EntityFuncs.ShootTimed( monster.pev, monster.Center(), Vector( 0, 0, -90 ), Math.RandomFloat( 1.5, 5.5 ) );
            return null;
        }

        CBaseEntity@ item = g_EntityFuncs.Create( drop, monster.Center(), g_vecZero, false, monster.edict() );

        if( item !is null )
            item.pev.spawnflags |= 1024; // no more respawn

        return @item;
    }
}

ASDeathDropConfig gpDeathDrop;
