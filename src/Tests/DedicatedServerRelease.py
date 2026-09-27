# ===================================================================
# ===================================================================
# Purpose:
#   Re-run a dedicated server with all #if SERVER directives disabled
# ===================================================================
# ===================================================================

from Tests.DebugCheck import DebugCheck;
from Tests.DedicatedServer import DedicatedServer;

class DedicatedServerRelease( DedicatedServer ):

    def Build(self) -> bool:

        dbg = DebugCheck();
        dbg.toggle_debug( "SERVER", "DEBUG" );
        result: bool = DedicatedServer().Build();
        dbg.toggle_debug( "DEBUG", "SERVER" );

        return result;

DedicatedServerRelease();
