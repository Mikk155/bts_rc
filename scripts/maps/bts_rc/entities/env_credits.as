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

final class ASCaption
{
    string Content;

    string Target;
    float Delay;

    float __pos__ = 1.0f;

    HUDTextParams __Params__;

    // Is this a scolling caption?
    bool Scroll = false;

    HUDTextParams& get_Params()
    {
        if( this.Scroll )
        {
            this.__Params__.y = this.__pos__;
            this.__Params__.holdTime = 0.3f + this.ScrollThink;
            this.__Params__.x = -1.0f;
            this.__Params__.fadeinTime = 0.0f;
        }

        this.__Params__.r1 = this.Color.r;
        this.__Params__.g1 = this.Color.g;
        this.__Params__.b1 = this.Color.b;
        this.__Params__.a1 = this.Color.a;

        return this.__Params__;
    }

    float ScrollThink;
    float ScrollRate;

    RGBA Color(255, 255, 255, 255);
}

final class env_credits : ScriptBaseMonsterEntity
{
    private
        dictionary m_PlayersVoting;

    private
        bool m_RestartSimulation;

    private
        bool m_Intermission;

    private
        int m_TotalPlayers;

    private
        array<ASCaption> m_Credits;

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

        ASCaption@ credit = this.m_Credits[index];

        auto params = credit.Params;
        params.channel = ++index;

        g_PlayerFuncs.HudMessageAll( params, credit.Content );
        this.PrintConsole( credit.Content );

        if( index == 1 )
        {
            if( !credit.Target.IsEmpty() )
            {
                g_EntityFuncs.FireTargets( credit.Target, null, null, USE_TOGGLE, 0.0f, credit.Delay );
                credit.Target = String::EMPTY_STRING;
            }

            if( !credit.Scroll )
            {
                self.pev.frags = g_Engine.time + params.fadeinTime + params.fadeoutTime + params.holdTime;
                this.m_Credits.removeAt(0);
                return index;
            }

            this.m_ScrollRate = credit.ScrollRate;

            self.pev.frags = g_Engine.time + credit.ScrollThink;
        }

        credit.__pos__ -= this.m_ScrollRate;

        if( credit.__pos__ <= 0.0f )
            this.m_Credits.removeAt(0);

        if( credit.__pos__ < 0.7f )
            return this.PrintNext(index);

        int onScreen = index;
        while( onScreen < 4 )
        {
            HUDTextParams params;
            params.channel = ++onScreen;
            g_PlayerFuncs.HudMessageAll( params, '\n' );
        }

        return index;
    }

    private
        string m_FormatedTime;

    private
        void FormatTime( const string&in name, int number )
        {
            if( number > 0 )
            {
                this.m_FormatedTime.opAddAssign( ' ' );
                this.m_FormatedTime.opAddAssign( number );
                this.m_FormatedTime.opAddAssign( ' ' );
                this.m_FormatedTime.opAddAssign( name );

                if( number > 1 )
                    this.m_FormatedTime.opAddAssign( 's' );

                this.m_FormatedTime.opAddAssign( '.' );
            }
        }

    const string& get_FormatedTime() property
    {
        if( this.m_FormatedTime.IsEmpty() )
        {
            int days = g_DataTracker.Difference.GetDays();
            int hours = g_DataTracker.Difference.GetHours();
            int minutes = g_DataTracker.Difference.GetMinutes();
            int seconds = g_DataTracker.Difference.GetSeconds();

            if( seconds >= 60 ) { minutes++; }
            if( minutes >= 60 ) { hours++; }
            if( hours >= 24 ) { days++; }

            this.m_FormatedTime = "Simulation completed in";
            this.FormatTime( "day", days );
            this.FormatTime( "hour", hours );
            this.FormatTime( "minute", minutes );
            this.FormatTime( "second", seconds );

            this.m_FormatedTime.opAddAssign( "\nIn difficulty \"" );

            switch( Difficulty::Level() )
            {
                case Difficulty::Storymode:
                {
                    this.m_FormatedTime.opAddAssign( "Story Mode" );
                    break;
                }
                case Difficulty::Relaxed:
                {
                    this.m_FormatedTime.opAddAssign( "Relaxed" );
                    break;
                }
                case Difficulty::Medium:
                {
                    this.m_FormatedTime.opAddAssign( "Medium" );
                    break;
                }
                case Difficulty::Punished:
                {
                    this.m_FormatedTime.opAddAssign( "Punished" );
                    break;
                }
                case Difficulty::TorturedStandard:
                {
                    this.m_FormatedTime.opAddAssign( "Standard Tortured" );
                    break;
                }
                case Difficulty::TorturedLegacy:
                {
                    this.m_FormatedTime.opAddAssign( "Legacy Tortured" );
                    break;
                }
            }

            this.m_FormatedTime.opAddAssign( "\"\n" );

            if( Difficulty::HellBound() )
            {
                this.m_FormatedTime.opAddAssign( "In HellBound mode too? You have Limitless Potential\n" );
            }

            switch( Difficulty::Level() )
            {
                case Difficulty::Storymode:
                {
                    this.m_FormatedTime.opAddAssign( "There's always a first time." );
                    break;
                }
                case Difficulty::Relaxed:
                case Difficulty::Medium:
                {
                    this.m_FormatedTime.opAddAssign( "Well done!" );
                    break;
                }
                case Difficulty::Punished:
                {
                    this.m_FormatedTime.opAddAssign( "Great work!" );
                    break;
                }
                case Difficulty::TorturedStandard:
                {
                    this.m_FormatedTime.opAddAssign( "Amazing work!\nReally though?\nDamn." );
                    break;
                }
                case Difficulty::TorturedLegacy:
                {
                    this.m_FormatedTime.opAddAssign( "Unbelievable work!\nYou just join the ranked of The Tormented" );
                    break;
                }
            }

            this.m_FormatedTime.opAddAssign( '\n' );

            this.PrintConsole( this.FormatedTime );
        }
        return this.m_FormatedTime;
    }

    private
        void VoteCallback( CBasePlayer@ player, const TextMenu::v1::MenuOption@ option )
        {
            if( player !is null && option !is null )
            {
                string idx = string( player.entindex() );

                if( option.Id == 0 )
                {
                    m_PlayersVoting[ idx ] = true;
                }
                else
                {
                    m_PlayersVoting.delete( idx );
                }
            }
            g_Game.AlertMessage( at_console, "Called vote or expired!\n" );
        }

    private
        array<string> m_PrintedToConsole(0);

    void PrintConsole( string&in message )
    {
        if( this.m_PrintedToConsole.find( message ) >= 0 )
            return;

        m_PrintedToConsole.insertLast( message );

        if( !message.EndsWith( '\n' ) )
            message.opAddAssign( '\n' );

        g_PlayerFuncs.ClientPrintAll( HUD_PRINTCONSOLE, message );
    }

    private
        float m_ScrollRate;

    void Think()
    {
        if( this.m_Intermission )
        {
            if( this.m_RestartSimulation )
            {
                g_EngineFuncs.ChangeLevel( string( g_Engine.mapname ) );
            }
            else
            {
                g_EngineFuncs.ChangeLevel( g_MapCycle.GetNextMap() );
            }
            return;
        }

        self.pev.nextthink = g_Engine.time;

        if( m_Credits.length() <= 0 )
        {
            if( g_DataTracker.CurrentPlayerMessages.length() <= 0 )
            {
                self.pev.nextthink = g_Engine.time + 5.0f;

                if( !g_IsMainMap )
                {
                    g_EntityFuncs.FireTargets( self.pev.target, null, null, USE_TOGGLE, 0.0f );
                    self.pev.flags |= FL_KILLME;
                    g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Skiping level change in da test chamberrrrr\n" );
                    return;
                }

                this.m_Intermission = true;
                NetworkMessage m( MSG_ALL, NetworkMessages::SVC_INTERMISSION );
                m.End();
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

            params.y = 0.60;
            params.fadeinTime = 1.0f;
            params.holdTime = 3.0f;
            params.fadeoutTime = 1.0f;
            g_PlayerFuncs.HudMessageAll( params, message );

            float time = params.fadeinTime + params.holdTime + params.fadeoutTime + 0.5f;
            self.pev.nextthink = g_Engine.time + time;

            params.holdTime = time;
            params.channel = 2;
            params.y = 0.20;
            params.fadeinTime = 0.0f;
            params.fadeoutTime = 0.0f;
            g_PlayerFuncs.HudMessageAll( params, this.FormatedTime );

            this.PrintConsole( message );

            return;
        }

        int percent = ( this.m_TotalPlayers > 0 ? int( ( m_PlayersVoting.getSize() * 100 ) / this.m_TotalPlayers ) : 0 );
        this.m_TotalPlayers = 0;

        this.m_RestartSimulation = ( percent > 50 );

        for( int i = 1; i <= g_Engine.maxClients; i++ )
        {
            auto player = g_PlayerFuncs.FindPlayerByIndex(i);

            if( player !is null )
            {
                this.m_TotalPlayers++;

                TextMenu::v1::Menu menu;

                menu.Text
                    .ColorGray()
                    .Write( "Reset simulation? " )
                    .ColorOrange()
                    .Write( "%" );

                if( this.m_RestartSimulation )
                    menu.Text.ColorGreen();
                else
                    menu.Text.ColorRed();

                menu.Text
                    .Write( percent )
                    .ColorOrange()
                    .Write( " (" )
                    .ColorGray()
                    .Write( ( this.m_RestartSimulation ? "Restart" : "Next map" ) )
                    .ColorOrange()
                    .Write( ")" )
                .ColorGray();

                auto@ optionResetSimulation = menu.AddOption();
                auto@ optionEndSimulation = menu.AddOption();

                string idx = string( player.entindex() );

                if( m_PlayersVoting.exists( idx ) )
                {
                    optionResetSimulation.Text.ColorGreen();
                }
                else
                {
                    optionEndSimulation.Text.ColorGreen();
                }

                optionResetSimulation.Text.Write( "Yes, Restart map." ).ColorGray();
                optionEndSimulation.Text.Write( "No, Next map." ).ColorGray();

                optionResetSimulation.SetCallback( @TextMenu::v1::MenuOptionSelect( this.VoteCallback ) );
                optionEndSimulation.SetCallback( @TextMenu::v1::MenuOptionSelect( this.VoteCallback ) );

                menu.Open( player, 5 );
            }
        }

        if( self.pev.frags <= g_Engine.time )
            this.PrintNext(0);
    }

    private bool m_Thinking;

    void Use( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE useType, float value )
    {
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

        if( this.m_Thinking )
        {
            if( !g_IsMainMap )
            {
                g_EntityFuncs.FireTargets( self.pev.target, null, null, USE_TOGGLE, 0.0f );
                self.pev.flags |= FL_KILLME;
                g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Killed credits, activate again\n" );
                return;
            }
            return;
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

        dictionary json;
        if( !meta_api::json::v1::Deserialize( "bts_rc/credits.json", json ) )
        {
            g_Logger.critical.print( "Could not open bts_rc/credits.json" );
            int[]a(0);a[1];
        }

        float fadeTime = float( json[ "fadetime" ] );

        dictionary@ captions = cast<dictionary@>( json[ "captions" ] );
        const uint length = captions.getSize();

        ASCaption caption;

        for( uint ui = 0; ui < length; ui++ )
        {
            dictionary@ config = cast<dictionary@>( captions[ string( ui ) ] );

            caption.Target = string( config[ "target" ] );
            caption.Content = string( config[ "message" ] );
            caption.Delay = float( config[ "delay" ] );

            dictionary@ rgb;
            if( config.get( "rgb", @rgb ) )
            {
                caption.Color.r = int( rgb[0] );
                caption.Color.g = int( rgb[1] );
                caption.Color.b = int( rgb[2] );
            }

            if( config.exists( "scroll" ) )
                caption.Scroll = bool( config[ "scroll" ] );

            if( config.exists( "scroll_think" ) )
                caption.ScrollThink = float( config[ "scroll_think" ] );

            if( config.exists( "scroll_rate" ) )
                caption.ScrollRate = float( config[ "scroll_rate" ] );

            if( !caption.Scroll )
            {
                if( config.exists( "x" ) )
                    caption.__Params__.x = float( config[ "x" ] );

                if( config.exists( "y" ) )
                    caption.__Params__.y = float( config[ "y" ] );

                if( config.exists( "fadeintime" ) )
                    caption.__Params__.fadeinTime = float( config[ "fadeintime" ] );

                if( config.exists( "fadeouttime" ) )
                    caption.__Params__.fadeoutTime = float( config[ "fadeouttime" ] );

                if( config.exists( "holdtime" ) )
                    caption.__Params__.holdTime = float( config[ "holdtime" ] );

                if( config.exists( "fxtime" ) )
                    caption.__Params__.fxTime = float( config[ "fxtime" ] );

                if( config.exists( "effect" ) )
                    caption.__Params__.effect = int( config[ "effect" ] );

                if( config.get( "rgb2", @rgb ) )
                {
                    caption.__Params__.r2 = int( rgb[0] );
                    caption.__Params__.g2 = int( rgb[1] );
                    caption.__Params__.b2 = int( rgb[2] );
                }
            }

            this.m_Credits.insertLast( caption );

            if( g_Logger.trace.active )
            {
                g_EngineFuncs.ServerPrint( "ASCaption\n{\n" );
                g_EngineFuncs.ServerPrint( "\tIndex = " + ui + "\n" );
                string printCopy = caption.Content.Replace( '\n', "\\n" );

                g_EngineFuncs.ServerPrint( "\tContent = \"" );
                while( printCopy.Length() > 0 )
                {
                    g_EngineFuncs.ServerPrint( printCopy.SubString( 0, 64 ) );
                    if( printCopy.Length() < 64 )
                        break;
                    printCopy = printCopy.SubString( 64 );
                }
                g_EngineFuncs.ServerPrint( "\"\n" );
                g_EngineFuncs.ServerPrint( "\tRed = " + caption.Color.r + "\n" );
                g_EngineFuncs.ServerPrint( "\tGreen = " + caption.Color.g + "\n" );
                g_EngineFuncs.ServerPrint( "\tBlue = " + caption.Color.b + "\n" );

                if( !caption.Target.IsEmpty() )
                {
                    g_EngineFuncs.ServerPrint( "\tTarget = " + caption.Target + "\n" );

                    if( caption.Delay > 0.0f )
                        g_EngineFuncs.ServerPrint( "\tDelay = " + caption.Delay + "\n" );
                }

                if( caption.Scroll )
                {
                    g_EngineFuncs.ServerPrint( "\tScroll = " + ( caption.Scroll ? "true" : "false" ) + "\n" );
                    g_EngineFuncs.ServerPrint( "\tScrollThink = " + caption.ScrollThink + "\n" );
                    g_EngineFuncs.ServerPrint( "\tScrollRate = " + caption.ScrollRate + "\n" );
                }
                else
                {
                    g_EngineFuncs.ServerPrint( "\tParams.x = " + caption.__Params__.x + " (Not scroll)\n" );
                    g_EngineFuncs.ServerPrint( "\tParams.y = " + caption.__Params__.y + " (Not scroll)\n" );
                    g_EngineFuncs.ServerPrint( "\tParams.fadeinTime = " + caption.__Params__.fadeinTime + " (Not scroll)\n" );
                    g_EngineFuncs.ServerPrint( "\tParams.fadeoutTime = " + caption.__Params__.fadeoutTime + " (Not scroll)\n" );
                    g_EngineFuncs.ServerPrint( "\tParams.holdTime = " + caption.__Params__.holdTime + " (Not scroll)\n" );
                    g_EngineFuncs.ServerPrint( "\tParams.fxTime = " + caption.__Params__.fxTime + " (Not scroll)\n" );
                    g_EngineFuncs.ServerPrint( "\tParams.effect = " + caption.__Params__.effect + " (Not scroll)\n" );
                    g_EngineFuncs.ServerPrint( "\tParams.r2 = " + caption.__Params__.r2 + " (Not scroll)\n" );
                    g_EngineFuncs.ServerPrint( "\tParams.g2 = " + caption.__Params__.g2 + " (Not scroll)\n" );
                    g_EngineFuncs.ServerPrint( "\tParams.b2 = " + caption.__Params__.b2 + " (Not scroll)\n" );
                }

                g_EngineFuncs.ServerPrint( "}\n" );
            }
        }

        this.Fade( fadeTime );

        self.pev.message = string_t( string( json[ "target" ] ) );
        g_EntityFuncs.FireTargets( string( self.pev.message ), self, self, USE_TOGGLE, 0.0f, float( json[ "delay" ] ) );

        self.pev.nextthink = g_Engine.time + ( fadeTime * 2 );

        this.m_Thinking = true;
    }

    void Fade( float time, bool firstCall = true )
    {
        if( firstCall )
        {
//            g_EntityFuncs.FireTargets( string( self.pev.message ), self, self, USE_TOGGLE, 0.0f );
            g_Scheduler.SetTimeout( @this, "Fade", time, time, false );
            g_PlayerFuncs.ScreenFadeAll( g_vecZero, time, 1.0f, 255, FFADE_OUT );
        }
        else
        {
            g_PlayerFuncs.ScreenFadeAll( g_vecZero, time, 1.0f, 255, FFADE_IN );
        }
    }
}
