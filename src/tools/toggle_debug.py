# ===================================================================
# ===================================================================
# Purpose:
#   toggle all .as files SERVER pre procesor to/from DEBUG for local testing
# ===================================================================
# ===================================================================

import os;
import sys;

gpWorkspace: str = os.path.dirname( os.path.dirname( os.path.dirname( __file__ ) ) );
gpBuilders = []

sys.path.append( os.path.join( gpWorkspace, "src" ) );

from Tests.PyTest import PyTest;
from Tests.ToggleDebug import ToggleDebug;

debug: ToggleDebug = ToggleDebug()

while True:

    action: int = None;

    while action != 1 and action != 2:

        if action is not None:
            os.system( "cls" if os.name == "nt" else "clear" );
            print( "Invalid option!" );
        else:
            print( "Select one of:" )

        print( "1: Disable debug" );
        print( "2: Enable debug" );

        try:
            action = int( input( "> " ) )
        except ValueError:
            action = 0;

    debug.ToggleDebug( ( action == 1 ) );
    PyTest.WriteAllScripts();
