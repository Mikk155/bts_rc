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

#include "../../../mikk155/meta_api/json/v1"

final class ASDataTracker
{
    private
        dictionary m_Data;

    void Delete( CBasePlayer@ player )
    {
        if( player !is null )
        {
            this.m_Data.delete( g_EngineFuncs.GetPlayerAuthId( player.edict() ) );
        }
    }

    void Track( CBasePlayer@ player, CCharacter@ character )
    {
        if( player !is null && character !is null )
        {
            dictionary@ data = { };

            @this.m_Data[ g_EngineFuncs.GetPlayerAuthId( player.edict() ) ] = data;

            // -TODO Move to initializer list
            data[ "classify_index" ] = int( character.Classify );
            data[ "classify" ] = Classification::ToString( character.Classify );
            data[ "model" ] = character.Name;
            data[ "points" ] = int( player.pev.frags );
            data[ "joined_at" ] = DateTime().ToUnixTimestamp();
            data[ "difficulty" ] = int( Difficulty::Level() );
            data[ "hellbound" ] = Difficulty::HellBound();

            ChatColor::Say( player, ChatColor::Color::Green, string( player.pev.netname ) + ": Now tracking your player data.", { player }  );
        }
    }

    private
        array<string> m_CurrentRun;

    array<string>@ get_CurrentPlayerMessages()
    {
        return @this.m_CurrentRun;
    }

    private
        DateTime m_Start;

    private
        TimeDifference m_Diff;

    const TimeDifference& get_Difference() const
    {
        return this.m_Diff;
    }

    void Stop()
    {
        DateTime now = DateTime();
        time_t now_unix = now.ToUnixTimestamp();
        this.m_Diff = this.m_Start - now;

        for( int i = 1; i <= g_Engine.maxClients; i++ )
        {
            auto player = g_PlayerFuncs.FindPlayerByIndex(i);

            if( player is null || !player.IsConnected() )
                continue;

            ChatColor::Say( player, ChatColor::Color::Green, string( player.pev.netname ) + ": Processing data...", { player }  );

            dictionary@ data = cast<dictionary@>( this.m_Data[ g_EngineFuncs.GetPlayerAuthId( player.edict() ) ] );

            data[ "points" ] = int( player.pev.frags );
            data[ "ended_at" ] = now_unix;
            data[ "name" ] = string( player.pev.netname );

            string buffer;

            snprintf( buffer, "%1 completed the simulation as %2 (%3) with %4 points.\n",
                string( player.pev.netname ),
                string( data[ "classify" ] ),
                string( data[ "model" ] ),
                int( data[ "points" ] )
            );

            m_CurrentRun.insertLast( buffer );
        }

        meta_api::json::v1::Serialize( this.m_Data, "scripts/maps/store/bts_rc_datatracker.json" );
    }
}

ASDataTracker g_DataTracker;
