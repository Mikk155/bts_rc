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

final class ASZombieEngineer : EntityOverriden, IConfigurable
{
    const string& GetName() const override
    {
        return "zombie_engineer";
    }

    const string GetSchema() const override {
        return """{
            "type": "object",
            "unevaluatedProperties": false,
            "title": "Zombie engineer config",
            "description": "Control attributes for zombie engineer.",
            "properties":
            {
                "health":
                {
                    "type": "integer",
                    "description": "Canister health before explode"
                },
                "explosion":
                {
                    "type": "integer",
                    "description": "Canister explosion radius damage"
                },
                "stray":
                {
                    "type": "integer",
                    "minimum": 0,
                    "maximum": 100,
                    "description": "when shooting the zombies in the chest or stomach there is a risk of damaging the canister, in percentage 1-100"
                },
                "degrade":
                {
                    "type": "integer",
                    "description": "damaged canisters will degrade until they explode when the zombie dies, this sets how fast this happens"
                }
            }
        }""";
    }

    private
        int stray;
    private
        int explosion;
    private
        int degrade;
    private
        int health;

    bool Register( meta_api::json::v2::json@ config ) override
    {
        if( g_MapConfig.MapLoading )
        {
            EntityOverriden::SetThink( 0.1f );
            EntityOverriden::Register( this );
        }

        this.health = int( config[ "health" ] );
        this.explosion = int( config[ "explosion" ] );
        this.stray = int( config[ "stray" ] );
        this.degrade = int( config[ "degrade" ] );

        return true;
    }

    bool AddEntity( CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( monster is null )
            return false;

        string classname = monster.GetClassname();
        string model = string( monster.pev.model );

        if( classname == "monster_gonome" )
        {
            if( model == "models/bts_rc/monsters/zombie_engineer2.mdl" )
                return EntityOverriden::AddEntity( entity, monster );
        }

        if( classname == "monster_zombie_soldier" )
        {
            if( model == "models/bts_rc/monsters/zombie_engineer.mdl"
            ||   model == "models/bts_rc/monsters/zombie_construction_welder.mdl" )
                return EntityOverriden::AddEntity( entity, monster );
        }

        return false;
    }

    uint TakeDamage( uint index, CBaseMonster@ monster, DamageInfo@ info ) override
    {
        if( !monster.IsAlive() || info.flDamage <= 0 )
            return EntityOverridenAction::None;

        CBaseEntity@ attacker = info.pAttacker;

        switch( monster.m_LastHitGroup )
        {
            case 10:
            {
                if( attacker !is null && attacker.IsPlayer() )
                {
                    TraceResult tr = g_Utility.GetGlobalTrace();

                    NetworkMessage m( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, attacker.edict() );
                        m.WriteByte( TE_ARMOR_RICOCHET );
                        m.WriteCoord( tr.vecEndPos.x );
                        m.WriteCoord( tr.vecEndPos.y );
                        m.WriteCoord( tr.vecEndPos.z );
                        m.WriteByte( 10 ); // scale in 0.1's
                    m.End();
                }
                break;
            }
            case HITGROUP_CHEST:
            case HITGROUP_STOMACH:
            {
                if( this.stray == 100 || ( this.stray > 0 && Math.RandomLong( 1, 100 ) <= this.stray ) )
                {
                    break;
                }
                return EntityOverridenAction::None;
            }
            default:
            {
                if( true ) // WARNING: Unreachable code
                    return EntityOverridenAction::None;
            }
        }

        dictionary@ data = monster.GetUserData();

        int canisterHealth;

        if( !data.get( "canister_hp", canisterHealth ) )
        {
            data[ "canister_hp" ] = canisterHealth = this.health;
        }

        data[ "canister_hp" ] = canisterHealth = ( canisterHealth - int( info.flDamage ) );

        if( canisterHealth <= 0 )
        {
            Vector vecOrigin;
            monster.GetAttachment( 1, vecOrigin, void );
            monster.Killed( ( attacker !is null ? attacker.pev : null ), GIB_ALWAYS );
            g_EntityFuncs.CreateExplosion( vecOrigin, g_vecZero, monster.edict(), this.explosion, true );
            return EntityOverridenAction::Remove;
        }

        return EntityOverridenAction::None;
    }

    uint EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( monster is null )
            return EntityOverridenAction::Remove;

        dictionary@ data = monster.GetUserData();

        int canisterHealth;

        if( !data.get( "canister_hp", canisterHealth ) )
        {
            data[ "canister_hp" ] = canisterHealth = this.health;
        }

        Vector vecOrigin;

        if( canisterHealth <= 0 )
        {
            if( monster.IsAlive() )
            {
                monster.Killed( null, GIB_ALWAYS );
            }

            monster.GetAttachment( 1, vecOrigin, void );
            g_EntityFuncs.CreateExplosion( vecOrigin, g_vecZero, monster.edict(), this.explosion, true );

            return EntityOverridenAction::Remove;
        }

        if( Math.RandomLong( 0, this.health ) > canisterHealth )
        {
            if( this.degrade > 0 )
            {
                data[ "canister_hp" ] = canisterHealth - degrade;
            }

            monster.GetAttachment( 1, vecOrigin, void );

            NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
                m.WriteByte( TE_SPRITE );
                m.WriteCoord( vecOrigin.x );
                m.WriteCoord( vecOrigin.y );
                m.WriteCoord( vecOrigin.z + ( !monster.IsAlive() ? 16.0 : 8.0 ) );
                m.WriteShort( models::xsmoke4 );
                m.WriteByte( 3 );   // scale * 10
                m.WriteByte( 128 ); // brightness
            m.End();
        }

        return EntityOverridenAction::None;
    }
}
