mixin class CBaseWeapon
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
                if( gpTraceBlood && tr.iHitgroup != 10 && hit.IsMonster() && freeedicts(1) )
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

                bool should_sparks = gpTraceSparks;
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
