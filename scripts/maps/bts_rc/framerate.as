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

#include "../../mikk155/Server/Framerate"

int g_AvgAccumulator = 0;
int g_AvgSamples = 0;
int g_LastAverage = 0;
Server::Framerate::FrameRateCallback@ cb = Server::Framerate::SetCallback( function( const ServerFramerate@ data )
{
    if( data.LastFrame )
    {
        g_AvgAccumulator += data.Frames;
        g_AvgSamples++;

        if( g_AvgSamples >= 10 )
        {
            g_LastAverage = int( g_AvgAccumulator / g_AvgSamples );
            g_AvgAccumulator = 0;
            g_AvgSamples = 0;
        }
    }

    HUDTextParams params;
    params.holdTime = 1.0f;
    params.fadeinTime = 0.0f;
    params.r1 = 255;
    params.g1 = params.b1 = 0;
    params.y = 0.3;
    params.x = 0.0;

    string buffer;
    snprintf( buffer, "time: %1\nframes last second: %2\nframes this second: %3\nCurrent framerate: %4\nAverage framerate: %5\n",
        int(g_Engine.time), data.Frames, data.Count, data.Current, g_LastAverage );

    for( int i = 1; i <= g_Engine.maxClients; i++ )
    {
        auto player = g_PlayerFuncs.FindPlayerByIndex(i);

        if( player !is null )
        {
            g_PlayerFuncs.HudMessage( player, params, buffer );
        }
    }
} );
