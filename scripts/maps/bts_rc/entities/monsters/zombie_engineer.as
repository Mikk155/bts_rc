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

    private int m_SpriteCanisterGas;
    private int m_CanisterStrayChance;
    private int m_CanisterDamage;
    private int m_CanisterDegrade;
    private int m_CanisterHealth;

    bool Register( btson@ config ) override
    {
        if( g_MapConfig.MapLoading )
        {
            m_SpriteCanisterGas = g_Game.PrecacheModel( "sprites/xsmoke4.spr" );
            EntityOverriden::SetThink( 0.1f );
            EntityOverriden::Register( this );
        }
        this.m_CanisterHealth = int( config[ "health" ] );
        this.m_CanisterDamage = int( config[ "explosion" ] );
        this.m_CanisterStrayChance = int( config[ "stray" ] );
        this.m_CanisterDegrade = int( config[ "degrade" ] );
        return true;
    }

    bool IsValid( const string&in classname, const string&in model )
    {
        if( classname == "monster_gonome" )
        {
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
                if( this.m_CanisterStrayChance == 100 || ( this.m_CanisterStrayChance > 0 && Math.RandomLong( 1, 100 ) <= this.m_CanisterStrayChance ) )
                    ShouldHandleDamage = true;
                break;
            }
        }

        if( !ShouldHandleDamage || info.flDamage < 1 )
            return;

        dictionary@ data = victim.GetUserData();

        int canisterHealth;

        if( !data.get( "canister_hp", canisterHealth ) )
        {
            data[ "canister_hp" ] = canisterHealth = this.m_CanisterHealth;
        }

        data[ "canister_hp" ] = canisterHealth = ( canisterHealth - int( info.flDamage ) );

        if( canisterHealth <= 0 )
        {
            EntityThink( 0, victim, victim );
            victim.Killed( ( attacker !is null ? attacker.pev : null ), GIB_ALWAYS );
            this.Remove( victim );
        }
    }

    uint EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( monster is null )
            return EntityOverridenAction::Remove;

        dictionary@ data = monster.GetUserData();

        int canisterHealth;

        if( !data.get( "canister_hp", canisterHealth ) )
        {
            data[ "canister_hp" ] = canisterHealth = this.m_CanisterHealth;
        }

        Vector vecOrigin;

        if( Math.RandomLong( 0, this.m_CanisterHealth ) > canisterHealth )
        {
            if( this.m_CanisterDegrade > 0 )
            {
                data[ "canister_hp" ] = canisterHealth = ( canisterHealth - m_CanisterDegrade );
            }

            monster.GetAttachment( 0, vecOrigin, void );

            NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
                m.WriteByte( TE_SPRITE );
                m.WriteCoord( vecOrigin.x );
                m.WriteCoord( vecOrigin.y );
                m.WriteCoord( vecOrigin.z + ( !monster.IsAlive() ? 16.0 : 8.0 ) );
                m.WriteShort( this.m_SpriteCanisterGas );
                m.WriteByte( 3 );   // scale * 10
                m.WriteByte( 128 ); // brightness
            m.End();
        }

        if( canisterHealth < 0 )
        {
            if( !monster.IsAlive() )
            {
                if( vecOrigin == g_vecZero )
                {
                    monster.GetAttachment( 0, vecOrigin, void );
                }

                g_EntityFuncs.CreateExplosion( vecOrigin, g_vecZero, null, this.m_CanisterDamage, true );
            }

            return EntityOverridenAction::Remove;
        }

        return EntityOverridenAction::None;
    }
}

ASZombieEngineer gpZombieEngineer;
