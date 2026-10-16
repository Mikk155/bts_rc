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

namespace EntityOverriden
{
    array<EntityOverriden@> gpEntityOverriden(0);

    // Register the given EntityOverriden
    void Register( EntityOverriden@ instance )
    {
        if( g_Logger.info.active )
            g_Logger.info.print( "Registering EntityOverriden \"{}\"", { instance.GetName() } );

        gpEntityOverriden.insertLast(instance);
    }

    // Register a entity to its EntityOverriden system
    bool Register( CBaseEntity@ entity, CBaseMonster@ monster )
    {
        bool added = false;

        uint length = gpEntityOverriden.length();

        for( uint ui = 0; ui < length; ui++ )
        {
            EntityOverriden@ overrider = gpEntityOverriden[ui];

            if( overrider !is null && overrider.AddEntity( entity, monster ) )
            {
                if( g_Logger.debug.active )
                    g_Logger.debug.print( "[{}] Registering {} at {}", { overrider.GetName(), entity.GetClassname(), entity.pev.origin.ToString() } );
                added = true;
            }
        }
        return added;
    }
}

enum EntityOverridenAction
{
    None = 0,
    Remove = ( 1 << 0 ),
    Break = ( 1 << 1 )
};

/// Inherit from this class to make changes into map entities
abstract class EntityOverriden
{
    // https://github.com/anjo76/angelscript/issues/68
    const string& GetName() const
    {
        g_Logger.critical.print( "Unnamed EntityOverriden instance! Make sure to override the GetName method." );
        m_Handles[ m_Handles.length() ]; // Stop the module somehow since no "throw" exists x[
        return String::EMPTY_STRING;
    }

    // List of entities
    protected array<EHandle> m_Handles(0);

    // Find a entity by reference. return it's index and handle in m_Handles.
    bool Find( CBaseEntity@ entity, int &out index, EHandle &out handle )
    {
        if( entity !is null )
        {
            uint length = this.m_Handles.length();

            CBaseEntity@ e = null;

            for( uint ui = 0; ui < length; ui++ )
            {
                EHandle h = this.m_Handles[ui];

                if( h.IsValid() && ( @e = h.GetEntity() ) !is null && e is entity )
                {
                    index = ui;
                    handle = h;
                    return true;
                }
            }
        }
        return false;
    }

    // Find a entity by reference. return it's handle in m_Handles.
    bool Find( CBaseEntity@ entity, EHandle &out handle )
    {
        return this.Find( entity, void, handle );
    }

    // Find a entity by reference. return it's index in m_Handles.
    bool Find( CBaseEntity@ entity, int &out index )
    {
        return this.Find( entity, index, void );
    }

    // Removes the entity with the given index at m_Handles.
    void Remove( int index )
    {
        if( index >= 0 && index < int( this.m_Handles.length() ) )
        {
            if( g_Logger.debug.active )
                g_Logger.debug.print( "[{}] Removing entity at index {}", { this.GetName(), index } );

            this.m_Handles.removeAt( index );
        }
    }

    // Find a entity by reference. if exists in m_Handles removes it.
    void Remove( CBaseEntity@ entity )
    {
        int index;

        if( this.Find( entity, index, void ) )
        {
            this.Remove( index );
        }
    }

    // Whatever a entity should be added to the instance, entity and monster are the same instance just casted before hand.
    bool AddEntity( CBaseEntity@ entity, CBaseMonster@ monster )
    {
        this.m_Handles.insertLast( EHandle( entity ) );
        return true;
    }

    // Called every frame for every entity in this.m_Handles. See EntityOverridenAction for bits
    uint EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster )
    {
        return EntityOverridenAction::None;
    }

    // Called every time a entity in this.m_Handles takes damage. See EntityOverridenAction for bits
    uint TakeDamage( uint index, CBaseMonster@ monster, DamageInfo@ info )
    {
        return EntityOverridenAction::None;
    }

    // Called every time a entity in this.m_Handles is killed. See EntityOverridenAction for bits
    uint Killed( uint index, CBaseMonster@ monster, CBaseEntity@ attacker, bool gibbed )
    {
        return EntityOverridenAction::None;
    }

    // Whatever it's a think instance and it's time to call Think
    bool ShouldThink()
    {
        return ( this.thinks && g_Engine.time >= this.nextthink );
    }

    bool CheckFlags( uint flags, int index ) final
    {
        if( ( flags & EntityOverridenAction::Remove ) != 0 )
        {
            if( g_Logger.debug.active )
                g_Logger.debug.print( "[{}] requested to remove a entity at index {}", { this.GetName(), index } );

            this.Remove( index );
        }

        if( ( flags & EntityOverridenAction::Break ) != 0 )
        {
            return true;
        }

        return false;
    }

    // Called every frame before EntityThink.
    void Think()
    {
        this.nextthink = g_Engine.time + this.interval;

        uint length = this.m_Handles.length();

        for( int index = length; index-- > 0; )
        {
            EHandle handle = this.m_Handles[index];

            CBaseEntity@ entity = null;

            if( !handle.IsValid() || ( @entity = handle.GetEntity() ) is null )
            {
                if( g_Logger.debug.active )
                    g_Logger.debug.print( "[{}] Got an invalid handle at index {}", { this.GetName(), index } );
                this.Remove( index );
                continue;
            }

            CBaseMonster@ monster = null;

            if( entity.IsMonster() )
                @monster = cast<CBaseMonster@>(entity);

            if( this.CheckFlags( EntityThink( index, entity, monster ), index ) )
                break;
        }
    }

    protected bool thinks = false;
    protected float interval;
    protected float nextthink;

    // Set entity think rate, Use a negative value to stop thinking.
    void SetThink( float time ) final
    {
        this.interval = time;
        this.thinks = ( this.interval >= 0.0 );

        if( this.thinks )
        {
            if( g_Logger.debug.active )
                g_Logger.debug.print( "[{}] Set think to {}", { this.GetName(), this.interval } );

            this.nextthink = g_Engine.time + this.interval;
        }
        else
        {
            if( g_Logger.debug.active )
                g_Logger.debug.print( "[{}] Stop thinking", { this.GetName() } );
        }
    }
}
