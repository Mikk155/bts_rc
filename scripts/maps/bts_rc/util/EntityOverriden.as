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
        this.m_Handles.insertLast( EHandle( entity ) );
    }

    // Called every frame for every entity in this.m_Handles. See EntityOverridenAction for bits
    uint EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster )
    {
        return EntityOverridenAction::None;
    }

    bool ShouldThink()
    {
        return ( this.active && this.thinks && g_Engine.time >= this.nextthink );
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

    bool active = true;

    bool thinks = false;
    float interval;
    float nextthink;

    void Parse( dictionary@ json )
    {
        json.get( "active", active );

        if( json.get( "interval", this.interval ) && this.interval >= 0.1 )
        {
            this.thinks = true;
            this.nextthink = g_Engine.time + this.interval;
        }
    }
}
