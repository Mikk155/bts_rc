/*
    Author: Mikk
*/

namespace BloodSplash
{
    array<string>@ Red = {
        "sprites/test/hblood_1.spr",
        "sprites/test/hblood_2.spr",
        "sprites/test/hblood_3.spr"
    };

    array<string>@ Yellow = {
        "sprites/test/ablood_1.spr",
        "sprites/test/ablood_2.spr",
        "sprites/test/ablood_3.spr",
        "sprites/test/ablood_4.spr",
        "sprites/test/ablood_5.spr"
    };

    void Create(edict_t@ hit, const int &in group, Vector &in destination )
    {
        if( group == 10 )
            return;

        if( g_EntityFuncs.IsValidEntity( hit ) && freeedicts( 1 ) )
        {
            CBaseEntity@ entity = g_EntityFuncs.Instance( hit );

            if( entity !is null && entity.IsMonster() )
            {
                CBaseMonster@ monster = cast<CBaseMonster@>(entity);
                
                if( monster !is null && monster.m_bloodColor != DONT_BLEED )
                {
                    CSprite@ spr = null;

                    if( monster.m_bloodColor == BLOOD_COLOR_RED )
                    {
                        @spr = g_EntityFuncs.CreateSprite( Red[ Math.RandomLong( 0, Red.length() -1 ) ], destination, true );
                    }
                    else if( monster.m_bloodColor == ( BLOOD_COLOR_GREEN | BLOOD_COLOR_YELLOW ) )
                    {
                        @spr = g_EntityFuncs.CreateSprite( Yellow[ Math.RandomLong( 0, Yellow.length() -1 ) ], destination, true );
                    }

                    if( spr !is null )
                    {
                        spr.AnimateAndDie( 60.0f );
                        spr.pev.scale = 0.4;
                    }
                }
            }
        }
    }
}
