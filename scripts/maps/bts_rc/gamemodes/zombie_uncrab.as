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
*   Author: Mikk
*   Original Code: Gaftherman
*   Original Idea: EdgarBarney (Trinity Rendering)
*/

namespace zombie_uncrab
{
    class CConfig : IConfigContext
    {
        bool TrackHealth;

        const Cvar@ sk_headcrab_health = g_EngineFuncs.CVarGetPointer( "sk_headcrab_health" );

        CConfig()
        {
            ConfigContext::Register( this );
        }

        const string& get_Name() override {
            return "zombie_uncrab";
        }

        bool IsValid( CBaseEntity@ zombie )
        {
            if( zombie is null )
                return false;

            string classname = zombie.GetClassname();

            if( "monster_zombie" != classname
            && "monster_zombie_soldier" != classname
            && "monster_zombie_barney" != classname
            && "monster_gonome" != classname )
                return false;

            return true;
        }

        void Parse( dictionary@ json )
        {
            bool register;

            if( json.get( "active", register ) && register )
            {
                if( json.get( "track_health", TrackHealth ) && TrackHealth )
                {
                    g_Hooks.RegisterHook( Hooks::Monster::MonsterTakeDamage,
                    MonsterTakeDamageHook( function( DamageInfo@ info )
                    {
                        if( info.flDamage <= 0 || !gpConfig.IsValid( info.pVictim ) )
                            return HOOK_CONTINUE;

                        CBaseMonster@ monster = cast<CBaseMonster@>( info.pVictim );

                        if( monster is null || monster.m_LastHitGroup != 1 )
                            return HOOK_CONTINUE;

                        dictionary@ data = info.pVictim.GetUserData();

                        data["headcrab_damage"] = int( data["headcrab_damage"] ) + info.flDamage;

                        return HOOK_CONTINUE;
                    } ) );
                }

                g_Hooks.RegisterHook( Hooks::Monster::MonsterKilled,
                MonsterKilledHook( function( CBaseMonster@ monster, CBaseEntity@ attacker, int gib )
                {
                    if( !freeedicts(1) || !gpConfig.IsValid( monster ) )
                        return HOOK_CONTINUE;

                    const float headcrab_damage = int( monster.GetUserData()[ "headcrab_damage" ] );

                    // Check if the stored received damage is less than a headcrab's HP
                    if( gpConfig.TrackHealth && headcrab_damage >= gpConfig.sk_headcrab_health.value )
                        return HOOK_CONTINUE;

                    monster.SetBodygroup( 1, 1 );

                    if( gib != GIB_ALWAYS )
                    {
                        // If the monster hasn't been gibed then make sure it supports the "no crab" bodygroup
                        if( monster.GetBodygroup( 1 ) != 1 )
                            return HOOK_CONTINUE;
                    }

                    Vector origin, angles;
                    monster.GetAttachment( ( monster.GetClassname() == "monster_gonome" ? 1 : 0 ), origin, angles );

                    auto headcrab = g_EntityFuncs.Create( "monster_headcrab", origin, monster.pev.angles, false, monster.edict() );

                    if( headcrab is null )
                        return HOOK_CONTINUE;

                    // Damage headcrab based on how much damage the zombie got on the headcrab
                    if( gpConfig.TrackHealth )
                        headcrab.TakeDamage( null, null, headcrab_damage, DMG_GENERIC );

                    // Make crab think earlier so it does drop to floor before relocate is called
                    headcrab.pev.nextthink = g_Engine.time;

                    g_Scheduler.SetTimeout( @gpConfig, "RelocateHeadcrab", 0.05f, EHandle(headcrab), origin.z );

                    return HOOK_CONTINUE;
                } ) );
            }
        }

        void RelocateHeadcrab( EHandle entity, float height )
        {
            if( !entity.IsValid() )
                return;

            auto headcrab = cast<CBaseMonster@>( entity.GetEntity() );

            if( headcrab is null )
                return;

            // Jump sequence
            headcrab.pev.sequence = 10;

            headcrab.pev.flags &= ~FL_ONGROUND;
            headcrab.pev.origin.z = height;
            g_EntityFuncs.SetOrigin( headcrab, headcrab.pev.origin );

            headcrab.pev.velocity.x = Math.RandomFloat( -50, 50 );
            headcrab.pev.velocity.y = Math.RandomFloat( -50, 50 );
            headcrab.pev.velocity.z = Math.RandomFloat( 50, 150 );
        }
    }

    CConfig gpConfig;
}
