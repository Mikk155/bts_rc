# ===================================================================
# ===================================================================
# Purpose:
#   Check validation of AngelScript debug preprocessors
# ===================================================================
# ===================================================================

from Tests.PyBuilder import PyBuilder;

class DebugCheck( PyBuilder ):

    def toggle_debug( self, processFrom: str, processTo: str, local = False ) -> int:

        import os;
        import pathlib;

        files: int = 0;
        totalMatches: int = 0;

        scriptFilesPath: str = os.path.join( self.Workspace, "scripts", "maps", "bts_rc" );

        for path in pathlib.Path( scriptFilesPath ).rglob( f"*.as" ):

            if not path.is_file():
                continue;

            content: str = None;

            with open( path, "r", encoding="utf-8" ) as fStream:
                content: str = fStream.read();
                fStream.close();

            currentMatches = 0;
            while content.find( f"#if {processFrom}" ) >= 0:
                if local is False:
                    return 1;
                currentMatches += 1;
                content = content.replace( processFrom, processTo, 1 );

            if currentMatches > 0:

                print( f"Updated {currentMatches} macros on file {os.path.relpath( path )}" );

                with open( path, "w", encoding="utf-8" ) as fStream:

                    fStream.write( content );
                    totalMatches += currentMatches;
                    files += 1;
                    fStream.close();

        if totalMatches > 0:
            print( f"{totalMatches} macros has been updated on {files} files" );
        elif local is True:
            print( "No files were updated" );

        return files;

    def Build(self) -> bool:
        processedFiles = self.toggle_debug( "DEBUG", "SERVER" );
        if processedFiles != 0:
            self.Log( "{} Un processed files. run src/toggle_debug.py to replace DEBUG pre processors to SERVER!", processedFiles );
            return False;
        self.Log( "All AngelScript pre processors are updated" );
        return True;

DebugCheck();
