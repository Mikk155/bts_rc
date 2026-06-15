# ===================================================================
# ===================================================================
# Purpose:
#   Check validation of scripts/maps/bts_rc/bts_rc.fgd
# ===================================================================
# ===================================================================

from Tests.PyBuilder import PyBuilder;

class FGDCheck( PyBuilder ):

    def Build(self) -> bool:
        import os;
        from valvefgd import FgdParse
        fgd = FgdParse( os.path.join( self.Workspace, "scripts", "maps", "bts_rc", "bts_rc.fgd" ) );
        self.Log( "FGD file propertly loads" );
        return True;

FGDCheck();
