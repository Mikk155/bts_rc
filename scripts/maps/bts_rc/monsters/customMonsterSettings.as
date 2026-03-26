/*
    Author: Nero
*/


namespace btscm
{

/////////////////
// SETTINGS //
/////////////////

/*custommonsters.as*/
const float THINKRATE_MAIN              = 0.1; //Needs to be <= than the other thinkrate variables
const float THINKRATE_OTHER         = 0.1; //affects death and certain skills


/*zombies.as*/
const float CANISTER_HEALTH         = 50.0;
const float CANISTER_DAMAGE         = 125.0; //when it explodes
const float CANISTER_DEGRADE            = 0.5; //damaged canisters will degrade until they explode when the zombie dies, this sets how fast this happens
const int CANISTER_STRAY_CHANCE = 5; //when shooting the zombies in the chest or stomach there is a risk of damaging the canister, in percentage 1-100


/*robogrunts.as*/
//how much damage the robot takes from various sources
//multipliers; 0.0 = damage is set to 0, 0.5 = damage is halved, 1.0 = damage is unaffected, 2.0 = damage is doubled, etc.
const float DAMAGE_MULT_BULLET      = 0.21;
const float DAMAGE_MULT_MELEE       = 0.08;
const float DAMAGE_MULT_BLAST       = 0.7;
const float DAMAGE_MULT_BURN        = 0.18;
const float DAMAGE_MULT_POISON      = 0.07;
const float DAMAGE_MULT_GENERIC     = 0.6;

//robots will explode shortly after death, can be set to 0
const float EXPLODE_DAMAGE              = 125.0;

//low-health mode = periodically causes damage to players near the npc, with some effects, also causes damage if players use melee
const float ROBOT_LOWHEALTH         = 0.3; //when to trigger low-health mode (percentage 0.0 - 1.0) eg: 0.3 = trigger when health is at 30%
const float SHOCKTOUCH_DAMAGE       = 125.0; //when low-health is active, periodically shock anything in close proximity


/*hwrgboss.as*/
const float THINKRATE_AOE_CHECK = 0.5; //checks if there are players near the boss

//how much damage the boss takes from various sources
//multipliers; 0.0 = damage is set to 0, 0.5 = damage is halved, 1.0 = damage is unaffected, 2.0 = damage is doubled, etc.
const float DAMAGE_MULT_SHIELD      = 0.0;
const float DAMAGE_MULT_HEAD        = 0.9; //sniper rifle only

//if the boss is shooting and a Shield Stomp is triggered, it first uses either a Kick, or a Shield Slam (just a smoother transition between the animation)
const float KICK_RANGE                      = 80.0;
const float KICK_DAMAGE                 = 15.0;
const float KICK_FORCE                      = 400.0; //for knockback

const float SHIELD_SLAM_RANGE       = 70.0;
const float SHIELD_SLAM_DAMAGE      = 30.0;
const float SHIELD_SLAM_FORCE       = 200.0; //for knockback

const int SHIELD_AOE_TRIGGER            = 1; //the minimum number of players around the boss to trigger a stomp
const int SHIELD_AOE_RADIUS         = 240;
const float SHIELD_AOE_DAMAGE       = 15.0;
const float SHIELD_AOE_KNOCKBACK    = 1337.0;
const float SURROUND_RADIUS         = 220.0; //the number of players within this range will change the color and damage of the aoe
const float SURROUND_BONUS          = 1.1; //damage multiplied by this for every player in range (~ish) set to 0.0 for no bonus (unless my math is flawed :owo:)
const RGBA SONIC_BEAM_COLOR_1   = RGBA(188, 220, 255, 255); //based on number of nearby players
const RGBA SONIC_BEAM_COLOR_2   = RGBA(101, 133, 221, 255);
const RGBA SONIC_BEAM_COLOR_3   = RGBA(67, 85, 255, 255);
const RGBA SONIC_BEAM_COLOR_4   = RGBA(62, 33, 211, 255);

const float ANTIFLARE_RANGE         = 200.0;

////////////////////////////////////////////////////////
// OTHER (shouldn't need changing, but might) //
////////////////////////////////////////////////////////

/*custommonsters.as*/
const string KVN_MONSTERTHINK       = "$f_btscmthink";


/*zombies.as*/
const int HITGROUP_CANISTER         = 10;
const string KVN_ZOMBIECANHP            = "$f_zecanisterhp";
const string SPRITE_CANISTER_GAS    = "sprites/xsmoke4.spr";


/*robogrunts.as*/
const string KVN_DOSMOKEPUFF            = "$i_rgdosmokepuff";
const string KVN_DIETHINK               = "$f_rgdiethink";
const string KVN_REMOVETIME         = "$f_rgremovetime";
const string KVN_SHOCKTOUCH         = "$i_rgshocktouch";
const string KVN_NEXTSHOCK              = "$f_rgnextshock";
const string KVN_NEXTSPARK              = "$f_rgnextspark";
const string KVN_DOUBLESPARK            = "$i_rgdoublespark";

const string SPRITE_RGRUNT_SMOKE    = "sprites/steam1.spr";
const string MODEL_RGRUNT_GIB1      = "models/computergibs.mdl";
const string MODEL_RGRUNT_GIB2      = "models/chromegibs.mdl";


/*hwrgboss*/
const int HITGROUP_SHIELD               = 15;
//const int HITGROUP_MINIGUN            = 16; //only here if you want to do something if players shoot the minigun

const string KVN_KICK                       = "$f_hwrgkick";
const string KVN_SHIELDCHECK            = "$f_hwrgshieldcheck";
const string KVN_SHIELDSLAM         = "$f_hwrgshieldslam";
const string KVN_SHIELDSTOMP            = "$f_hwrgshieldstomp";

const string SPRITE_SHIELD_AOE      = "sprites/shockwave.spr";
const string SPRITE_ANTIFLARE           = "sprites/laserbeam.spr";

} //namespace btscm END