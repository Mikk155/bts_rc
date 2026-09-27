# ===================================================================
# ===================================================================
# Purpose:
#   Check validation of scripts/maps/bts_rc/bts_rc.fgd
# ===================================================================
# ===================================================================

import os;
from valvefgd import FgdParse;

from Tests.PyTest import PyTest;

class FGDCheck( PyTest ):

    def Build(self) -> bool:
        fgd = FgdParse( os.path.join( self.Workspace, "scripts", "maps", "bts_rc", "bts_rc.fgd" ) );
        return True;

FGDCheck();
