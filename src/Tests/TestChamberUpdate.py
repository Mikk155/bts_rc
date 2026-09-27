# ===================================================================
# ===================================================================
# Purpose:
#   Install to repo the compiled maps if any.
# ===================================================================
# ===================================================================

import os;
import shutil;

from Tests.PyTest import PyTest;

class TestChamberUpdate( PyTest ):

    m_BSPFile: str = os.path.join( os.path.dirname( PyTest.GetWorkspace() ), "svencoop", "maps", "bts_rc_test_chamber.bsp" );

    def ShouldBuild(self) -> bool:
        return ( self.Type == PyTest.BuildType.Local and os.path.exists( self.m_BSPFile ) );

    def Build(self) -> bool:

        shutil.move( self.m_BSPFile, os.path.join( self.Workspace, "maps", "bts_rc_test_chamber.bsp" ) );
        shutil.move( self.m_BSPFile.replace( ".bsp", ".map" ), os.path.join( self.Workspace, "maps", "bts_rc_test_chamber.map" ) );

        return True;

TestChamberUpdate();
