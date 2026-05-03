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

namespace deathdrop
{
    class CConfig : IConfigContext
    {
        dictionary m_Monsters;

        CConfig()
        {
            ConfigContext::Register( this );
        }

        const string& get_Name() override {
            return "deathdrop";
        }

        void Parse( dictionary@ json )
        {
            array<string>@ monsters = json.getKeys();
            uint size = monsters.length();

            for( uint ui = 0; ui < size; ui++ )
            {
                string monster = monsters[ui];
                dictionary values = cast<dictionary@>( json[ monster ] );

                uint valuesSize = values.getSize();

                array<string> itemNames( valuesSize );

                for( uint ui2 = 0; ui2 < valuesSize; ui2++ )
                {
                    itemNames[ui2] = string( values[ui2] );

                    if( g_Logger.info )
                        g_Logger.info = snprintf( glog, "Adding drop \"%1\" for \"%2\"", itemNames[ui2], monster );
                }

                if( g_Logger.info )
                    g_Logger.info = snprintf( glog, "Drops for \"%1\" with %2 percent chance for each.", monster, 100.0f / itemNames.length() );

                m_Monsters[ monster ] = itemNames;
            }
        }
    }

    CConfig gpConfig;

    void MonsterKilled( CBaseMonster@ monster, CBaseEntity@ attacker, int gib )
    {
        if( monster is null || !FreeEdicts( 1 ) )
            return;

        array<string>@ drops;

        if( !gpConfig.m_Monsters.get( string( monster.pev.model ), @drops ) )
            gpConfig.m_Monsters.get( monster.GetClassname(), @drops );

        if( drops is null || drops.length() <= 0 )
            return;

        string drop = drops[ Math.RandomLong( 0, drops.length() - 1 ) ];

        if( drop.IsEmpty() )
            return;

        if( g_Logger.trace )
            g_Logger.trace = snprintf( glog, "monster \"%1\" droping %2 at %3 ", monster.GetClassname(), drop, monster.GetOrigin().ToString() );

        if( drop == "grenade" )
        {
            g_EntityFuncs.ShootTimed( monster.pev, monster.Center(), Vector( 0, 0, -90 ), Math.RandomFloat( 1.5, 5.5 ) );
            return;
        }

        CBaseEntity@ item = g_EntityFuncs.Create( drop, monster.Center(), g_vecZero, false, monster.edict() );

        if( item !is null )
            item.pev.spawnflags |= 1024; // no more respawn
    }
}
