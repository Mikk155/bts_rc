# ===================================================================
# ===================================================================
# Purpose:
#   cleanup garbage from MEGA sync
# ===================================================================
# ===================================================================

import os;

from Tests.PyBuilder import PyBuilder;

class Cleanup( PyBuilder ):

    def ShouldBuild(self) -> bool:
        return ( self.Type == PyBuilder.BuildType.Local );

    def Build(self) -> bool:

        def isExtension( filePath: str, fileExtensions: list[str] ) -> bool:

            index: int = filePath.rfind( '.' );

            if index >= 0 and filePath[ index : ] in fileExtensions:
                return True;

            return False;

        allowedExtensions = [
            ".bsp",
            ".cfg",
            ".gmr",
            ".gsr"
        ];

        mapsDirectory: str = os.path.join( self.Workspace, "maps" );

        for fileName in os.listdir( mapsDirectory ):
            if not isExtension( os.path.join( mapsDirectory, fileName ), allowedExtensions ) and os.path.isfile( fileName ):
                os.remove( os.path.join( mapsDirectory, fileName ) );

        return True;

Cleanup();
