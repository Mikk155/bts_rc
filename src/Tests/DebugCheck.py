# ===================================================================
# ===================================================================
# Purpose:
#   Check validation of AngelScript debug preprocessors
# ===================================================================
# ===================================================================

from Tests.PyTest import PyTest;

class DebugCheck( PyTest ):

    def toggle_debug( self, processFrom: str, processTo: str, silent: bool = True ) -> tuple[int, int]:

        files: int = 0;
        totalMatches: int = 0;

        for script in self.Scripts:

            currentMatches = 0;
            while script.Content.find( f"#if {processFrom}" ) >= 0:
                currentMatches += 1;
                script.Content = script.Content.replace( processFrom, processTo, 1 );

            if currentMatches > 0:
                if not silent:
                    self.Log( f"Updated {currentMatches} pre processor{ 's' if currentMatches > 1 else '' } on file {script.Path}" );
                totalMatches += currentMatches;
                files += 1;

        return ( files, totalMatches );

    def Build( self ) -> bool:

        matches: tuple[ int, int ];

        match self.Type:

            case PyTest.BuildType.Release:
                matches = self.toggle_debug( "SERVER", "DEBUG" );

                if matches[0] != 0:
                    self.Log( "Updated {} pre-processors in {} files.", matches[1], matches[0] );
                    return True;

            case PyTest.BuildType.Check:
                matches = self.toggle_debug( "DEBUG", "SERVER" );

                if matches[0] != 0:
                    self.Log( "{} Un processed pre-processors on {} files. run src/main.py to replace DEBUG pre processors to SERVER!", matches[1], matches[0] );

            case PyTest.BuildType.Local:
                matches = self.toggle_debug( "DEBUG", "SERVER" );

                if matches[0] != 0:
                    self.Log( "All {} pre-processors in {} files has been updated. Commit the changes.", matches[1], matches[0] );
                    return True;

        return ( matches[0] == 0 );

DebugCheck();
