# ===================================================================
# ===================================================================
# Purpose:
#   Check validation of AngelScript debug preprocessors
# ===================================================================
# ===================================================================

from Tests.PyTest import PyTest;

class DebugCheck( PyTest ):

    def toggle_debug( self, state: bool ) -> None:

        fromState = str( not state ).lower();
        toState = str( state ).lower();
        findState = f"const bool g_Debug = {fromState};";
        setState = f"const bool g_Debug = {toState};";

        for script in self.Scripts:
            if findState in script.Content:
                script.Content = script.Content.replace( findState, setState );

    def ShouldBuild(self) -> bool:
        return ( self.Type == PyTest.BuildType.Release );

    def Build( self ) -> bool:
        self.toggle_debug( False );
        self.Log( "Set g_Debug to false." );
        return True;

DebugCheck();
