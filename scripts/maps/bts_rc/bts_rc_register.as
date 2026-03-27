/*
    Author: Mikk
*/

/*==========================================================================
*   - Start of includes
==========================================================================*/

#include "../../mikk155/meta_api"

#include "entities/ammo"
#include "monsters/custommonsters" //Nero ADDED 2026-01-07 Custom Monsters
#include "entities/env_bloodpuddle"
#include "entities/func_bts_recharger"
#include "entities/items"
#include "entities/point_checkpoint"
#include "entities/randomizer"
#include "entities/trigger_update_class"

#include "gamemodes/lasers"
#include "gamemodes/player_voices"

#include "Hooks/monster_killed"
#include "Hooks/monster_takedamage"
#include "Hooks/player_connect" /* -TODO Remove this line in 5.27 */
#include "Hooks/player_takedamage"
#include "Hooks/player_think"

#include "weapons/proj/flare"
#include "weapons/proj/m79_rocket"

#include "weapons/weapon_bts_axe"
#include "weapons/weapon_bts_beretta"
#include "weapons/weapon_bts_crowbar"
#include "weapons/weapon_bts_eagle"
#include "weapons/weapon_bts_flamethrower"
#include "weapons/weapon_bts_flare"
#include "weapons/weapon_bts_flaregun"
#include "weapons/weapon_bts_flashlight"
#include "weapons/weapon_bts_glock"
#include "weapons/weapon_bts_glock17f"
#include "weapons/weapon_bts_glock18"
#include "weapons/weapon_bts_glocksd"
#include "weapons/weapon_bts_handgrenade"
#include "weapons/weapon_bts_knife"
#include "weapons/weapon_bts_m16"
#include "weapons/weapon_bts_m16sd"
#include "weapons/weapon_bts_m4"
#include "weapons/weapon_bts_m4sd"
#include "weapons/weapon_bts_m79"
#include "weapons/weapon_bts_medkit"
#include "weapons/weapon_bts_mp5"
#include "weapons/weapon_bts_mp5gl"
#include "weapons/weapon_bts_pipe"
#include "weapons/weapon_bts_pipewrench"
#include "weapons/weapon_bts_poolstick"
#include "weapons/weapon_bts_python"
#include "weapons/weapon_bts_saw"
#include "weapons/weapon_bts_sawsd"
#include "weapons/weapon_bts_sbshotgun"
#include "weapons/weapon_bts_screwdriver"
#include "weapons/weapon_bts_shotgun"
#include "weapons/weapon_bts_sniperrifle"
#include "weapons/weapon_bts_uzi"
#include "weapons/weapon_bts_uzisd"
#include "weapons/weapon_bts_xbow"
#include "weapons/weapon_bts_sw637"
/*==========================================================================
*   - End
==========================================================================*/

/*==========================================================================
*   - Start of base class for weapons
==========================================================================*/
mixin class bts_rc_base_weapon
{
    // Default flags for weapons
    protected int m_flags = (ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_NOAUTORELOAD);

    // To not cast repeatedly
    private CBasePlayer @player = null;
    protected CBasePlayer @get_player()
    {
        if (player is null || player !is self.m_hPlayer.GetEntity())
        {
            @player = cast<CBasePlayer>(self.m_hPlayer.GetEntity());
        }
        return @player;
    }

    // A weapon is deployed
    protected bool bts_deploy(const string&in viewmodel, const string&in playermodel, int animation, const string&in animation_ext, int hands_group, float time = 1.0f)
    {
        self.DefaultDeploy( self.GetV_Model( viewmodel ), self.GetP_Model( playermodel ), animation, animation_ext, 0, hands_group );
        m_pPlayer.pev.viewmodel = self.GetV_Model(viewmodel);
        m_pPlayer.pev.weaponmodel = self.GetP_Model(playermodel);

        m_pPlayer.set_m_szAnimExtension(animation_ext);

        // Set the correct bodygroup for character hands in the given hands_group, most of the weapons has it in the bodygroup 1s
        pev.body = g_ModelFuncs.SetBodygroup(g_ModelFuncs.ModelIndex(viewmodel), pev.body, hands_group, g_PlayerClass[m_pPlayer]);
        self.SendWeaponAnim(animation, 0, pev.body);

        m_pPlayer.m_flNextAttack = time; // For some reason the weapon's *Attack functions weren't being called without this.

        time += g_Engine.time;

        if (self.m_flNextPrimaryAttack < time)
            self.m_flNextPrimaryAttack = time;

        if (self.m_flTimeWeaponIdle < time)
            self.m_flTimeWeaponIdle = time;

        if (self.m_flNextSecondaryAttack < time)
            self.m_flNextSecondaryAttack = time;

        return true;
    }

    protected void bts_post_attack(TraceResult&in tr)
    {
        if (g_EntityFuncs.IsValidEntity(tr.pHit))
        {
            CBaseEntity @hit = g_EntityFuncs.Instance(tr.pHit);

            if (hit !is null)
            {
                bool should_bleed = (cvar_trace_blood.GetInt() != 1);
                if (should_bleed && tr.iHitgroup != 10 && hit.IsMonster() && freeedicts(1))
                {
                    CBaseMonster @monster = cast<CBaseMonster @>(hit);

                    if (monster !is null && monster.m_bloodColor != DONT_BLEED)
                    {
                        CSprite @spr = null;

                        if (monster.m_bloodColor == BLOOD_COLOR_RED)
                        {
                            switch (Math.RandomLong(1, 3))
                            {
                                case 1:
                                    @spr = g_EntityFuncs.CreateSprite("sprites/bts_rc/hblood_1.spr", tr.vecEndPos, true);
                                    break;
                                case 2:
                                    @spr = g_EntityFuncs.CreateSprite("sprites/bts_rc/hblood_2.spr", tr.vecEndPos, true);
                                    break;
                                case 3:
                                    @spr = g_EntityFuncs.CreateSprite("sprites/bts_rc/hblood_3.spr", tr.vecEndPos, true);
                                    break;
                            }
                        }
                        else if (monster.m_bloodColor == (BLOOD_COLOR_GREEN | BLOOD_COLOR_YELLOW))
                        {
                            switch (Math.RandomLong(1, 5))
                            {
                                case 1:
                                    @spr = g_EntityFuncs.CreateSprite("sprites/bts_rc/ablood_1.spr", tr.vecEndPos, true);
                                    break;
                                case 2:
                                    @spr = g_EntityFuncs.CreateSprite("sprites/bts_rc/ablood_2.spr", tr.vecEndPos, true);
                                    break;
                                case 3:
                                    @spr = g_EntityFuncs.CreateSprite("sprites/bts_rc/ablood_3.spr", tr.vecEndPos, true);
                                    break;
                                case 4:
                                    @spr = g_EntityFuncs.CreateSprite("sprites/bts_rc/ablood_4.spr", tr.vecEndPos, true);
                                    break;
                                case 5:
                                    @spr = g_EntityFuncs.CreateSprite("sprites/bts_rc/ablood_5.spr", tr.vecEndPos, true);
                                    break;
                            }
                        }

                        if (spr !is null)
                        {
                            spr.AnimateAndDie(60.0f);
                            spr.pev.scale = Math.RandomFloat(0.05, 0.25);
                        }
                    }
                }

                bool should_sparks = (cvar_trace_sparks.GetInt() != 1);
                if (should_sparks && freeedicts(17))
                {
                    int sparks_color;

                    if ("monster_robogrunt" == hit.pev.classname)
                    {
                        sparks_color = 5;
                    }
                    else if ("models/bts_rc/monsters/robothwgrunt.mdl" == hit.pev.model)
                    {
                        //Nero CHANGED 2026-01-07 Custom Monsters
                        should_sparks = false; //sparks_color = 7;
                    }
                    else if ("models/bts_rc/monsters/rgrunt_opfor.mdl" == hit.pev.model)
                    {
                        //Nero CHANGED 2026-01-07 Custom Monsters
                        should_sparks = false; //sparks_color = 7;
                    }
                    else if ("monster_sentry" == hit.pev.classname || "monster_turret" == hit.pev.classname || "monster_miniturret" == hit.pev.classname)
                    {
                        sparks_color = 4;
                    }
                    else if (tr.iHitgroup == 10)
                    {
                        if ("monster_zombie_soldier" == hit.pev.classname)
                        {
                            if ("models/bts_rc/monsters/zombie_hev.mdl" == hit.pev.model)
                            {
                                sparks_color = 7;
                            }
                            
                        }
                        else if (hit.pev.classname == "monster_alien_grunt")
                        {
                            sparks_color = 0;
                        }
                        else if (hit.pev.classname == "monster_gonome")
                        {
                            if ("models/bts_rc/monsters/gonome_hev.mdl" == hit.pev.model)
                            {
                                sparks_color = 7;
                            }
                        }
                        else if (hit.pev.classname == "monster_zombie_soldier")
                        {
                            if ("models/bts_rc/monsters/zombie_hev2.mdl" == hit.pev.model)
                            {
                                sparks_color = 7;
                            }
                        }
                        else
                        {
                            should_sparks = false;
                        }
                    }
                    else
                    {
                        should_sparks = false;
                    }

                    if (should_sparks)
                    {
                        switch (Math.RandomLong(1, 5))
                        {
                            case 1:
                                g_SoundSystem.EmitSoundDyn(hit.edict(), CHAN_AUTO, "weapons/ric1.wav", 1.0, ATTN_NONE, 0, PITCH_NORM);
                                break;
                            case 2:
                                g_SoundSystem.EmitSoundDyn(hit.edict(), CHAN_AUTO, "weapons/ric2.wav", 1.0, ATTN_NONE, 0, PITCH_NORM);
                                break;
                            case 3:
                                g_SoundSystem.EmitSoundDyn(hit.edict(), CHAN_AUTO, "weapons/ric3.wav", 1.0, ATTN_NONE, 0, PITCH_NORM);
                                break;
                            case 4:
                                g_SoundSystem.EmitSoundDyn(hit.edict(), CHAN_AUTO, "weapons/ric4.wav", 1.0, ATTN_NONE, 0, PITCH_NORM);
                                break;
                            case 5:
                                g_SoundSystem.EmitSoundDyn(hit.edict(), CHAN_AUTO, "weapons/ric5.wav", 1.0, ATTN_NONE, 0, PITCH_NORM);
                                break;
                        }

                        NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                        m.WriteByte(TE_STREAK_SPLASH);
                        m.WriteCoord(tr.vecEndPos.x);
                        m.WriteCoord(tr.vecEndPos.y);
                        m.WriteCoord(tr.vecEndPos.z);
                        m.WriteCoord(0);
                        m.WriteCoord(0);
                        m.WriteCoord(g_Engine.v_forward.z);
                        m.WriteByte(sparks_color); // Color pallete: https://github.com/baso88/SC_AngelScript/wiki/images/engine_palette_2.png
                        m.WriteShort(30);          // Count
                        m.WriteShort(128);         // Base speed
                        m.WriteShort(100);         // Random velocity
                        m.End();

                        NetworkMessage m2(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                        m2.WriteByte(TE_DLIGHT);
                        m2.WriteCoord(tr.vecEndPos.x);
                        m2.WriteCoord(tr.vecEndPos.y);
                        m2.WriteCoord(tr.vecEndPos.z);
                        m2.WriteByte(5);   // radius
                        m2.WriteByte(150); // R
                        m2.WriteByte(100); // G
                        m2.WriteByte(0);   // B
                        m2.WriteByte(1);   // life in 0.1's
                        m2.WriteByte(1);   // decay in 0.1's
                        m2.End();

                        g_Utility.Sparks(tr.vecEndPos);
                        g_Utility.Ricochet(tr.vecEndPos, Math.RandomFloat(0.5, 1.5));
                    }
                }
            }
        }
    }

    bool AddToPlayer(CBasePlayer @player)
    {
        if (!BaseClass.AddToPlayer(player))
            return false;

        NetworkMessage weapon(MSG_ONE, NetworkMessages::WeapPickup, player.edict());
        weapon.WriteLong(g_ItemRegistry.GetIdForName(pev.classname));
        weapon.End();

        return true;
    }

    protected float Accuracy(float tr, float def, float trd, float defd)
    {
        if (g_PlayerClass.is_trained_personal(m_pPlayer))
        {
            if ((m_pPlayer.pev.button & IN_DUCK) != 0)
            {
                return trd;
            }
            return tr;
        }
        else if ((m_pPlayer.pev.button & IN_DUCK) != 0)
        {
            return defd;
        }
        return def;
    }
};

mixin class bts_rc_base_melee
{
    protected TraceResult m_trHit;
    protected int m_iSwing = 0;

    void PrimaryAttack()
    {
        if (!Swing(true))
        {
            SetThink(ThinkFunction(this.SwingAgain));
            pev.nextthink = g_Engine.time + 0.1f;
        }
    }

    protected void SwingAgain()
    {
        Swing(false);
    }

    protected void Smack()
    {
        g_WeaponFuncs.DecalGunshot(m_trHit, BULLET_PLAYER_CROWBAR);
    }
};
/*==========================================================================
*   - End
==========================================================================*/

/*==========================================================================
*   - HELLBOUND INJECTION
==========================================================================*/

namespace Hellbound
{
    funcdef HookReturnCode Think( CBasePlayer@ );

    Think@ callback;

    void Shutdown( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
    {
        if( callback is null )
            return;

        g_Hooks.RemoveHook( Hooks::Player::PlayerPostThink, @callback );
        @callback = null;
    }

    void Startup( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
    {
        if( callback !is null )
            return;

        @callback = Think( OnThink );

        g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @callback );
    }

    HookReturnCode OnThink( CBasePlayer@ player )
    {
        if( player !is null )
        {
            player.pev.health = 1;
            player.pev.armorvalue = 1;
            player.pev.max_health = 1;
        }
        
        return HOOK_CONTINUE;
    }
}

/*==========================================================================
*   - End
==========================================================================*/

/*==========================================================================
*   - Start of Cvars for server operators. Modify these in maps/bts_rc.cfg
==========================================================================*/
CCVar @cvar_player_models = CCVar("bts_rc_disable_player_models", 0, String::EMPTY_STRING, ConCommandFlag::AdminOnly);
CCVar @cvar_player_voices = CCVar("bts_rc_disable_player_voices", 0, String::EMPTY_STRING, ConCommandFlag::AdminOnly);
CCVar @cvar_bloodpuddles = CCVar("bts_rc_disable_bloodpuddles", 0, String::EMPTY_STRING, ConCommandFlag::AdminOnly);
CCVar @cvar_sentry_laser = CCVar("bts_rc_disable_sentry_laser", -1, String::EMPTY_STRING, ConCommandFlag::AdminOnly, @CSentryCallback);
CCVar @cvar_trace_blood = CCVar("bts_rc_disable_bloodsplash", 0, String::EMPTY_STRING, ConCommandFlag::AdminOnly);
CCVar @cvar_trace_sparks = CCVar("bts_rc_disable_sparks", 0, String::EMPTY_STRING, ConCommandFlag::AdminOnly);
/*==========================================================================
*   - End
==========================================================================*/

void MapActivate()
{
    meta_api::NoticeInstallation();
    /*==========================================================================
    *   - Start of turret lasers
    ==========================================================================*/
    const array<string> turrets = {
#if SERVER
        "monster_sentry",
#endif
        "monster_turret",
        "monster_miniturret"};

    for (uint ui = 0; ui < turrets.length(); ui++)
    {
        CBaseEntity @entity = null;

        while ((@entity = g_EntityFuncs.FindEntityByClassname(entity, turrets[ui])) !is null)
        {
            g_sentry_laser.handles.insertLast(EHandle(entity));
        }
    }
    /*==========================================================================
    *   - End
    ==========================================================================*/
}

void MapInit()
{
    /*==========================================================================
    *   - Start of custom entities registry
    ==========================================================================*/
    g_CustomEntityFuncs.RegisterCustomEntity("env_bloodpuddle::env_bloodpuddle", "env_bloodpuddle");
    g_CustomEntityFuncs.RegisterCustomEntity("func_bts_recharger::func_bts_recharger", "func_bts_recharger");
    g_CustomEntityFuncs.RegisterCustomEntity("trigger_update_class::trigger_update_class", "trigger_update_class");
    g_CustomEntityFuncs.RegisterCustomEntity("point_checkpoint::point_checkpoint", "point_checkpoint");
    btscm::CustomMonsterMapInit(); //Nero ADDED 2026-01-07 Custom Monsters

    // Randomizer
    g_CustomEntityFuncs.RegisterCustomEntity("randomizer::randomizer_npc", "randomizer_npc");
    g_CustomEntityFuncs.RegisterCustomEntity("randomizer::randomizer_item", "randomizer_item");
    g_CustomEntityFuncs.RegisterCustomEntity("randomizer::randomizer_hull", "randomizer_hull");
    g_CustomEntityFuncs.RegisterCustomEntity("randomizer::randomizer_boss", "randomizer_boss");
    g_CustomEntityFuncs.RegisterCustomEntity("randomizer::randomizer_wave", "randomizer_wave");
    g_CustomEntityFuncs.RegisterCustomEntity("randomizer::randomizer_headcrab", "randomizer_headcrab");
    g_CustomEntityFuncs.RegisterCustomEntity("randomizer::randomizer_hullwave", "randomizer_hullwave");

    // Items
    g_CustomEntityFuncs.RegisterCustomEntity("item_bts_armorvest", "item_bts_armorvest");
    g_CustomEntityFuncs.RegisterCustomEntity("item_bts_helmet", "item_bts_helmet");
    g_CustomEntityFuncs.RegisterCustomEntity("item_bts_hevbattery", "item_bts_hevbattery");
    g_CustomEntityFuncs.RegisterCustomEntity("item_bts_sprayaid", "item_bts_sprayaid");

    // Projectiles
    g_CustomEntityFuncs.RegisterCustomEntity("M79_ROCKET::CM79Rocket", "m79_rocket");
    g_CustomEntityFuncs.RegisterCustomEntity("FLARE::CFlare", "flare");
    g_CustomEntityFuncs.RegisterCustomEntity("BTS_FLAMETHROWER::flame_proj", "flame_proj");

    // Weapon Entities
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_axe::weapon_bts_axe", "weapon_bts_axe");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_pipewrench::weapon_bts_pipewrench", "weapon_bts_pipewrench");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_beretta::weapon_bts_beretta", "weapon_bts_beretta");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_crowbar::weapon_bts_crowbar", "weapon_bts_crowbar");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_eagle::weapon_bts_eagle", "weapon_bts_eagle");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_flare::weapon_bts_flare", "weapon_bts_flare");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_flaregun::weapon_bts_flaregun", "weapon_bts_flaregun");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_flashlight::weapon_bts_flashlight", "weapon_bts_flashlight");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_sw637::weapon_bts_sw637", "weapon_bts_sw637");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_glock::weapon_bts_glock", "weapon_bts_glock");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_glock17f::weapon_bts_glock17f", "weapon_bts_glock17f");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_glock18::weapon_bts_glock18", "weapon_bts_glock18");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_glocksd::weapon_bts_glocksd", "weapon_bts_glocksd");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_knife::weapon_bts_knife", "weapon_bts_knife");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_handgrenade::weapon_bts_handgrenade", "weapon_bts_handgrenade");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_m4::weapon_bts_m4", "weapon_bts_m4");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_m4sd::weapon_bts_m4sd", "weapon_bts_m4sd");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_m16::weapon_bts_m16", "weapon_bts_m16");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_m16sd::weapon_bts_m16sd", "weapon_bts_m16sd");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_m79::weapon_bts_m79", "weapon_bts_m79");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_medkit::weapon_bts_medkit", "weapon_bts_medkit");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_mp5gl::weapon_bts_mp5gl", "weapon_bts_mp5gl");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_mp5::weapon_bts_mp5", "weapon_bts_mp5");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_pipe::weapon_bts_pipe", "weapon_bts_pipe");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_poolstick::weapon_bts_poolstick", "weapon_bts_poolstick");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_python::weapon_bts_python", "weapon_bts_python");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_shotgun::weapon_bts_shotgun", "weapon_bts_shotgun");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_uzi::weapon_bts_uzi", "weapon_bts_uzi");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_uzisd::weapon_bts_uzisd", "weapon_bts_uzisd");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_saw::weapon_bts_saw", "weapon_bts_saw");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_sawsd::weapon_bts_sawsd", "weapon_bts_sawsd");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_sbshotgun::weapon_bts_sbshotgun", "weapon_bts_sbshotgun");
    g_CustomEntityFuncs.RegisterCustomEntity("weapon_bts_screwdriver::weapon_bts_screwdriver", "weapon_bts_screwdriver");

    // Ammo
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_beretta", "ammo_bts_beretta");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_beretta_battery", "ammo_bts_beretta_battery");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_eagle", "ammo_bts_eagle");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_eagle_battery", "ammo_bts_eagle_battery");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_eagle", "ammo_bts_dreagle");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_flarebox", "ammo_bts_flarebox");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_battery", "ammo_bts_battery");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_sw637", "ammo_bts_sw637");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_glock", "ammo_bts_glock");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_glock17f", "ammo_bts_glock17f");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_glock17f_battery", "ammo_bts_glock17f_battery");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_glock18", "ammo_bts_glock18");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_glocksd", "ammo_bts_glocksd");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_glocksd_battery", "ammo_bts_glocksd_battery");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_glocksd", "ammo_bts_dglocksd");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m4", "ammo_bts_m4");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_dummy", "ammo_bts_dummy");
//  g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m4", "ammo_bts_556mag"); // uncomment this to have infinite 556 ammo
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m4sd", "ammo_bts_m4sd");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m16", "ammo_bts_m16");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m16sd", "ammo_bts_m16sd");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m16", "ammo_bts_556round");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m16_grenade", "ammo_bts_m16_grenade");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m16sd_grenade", "ammo_bts_m16sd_grenade");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_m79", "ammo_bts_m79");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_mp5", "ammo_bts_mp5");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_mp5", "ammo_bts_dmp5");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_mp5gl", "ammo_bts_mp5gl");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_mp5gl", "ammo_bts_9mmbox");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_mp5gl_grenade", "ammo_bts_mp5gl_grenade");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_python", "ammo_bts_python");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_python", "ammo_bts_357cyl");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_saw", "ammo_bts_saw");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_sawsd", "ammo_bts_sawsd");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_saw", "ammo_bts_dsaw");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_sbshotgun", "ammo_bts_sbshotgun");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_sbshotgun_battery", "ammo_bts_sbshotgun_battery");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_shotgun", "ammo_bts_shotgun");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_shotgun", "ammo_bts_shotshell");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_uzi", "ammo_bts_uzi");
    g_CustomEntityFuncs.RegisterCustomEntity("ammo_bts_uzisd", "ammo_bts_uzisd");

    // Weapons
    g_ItemRegistry.RegisterWeapon("weapon_bts_axe", "bts_rc/weapons");
    g_ItemRegistry.RegisterWeapon("weapon_bts_pipewrench", "bts_rc/weapons");
    g_ItemRegistry.RegisterWeapon("weapon_bts_beretta", "bts_rc/weapons", "9mm", "bts:battery", "ammo_bts_beretta", "ammo_bts_beretta_battery");
    g_ItemRegistry.RegisterWeapon("weapon_bts_crowbar", "bts_rc/weapons");
    g_ItemRegistry.RegisterWeapon("weapon_bts_eagle", "bts_rc/weapons", "357", "bts:battery", "ammo_bts_eagle", "ammo_bts_eagle_battery");
    g_ItemRegistry.RegisterWeapon("weapon_bts_flare", "bts_rc/weapons", "weapon_bts_flare", "", "weapon_bts_flare", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_flaregun", "bts_rc/weapons", "bts:flare", "", "ammo_bts_flarebox", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_flashlight", "bts_rc/weapons", "bts:battery", "", "ammo_bts_battery", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_sw637", "bts_rc/weapons", "38", "", "ammo_bts_sw637", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_glock", "bts_rc/weapons", "9mm", "", "ammo_bts_glock", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_glock17f", "bts_rc/weapons", "9mm", "bts:battery", "ammo_bts_glock17f", "ammo_bts_glock17f_battery");
    g_ItemRegistry.RegisterWeapon("weapon_bts_glock18", "bts_rc/weapons", "9mm", "", "ammo_bts_glock18", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_glocksd", "bts_rc/weapons", "9mm", "bts:battery", "ammo_bts_glocksd", "ammo_bts_glocksd_battery");
    g_ItemRegistry.RegisterWeapon("weapon_bts_knife", "bts_rc/weapons");
    g_ItemRegistry.RegisterWeapon("weapon_bts_handgrenade", "bts_rc/weapons", "Hand Grenade", "", "weapon_bts_handgrenade", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_m4", "bts_rc/weapons", "556", "", "ammo_bts_m4", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_m4sd", "bts_rc/weapons", "556", "", "ammo_bts_m4sd", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_m16", "bts_rc/weapons", "556", "ARgrenades", "ammo_bts_m16", "ammo_bts_m16_grenade");
    g_ItemRegistry.RegisterWeapon("weapon_bts_m16sd", "bts_rc/weapons", "556", "ARgrenades", "ammo_bts_m16sd", "ammo_bts_m16sd_grenade");
    g_ItemRegistry.RegisterWeapon("weapon_bts_m79", "bts_rc/weapons", "ARgrenades", "", "ammo_bts_m79", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_medkit", "bts_rc/weapons", "health", "", "ammo_medkit");
    g_ItemRegistry.RegisterWeapon("weapon_bts_mp5gl", "bts_rc/weapons", "9mm", "ARgrenades", "ammo_bts_mp5gl", "ammo_bts_mp5gl_grenade");
    g_ItemRegistry.RegisterWeapon("weapon_bts_mp5", "bts_rc/weapons", "9mm", "", "ammo_bts_mp5", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_pipe", "bts_rc/weapons");
    g_ItemRegistry.RegisterWeapon("weapon_bts_poolstick", "bts_rc/weapons");
    g_ItemRegistry.RegisterWeapon("weapon_bts_python", "bts_rc/weapons", "357", "", "ammo_bts_python", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_shotgun", "bts_rc/weapons", "buckshot", "", "ammo_bts_shotgun", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_uzi", "bts_rc/weapons", "9mm", "", "ammo_bts_uzi", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_uzisd", "bts_rc/weapons", "9mm", "", "ammo_bts_uzisd", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_saw", "bts_rc/weapons", "556", "", "ammo_bts_saw", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_sawsd", "bts_rc/weapons", "556", "", "ammo_bts_sawsd", "");
    g_ItemRegistry.RegisterWeapon("weapon_bts_sbshotgun", "bts_rc/weapons", "buckshot", "bts:battery", "ammo_bts_sbshotgun", "ammo_bts_sbshotgun_battery");
    g_ItemRegistry.RegisterWeapon("weapon_bts_screwdriver", "bts_rc/weapons");
    BTS_XBOW::Register();
    weapon_bts_sniperrifle::Register();
    BTS_FLAMETHROWER::Register();
    weapon_bts_sw637::Register();
    /*==========================================================================
    *   - End
    ==========================================================================*/

    /*==========================================================================
    *   - Start of Item Mapping
    ==========================================================================*/
    g_ClassicMode.ForceItemRemap(true);
    g_ClassicMode.SetItemMappings(
        {ItemMapping("weapon_9mmhandgun", "ammo_bts_dglocksd"),
         ItemMapping("weapon_glock", "ammo_bts_dglocksd"),
         ItemMapping("weapon_357", "ammo_bts_357cyl"),
         ItemMapping("weapon_eagle", "ammo_bts_dreagle"),
         ItemMapping("weapon_uzi", "ammo_bts_9mmbox"),
         ItemMapping("weapon_uziakimbo", "ammo_bts_9mmbox"),
         ItemMapping("weapon_9mmAR", "ammo_bts_9mmbox"),
         ItemMapping("weapon_mp5", "ammo_bts_9mmbox"),
         ItemMapping("weapon_shotgun", "ammo_bts_shotshell"),
         ItemMapping("weapon_m16", "ammo_bts_dummy"), //please consult yourself with line 183 of ammo.as line
         ItemMapping("weapon_sniperrifle", "weapon_bts_sniperrifle"),
         ItemMapping("weapon_saw", "ammo_bts_dsaw"),
         ItemMapping("weapon_m249", "ammo_bts_dsaw"),
         ItemMapping("weapon_minigun", "ammo_bts_dsaw"),
         ItemMapping("weapon_rpg", "weapon_bts_m79"),
         ItemMapping("weapon_medkit", "weapon_bts_medkit")});
    /*==========================================================================
    *   - End
    ==========================================================================*/

    /*==========================================================================
    *   - Start of player voice responses
    ==========================================================================*/
    // Initialize handlers for specific classes
    CVoices @scientist = @CVoices("scientist");
    CVoices @barney = @CVoices("barney");
    CVoices @construction = @CVoices("construction");
    CVoices @helmet = @CVoices("helmet");
    CVoices @cleansuit = @CVoices("cleansuit");
    CVoices @veteran = @CVoices("veteran");
    CVoices @otis = @CVoices("otis");
    CVoices @bscientist = @CVoices("bscientist");

    // Save them in the voice responses class
    g_VoiceResponse.voices["scientist"] = @scientist;
    g_VoiceResponse.voices["barney"] = @barney;
    g_VoiceResponse.voices["construction"] = @construction;
    g_VoiceResponse.voices["helmet"] = @helmet;
    g_VoiceResponse.voices["cleansuit"] = @cleansuit;
    g_VoiceResponse.voices["veteran"] = @veteran;
    g_VoiceResponse.voices["otis"] = @otis;
    g_VoiceResponse.voices["bscientist"] = @bscientist;

    // Constructor
    construction.takedamage.cooldown = 1.0;
    construction.takedamage.push_back("bts_rc/player/construction/co_pain1.wav");
    construction.takedamage.push_back("bts_rc/player/construction/co_pain2.wav");
    construction.takedamage.push_back("bts_rc/player/construction/co_pain3.wav");
    construction.takedamage.push_back("bts_rc/player/construction/co_pain4.wav");
    construction.killed.push_back("bts_rc/player/construction/co_die1.wav");
    construction.killed.push_back("bts_rc/player/construction/co_die2.wav");
    construction.killed.push_back("bts_rc/player/construction/co_die3.wav");
    construction.killed.push_back("bts_rc/player/construction/co_die4.wav");

    // Barney
    barney.takedamage.cooldown = 1.0;
    barney.takedamage.push_back("barney/ba_pain1.wav");
    barney.takedamage.push_back("barney/ba_pain2.wav");
    barney.takedamage.push_back("barney/ba_pain3.wav");
    barney.killed.push_back("barney/ba_die1.wav");
    barney.killed.push_back("barney/ba_die2.wav");
    barney.killed.push_back("barney/ba_die3.wav");
    
    // Otis
    otis.takedamage.cooldown = 1.0;
    otis.takedamage.pitch = 94.0f;
    otis.killed.pitch = 94.0f;
    otis.takedamage.push_back("otis/scar.wav");
    otis.takedamage.push_back("barney/ba_pain1.wav");
    otis.takedamage.push_back("barney/ba_pain2.wav");
    otis.takedamage.push_back("barney/ba_pain3.wav");
    otis.takedamage.push_back("barney/aghh.wav");
    otis.takedamage.push_back("barney/ba_die3.wav");
    otis.takedamage.push_back("barney/ba_pain3.wav");
    otis.killed.push_back("barney/ba_die1.wav");
    otis.killed.push_back("barney/ba_die2.wav");
    otis.killed.push_back("barney/ba_die3.wav");

    // Veteran
    veteran.takedamage.cooldown = 1.0;
    veteran.takedamage.pitch = 103.0f;
    veteran.killed.pitch = 103.0f;
    veteran.takedamage.push_back("fgrunt/gr_pain1.wav");
    veteran.takedamage.push_back("fgrunt/gr_pain2.wav");
    veteran.takedamage.push_back("fgrunt/gr_pain3.wav");
    veteran.takedamage.push_back("fgrunt/gr_pain4.wav");
    veteran.takedamage.push_back("fgrunt/gr_pain5.wav");
    veteran.takedamage.push_back("fgrunt/gr_pain6.wav");
    veteran.killed.push_back("fgrunt/death1.wav");
    veteran.killed.push_back("fgrunt/death2.wav");
    veteran.killed.push_back("fgrunt/death3.wav");
    veteran.killed.push_back("fgrunt/death4.wav");
    veteran.killed.push_back("fgrunt/death5.wav");
    veteran.killed.push_back("fgrunt/death6.wav");

    // H.E.V
    helmet.takedamage.cooldown = 1.0;
    helmet.takedamage.push_back("bts_rc/player/helmet/hm_pain1.wav");
    helmet.takedamage.push_back("bts_rc/player/helmet/hm_pain2.wav");
    helmet.takedamage.push_back("bts_rc/player/helmet/hm_pain3.wav");
    helmet.takedamage.push_back("bts_rc/player/helmet/hm_pain4.wav");
    helmet.takedamage.push_back("bts_rc/player/helmet/hm_pain5.wav");
    helmet.killed.push_back("bts_rc/player/helmet/hm_death1.wav");
    helmet.killed.push_back("bts_rc/player/helmet/hm_death2.wav");
    helmet.killed.push_back("bts_rc/player/helmet/hm_death3.wav");
    helmet.killed.push_back("bts_rc/player/helmet/hm_death4.wav");

    // Cleansuit
    cleansuit.takedamage.cooldown = 1.0;
    cleansuit.takedamage.push_back("bts_rc/player/cleansuit/cl_pain1.wav");
    cleansuit.takedamage.push_back("bts_rc/player/cleansuit/cl_pain2.wav");
    cleansuit.takedamage.push_back("bts_rc/player/cleansuit/cl_pain3.wav");
    cleansuit.takedamage.push_back("bts_rc/player/cleansuit/cl_pain4.wav");
    cleansuit.takedamage.push_back("bts_rc/player/cleansuit/cl_pain5.wav");
    cleansuit.killed.push_back("bts_rc/player/cleansuit/cl_death1.wav");
    cleansuit.killed.push_back("bts_rc/player/cleansuit/cl_death2.wav");
    cleansuit.killed.push_back("bts_rc/player/cleansuit/cl_death3.wav");
    cleansuit.killed.push_back("bts_rc/player/cleansuit/cl_death4.wav");

    // Black Scientist
    bscientist.takedamage.cooldown = 1.0;
    bscientist.takedamage.pitch = 94.0f;
    bscientist.killed.pitch = 94.0f;
    bscientist.takedamage.push_back("scientist/sci_pain1.wav");
    bscientist.takedamage.push_back("scientist/sci_pain2.wav");
    bscientist.takedamage.push_back("scientist/sci_pain3.wav");
    bscientist.takedamage.push_back("scientist/sci_pain4.wav");
    bscientist.takedamage.push_back("scientist/sci_pain5.wav");
    bscientist.takedamage.push_back("scientist/sci_pain6.wav");
    bscientist.takedamage.push_back("scientist/sci_pain7.wav");
    bscientist.takedamage.push_back("scientist/sci_pain8.wav");
    bscientist.takedamage.push_back("scientist/sci_pain9.wav");
    bscientist.takedamage.push_back("scientist/sci_pain10.wav");
    bscientist.takedamage.push_back("scientist/sci_fear11.wav");
    bscientist.takedamage.push_back("scientist/sci_fear15.wav");
    bscientist.killed.push_back("scientist/sci_die1.wav");
    bscientist.killed.push_back("scientist/sci_die2.wav");
    bscientist.killed.push_back("scientist/sci_die3.wav");
    bscientist.killed.push_back("scientist/scream21.wav");
    bscientist.killed.push_back("scientist/scream23.wav");

    // Scientist
    scientist.takedamage.cooldown = 1.0;
    scientist.takedamage.push_back("scientist/sci_pain1.wav");
    scientist.takedamage.push_back("scientist/sci_pain2.wav");
    scientist.takedamage.push_back("scientist/sci_pain3.wav");
    scientist.takedamage.push_back("scientist/sci_pain4.wav");
    scientist.takedamage.push_back("scientist/sci_pain5.wav");
    scientist.takedamage.push_back("scientist/sci_pain6.wav");
    scientist.takedamage.push_back("scientist/sci_pain7.wav");
    scientist.takedamage.push_back("scientist/sci_pain8.wav");
    scientist.takedamage.push_back("scientist/sci_pain9.wav");
    scientist.takedamage.push_back("scientist/sci_pain10.wav");
    scientist.takedamage.push_back("scientist/sci_fear11.wav");
    scientist.takedamage.push_back("scientist/sci_fear15.wav");
    scientist.killed.push_back("scientist/sci_die1.wav");
    scientist.killed.push_back("scientist/sci_die2.wav");
    scientist.killed.push_back("scientist/sci_die3.wav");
    scientist.killed.push_back("scientist/scream21.wav");
    scientist.killed.push_back("scientist/scream23.wav");
    /*==========================================================================
    *   - End
    ==========================================================================*/

    /*==========================================================================
    *   - Start of precaching
    ==========================================================================*/
    for (uint ui = 0; ui < precache::sounds.length(); ui++)
        g_SoundSystem.PrecacheSound(precache::sounds[ui]);
    precache::sounds = {};

    for (uint ui = 0; ui < precache::models.length(); ui++)
        g_Game.PrecacheModel(precache::models[ui]);
    precache::models = {};

    for (uint ui = 0; ui < precache::generic.length(); ui++)
        g_Game.PrecacheGeneric(precache::generic[ui]);
    precache::generic = {};

    // Global model indexes
    models::WXplo1 = g_Game.PrecacheModel("sprites/WXplo1.spr");
    models::zerogxplode = g_Game.PrecacheModel("sprites/zerogxplode.spr");
    models::steam1 = g_Game.PrecacheModel("sprites/steam1.spr");
    models::laserbeam = g_Game.PrecacheModel("sprites/laserbeam.spr");
    models::shell = g_Game.PrecacheModel("models/hlclassic/shell.mdl");
    models::saw_shell = g_Game.PrecacheModel("models/bts_rc/weapons/saw_shell.mdl");
    models::shotgunshell = g_Game.PrecacheModel("models/hlclassic/shotgunshell.mdl");

#if SERVER
    g_Game.PrecacheOther("monster_headcrab");
#endif
    /*==========================================================================
    *   - End
    ==========================================================================*/

    /*==========================================================================
    *   - Start of hooks
    ==========================================================================*/
    g_Hooks.RegisterHook(Hooks::Player::PlayerPostThink, @player_think);
    g_Hooks.RegisterHook(Hooks::Player::PlayerTakeDamage, @player_takedamage);
    g_Hooks.RegisterHook(Hooks::Monster::MonsterKilled, @monster_killed);
    g_Hooks.RegisterHook(Hooks::Monster::MonsterTakeDamage, @monster_takedamage);
    g_Hooks.RegisterHook(Hooks::Player::PlayerLeftObserver, @PlayerLeftObserver );
    g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @OnPlayerPostThink );
    /* -TODO Remove this line in 5.27 */ if (g_Game.GetGameVersion() == 526)
    {
        g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @notice_assets::player_connect);
    }
    /*==========================================================================
    *   - End
    ==========================================================================*/
}

// Model indexes
namespace models
{
    int WXplo1;
    int zerogxplode;
    int steam1;
    int laserbeam;
    int shell;
    int saw_shell;
    int shotgunshell;
}

// sven only has 8192 edicts at any given time
// so assume each player carries exactly 16 weapons, and then leave 100 slots free for various temporary things. -Zode
bool freeedicts(int overhead = 1)
{
    return (g_EngineFuncs.NumberOfEntities() < g_Engine.maxEntities - (16 * g_Engine.maxClients) - 100 - overhead);
}

#if SERVER
// Should we display info of aiming entity?
void whatsthat(CBasePlayer @player)
{
    if (player !is null && player.IsConnected())
    {
        TraceResult tr;
        Math.MakeVectors(player.pev.v_angle);
        g_Utility.TraceLine(player.EyePosition(), player.EyePosition() + player.GetAutoaimVector(1.0) * 500.0f, dont_ignore_monsters, player.edict(), tr);

        if (g_EntityFuncs.IsValidEntity(tr.pHit))
        {
            CBaseEntity @hit = g_EntityFuncs.Instance(tr.pHit);

            if (hit !is null && hit.GetCustomKeyvalues().HasKeyvalue("$s_message"))
            {
                g_PlayerFuncs.ClientPrint(player, HUD_PRINTCENTER, hit.GetCustomKeyvalues().GetKeyvalue("$s_message").GetString() + "\n");
            }
        }
    }
}
#endif

// Barney > Scientist > Construction > Black Scientist    > Helmet > Cleansuit      > Operative > Black Otis      > Green Construction > Veterans
// Blue   > White     > Yellow       > White (Blk hand)   > Orange > White (Yellow) > Gray      > Blue (Blk Hand) > Green              > Gray (Speical)

enum PM
{
    UNSET = -1,
    BARNEY = 0,
    SCIENTIST = 1,
    CONSTRUCTION = 2,
    BSCIENTIST = 3,
    HELMET = 4,
    CLSUIT = 5,
    OPERATIVE = 6,
    OTIS = 7,
    GCONSTRUCTION = 8,
    VETERAN = 9
};

final class PlayerClass
{
    // Index of the last used model so we give each player a different one instead of a random one.
    private uint mdl_scientist_last = Math.RandomLong(0, 4);
    private array<string> mdl_scientist = {
        "bts_scientist",
        "bts_scientist3",
        "bts_scientist4",
        "bts_scientist5",
        "bts_scientist6"};
    private uint mdl_barney_last = Math.RandomLong(0, 2);
    private array<string> mdl_barney = {
        "bts_barney",
        "bts_barney2",
        "bts_barney3"};
    private uint mdl_con_last = Math.RandomLong(0, 3);
    private array<string> mdl_con = {
        "bts_construction",
        "bts_construction2",
        "bts_construction3"};
    private uint mdl_operative_last = Math.RandomLong(0, 5);
    private array<string> mdl_operative = {
        "bts_op",
        "bts_op2",
        "bts_op3",
        "bts_op4",
        "bts_op5",
        "bts_op6"};

    const PM opIndex(CBasePlayer @player, bool DontSet = false)
    {
        if (player !is null)
        {
            dictionary @data = player.GetUserData();

            if (!data.exists("class"))
            {
                if (DontSet)
                {
                    return PM::UNSET;
                }

                switch( Math.RandomLong( 1, 3 ) )
                {
                    case 1:
                        g_PlayerClass.set_class( player, PM::BARNEY );
                    break;
                    case 2:
                        g_PlayerClass.set_class( player, PM::CONSTRUCTION );
                    break;
                    case 3:
                        g_PlayerClass.set_class( player, PM::OPERATIVE );
                    break;
                }
            }

            return PM(data["class"]);
        }

        return PM::SCIENTIST;
    }

    bool is_trained_personal(CBasePlayer @player)
    {
        PM pm = g_PlayerClass[player];

        switch (pm)
        {
            case PM::BARNEY:
            case PM::OTIS:
            case PM::VETERAN:
            case PM::OPERATIVE:
            case PM::HELMET:
            case PM::CLSUIT:
                return true;
        }
        return false;
    }

    void set_class(CBasePlayer @player, PM player_class)
    {
        const string model = this.model(player_class);

        // Update class for bodygroups of view models n
        if (model == "bts_scientist3")
        {
            player_class = PM::BSCIENTIST;
        }
        if (model == "bts_construction2")
        {
            player_class = PM::GCONSTRUCTION;
        }
        if (model == "bts_otis_blk")
        {
            player_class = PM::OTIS;
        }

        player.GetUserData()["pm"] = model;
        player.GetUserData()["class"] = player_class;

        // Hide flashlight icon.
        player.m_iHideHUD |= HIDEHUD_FLASHLIGHT;

        player.pev.armortype = (player_class == PM::HELMET ? 100 : 50);

        // Re-Deploy weapon to update view model hands
        if (player.m_hActiveItem.IsValid())
        {
            CBaseEntity @active_item = player.m_hActiveItem.GetEntity();

            if (active_item !is null)
            {
                CBasePlayerItem @weapon = cast<CBasePlayerItem @>(active_item);

                if (weapon !is null)
                {
                    weapon.Deploy();
                }
            }
        }
    }

    // Return a player model for the given class
    const string& model(const PM player_class)
    {
        switch (player_class)
        {
            case PM::SCIENTIST:
            {
                mdl_scientist_last = (mdl_scientist_last >= mdl_scientist.length() - 1) ? 0 : mdl_scientist_last + 1;
                return mdl_scientist[mdl_scientist_last];
            }
            case PM::CONSTRUCTION:
            {
                mdl_con_last = (mdl_con_last >= mdl_con.length() - 1) ? 0 : mdl_con_last + 1;
                return mdl_con[mdl_con_last];
            }
            case PM::BARNEY:
            {
                mdl_barney_last = (mdl_barney_last >= mdl_barney.length() - 1) ? 0 : mdl_barney_last + 1;
                return mdl_barney[mdl_barney_last];
            }
            case PM::OPERATIVE:
            {
                mdl_operative_last = (mdl_operative_last >= mdl_operative.length() - 1) ? 0 : mdl_operative_last + 1;
                return mdl_operative[mdl_operative_last];
            }
            case PM::CLSUIT:
            {
                return "bts_cleansuit";
            }
            case PM::HELMET:
            {
                return "bts_helmet";
            }
        }
        return "bts_op3";
    }
}

PlayerClass g_PlayerClass;

namespace item_tracker
{
    // Last frame we did an operation.
    float time;
    // String containing all the information.
    string buffer;
}

//================================================================================================
//  Shows a MOTD message to the player
//  Code by Giegue. Taken from: https://github.com/JulianR0/TPvP/blob/master/src/plugins/TPvP.as#L7375
//================================================================================================
namespace motd
{
    void open(CBasePlayer @player, const string&in buffer)
    {
        if (player !is null && player.IsConnected())
        {
            uint iChars = 0;

            string szSplitMsg = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

            for (uint uChars = 0; uChars < item_tracker::buffer.Length(); uChars++)
            {
                szSplitMsg.SetCharAt(iChars, char(item_tracker::buffer[uChars]));
                iChars++;

                if (iChars == 32)
                {
                    NetworkMessage motd_append(MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict());
                    motd_append.WriteByte(0);
                    motd_append.WriteString(szSplitMsg);
                    motd_append.End();

                    iChars = 0;
                }
            }

            // If we reached the end, send the last letters of the message
            if (iChars > 0)
            {
                szSplitMsg.Truncate(iChars);

                NetworkMessage motd_fix(MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict());
                motd_fix.WriteByte(0);
                motd_fix.WriteString(szSplitMsg);
                motd_fix.End();
            }

            NetworkMessage motd_open(MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, player.edict());
            motd_open.WriteByte(1);
            motd_open.WriteString("\n");
            motd_open.End();
        }
    }
}

// Do we really need a script to do this?
namespace survival
{
    // This is stupid.
    void activate(CBaseEntity @pActivator, CBaseEntity @pCaller, USE_TYPE useType, float flValue)
    {
        g_SurvivalMode.Activate();
    }

    // Still stupid.
    void deactivate(CBaseEntity @pActivator, CBaseEntity @pCaller, USE_TYPE useType, float flValue)
    {
        g_SurvivalMode.Disable();
    }

    // Even more stupid.
    void toggle(CBaseEntity @pActivator, CBaseEntity @pCaller, USE_TYPE useType, float flValue)
    {
        if (g_SurvivalMode.IsActive())
        {
            deactivate(null, null, USE_SET, 0);
        }
        else
        {
            activate(null, null, USE_SET, 0);
        }
    }

    void enabled(CBaseEntity @pActivator, CBaseEntity @pCaller, USE_TYPE useType, float flValue)
    {
        g_EntityFuncs.FireTargets((g_SurvivalMode.MapSupportEnabled() && g_SurvivalMode.IsActive() ? "GM_SURVIVAL_ACTIVE" : "GM_SURVIVAL_INACTIVE"), null, null, USE_TOGGLE, 0, 0);
    }
}

// CRAP AHEAD! I know zzzzz but the map actually takes a lot to load so i'll optimize these as much as i can.
namespace precache
{
    array<string> sounds =
        {
            "bts_rc/items/armor_pickup1.wav",
            "bts_rc/items/battery_pickup1.wav",
            "bts_rc/items/battery_reload.wav",
            "bts_rc/items/nvg_off.wav",
            "bts_rc/items/nvg_on.wav",
            "bts_rc/items/sprayaid1.wav",
            "bts_rc/weapons/axe_hit1.wav",
            "bts_rc/weapons/axe_hit2.wav",
            "bts_rc/weapons/axe_hitbod1.wav",
            "bts_rc/weapons/axe_hitbod2.wav",
            "bts_rc/weapons/axe_hitbod3.wav",
            "bts_rc/weapons/axe_miss1.wav",
            "bts_rc/weapons/beretta_fire1.wav",
            "bts_rc/weapons/flare_bounce.wav",
            "bts_rc/weapons/flare_on.wav",
            "bts_rc/weapons/flare_pickup.wav",
            "bts_rc/weapons/flaregun_reload1.wav",
            "bts_rc/weapons/flaregun_reload2.wav",
            "bts_rc/weapons/flaregun_shot1.wav",
            "bts_rc/weapons/flarehit1.wav",
            "bts_rc/weapons/flarehitbod1.wav",
            "bts_rc/weapons/flashlight_hit1.wav",
            "bts_rc/weapons/flashlight_hit2.wav",
            "bts_rc/weapons/flashlight_hitbod1.wav",
            "bts_rc/weapons/flashlight_hitbod2.wav",
            "bts_rc/weapons/flashlight_hitbod3.wav",
            "bts_rc/weapons/flashlight_miss1.wav",
            "bts_rc/weapons/flmfire2.wav",
            "bts_rc/weapons/flmgrexp.wav",
            "bts_rc/weapons/flare_deploy.wav",
            "bts_rc/weapons/glock18_fire1.wav",
            "bts_rc/weapons/glock_fire1.wav",
            "bts_rc/weapons/glocksd_fire1.wav",
            "bts_rc/weapons/glocksd_fire2.wav",
            "bts_rc/weapons/gun_fire4.wav",
            "bts_rc/weapons/m16_fire1.wav",
            "bts_rc/weapons/m4_fire1.wav",
            "bts_rc/weapons/fidget_3.wav",
            "bts_rc/weapons/fidget1.wav",
            "bts_rc/weapons/m4sd_fire1.wav",
            "bts_rc/weapons/m79_fire.wav",
            "bts_rc/weapons/mp5_fire1.wav",
            "bts_rc/weapons/mp5_slap.wav",
            "bts_rc/weapons/pipe_hit1.wav",
            "bts_rc/weapons/9mm_draw.wav",
            "bts_rc/weapons/pipe_hit2.wav",
            "bts_rc/weapons/saw_reload2.wav",
            "bts_rc/weapons/pipe_hitbod1.wav",
            "bts_rc/weapons/pipe_hitbod2.wav",
            "bts_rc/weapons/pipe_hitbod3.wav",
            "bts_rc/weapons/pipe_miss1.wav",
            "bts_rc/weapons/mp5_clip.wav",
            "hlclassic/weapons/g_bounce3.wav",
            "bts_rc/weapons/cbar_draw.wav",
            "bts_rc/weapons/grenade_pinpull.wav",
            "weapons/pwrench_big_hit1.wav",
            "weapons/pwrench_big_hit2.wav",
            "bts_rc/weapons/grenade_draw.wav",
            "bts_rc/weapons/grenade_throw1.wav",
            "zombie/claw_strike1.wav",
            "zombie/claw_strike2.wav",
            "zombie/claw_strike3.wav",
            "zombie/claw_miss1.wav",
            "zombie/claw_miss2.wav",
            "zombie/zo_attack1.wav",
            "zombie/zo_attack2.wav",
            "zombie/zo_idle1.wav",
            "zombie/zo_idle2.wav",
            "zombie/zo_idle3.wav",
            "zombie/zo_idle4.wav",
            "zombie/zo_alert10.wav",
            "zombie/zo_alert20.wav",
            "zombie/zo_alert30.wav",
            "zombie/zo_pain1.wav",
            "zombie/zo_pain2.wav",
            "bullchicken/bc_bite1.wav",
            "bullchicken/bc_bite2.wav",
            "bullchicken/bc_bite3.wav",
            "bts_rc/weapons/grenade_throw2.wav",
            "bts_rc/weapons/sniper_fire.wav",
            "bts_rc/weapons/sniper_reload_first_seq.wav",
            "sound/weapons/sniper_reload_second_seq.wav",
            "bts_rc/weapons/sniper_bolt1.wav",
            "bts_rc/weapons/sniper_bolt2.wav",
            "weapons/pwrench_big_hitbod1.wav",
            "weapons/pwrench_big_hitbod2.wav",
            "weapons/pwrench_big_miss.wav",
            "weapons/pwrench_hit1.wav",
            "weapons/pwrench_hit2.wav",
            "weapons/pwrench_hitbod1.wav",
            "weapons/pwrench_hitbod2.wav",
            "weapons/pwrench_hitbod3.wav",
            "bts_rc/weapons/9mm_clip.wav",
            "weapons/pwrench_miss1.wav",
            "bts_rc/weapons/reload1.wav",
            "bts_rc/weapons/reload3.wav",
            "bts_rc/weapons/sbshotgun_fire1.wav",
            "bts_rc/weapons/sbscock1.wav",
            "bts_rc/snapbug/sb_idle1.wav",
            "bts_rc/snapbug/sb_idle2.wav",
            "bts_rc/snapbug/sb_idle1.wav",
            "bts_rc/snapbug/sb_alert3.wav",
            "bts_rc/snapbug/sb_pain1.wav",
            "bts_rc/snapbug/sb_pain2.wav",
            "bts_rc/snapbug/sb_pain1.wav",
            "bts_rc/snapbug/sb_attack1.wav",
            "bts_rc/snapbug/sb_attack2.wav",
            "bts_rc/snapbug/sb_attack1.wav",
            "bts_rc/snapbug/sb_die1.wav",
            "bts_rc/snapbug/sb_die2.wav",
            "headcrab/hc_headbite.wav",
            "bts_rc/weapons/sd_hit1.wav",
            "bts_rc/weapons/sd_hit2.wav",
            "bts_rc/weapons/sd_hitbod1.wav",
            "bts_rc/weapons/sd_hitbod2.wav",
            "bts_rc/weapons/sd_hitbod3.wav",
            "bts_rc/weapons/sd_miss1.wav",
            "bts_rc/weapons/spas12_dbarrel1.wav",
            "bts_rc/weapons/uzi_fire1.wav",
            "bts_rc/weapons/m79_close.wav",
            "bts_rc/weapons/xbow_fire1.ogg",
            "bts_rc/weapons/saw_reload.wav",
            "bts_rc/rgrunt/rbhw_shield_smash.ogg", // i dont have the file but juuust in case
            "debris/wood1.wav",
            "debris/wood2.wav",
            "hlclassic/items/9mmclip1.wav",
            "hlclassic/weapons/357_cock1.wav",
            "hlclassic/weapons/357_shot1.wav",
            "hlclassic/weapons/357_reload1.wav",
            "hlclassic/weapons/357_shot2.wav",
            "hlclassic/weapons/glauncher.wav",
            "hlclassic/weapons/glauncher2.wav",
            "hlclassic/weapons/reload1.wav",
            "hlclassic/weapons/reload2.wav",
            "hlclassic/weapons/reload3.wav",
            "hlclassic/weapons/sbarrel1.wav",
            "hlclassic/weapons/scock1.wav",
            "items/flashlight1.wav",
            "items/gunpickup2.wav",
            "items/medshot4.wav",
            "items/medshotno1.wav",
            "items/suitcharge1.wav",
            "items/suitchargeno1.wav",
            "items/suitchargeok1.wav",
            "vox/authorized.wav",
            "vox/maintenance.wav",
            "vox/research.wav",
            "vox/security.wav",
            "vox/user.wav",
            "weapons/ric1.wav",
            "weapons/ric2.wav",
            "weapons/ric3.wav",
            "weapons/ric4.wav",
            "weapons/ric5.wav",
            "weapons/cbar_hit1.wav",
            "weapons/cbar_hit2.wav",
            "weapons/cbar_hitbod1.wav",
            "weapons/cbar_hitbod2.wav",
            "weapons/cbar_hitbod3.wav",
            "weapons/cbar_miss1.wav",
            "weapons/desert_eagle_fire.wav",
            "weapons/electro4.wav",
            "weapons/knife1.wav",
            "weapons/knife2.wav",
            "weapons/knife3.wav",
            "weapons/knife_hit_flesh1.wav",
            "weapons/knife_hit_flesh2.wav",
            "weapons/knife_hit_wall1.wav",
            "weapons/knife_hit_wall2.wav",
            "bts_rc/weapons/38_shot1.wav",
            "bts_rc/weapons/38_shot2.wav",
            "bts_rc/weapons/sw_bullet_insert_1.wav",
            "bts_rc/weapons/sw_cylinder_open.wav",
            "bts_rc/weapons/sw_cylinder_close.wav",
            "weapons/xbow_hit1.wav",
            "weapons/xbow_hitbod1.wav"};

    array<string> models =
        {
            "models/bshift/barney_helmet.mdl",
            "models/bshift/barney_vest.mdl",
            "models/bts_rc/furniture/w_flashlightbattery.mdl",
            "models/bts_rc/items/w_medkits.mdl",
            "models/bts_rc/weapons/flare.mdl",
            "models/bts_rc/weapons/p_9mmARGL.mdl",
            "models/bts_rc/weapons/p_9mmar.mdl",
            "models/bts_rc/monsters/zombie_barney.mdl",
            "models/bts_rc/monsters/zombie_blackops.mdl",
            "models/bts_rc/weapons/p_9mmhandgunsd.mdl",
            "models/bts_rc/weapons/p_axe.mdl",
            "models/bts_rc/weapons/p_beretta.mdl",
            "models/bts_rc/weapons/p_desert_eagle.mdl",
            "models/bts_rc/weapons/p_sw637.mdl",
            "models/bts_rc/weapons/p_flame.mdl",
            "models/bts_rc/weapons/p_flare.mdl",
            "models/bts_rc/weapons/p_flaregun.mdl",
            "models/bts_rc/weapons/p_flashlight.mdl",
            "models/bts_rc/weapons/p_glock17f.mdl",
            "models/bts_rc/weapons/p_glock18.mdl",
            "models/bts_rc/weapons/p_m16.mdl",
            "models/bts_rc/weapons/p_m16sd.mdl",
            "models/bts_rc/weapons/p_m4.mdl",
            "models/bts_rc/weapons/p_m4sd.mdl",
            "models/bts_rc/weapons/p_m79.mdl",
            "models/bts_rc/weapons/p_medkit.mdl",
            "models/bts_rc/weapons/p_pipe.mdl",
            "models/bts_rc/weapons/p_pipe_wrench.mdl",
            "models/bts_rc/weapons/p_poolstick.mdl",
            "models/bts_rc/weapons/p_saw.mdl",
            "models/bts_rc/weapons/p_sawsd.mdl",
            "models/bts_rc/weapons/p_sbshotgun.mdl",
            "models/bts_rc/weapons/p_screwdriver.mdl",
            "models/bts_rc/weapons/p_shotgun.mdl",
            "models/bts_rc/weapons/p_uzi.mdl",
            "models/bts_rc/weapons/p_uzisd.mdl",
            "models/bts_rc/weapons/p_m40a1.mdl",
            "models/bts_rc/weapons/v_357.mdl",
            "models/bts_rc/weapons/v_9mmARGL.mdl",
            "models/bts_rc/weapons/v_9mmar.mdl",
            "models/bts_rc/weapons/v_9mmhandgun.mdl",
            "models/bts_rc/weapons/v_9mmhandgunsd.mdl",
            "models/bts_rc/weapons/v_axe.mdl",
            "models/bts_rc/weapons/v_beretta.mdl",
            "models/bts_rc/weapons/v_crowbar.mdl",
            "models/bts_rc/weapons/v_desert_eagle.mdl",
            "models/bts_rc/weapons/v_sw637.mdl",
            "models/bts_rc/weapons/v_flame.mdl",
            "models/bts_rc/weapons/v_flare.mdl",
            "models/bts_rc/weapons/v_flaregun.mdl",
            "models/bts_rc/weapons/v_flashlight.mdl",
            "models/bts_rc/weapons/v_glock17f.mdl",
            "models/bts_rc/weapons/v_glock18.mdl",
            "models/bts_rc/weapons/v_grenade.mdl",
            "models/bts_rc/weapons/v_knife.mdl",
            "models/bts_rc/weapons/v_m16a2.mdl",
            "models/bts_rc/weapons/v_m16a2sd.mdl",
            "models/bts_rc/weapons/v_m4.mdl",
            "models/bts_rc/weapons/v_m4sd.mdl",
            "models/bts_rc/weapons/v_m79.mdl",
            "models/bts_rc/weapons/v_medkit.mdl",
            "models/bts_rc/weapons/v_pipe.mdl",
            "models/bts_rc/weapons/v_pipe_wrench.mdl",
            "models/bts_rc/weapons/v_poolstick.mdl",
            "models/bts_rc/weapons/v_m40a1.mdl",
            "models/bts_rc/weapons/v_saw.mdl",
            "models/bts_rc/weapons/v_sawsd.mdl",
            "models/bts_rc/weapons/v_sbshotgun.mdl",
            "models/bts_rc/weapons/v_screwdriver.mdl",
            "models/bts_rc/weapons/v_shotgun.mdl",
            "models/bts_rc/weapons/v_uzi.mdl",
            "models/bts_rc/weapons/v_uzisd.mdl",
            "models/bts_rc/weapons/w_556nato.mdl",
            "models/bts_rc/weapons/w_9mmARGL.mdl",
            "models/bts_rc/weapons/w_9mmar.mdl",
            "models/bts_rc/weapons/w_9mmarclip.mdl",
            "models/bts_rc/weapons/w_9mmhandgunsd.mdl",
            "models/bts_rc/weapons/w_axe.mdl",
            "models/bts_rc/weapons/w_beretta.mdl",
            "models/bts_rc/weapons/w_desert_eagle.mdl",
            "models/bts_rc/weapons/w_sw637.mdl",
            "models/bts_rc/weapons/w_sw637_ammobox.mdl",
            "models/bts_rc/weapons/w_flame.mdl",
            "models/bts_rc/weapons/w_flare.mdl",
            "models/bts_rc/weapons/w_flaregun.mdl",
            "models/bts_rc/weapons/w_flaregun_clip.mdl",
            "models/bts_rc/weapons/w_flashlight.mdl",
            "models/hunger/w_gas.mdl",
            "models/bts_rc/null.mdl",
            "models/bts_rc/weapons/w_m16.mdl",
            "models/bts_rc/weapons/w_m16sd.mdl",
            "models/bts_rc/weapons/w_m4.mdl",
            "models/bts_rc/weapons/w_m4sd.mdl",
            "models/bts_rc/weapons/w_m79.mdl",
            "models/bts_rc/weapons/w_medkit.mdl",
            "models/bts_rc/weapons/w_pmedkit.mdl",
            "models/bts_rc/weapons/w_pipe.mdl",
            "models/bts_rc/weapons/w_pipe_wrench.mdl",
            "models/bts_rc/weapons/w_poolstick.mdl",
            "models/bts_rc/weapons/w_saw.mdl",
            "models/bts_rc/weapons/w_sawsd.mdl",
            "models/bts_rc/weapons/w_saw_clip.mdl",
            "models/bts_rc/weapons/w_sbshotgun.mdl",
            "models/bts_rc/weapons/w_screwdriver.mdl",
            "models/bts_rc/weapons/w_shotgun.mdl",
            "models/bts_rc/weapons/w_uzi.mdl",
            "models/bts_rc/weapons/w_m40a1.mdl",
            "models/bts_rc/weapons/w_uzisd.mdl",
            "models/bts_rc/weapons/w_uzi_clip.mdl",
            "models/hlclassic/grenade.mdl",
            "models/hlclassic/p_357.mdl",
            "models/bts_rc/weapons/p_9mmhandgun.mdl",
            "models/hlclassic/p_crowbar.mdl",
            "models/hlclassic/w_shotshell.mdl",
            "models/hlclassic/p_grenade.mdl",
            "models/hlclassic/w_357.mdl",
            "models/hlclassic/w_357ammo.mdl",
            "models/hlclassic/w_357ammobox.mdl",
            "models/hlclassic/w_9mmarclip.mdl",
            "models/hlclassic/w_9mmclip.mdl",
            "models/bts_rc/weapons//w_9mmhandgun.mdl",
            "models/bts_rc/weapons/w_glock17f.mdl",
            "models/bts_rc/weapons/w_glock18.mdl",
            "models/hlclassic/w_argrenade.mdl",
            "models/bts_rc/weapons/w_argrenade_solo.mdl",
            "models/bts_rc/weapons/w_357ammo.mdl",
            "models/bts_rc/weapons/w_357ammobox.mdl",
            "models/bts_rc/weapons/w_battery.mdl",
            "models/bts_rc/weapons/w_crowbar.mdl",
            "models/hlclassic/w_grenade.mdl",
            "models/bts_rc/weapons/w_shotbox.mdl",
            "models/mikk/misc/bloodpuddle.mdl",
            "models/opfor/p_knife.mdl",
            "models/opfor/w_knife.mdl",
            "models/tool_box.mdl",
            "models/w_security.mdl",
            "models/bts_rc/items/w_antidote.mdl",
            "models/w_shotshell.mdl",
            "models/bts_rc/monsters/snapbugattach.mdl",
            "models/bts_rc/monsters/snapbug.mdl",
            "sprites/SAWFlash.spr",
            "sprites/glow01.spr",
            "sprites/bts_rc/640hudof01.spr",
            "sprites/bts_rc/640hudof02.spr",
            "sprites/bts_rc/M79_crosshair.spr",
            "sprites/bts_rc/ablood_1.spr",
            "sprites/bts_rc/ablood_2.spr",
            "sprites/bts_rc/ablood_3.spr",
            "sprites/bts_rc/ablood_4.spr",
            "sprites/bts_rc/ablood_5.spr",
            "sprites/bts_rc/ammo_battery.spr",
            "sprites/bts_rc/ammo_flare.spr",
            "sprites/bts_rc/flare_selection.spr",
            "sprites/bts_rc/hblood_1.spr",
            "sprites/bts_rc/hblood_2.spr",
            "sprites/bts_rc/hblood_3.spr",
            "sprites/bts_rc/inv_card_maint.spr",
            "sprites/bts_rc/inv_card_research.spr",
            "sprites/bts_rc/inv_card_security.spr",
            "sprites/bts_rc/muzzleflash12.spr",
            "sprites/bts_rc/screwd.spr",
            "sprites/bts_rc/w_beretta.spr",
            "sprites/bts_rc/w_flare.spr",
            "sprites/bts_rc/w_glocksd1.spr",
            "sprites/bts_rc/w_glocksd4.spr",
            "sprites/bts_rc/weapon_M79.spr",
            "sprites/bts_rc/fthrow.spr",
            "sprites/bts_rc/opaqueexplode02.spr",
            "sprites/bts_rc/bts_rc_snapbug.spr",
            "sprites/bts_rc/tfchud07.spr",
            "sprites/bts_rc/wepspr.spr",
            "sprites/bts_rc/gametitle.spr", //Nero ADDED 2026-01-10
            //Playermodels
            "models/player/bts_barney/bts_barney.mdl",
            "models/player/bts_barney3/bts_barney3.mdl",
            "models/player/bts_cleansuit/bts_cleansuit.mdl",
            "models/player/bts_construction2/bts_construction2.mdl",
            "models/player/bts_construction3/bts_construction3.mdl",
            "models/player/bts_op/bts_op.mdl",
            "models/player/bts_op2/bts_op2.mdl",
            "models/player/bts_op3/bts_op3.mdl",
            "models/player/bts_op4/bts_op4.mdl",
            "models/player/bts_op5/bts_op5.mdl",
            "models/player/bts_op6/bts_op6.mdl",
            "models/player/bts_op_band/bts_op_band.mdl",
            "models/player/bts_op_free/bts_op_free.mdl",
            "models/player/bts_op_hurt/bts_op_hurt.mdl",
            "models/player/bts_otis/bts_otis.mdl",
            "models/player/bts_otis2/bts_otis2.mdl",
            "models/player/bts_otis_blk/bts_otis_blk.mdl",
            "models/player/bts_scientist2/bts_scientist2.mdl",
            "models/player/bts_scientist3/bts_scientist3.mdl",
            "models/player/bts_scientist4/bts_scientist4.mdl",
            "models/player/bts_scientist5/bts_scientist5.mdl",
            "models/player/bts_scientist6/bts_scientist6.mdl"};

    array<string> generic =
        {
            "events/muzzle_saw.txt",
            "sprites/bts_rc/weapons/weapon_bts_pipewrench.txt",
            "sprites/bts_rc/weapons/weapon_bts_axe.txt",
            "sprites/bts_rc/weapons/weapon_bts_beretta.txt",
            "sprites/bts_rc/weapons/weapon_bts_crowbar.txt",
            "sprites/bts_rc/weapons/weapon_bts_eagle.txt",
            "sprites/bts_rc/weapons/weapon_bts_flamethrower.txt",
            "sprites/bts_rc/weapons/weapon_bts_flare.txt",
            "sprites/bts_rc/weapons/weapon_bts_flaregun.txt",
            "sprites/bts_rc/weapons/weapon_bts_sw637.txt",
            "sprites/bts_rc/weapons/weapon_bts_glock.txt",
            "sprites/bts_rc/weapons/weapon_bts_glock17f.txt",
            "sprites/bts_rc/weapons/weapon_bts_glock18.txt",
            "sprites/bts_rc/weapons/weapon_bts_glocksd.txt",
            "sprites/bts_rc/weapons/weapon_bts_handgrenade.txt",
            "sprites/bts_rc/weapons/weapon_bts_knife.txt",
            "sprites/bts_rc/weapons/weapon_bts_m16.txt",
            "sprites/bts_rc/weapons/weapon_bts_m16sd.txt",
            "sprites/bts_rc/weapons/weapon_bts_m4.txt",
            "sprites/bts_rc/weapons/weapon_bts_m4sd.txt",
            "sprites/bts_rc/weapons/weapon_bts_m79.txt",
            "sprites/bts_rc/weapons/weapon_bts_medkit.txt",
            "sprites/bts_rc/weapons/weapon_bts_mp5.txt",
            "sprites/bts_rc/weapons/weapon_bts_mp5gl.txt",
            "sprites/bts_rc/weapons/weapon_bts_pipe.txt",
            "sprites/bts_rc/weapons/weapon_bts_poolstick.txt",
            "sprites/bts_rc/weapons/weapon_bts_python.txt",
            "sprites/bts_rc/weapons/weapon_bts_saw.txt",
            "sprites/bts_rc/weapons/weapon_bts_sawsd.txt",
            "sprites/bts_rc/weapons/weapon_bts_sbshotgun.txt",
            "sprites/bts_rc/weapons/weapon_bts_screwdriver.txt",
            "sprites/bts_rc/weapons/weapon_bts_shotgun.txt",
            "sprites/bts_rc/weapons/weapon_bts_uzi.txt",
            "sprites/bts_rc/weapons/weapon_bts_uzisd.txt"};
}
