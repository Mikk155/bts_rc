# ===================================================================
# ===================================================================
# Purpose:
#   Re-run a dedicated server with all #if SERVER directives disabled
# ===================================================================
# ===================================================================

from Tests.ToggleDebug import ToggleDebug;
from Tests.DedicatedServer import DedicatedServer;

class DedicatedServerRelease( DedicatedServer ):

    def Build( self ) -> bool:

        ToggleDebug.ToggleDebug( False );
        result: bool = DedicatedServer().Build();
        ToggleDebug.ToggleDebug( True );

        return result;

DedicatedServerRelease();
