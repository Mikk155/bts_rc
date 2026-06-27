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
    Author: Mikk
    Original code: Nero
*/

class ZombieEngineer : EntityOverriden, IConfigurableContext
{
    const string& GetName() const override {
        return "zombie_engineer";
    }

    const string GetSchema() const {
        return String::EMPTY_STRING;
    }

    private int m_SpriteCanisterGas;

    // when shooting the zombies in the chest or stomach there is a risk of damaging the canister, in percentage 1-100
    private uint m_CanisterStrayChance = 5;
    private int m_CanisterDamage = 125;
    // damaged canisters will degrade until they explode when the zombie dies, this sets how fast this happens
    private float m_CanisterDegrade = 0.5;
    private int m_CanisterHealth = 50;

    bool Register( meta_api::json::v2::json@ config ) override
    {
        m_SpriteCanisterGas = g_Game.PrecacheModel( "sprites/xsmoke4.spr" );
        return true;
    }

    bool IsValid( const string&in classname, const string&in model )
    {
        if( classname == "monster_gonome" ) {
            if( model == "models/bts_rc/monsters/zombie_engineer2.mdl" )
                return true;
        }
        if( classname == "monster_zombie_soldier" &&
        ( model == "models/bts_rc/monsters/zombie_engineer.mdl" || model == "models/bts_rc/monsters/zombie_construction_welder.mdl" ) )
            return true;
        return false;
    }

    bool AddEntity( uint index, CBaseEntity@ entity, CustomKeyvalues@ ckv, CBaseMonster@ monster ) override
    {
        if( !this.IsValid( entity.GetClassname(), string( entity.pev.model ) ) )
            return false;

        return EntityOverriden::AddEntity( index, entity, ckv, monster );
    }

    void TakeDamage( CBaseMonster@ victim, DamageInfo@ info )
    {
        bool ShouldHandleDamage = false;

        CBaseEntity@ attacker = info.pAttacker;

        switch( victim.m_LastHitGroup )
        {
            case 10:
            {
                info.flDamage *= 0.1;
                ShouldHandleDamage = true;

                if( attacker !is null && attacker.IsPlayer() )
                {
                    TraceResult tr = g_Utility.GetGlobalTrace();
                    NetworkMessage ricochet( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, attacker.edict() );
                    ricochet.WriteByte( TE_ARMOR_RICOCHET );
                    ricochet.WriteCoord( tr.vecEndPos.x );
                    ricochet.WriteCoord( tr.vecEndPos.y );
                    ricochet.WriteCoord( tr.vecEndPos.z );
                    ricochet.WriteByte( 10 ); // scale in 0.1's
                    ricochet.End();
                }
                break;
            }
            case HITGROUP_CHEST:
            case HITGROUP_STOMACH:
            {
                if( Math.RandomLong( 1, 100 ) <= this.m_CanisterStrayChance )
                    ShouldHandleDamage = true;
                break;
            }
        }

        if( !ShouldHandleDamage )
            return;

        CustomKeyvalues@ ckv = victim.GetCustomKeyvalues();

        float flCanisterHealth = ckv.GetKeyvalue( "$f_zecanisterhp" ).GetFloat();
        flCanisterHealth -= info.flDamage;

        if( flCanisterHealth > 0 )
        {
            ckv.SetKeyvalue( "$f_zecanisterhp", flCanisterHealth );
        }
        else if( flCanisterHealth != -1337 )
        {
            ckv.SetKeyvalue( "$f_zecanisterhp", -1337 );
            g_EntityFuncs.CreateExplosion( victim.pev.origin, g_vecZero, null, this.m_CanisterDamage, true );
            victim.Killed( ( attacker !is null ? attacker.pev : null ), GIB_ALWAYS );
        }
    }

    uint EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( monster is null )
            return EntityOverridenAction::Remove;

        CustomKeyvalues@ ckv = monster.GetCustomKeyvalues();

        float flNextThink = ckv.GetKeyvalue( "$f_btscmthink" ).GetFloat();

        if( flNextThink <= g_Engine.time )
        {
            if( !ckv.GetKeyvalue( "$f_zecanisterhp" ).Exists() )
                ckv.SetKeyvalue( "$f_zecanisterhp", this.m_CanisterHealth );

            if( FreeEdicts(1) )
            {
                float flCanisterHealth = ckv.GetKeyvalue( "$f_zecanisterhp" ).GetFloat();

                if( flCanisterHealth > 0 and Math.RandomLong( 0, this.m_CanisterHealth ) > flCanisterHealth )
                {
                    Vector vecOrigin;
                    Vector sashifixplis;
                    monster.GetAttachment( 0, vecOrigin, sashifixplis );

                    NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
                    m1.WriteByte( TE_SPRITE );
                    m1.WriteCoord( vecOrigin.x );
                    m1.WriteCoord( vecOrigin.y );
                    m1.WriteCoord( vecOrigin.z + ( monster.pev.deadflag == DEAD_DEAD ? 16.0 : 8.0 ) );
                    m1.WriteShort( m_SpriteCanisterGas );
                    m1.WriteByte( 3 );   // scale * 10
                    m1.WriteByte( 128 ); // brightness
                    m1.End();
                }
            }

            if( monster.pev.deadflag == DEAD_DEAD )
            {
                float flCanisterHealth = ckv.GetKeyvalue( "$f_zecanisterhp" ).GetFloat();

                if( flCanisterHealth <= 0 )
                {
                    Vector vecOrigin;
                    Vector sashifixplis;
                    monster.GetAttachment( 0, vecOrigin, sashifixplis );
                    g_EntityFuncs.CreateExplosion( vecOrigin, g_vecZero, null, this.m_CanisterDamage, true );
                }
                else if( flCanisterHealth < this.m_CanisterHealth )
                    ckv.SetKeyvalue( "$f_zecanisterhp", flCanisterHealth - this.m_CanisterDegrade );
            }

            ckv.SetKeyvalue( "$f_btscmthink", g_Engine.time + 0.1 );
        }

        return EntityOverridenAction::None;
    }
}

ZombieEngineer gpZombieEngineer;
