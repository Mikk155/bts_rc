# ===================================================================
# ===================================================================
# Purpose:
#   Check validation of AngelScript debug preprocessors
# ===================================================================
# ===================================================================

from Tests.PyBuilder import PyBuilder;

class DebugCheck( PyBuilder ):

    def toggle_debug( self, processFrom: str, processTo: str ) -> int:

        files: int = 0;
        totalMatches: int = 0;

        for script in self.Scripts:

            currentMatches = 0;
            while script.Content.find( f"#if {processFrom}" ) >= 0:
                if self.Type == PyBuilder.BuildType.Check:
                    return 1;
                currentMatches += 1;
                script.Content = script.Content.replace( processFrom, processTo, 1 );

            if currentMatches > 0:

                self.Log( f"Updated {currentMatches} pre processor on file {script.Path}" );
                totalMatches += currentMatches;
                files += 1;

        if totalMatches > 0:
            self.Log( f"{totalMatches} pre processor has been updated on {files} files" );
        elif self.Type == PyBuilder.BuildType.Local:
            self.Log( "No files were updated" );

        return files;

    def Build(self) -> bool:
        processedFiles = self.toggle_debug( "DEBUG", "SERVER" );
        if processedFiles != 0 and self.Type != PyBuilder.BuildType.Local:
            self.Log( "{} Un processed files. run src/toggle_debug.py to replace DEBUG pre processors to SERVER!", processedFiles );
            return False;
        self.Log( "All AngelScript pre processors are updated" );
        return True;

DebugCheck();
