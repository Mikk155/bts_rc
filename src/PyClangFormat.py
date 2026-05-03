import os;
import subprocess;
from main import *

class PyClangFormat( PyBuilder ):

    def Build( self ) -> bool:

        clang: str = os.path.join( gpWorkspace, "as-clang-format.exe" );
        targetDir: str = os.path.join( gpWorkspace, "scripts", "maps", "bts_rc" );

        if not os.path.isfile( clang ):
            self.Log( "Couldn't find as-clang-format at \"{}\" get from \"https://github.com/Mikk155/as-clang-format\"", clang );
            return False;

        formattedCount: int = 0;

        for root, _, files in os.walk( targetDir ):

            for file in files:

                if ( not file.endswith( ".as" ) ):
                    continue;

                filePath: str = os.path.join( root, file );

                try:

                    subprocess.run(
                        [ clang, "-i", filePath ],
                        check = True,
                        stdout = subprocess.DEVNULL,
                        stderr = subprocess.DEVNULL
                    );

                    formattedCount += 1;

                except subprocess.CalledProcessError as e:

                    self.Log( "Error {}", e );

                    return False;

        self.Log( "{} formated sources.", formattedCount );

        return True;