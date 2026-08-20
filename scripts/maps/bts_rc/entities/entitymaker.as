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

#if SERVER
namespace test_chamber
{
    final class entitymaker : ScriptBaseMonsterEntity
    {
        private
            string m_ClassName;

        private
            string m_Target;

        private
            dictionary m_KeyValues;

        bool KeyValue( const string&in key, const string&in value )
        {
            if( key[0] == "+" )
            {
                if( key == "+classname" )
                {
                    this.m_ClassName = value;
                }
                else if( key == "+targetname" )
                {
                    this.m_KeyValues[ "targetname" ] = value;
                }
                else if( key == "+target" )
                {
                    this.m_Target = value;
                }
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
        }

        void Use( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE useType, float value )
        {
            CBaseEntity@ child = g_EntityFuncs.CreateEntity( this.m_ClassName, this.m_KeyValues, true );
            Hooks::SquadmakerSpawn( self, child );
            g_EntityFuncs.FireTargets( this.m_Target, child, self, USE_TOGGLE, 0.0f );
        }
    }
}
#endif
