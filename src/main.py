# ===================================================================
# ===================================================================
# Purpose:
#   Generates documentation from the json schema validator
# ===================================================================
# ===================================================================

import os;
import sys;
from typing import Literal, LiteralString, Optional

gpEmptyString: Literal[ "" ] = "";

gpWorkspace: LiteralString = os.path.dirname( os.path.dirname( __file__ ) );

def Main() -> int:

    BUILD_DOCUMENTATION: bool = ( len(sys.argv) == 1 );

    if BUILD_DOCUMENTATION:
        from PyDocumentation import PyDocumentation;
        if PyDocumentation.Build() is False:
            return 1;

    return 0;

if __name__ == "__main__":
    exit( Main() );
