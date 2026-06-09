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
            const auto listNames = json.Keys;
            uint size = listNames.length();

            for( uint ui = 0; ui < size; ui++ )
            {
                string listName = listNames[ui];

                array<string>@ itemNames;

                if( meta_api::json::v2::fmt::ToArray( json[ listName ], itemNames ) )
                {
                    if( g_Logger.debug.active )
                        g_Logger.debug.print( snprintf( glog, "Adding drops for \"%1\"", listName ) );
                    @m_Monsters[ listName ] = itemNames;
                }

                // Just debug
                if( g_Logger.trace.active )
                {
                    dictionary count;
                    for( uint uilog = 0; uilog < itemNames.length(); uilog++ )
                    {
                        string name = string( itemNames[uilog] );
                        count[ name ] = int( count[ name ] ) + 1;
                    }

                    auto dropsCountKeys = count.getKeys();
                    for( uint uilog = 0; uilog < dropsCountKeys.length(); uilog++ )
                    {
                        string name = dropsCountKeys[uilog];
                        g_Logger.trace.print( snprintf( glog, "\"%1\" %2 percent of droping %3.", listName, ( 100.0f / itemNames.length() ) * int( count[name] ), ( name.IsEmpty() ? "nothing" : name ) ) );
                    }
                }
            }
        }
    }

    CBaseEntity@ Create( CBaseMonster@ monster )
    {
        if( monster is null || !FreeEdicts( 1 ) )
            return null;

        auto ckv = monster.GetCustomKeyvalues().GetKeyvalue( "$_deathdrop" );

        if( !ckv.Exists() )
            return null;

        string listName = ckv.GetString();

        string drop;

        if( listName[0] == '#' )
        {
            drop = listName.SubString(1);
        }
        else
        {
            array<string>@ drops;

            if( listName.Find( '.' ) != String::INVALID_INDEX )
            {
                array<string>@ randomListName = listName.Split( '.' );
                listName = randomListName[ Math.RandomLong( 0, randomListName.length() -1 ) ];
            }

            if( !m_Monsters.get( listName, @drops ) )
            {
                if( g_Logger.warning.active )
                    g_Logger.warning.print( snprintf( glog, "monster \"%1\" couldn't retrieve list with name \"%2\" at %3", monster.GetClassname(), listName, monster.GetOrigin().ToString() ) );
                return null;
            }

            if( drops is null || drops.length() <= 0 )
                return null;

            drop = drops[ Math.RandomLong( 0, drops.length() - 1 ) ];
        }

        if( drop.IsEmpty() )
            return null;

        if( g_Logger.debug.active )
            g_Logger.debug.print( snprintf( glog, "monster \"%1\" droping %2 at %3 ", monster.GetClassname(), drop, monster.GetOrigin().ToString() ) );

        if( drop == "grenade" )
        {
            auto timed = g_EntityFuncs.ShootTimed( monster.pev, monster.Center(), Vector( 0, 0, -90 ), Math.RandomFloat( 1.5, 5.5 ) );
            return timed;
        }

        CBaseEntity@ item = g_EntityFuncs.Create( drop, monster.Center(), g_vecZero, false, monster.edict() );

        if( item !is null )
        {
            item.pev.spawnflags |= 1024; // no more respawn
        }

        return @item;
    }
}

ASDeathDropConfig gpDeathDrop;
