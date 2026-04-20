array<EntityOverriden@> gpEntityOverriden(0);

enum EntityOverridenAction
{
    None = 0,
    Remove = ( 1 << 0 ),
    Break = ( 1 << 1 )
};

/// Inherit from this class to make changes into map entities
abstract class EntityOverriden : IConfigContext
{
    EntityOverriden()
    {
        gpEntityOverriden.insertLast(this);
        ConfigContext::Register(this);
    }

    const string& get_Name() {
        return String::EMPTY_STRING;
    }

    array<EHandle> m_Handles(0);

    void AddEntity( uint index, CBaseEntity@ entity, CustomKeyvalues@ ckv, CBaseMonster@ monster )
    {
        m_Handles.insertLast( EHandle( entity ) );
    }

    // Called every frame for every entity in this.m_Handles. See EntityOverridenAction for bits
    uint EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster )
    {
        return EntityOverridenAction::None;
    }

    // Called every frame before EntityThink.
    void Think()
    {
        for( int index = this.m_Handles.length(); index-- > 0; )
        {
            EHandle handle = this.m_Handles[index];

            CBaseEntity@ entity = null;

            if( !handle.IsValid() || ( @entity = handle.GetEntity() ) is null )
            {
                if( g_Logger.warning )
                    g_Logger.warning = snprintf( glog, "Got an invalid handle for %1 at index %2 removing...", this.Name, index );
                this.m_Handles.removeAt(index);
                continue;
            }

            CBaseMonster@ monster = null;

            if( entity.IsMonster() )
                @monster = cast<CBaseMonster@>(entity);

            uint flags = EntityThink( index, entity, monster );

            if( ( flags & EntityOverridenAction::Remove ) != 0 )
            {
                if( g_Logger.trace )
                    g_Logger.trace = snprintf( glog, "%1 requested to remove a entity at index %2 removing...", this.Name, index );
                this.m_Handles.removeAt(index);
            }

            if( ( flags & EntityOverridenAction::Break ) != 0 )
            {
                break;
            }
        }
    }

    float nextthink;

    void Parse( dictionary@ json )
    {
    }
}
