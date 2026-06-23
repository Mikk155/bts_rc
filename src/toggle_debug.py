# ===================================================================
# ===================================================================
# Purpose:
#   toggle all .as files SERVER pre procesor to/from DEBUG
# ===================================================================
# ===================================================================

import os;

action: int = None;

while action != 1 and action != 2:

    if action is not None:
        os.system( "cls" if os.name == "nt" else "clear" );
        print( "Invalid option!" );
    else:
        print( "Select one of:" )

    print( "1: SERVER -> DEBUG" );
    print( "2: DEBUG -> SERVER" );

    try:
        action = int( input( "> " ) )
    except ValueError:
        action = 0;

processFrom: str = "DEBUG";
processTo: str = "SERVER";

if action == 1:
    processFrom = "SERVER";
    processTo = "DEBUG";

gpBuilders = []
gpWorkspace: str = os.path.dirname( os.path.dirname( __file__ ) );

from Tests.PyBuilder import PyBuilder;

print( f"Toggle all pre processors {processFrom} -> {processTo}" );

import Tests.DebugCheck;
Tests.DebugCheck.DebugCheck().toggle_debug( processFrom, processTo );
PyBuilder.WriteAllScripts();

input( "All done!" );
