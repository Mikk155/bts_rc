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

namespace test_chamber
{
    final class entitymaker : ScriptBaseMonsterEntity
    {
        private
            string m_ClassName;

        private
            EHandle m_hChild;

        private
            bool m_IsThink;

        private
            bool m_IsOn;

        private
            string m_Target;

        private
            dictionary m_KeyValues;

        bool KeyValue( const string&in key, const string&in value )
        {
            if( key[0] == "_" )
            {
                if( key == "_classname" )
                {
                    this.m_ClassName = value;
                    return true;
                }
                else if( key == "_targetname" )
                {
                    this.m_KeyValues[ "targetname" ] = value;
                    return true;
                }
                else if( key == "_mode" )
                {
                    this.m_IsThink = ( atoi( value ) == 1 );
                    return true;
                }
                else if( key == "_starton" )
                {
                    this.m_IsOn = ( atoi( value ) == 1 );
                    return true;
                }
                else if( key == "_target" )
                {
                    this.m_Target = value;
                    return true;
                }
                return false;
            }

            this.m_KeyValues[ key ] = value;
            return true;
        }

        void SetPair( const string&in key, const string&in value )
        {
            if( !value.IsEmpty() )
                this.m_KeyValues[ key ] = value;
        }

        void Spawn()
        {
            self.pev.solid = SOLID_NOT;
            self.pev.movetype = MOVETYPE_NONE;
            self.pev.effects |= EF_NODRAW;

            SetPair( "model", self.pev.model );
            SetPair( "origin", self.pev.origin.ToString() );
            SetPair( "angles", self.pev.angles.ToString() );
            SetPair( "health", self.pev.health );
            SetPair( "max_health", self.pev.max_health );
            SetPair( "target", self.pev.target );
            SetPair( "message", self.pev.message );
            SetPair( "spawnflags", self.pev.spawnflags );

            CBaseEntity@ child = g_EntityFuncs.CreateEntity( this.m_ClassName, this.m_KeyValues, true );
            g_EntityFuncs.Remove( ( child is null ? self : child ) );

            if( this.m_IsOn )
            {
                Use( null, null, USE_TOGGLE, 0 );
            }
        }

        void SpawnChild()
        {
            if( this.m_hChild.IsValid() && this.m_hChild.GetEntity() !is null && this.m_hChild.GetEntity().IsAlive() )
                return;

            CBaseEntity@ child = g_EntityFuncs.CreateEntity( this.m_ClassName, this.m_KeyValues, true );
            Hooks::SquadmakerSpawn( self, child );
            this.m_hChild = EHandle( child );

            g_EntityFuncs.FireTargets( this.m_Target, child, self, USE_TOGGLE, 0.0f );
        }

        void Think()
        {
            self.pev.nextthink = g_Engine.time + 0.1f;
            SpawnChild();
        }

        void Use( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE useType, float value )
        {
            if( this.m_IsThink )
            {
                if( self.pev.nextthink >= g_Engine.time )
                {
                    self.pev.nextthink = 0;
                }
                else
                {
                    self.pev.nextthink = g_Engine.time;
                }
            }
            else
            {
                SpawnChild();
            }
        }
    }
}
