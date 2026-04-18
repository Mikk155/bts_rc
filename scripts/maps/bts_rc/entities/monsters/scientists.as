/**   MIT License
*   
*   Copyright (c) 2025 Mikk155 https://github.com/Mikk155/bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies or substantial portions of the Software.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*   SOFTWARE.
*/

/*
    Author: Nero
*/

namespace btscm
{

void ScientistThink()
{
    CBaseEntity@ pEntity = null;
    while( (@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "monster_scientist")) !is null )
    {
        CBaseMonster@ pMonster = pEntity.MyMonsterPointer();
        if( pMonster is null or pMonster.m_MonsterState == MONSTERSTATE_NONE or IgnoreThisScientist(EHandle(pEntity)) )
            continue;

        CustomKeyvalues@ pCustom = pEntity.GetCustomKeyvalues();
        float flNextThink = pCustom.GetKeyvalue(KVN_MONSTERTHINK).GetFloat();

        if( flNextThink <= g_Engine.time )
        {
            if( pEntity.pev.deadflag == DEAD_NO )
                CheckForRevive( EHandle(pEntity) );

            pCustom.SetKeyvalue( KVN_MONSTERTHINK, g_Engine.time + THINKRATE_OTHER );
        }
    }
}

bool IgnoreThisScientist( EHandle hMonster )
{
    CBaseMonster@ pMonster = hMonster.GetEntity().MyMonsterPointer();
    if( pMonster is null ) return true;
    if( pMonster.pev.SpawnFlagBitSet(256) ) return true; //Pre-Disaster

    return false;
}

void CheckForRevive( EHandle hMonster )
{
    CBaseMonster@ pMonster = hMonster.GetEntity().MyMonsterPointer();
    if( pMonster is null ) return;

    if( pMonster.m_hTargetEnt.IsValid() and pMonster.m_hTargetEnt.GetEntity().GetClassname() == "player" )
    {
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( pMonster.m_hTargetEnt.GetEntity() );
        if( pPlayer is null or pPlayer.IsAlive() or pPlayer.pev.iuser1 == OBS_NONE )
            return;

        CBaseEntity@ pCorpse = null;
        while( (@pCorpse = g_EntityFuncs.FindEntityByClassname(pCorpse, "deadplayer")) !is null )
        {
            if( pCorpse.pev.renderfx == kRenderFxDeadPlayer and pCorpse.pev.renderamt >= 0 )
            {
                CBaseEntity@ cbePlayer = g_EntityFuncs.Instance( int(pCorpse.pev.renderamt) );
                if( cbePlayer !is null and cbePlayer is pMonster.m_hTargetEnt.GetEntity() )
                {
                    if( (pMonster.pev.origin - pCorpse.pev.origin).Length() > 128.0 )
                        pMonster.m_hTargetEnt = EHandle( pCorpse );
                    else
                        pMonster.m_hTargetEnt = EHandle( cbePlayer );

                    //keep the player in place while revive is in progress, otherwise the scientist will follow the observer player blyat
                    if( (pMonster.pev.origin - pCorpse.pev.origin).Length() <= 128.0 and (cbePlayer.pev.origin - pCorpse.pev.origin).Length() > 16.0 )
                    {
                        if( pPlayer !is null and pPlayer.pev.iuser1 != OBS_ROAMING )
                        {
                            pPlayer.GetObserver().SetMode( OBS_ROAMING );
                            pPlayer.GetObserver().SetObserverModeControlEnabled( false );
                        }

                        pPlayer.pev.effects &= ~EF_NODRAW;
                        pPlayer.pev.rendermode = kRenderTransColor;
                        pPlayer.pev.renderamt = 0;

                        g_EntityFuncs.SetOrigin( cbePlayer, pCorpse.pev.origin );
                    }

                    break;
                }
            }
        }

        //g_Game.AlertMessage( at_notice, "m_hTargetEnt: %1\n", pMonster.m_hTargetEnt.GetEntity().GetClassname() );
    }
}

void ScientistMapInit()
{
    g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @PlayerPreThink );
}

HookReturnCode PlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags )
{
    if( pPlayer.pev.iuser1 != OBS_NONE )
    {
        CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
        float flNextThink = pCustom.GetKeyvalue(KVN_PLAYERTHINK).GetFloat();

        if( flNextThink <= g_Engine.time )
        {
            CBaseEntity@ pCorpse = null;
            while( (@pCorpse = g_EntityFuncs.FindEntityByClassname(pCorpse, "deadplayer")) !is null )
            {
                if( pCorpse.pev.renderfx == kRenderFxDeadPlayer and pCorpse.pev.renderamt >= 0 )
                {
                    CBaseEntity@ cbePlayer = g_EntityFuncs.Instance( int(pCorpse.pev.renderamt) );
                    if( cbePlayer !is null and cbePlayer is pPlayer )
                    {
                        if( (cbePlayer.pev.origin - pCorpse.pev.origin).Length() <= 128.0 )
                        {
                            pPlayer.pev.effects &= ~EF_NODRAW;
                            pPlayer.pev.rendermode = kRenderTransColor;
                            pPlayer.pev.renderamt = 0;
                        }
                        else
                        {
                            pPlayer.pev.effects |= EF_NODRAW;
                            pPlayer.pev.rendermode = kRenderNormal;
                        }

                        break;
                    }
                }
            }

            pCustom.SetKeyvalue( KVN_PLAYERTHINK, g_Engine.time + THINKRATE_PLAYER );
        }
    }

    return HOOK_CONTINUE;
}

} //namespace btscm END

/* TODO
    Move ScientistThink stuff into PlayerPreThink ??
*/


/* NOTES

//g_Game.AlertMessage( at_notice, "m_pSchedule: %1\n", pMonster.m_pSchedule.szName() );
//ScheduleFromName "Revive Speak/Revive"

kneel_idle
of1_a1_cpr1

slScientistCPRrevive: sequence 56 "lean", 49 "cprscientist"

kRenderFxDeadPlayer   17   kRenderAmt is the player index  

void CopyToBodyQue(entvars_t *pev) 
{
    if (pev->effects & EF_NODRAW)
        return;

    entvars_t *pevHead  = VARS(g_pBodyQueueHead);

    pevHead->angles     = pev->angles;
    pevHead->model      = pev->model;
    pevHead->modelindex = pev->modelindex;
    pevHead->frame      = pev->frame;
    pevHead->colormap   = pev->colormap;
    pevHead->movetype   = MOVETYPE_TOSS;
    pevHead->velocity   = pev->velocity;
    pevHead->flags      = 0;
    pevHead->deadflag   = pev->deadflag;
    pevHead->renderfx   = kRenderFxDeadPlayer;
    pevHead->renderamt  = ENTINDEX( ENT( pev ) );

    pevHead->effects    = pev->effects | EF_NOINTERP;
    //pevHead->goalstarttime = pev->goalstarttime;
    //pevHead->goalframe    = pev->goalframe;
    //pevHead->goalendtime = pev->goalendtime ;
    
    pevHead->sequence = pev->sequence;
    pevHead->animtime = pev->animtime;

    UTIL_SetOrigin(pevHead, pev->origin);
    UTIL_SetSize(pevHead, pev->mins, pev->maxs);
    g_pBodyQueueHead = pevHead->owner;
} 
*/