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

enum Difficulty
{
    Storymode = 0,
    Relaxed,
    Medium,
    Punished,
    TorturedStandard,
    TorturedLegacy,
    // Size reference
    __Size__
}

namespace Difficulty
{
    bool __HellBound__;
    Difficulty __Difficulty__;

    // Return whatever hellbound is enabled.
    const bool& HellBound()
    {
        return __HellBound__;
    }

    // Return whatever difficulty level the map is currently.
    const Difficulty& Level()
    {
        return __Difficulty__;
    }

    string ToString( const Difficulty&in diff )
    {
        switch( diff )
        {
            case Difficulty::Storymode:
                return "Story Mode (0)";
            case Difficulty::Relaxed:
                return "Relaxed (1)";
            case Difficulty::Medium:
                return "Medium (2)";
            case Difficulty::Punished:
                return "Punished (3)";
            case Difficulty::TorturedStandard:
                return "Tortured Standard (4)";
            case Difficulty::TorturedLegacy:
                return "Tortured Legacy (5)";
        }
        return String::EMPTY_STRING;
    }

    // Update difficulty
    void UpdateDifficulty( int diff, int hellbound = -1, bool silent = false )
    {
        Difficulty::__Difficulty__ = Difficulty(diff);

        if( hellbound > -1 )
        {
            Difficulty::__HellBound__ = ( hellbound == 1 );
        }

        if( !silent )
        {
            g_PlayerFuncs.ClientPrintAll( HUD::HUD_PRINTTALK, "The simulation difficulty has been adjusted to " + Difficulty::ToString( Difficulty::Level() ) + ( HellBound() ? " IN HELLBOUND MODE!" : "" ) + "\n" );
        }
    }
}
