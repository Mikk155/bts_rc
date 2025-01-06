
//===============================================
// NightVision
//===============================================

// Turn on night vision sound
const string CONST_HEV_NIGHTVISION_ON = "bts_rc/items/nvg_on.wav";

// Turn off night vision sound
const string CONST_HEV_NIGHTVISION_OFF = "bts_rc/items/nvg_off.wav";

// Player try to use night vision but has no suit power.
const string CONST_HEV_NIGHTVISION_NO_POWER = "items/suitchargeno1.wav";

// Screen Fade RGB
const Vector CONST_HEV_NIGHTVISION_COLOR = Vector( 250, 200, 20 );

//===============================================
// End
//===============================================

//===============================================
// Blood Puddle
//===============================================

// Blood puddle model
const string CONST_BLOODPUDDLE = "models/mikk/misc/bloodpuddle.mdl";

// Blood puddle step sounds
const array<string> CONST_BLOODPUDDLE_SND = {
    "player/pl_slosh1.wav",
    "player/pl_slosh2.wav",
    "player/pl_slosh3.wav",
    "player/pl_slosh4.wav",
};

//===============================================
// End
//===============================================

//===============================================
// Voice Responses
//===============================================

// Player take damage
const float CONST_VOICE_COOLDOWN_TAKEDAMAGE = 1.0;

// Player take damage but his head is underwater
//const float CONST_VOICE_COOLDOWN_DROWNDAMAGE = 1.0;

//===============================================
// End
//===============================================

//===============================================
// Item Tracker
//===============================================

// Title of the item tracker motd
const string CONST_WHO_HAS_WHAT_TITLE = "Who has what?\n";

// How concurrent to re-search for players and track their items? seconds.
const float CONST_WHO_HAS_WHAT_TIME = 5;

//===============================================
// End
//===============================================
