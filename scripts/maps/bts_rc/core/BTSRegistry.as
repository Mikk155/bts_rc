dictionary gp_Registry;

#include "IBTSConfigurable"

// Mother class of every context
abstract class BTSRegistry
{
    string __InternalName__;

    // Get internal name (Applied during registration)
    const string& get_Name() const final
    {
        return this.__InternalName__;
    }

    void Shutdown()
    {
        gp_Registry.delete( this.Name );
    }

    IBTSConfigurable@ ToConfigurable() final
    {
        return cast<IBTSConfigurable@>(this);
    }

    // Name of the registration context.
    const string& GetName() const
    {
        return this.__InternalName__;
    }

    // Called at MapInit
    void MapInit() {}
}

weakref<BTSRegistry> RegisterContext( BTSRegistry@ ctx, const string&in className )
{
    weakref<BTSRegistry> reg;

    if( ctx !is null )
    {
        @gp_Registry[ className ] = ctx;
        reg.opHndlAssign( ctx );
        ctx.__InternalName__ = className;

        if( g_Logger.trace.active )
        {
            g_Logger.trace.print( "Registering context \"{}\" ({}) at index {}", { ctx.GetName(), className, gp_Registry.getSize() } );
        }
    }

    return reg;
}
