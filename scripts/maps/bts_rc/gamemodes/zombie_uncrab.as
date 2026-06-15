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
*   Author: Mikk
*   Original Code: Gaftherman
*   Original Idea: EdgarBarney (Trinity Rendering)
*/

class ASZombieUncrabConfig : IConfigurable
{
    bool track_health;

    const Cvar@ sk_headcrab_health = g_EngineFuncs.CVarGetPointer( "sk_headcrab_health" );

    const string& get_Name() override
    {
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

    void Register( meta_api::json::v2::json@ json ) override
    {
        if( this.IsActive() )
        {
            this.track_health = json.ValueOrDefault( "track_health", true );
        }
    }

    void RelocateHeadcrab( EHandle entity, float height, float headcrab_damage )
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

        // Damage headcrab based on how much damage the zombie got on the headcrab
        if( headcrab_damage > 0.0 )
            headcrab.TakeDamage( null, null, headcrab_damage, ( DMG_GENERIC | DMG_NEVERGIB ) );

        headcrab.pev.velocity.x = Math.RandomFloat( -50, 50 );
        headcrab.pev.velocity.y = Math.RandomFloat( -50, 50 );
        headcrab.pev.velocity.z = Math.RandomFloat( 50, 150 );
    }

    CBaseEntity@ Create( CBaseMonster@ monster, CBaseEntity@ attacker, int gib, dictionary@ data )
    {
        if( !this.IsActive() || !this.IsValid( monster ) || !FreeEdicts(1) )
            return null;

        float headcrab_damage = 0.0f;

        // Check if the stored received damage is less than a headcrab's HP
        if( this.track_health )
            headcrab_damage = float( data[ "headcrab_damage" ] );

        monster.SetBodygroup( 1, 1 );

        if( gib != GIB_ALWAYS )
        {
            // If the monster hasn't been gibed then make sure it supports the "no crab" bodygroup
            if( monster.GetBodygroup( 1 ) != 1 )
                return null;
        }

        Vector origin, angles;
        monster.GetAttachment( ( monster.GetClassname() == "monster_gonome" ? 1 : 0 ), origin, angles );

        auto headcrab = g_EntityFuncs.Create( "monster_headcrab", origin, monster.pev.angles, false, monster.edict() );

        if( headcrab is null )
            return null;

        // Make crab think earlier so it does drop to floor before relocate is called
        headcrab.pev.nextthink = g_Engine.time;
        g_Scheduler.SetTimeout( @this, "RelocateHeadcrab", 0.05f, EHandle(headcrab), origin.z, headcrab_damage );

        return @headcrab;
    }
}

ASZombieUncrabConfig gpZombieUncrab;
