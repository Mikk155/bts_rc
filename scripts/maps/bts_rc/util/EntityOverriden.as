array<EntityOverriden@> gpEntityOverriden(0);

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

    CScheduledFunction@ m_Think = null;

    // Called every this.nextthink for every entity in this.m_Handles. return false to remove the entity from the list
    bool EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster )
    {
        return true;
    }

    // Called every this.nextthink before EntityThink
    void Think()
    {
        for( int i = this.m_Handles.length(); i-- > 0; )
        {
            EHandle handle = this.m_Handles[i];

            CBaseEntity@ entity = null;

            if( !handle.IsValid() || ( @entity = handle.GetEntity() ) is null )
            {
                if( g_Logger.warning )
                    g_Logger.warning = snprintf( glog, "Got an invalid handle for %1 at index %2 removing...", this.Name, i );
                this.m_Handles.removeAt(i);
                continue;
            }

            CBaseMonster@ monster = null;

            if( entity.IsMonster() )
                @monster = cast<CBaseMonster@>(entity);

            if( !EntityThink( entity.entindex(), entity, monster ) )
            {
                if( g_Logger.trace )
                    g_Logger.trace = snprintf( glog, "%1 requested to remove a entity at index %2 removing...", this.Name, i );
                this.m_Handles.removeAt(i);
            }
        }
    }

    private float m_ThinkTime;

    float nextthink
    {
        get {
            return m_ThinkTime;
        }
        set {
            if( m_Think !is null )
            {
                g_Scheduler.RemoveTimer( this.m_Think );
                @this.m_Think = null;
            }

            this.m_ThinkTime = value;

            if( this.m_ThinkTime > 0 )
            {
                @this.m_Think = g_Scheduler.SetInterval( @this, "Think", this.m_ThinkTime, g_Scheduler.REPEAT_INFINITE_TIMES );
            }
        }
    }

    void Parse( dictionary@ json )
    {
    }
}
