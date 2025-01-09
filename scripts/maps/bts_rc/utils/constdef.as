
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
const array<string>@ CONST_BLOODPUDDLE_SND = {
    "player/pl_slosh1.wav",
    "player/pl_slosh2.wav",
    "player/pl_slosh3.wav",
    "player/pl_slosh4.wav",
};

// small size monsters for puddle's scale
array<string>@ CONST_BLOODPUDDLE_SMALL = {
    "moster_headcrab",
    "monster_houndeye",
    "monster_babycrab"
};

// Min and max size for small puddles
const array<float>@ CONST_BLOODPUDDLE_SIZE_SMALL = { 0.5, 1.5 };

// Min and max size for big puddles
const array<float>@ CONST_BLOODPUDDLE_SIZE_BIG = { 1.5, 2.5 };

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

//===============================================
// Damage reaction to DMG_RADIOACTIVE
//===============================================

const float CONST_CLSUIT_RADIATION_MULTIPLIER = 0.3;

// Geiger damage sound
const array<string> CONST_GEIGER_SND = {
    "player/geiger1.wav",
    "player/geiger2.wav",
    "player/geiger3.wav",
    "player/geiger4.wav",
    "player/geiger5.wav",
    "player/geiger6.wav",
};

//===============================================
// End
//===============================================

//===============================================
// Lasers
//===============================================

const array<string> CONST_LASERS_MONSTERS = {
    "monster_sentry",
    "monster_turret",
    "monster_miniturret"
};

// Sprite of the laser
const string CONST_LASERS_BEAM = "sprites/laserbeam.spr";
const string CONST_LASERS_MODEL = "sprites/glow_red.spr";

// renderamt of the glow at the turret
const float CONST_LASERS_GRENDERAMT = 255;

// renderamt of the glow at the target
const float CONST_LASERS_SRENDERAMT = 80;

// Offset down from the target's enemy EyePosition
const float CONST_LASERS_TARGET_OFFSET = 10;

//===============================================
// End
//===============================================
