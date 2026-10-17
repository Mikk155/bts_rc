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

/*
    Author: Nero
*/

namespace btscm
{

    /////////////////
    // SETTINGS //
    /////////////////

    /*custommonsters.as*/
    const float THINKRATE_MAIN = 0.1;  // Needs to be <= than the other thinkrate variables
    const float THINKRATE_OTHER = 0.1; // affects death and certain skills

    /*hwrgboss.as*/
    const float THINKRATE_AOE_CHECK = 0.5; // checks if there are players near the boss

    // if the boss is shooting and a Shield Stomp is triggered, it first uses either a Kick, or a Shield Slam (just a smoother transition between the animation)
    const float KICK_RANGE = 80.0;
    const float KICK_DAMAGE = 15.0;
    const float KICK_FORCE = 400.0; // for knockback

    const float SHIELD_SLAM_RANGE = 70.0;
    const float SHIELD_SLAM_DAMAGE = 30.0;
    const float SHIELD_SLAM_FORCE = 200.0; // for knockback

    const int SHIELD_AOE_TRIGGER = 1;      // the minimum number of players around the boss to trigger a stomp

    ////////////////////////////////////////////////////////
    // OTHER (shouldn't need changing, but might) //
    ////////////////////////////////////////////////////////

    /*custommonsters.as*/
    const string KVN_MONSTERTHINK = "$f_btscmthink";

    const string SPRITE_RGRUNT_SMOKE = "sprites/steam1.spr";

    const string KVN_KICK = "$f_hwrgkick";
    const string KVN_SHIELDCHECK = "$f_hwrgshieldcheck";
    const string KVN_SHIELDSLAM = "$f_hwrgshieldslam";
    const string KVN_SHIELDSTOMP = "$f_hwrgshieldstomp";

    const string SPRITE_SHIELD_AOE = "sprites/shockwave.spr";
    const string SPRITE_ANTIFLARE = "sprites/laserbeam.spr";

} // namespace btscm END
