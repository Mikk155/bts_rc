namespace Hooks
{
    class __CStartFrame__ : ScriptBaseEntity
    {
        void Spawn()
        {
            self.pev.movetype = MOVETYPE_NONE;
            self.pev.solid = SOLID_NOT;
            self.pev.nextthink = g_Engine.time;
        }

        void Think()
        {
            uint length = gpEntityOverriden.length();

            for( uint ui = 0; ui < length; ui++ )
            {
                EntityOverriden@ overrider = gpEntityOverriden[ui];

                if( overrider !is null )
                {
                    if( overrider.nextthink <= g_Engine.time )
                    {
                        overrider.Think();
                    }
                }
            }

            self.pev.nextthink = g_Engine.time;
        }
    }

    const bool __StartFrameRegister__()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "Hooks::__CStartFrame__", "StartFrame" );
        return true;
    }

    const bool __StartFrame__ = __StartFrameRegister__();

    void StartFrame()
    {
        g_EntityFuncs.Create( "StartFrame", g_vecZero, g_vecZero, false, null );
    }
}
