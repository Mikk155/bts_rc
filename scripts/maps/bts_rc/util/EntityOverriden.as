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

    void Register( EntityOverriden@ instance )
    {
        if( g_Logger.info.active )
            g_Logger.info.print( "Registering EntityOverriden {}", { instance.GetName() } );

        gpEntityOverriden.insertLast(instance);
    }

    // Register a entity to its EntityOverriden system
    bool Register( uint index, CBaseEntity@ entity, CustomKeyvalues@ ckv, CBaseMonster@ monster )
    {
        bool added = false;

        uint length = gpEntityOverriden.length();

        for( uint ui = 0; ui < length; ui++ )
        {
            EntityOverriden@ overrider = gpEntityOverriden[ui];

            if( overrider !is null && overrider.AddEntity( index, entity, ckv, monster ) )
            {
                if( g_Logger.trace.active )
                    g_Logger.trace.print( "Registering {} at {} for {}", { entity.GetClassname(), entity.pev.origin.ToString(), overrider.GetName() } );
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
    const string& GetName() const
    {
        g_Logger.critical.print( "Unnamed EntityOverriden instance! Make sure to override the GetName method." );
        m_Handles[ m_Handles.length() ]; // Stop the module somehow since no "throw" exists x[
        return String::EMPTY_STRING;
    }

    // List of entities
    protected array<EHandle> m_Handles(0);

    // Whatever a entity should be added to the instance, entity and monster are the same instance just casted before hand.
    bool AddEntity( uint index, CBaseEntity@ entity, CustomKeyvalues@ ckv, CBaseMonster@ monster )
    {
        this.m_Handles.insertLast( EHandle( entity ) );
        return true;
    }

    // Called every frame for every entity in this.m_Handles. See EntityOverridenAction for bits
    uint EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster )
    {
        return EntityOverridenAction::None;
    }

    // Whatever it's a think instance and it's time to call Think
    bool ShouldThink()
    {
        return ( this.thinks && g_Engine.time >= this.nextthink );
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
                if( g_Logger.warning.active )
                    g_Logger.warning.print( snprintf( glog, "Got an invalid handle for %1 at index %2 removing...", this.GetName(), index ) );
                this.m_Handles.removeAt(index);
                continue;
            }

            CBaseMonster@ monster = null;

            if( entity.IsMonster() )
                @monster = cast<CBaseMonster@>(entity);

            uint flags = EntityThink( index, entity, monster );

            if( ( flags & EntityOverridenAction::Remove ) != 0 )
            {
                if( g_Logger.trace.active )
                    g_Logger.trace.print( snprintf( glog, "%1 requested to remove a entity at index %2 removing...", this.GetName(), index ) );
                this.m_Handles.removeAt(index);
            }

            if( ( flags & EntityOverridenAction::Break ) != 0 )
            {
                break;
            }
        }
    }

    protected bool thinks = false;
    protected float interval;
    protected float nextthink;

    // Set entity think rate, negative values to stop thinking
    void SetThink( float time )
    {
        this.interval = time;
        this.thinks = ( this.interval >= 0.0 );

        if( this.thinks )
        {
            this.nextthink = g_Engine.time + this.interval;
        }
    }
}
