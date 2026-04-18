# ===================================================================
# ===================================================================
# Purpose:
#   Generates documentation from the json schema validator
# ===================================================================
# ===================================================================

import os;
import sys;
from PyBuilder import PyBuilder;
from typing import Literal, LiteralString, Optional

gpEmptyString: Literal[ "" ] = "";

gpWorkspace: LiteralString = os.path.dirname( os.path.dirname( __file__ ) );

def Main() -> int:

    Builders: list[PyBuilder] = [];

    LOCAL_BUILDER: bool = ( len(sys.argv) == 1 );

    if LOCAL_BUILDER:

        from PyDocumentation import PyDocumentation;
        Builders.append( PyDocumentation() );

    for builder in Builders:

        ok = True;

        try:
            ok = builder.Build();
        except Exception as e:
            print( f"{builder.Name}: throw an exception: {e}" );
            return 1;

        if ok is False:
            print( f"{builder.Name}: Failed build." );
            return 1;

    return 0;

if __name__ == "__main__":
    exit( Main() );
