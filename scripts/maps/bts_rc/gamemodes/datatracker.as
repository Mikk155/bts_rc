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

final class ASDataTracker : IConfigurable
{

    const string& GetName() const override
    {
        return "data_tracker";
    }

    const string GetSchema() const override
    {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Map configuration",
            "description": "Configuration about the *configuration* system..",
            "properties":
            {
                "active":
                {
                    "type": "boolean",
                    "description": "When active. tracks player data and writes to scripts/maps/store/bts_rc_datatracker.json"
                }
            }
        }""";
    }

    bool Register( meta_api::json::v2::json@ config ) override
    {
        config.Get( "active", this.m_TrackDataActive );

        if( !g_IsMainMap && g_MapConfig.MapLoading )
        {
            this.m_TrackDataActive = true;
        }

        return true;
    }

    bool m_TrackDataActive;

    private
        dictionary m_Data;

    void Delete( CBasePlayer@ player )
    {
        if( player !is null )
        {
            this.m_Data.delete( Player::GetUniqueID( player ) );
        }
    }

    void Track( CBasePlayer@ player )
    {
        if( player !is null )
        {
            dictionary@ data = {
                { "joined_at", DateTime().ToUnixTimestamp() }
            };

            @this.m_Data[ Player::GetUniqueID( player ) ] = data;

            ChatColor::Say( player, ChatColor::Color::Green, "Now tracking your player data.\n", player, true );
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
        this.m_Diff.MakeAbsolute();

        for( int i = 1; i <= g_Engine.maxClients; i++ )
        {
            auto player = g_PlayerFuncs.FindPlayerByIndex(i);

            if( player is null || !player.IsConnected() )
                continue;

            auto character = GetCharacter( player );

            if( character is null )
                continue;

            dictionary@ data = cast<dictionary@>( this.m_Data[ Player::GetUniqueID( player ) ] );

            if( data is null )
            {
                ChatColor::Say( player, ChatColor::Color::Red, "No data tracked for joining after the simulation started.\n", player, true );
                continue;
            }

            ChatColor::Say( player, ChatColor::Color::Green, "Processing data...\n", player, true );

            string netname = string( player.pev.netname );
            int points = int( player.pev.frags );
            string model = character.Name;
            int classify_index = int( character.Classify );
            string classify_name = Classification::ToString( character.Classify );

            // After credits message display
            string buffer;

            snprintf( buffer, "%1 completed the simulation as %2 (%3) with %4 points and %5 deaths.\n",
                netname,
                classify_name,
                model.SubString( 4 ), // Remove the "bts_" prefix
                points,
                player.m_iDeaths
            );

            m_CurrentRun.insertLast( buffer );

            // Data to store at json
            if( this.m_TrackDataActive )
            {
                data[ "name" ] = netname;
                data[ "points" ] = points;
                data[ "model" ] = model;
                data[ "ended_at" ] = now_unix;
                data[ "classify_index" ] = classify_index;
                data[ "classify" ] = classify_name;
                data[ "difficulty" ] = int( Difficulty::Level() );
                data[ "hellbound" ] = Difficulty::HellBound();
                data[ "deaths" ] = player.m_iDeaths;
            }
        }

        if( this.m_TrackDataActive )
        {
            meta_api::json::v1::Serialize( this.m_Data, "scripts/maps/store/bts_rc_datatracker.json" );
        }
    }
}

ASDataTracker g_DataTracker;
