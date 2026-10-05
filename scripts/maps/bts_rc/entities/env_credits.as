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

const bool Reg_env_credits = CustomEntity( "env_credits", true );

final class ASCredit
{
    string Content;

    float Speed;

    float __pos__ = 1.0f;

    private
        HUDTextParams __Params__;

    HUDTextParams& get_Params()
    {
        this.__Params__.y = this.__pos__;
        this.__Params__.r1 = this.Color.r;
        this.__Params__.g1 = this.Color.g;
        this.__Params__.b1 = this.Color.b;
        this.__Params__.a1 = this.Color.a;
        this.__Params__.holdTime = 0.3f;
        this.__Params__.x = -1.0f;
        this.__Params__.fadeinTime = 0.0f;

        return this.__Params__;
    }

    RGBA Color(255, 255, 255, 255);
}

final class env_credits : ScriptBaseMonsterEntity
{
    private
        array<ASCredit> m_Credits;

    void Spawn()
    {
        self.pev.solid = SOLID_NOT;
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.effects |= EF_NODRAW;
    }

    int PrintNext( uint index )
    {
        if( index >= 4 || m_Credits.length() <= index )
            return index;

        ASCredit@ credit = this.m_Credits[index];
        ++index;

        auto params = credit.Params;
        params.channel = index ;

        g_PlayerFuncs.HudMessageAll( params, credit.Content );

        credit.__pos__ -= 0.005f;

        if( credit.__pos__ <= 0.0f )
            this.m_Credits.removeAt(0);

        if( credit.__pos__ < 0.7f )
            return this.PrintNext(index);

        return index;
    }

    void Think()
    {
        if( m_Credits.length() <= 0 )
        {
            if( g_DataTracker.CurrentPlayerMessages.length() <= 0 )
            {
                g_EntityFuncs.FireTargets( self.pev.target, null, null, USE_TOGGLE, 0.0f );
                self.pev.flags |= FL_KILLME;
                return;
            }

            string message = g_DataTracker.CurrentPlayerMessages[0];
            g_DataTracker.CurrentPlayerMessages.removeAt(0);

            HUDTextParams params;
            params.channel = 1;
            params.x = -1;
            params.r1 = 255;
            params.g1 = 0;
            params.b1 = 0;

            params.y = 0.40;
            params.fadeinTime = 1.0f;
            params.holdTime = 3.0f;
            params.fadeoutTime = 1.0f;
            g_PlayerFuncs.HudMessageAll( params, message );

            self.pev.nextthink = g_Engine.time + params.fadeinTime + params.holdTime + params.fadeoutTime + 0.5f;

            params.channel = 2;
            params.y = 0.30;
            params.fadeinTime = 0.0f;
            params.holdTime = self.pev.nextthink;
            params.fadeoutTime = 0.0f;
            g_PlayerFuncs.HudMessageAll( params, "Simulation completed in " + g_DataTracker.FormatedTime );

            return;
        }

        int onScreen = this.PrintNext(0);

        while( onScreen < 4 )
        {
            HUDTextParams params;
            params.channel = ++onScreen;
            g_PlayerFuncs.HudMessageAll( params, '\n' );
        }

        self.pev.nextthink = g_Engine.time + 0.01f;
    }

    private bool m_Thinking;

    void Use( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE useType, float value )
    {
        // Test points only
        if( true )
        {
            g_DataTracker.Stop();
            self.pev.nextthink = g_Engine.time + 2.0f;
            return;
        }

        if( this.m_Thinking )
            return;

        if( !g_IsMainMap )
        {
            CBasePlayer@ player;

            if( activator is null || !activator.IsPlayer() || ( @player = cast<CBasePlayer@>( activator ) ) is null )
                return;

            if( g_PlayerFuncs.AdminLevel( player ) < AdminLevel_t::ADMIN_YES )
            {
                g_PlayerFuncs.ClientPrint( player, HUD_PRINTTALK, "Only administrators can fire this entity.\n" );
                return;
            }
        }

        g_DataTracker.Stop();

        string creditsPath = "scripts/maps/bts_rc/credits.txt";

        File@ fStream = g_FileSystem.OpenFile( creditsPath, OpenFile::READ );

        if( fStream is null || !fStream.IsOpen() )
        {
            g_Logger.critical.print("Could not open {}", { creditsPath } );
            int[]a(0);a[1];
        }

        if( g_Logger.info.active )
            g_Logger.info.print("Parsing credits file..." );

        ASCredit credit;

        while( !fStream.EOFReached() )
        {
            string line;
            fStream.ReadLine( line );

            if( line.StartsWith( "//" ) )
            {
                continue;
            }
#if FALSE
            else if( line.StartsWith( "$br" ) )
            {
                this.m_Credits.insertLast( credit );
                credit.Content = String::EMPTY_STRING;
            }
#endif
            else if( line.StartsWith( "$rgb" ) )
            {
                array<string>@ rgb = line.SubString( 5 ).Split( ' ' );

                if( rgb.length() > 0 )
                    credit.Color.r = atoi( rgb[0] );
                if( rgb.length() > 1 )
                    credit.Color.g = atoi( rgb[1] );
                if( rgb.length() > 2 )
                    credit.Color.b = atoi( rgb[2] );
            }
            else if( line.StartsWith( "$r" ) )
            {
                credit.Color.r = atoi( line.SubString( 3 ) );
            }
            else if( line.StartsWith( "$g" ) )
            {
                credit.Color.g = atoi( line.SubString( 3 ) );
            }
            else if( line.StartsWith( "$b" ) )
            {
                credit.Color.b = atoi( line.SubString( 3 ) );
            }
            else if( line.StartsWith( "$t" ) )
            {
                credit.Speed = atof( line.SubString( 3 ) );
            }
            else
            {
                if( line.IsEmpty() )
                {
#if FALSE
                    line = '\n';
#endif
                    continue;
                }

                credit.Content = line;
#if FALSE
                credit.Content.opAddAssign( line );
                credit.Content.opAddAssign( '\n' );
#endif
                this.m_Credits.insertLast( credit );
            }

            credit.Speed = Math.clamp( 0.1f, 1.0f, credit.Speed );
        }

#if FALSE
        if( credit.Content != String::EMPTY_STRING )
            this.m_Credits.insertLast( credit );
#endif

        fStream.Close();

        this.Fade( 2.0f );

        self.pev.nextthink = g_Engine.time + 2.0f;

        this.m_Thinking = true;
    }

    void Fade( float time, bool firstCall = true )
    {
        if( firstCall )
        {
            g_Scheduler.SetTimeout( @this, "Fade", time, time, false );
            g_PlayerFuncs.ScreenFadeAll( g_vecZero, time, 1.0f, 255, FFADE_OUT );
        }
        else
        {
            g_PlayerFuncs.ScreenFadeAll( g_vecZero, time, 1.0f, 255, FFADE_IN );
        }
    }
}
