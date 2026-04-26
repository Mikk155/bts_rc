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

namespace env_commentary
{
    class env_commentary : ScriptBaseAnimating
    {
        string Commentary;
        string soundfile;

        void SetAnim( int animIndex )
        {
            self.pev.sequence = animIndex;
            self.pev.frame = 0;
            self.ResetSequenceInfo();
        }

        void Precache()
        {
            if( ( self.pev.spawnflags & 1 ) == 0 )
            {
                g_Game.PrecacheModel( "models/mikk/misc/devcommentary.mdl" );
                snprintf( soundfile, "sound/bts_rc/devcom/%1.mp3", self.pev.message );
                g_Game.PrecacheOther( soundfile );
                snprintf( soundfile, ";mp3 play \"%1\";\n", soundfile );
            }
        }

        void Spawn()
        {
            Precache();

            self.pev.movetype = MOVETYPE_NONE;
            self.pev.solid = SOLID_TRIGGER;

            g_EntityFuncs.SetModel( self, "models/mikk/misc/devcommentary.mdl" );
            g_EntityFuncs.SetOrigin( self, self.pev.origin );

            g_EntityFuncs.SetSize( self.pev, Vector( -12.2, -12.2, -12.2 ), Vector( 12.2, 12.2, 12.2 ) );

            SetAnim( 0 ); // set sequence to 0 aka idle

            self.pev.framerate = 1.0f;
            self.pev.framerate = 1.0f;
            self.pev.nextthink = g_Engine.time + 0.1f;
        }

        void Think()
        {
            self.StudioFrameAdvance();
            self.pev.nextthink = g_Engine.time + 0.1;
        }

        void Touch( CBaseEntity@ other )
        {
            if( other is null || !other.IsPlayer() )
                return;

            for( int i = 1; i <= g_Engine.maxClients; i++ )
            {
                auto player = g_PlayerFuncs.FindPlayerByIndex(i);

                if( player is null || !player.IsConnected() || ( player.pev.flags & FL_FROZEN ) != 0 || !self.Intersects( player ) )
                    continue;

                if( ( player.pev.button & IN_USE ) == 0 )
                {
                    g_PlayerFuncs.PrintKeyBindingString( player, "Press +use to interact.\n" );
                    continue;
                }

                // Remove the above message
                g_PlayerFuncs.PrintKeyBindingString( player, "\n" );

                // Load just in time to not carry the memory from the start
                if( Commentary.IsEmpty() )
                {
                    string filename;
                    snprintf( filename, "scripts/maps/bts_rc/devcom/%1.txt", string( self.pev.message ) );
                    auto file = g_FileSystem.OpenFile( filename, OpenFile::READ );

                    if( file is null || !file.IsOpen() )
                    {
                        snprintf( Commentary, "Could not open file \"%1\"", filename );
                    }
                    else
                    {
                        while( !file.EOFReached() )
                        {
                            string line;
                            file.ReadLine( line );
                            snprintf( Commentary, "%1%2\n", Commentary, line );
                        }
                        file.Close();
                    }
                }

                if( ( self.pev.spawnflags & 1 ) == 0 )
                {
                    NetworkMessage m( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, player.edict() );
                        m.WriteString( soundfile );
                    m.End();
                }

                g_EntityFuncs.FireTargets( self.pev.target, player, self, USE_TOGGLE, 0 );

                bool IsMotd = ( int( self.pev.frags ) == 0 );

                auto ed = player.edict();

                string motdTitle = string( self.pev.netname );

                if ( !motdTitle.IsEmpty() )
                {
                    if( IsMotd )
                    {
                        NetworkMessage m( MSG_ONE, NetworkMessages::ServerName, ed );
                            m.WriteString( motdTitle );
                        m.End();
                    }
                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "Developer commentary: " + motdTitle + "\n" );
                }

                auto length = Commentary.Length();
                string buffer;
                uint cur = 0;

                while( length > cur )
                {
                    buffer = Commentary.SubString( cur, cur + 45 > length ? length - cur : 45 );
                    cur += 45;

                    if( IsMotd )
                    {
                        NetworkMessage m( MSG_ONE, NetworkMessages::MOTD, ed );
                            m.WriteByte( buffer.Length() == 45 ? 0 : 1 );
                            m.WriteString( buffer );
                        m.End();  
                    }
                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, buffer );
                }

                // Restore the hostname
                if( IsMotd && !motdTitle.IsEmpty() )
                {
                    NetworkMessage m( MSG_ONE, NetworkMessages::ServerName, ed );
                        m.WriteString( g_EngineFuncs.CVarGetString( "hostname" ) );
                    m.End();
                }

                player.pev.flags |= FL_FROZEN;
                player.pev.flags |= FL_NOTARGET;
                player.pev.flags |= FL_GODMODE;
                player.pev.button &= ~IN_USE;

                g_Scheduler.SetTimeout( "__devcom_unlock_player__", self.pev.health, EHandle( player ), string( self.pev.noise ) );
            }
        }

        void UpdateOnRemove()
        {
            g_EntityFuncs.FireTargets( self.pev.noise1, self, self, USE_TOGGLE, 0 );
        }
    }

    bool env_commentary_register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "env_commentary::env_commentary", "env_commentary" );
        return true;
    }

    bool env_commentary_registered = env_commentary_register();
}

void __devcom_unlock_player__( EHandle entity, string target )
{
    if( !entity.IsValid() )
        return;
    
    auto player = cast<CBasePlayer@>( entity.GetEntity() );

    if( player is null )
        return;

    player.pev.flags &= ~FL_FROZEN;
    player.pev.flags &= ~FL_NOTARGET;
    player.pev.flags &= ~FL_GODMODE;

    g_EntityFuncs.FireTargets( target, player, player, USE_TOGGLE, 0 );
}
