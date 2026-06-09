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

array<EntityOverriden@> gpEntityOverriden(0);

enum EntityOverridenAction
{
    None = 0,
    Remove = ( 1 << 0 ),
    Break = ( 1 << 1 )
};

/// Inherit from this class to make changes into map entities
abstract class EntityOverriden : IConfigurable
{
    EntityOverriden()
    {
        gpEntityOverriden.insertLast(this);
    }

    array<EHandle> m_Handles(0);

    void AddEntity( uint index, CBaseEntity@ entity, CustomKeyvalues@ ckv, CBaseMonster@ monster )
    {
        this.m_Handles.insertLast( EHandle( entity ) );
    }

    // Called every frame for every entity in this.m_Handles. See EntityOverridenAction for bits
    uint EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster )
    {
        return EntityOverridenAction::None;
    }

    bool ShouldThink()
    {
        return ( this.IsActive() && this.thinks && g_Engine.time >= this.nextthink );
    }

    // Called every frame before EntityThink.
    void Think()
    {
        if( !this.ShouldThink() )
            return;

        this.nextthink = g_Engine.time + this.interval;

        uint length = this.m_Handles.length();

        for( int index = length; index-- > 0; )
        {
            EHandle handle = this.m_Handles[index];

            CBaseEntity@ entity = null;

            if( !handle.IsValid() || ( @entity = handle.GetEntity() ) is null )
            {
                if( g_Logger.warning.active )
                    g_Logger.warning.print( snprintf( glog, "Got an invalid handle for %1 at index %2 removing...", this.Name, index ) );
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
                    g_Logger.trace.print( snprintf( glog, "%1 requested to remove a entity at index %2 removing...", this.Name, index ) );
                this.m_Handles.removeAt(index);
            }

            if( ( flags & EntityOverridenAction::Break ) != 0 )
            {
                break;
            }
        }
    }

    bool thinks = false;
    float interval;
    float nextthink;

    void Register( meta_api::json::v2::json@ json ) override
    {
        if( this.IsActive() )
        {
            if( this.interval >= 0.1 )
            {
                this.thinks = true;
                this.nextthink = g_Engine.time + this.interval;
            }
        }
    }
}
