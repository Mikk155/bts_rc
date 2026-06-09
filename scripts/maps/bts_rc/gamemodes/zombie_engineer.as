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
    Author: Mikk
    Original code: Nero
*/

class ZombieEngineer : EntityOverriden
{
    const string& get_Name() {
        return "zombie_engineer";
    }

    private int m_SpriteCanisterGas;

    // when shooting the zombies in the chest or stomach there is a risk of damaging the canister, in percentage 1-100
    private uint m_CanisterStrayChance = 5;
    private int m_CanisterDamage = 125;
    // damaged canisters will degrade until they explode when the zombie dies, this sets how fast this happens
    private float m_CanisterDegrade = 0.5;
    private int m_CanisterHealth = 50;

    void Register( meta_api::json::v2::json@ json ) override
    {
        if( this.IsActive() )
        {
            m_SpriteCanisterGas = g_Game.PrecacheModel( "sprites/xsmoke4.spr" );
        }

        EntityOverriden::Register( json );
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

    void AddEntity( uint index, CBaseEntity@ entity, CustomKeyvalues@ ckv, CBaseMonster@ monster ) override
    {
        if( this.IsValid( entity.GetClassname(), string( entity.pev.model ) ) )
            EntityOverriden::AddEntity( index, entity, ckv, monster );
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
