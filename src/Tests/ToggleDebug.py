'''
### **Purpose:**
#### Release:
    Switch all AngelScript SERVER pre processors to a disabled DEBUG and set g_Debug property to false.
##### Note: Use src/tools/toggle_debug.py to momentarly enable/disable debug mode for testing things are not broken.
'''

from Tests.PyTest import PyTest;

class ToggleDebug( PyTest ):

    def ToggleDebug( self, state: bool ) -> None:

        fromState = str( not state ).lower();
        toState = str( state ).lower();
        findState = f"const bool g_Debug = {fromState};";
        setState = f"const bool g_Debug = {toState};";
        processTo: str = "SERVER" if state else "DEBUG";
        processFrom: str = "DEBUG" if state else "SERVER";

        processors = 0;

        for script in self.Scripts:

            while( script.Content.find( f"#if {processFrom}" ) > -1 ):
                script.Content = script.Content.replace( f"#if {processFrom}", f"#if {processTo}", 1 );
                processors += 1;

            if findState in script.Content:

                script.Content = script.Content.replace( findState, setState );
                self.Log( "Set const bool g_Debug = {};", toState );

        self.Log( "Set {} pre-processors to {} ({} -> {})", processors, toState, processFrom, processTo );

    def ShouldBuild( self ) -> bool:
        return ( self.Type == PyTest.BuildType.Release );

    def Build( self ) -> bool:
        self.ToggleDebug( False );
        return True;

ToggleDebug();
