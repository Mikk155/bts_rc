# ===================================================================
# ===================================================================
# Purpose:
#   cleanup garbage from MEGA sync
# ===================================================================
# ===================================================================

import os;

from Tests.PyTest import PyTest;

class Cleanup( PyTest ):

    def ShouldBuild(self) -> bool:
        return ( self.Type == PyTest.BuildType.Local );

    def Build(self) -> bool:

        def isExtension( filePath: str, fileExtensions: list[str] ) -> bool:

            index: int = filePath.rfind( '.' );

            for ext in fileExtensions:
                if filePath.endswith( ext ):
                    return True;

#            if index >= 0 and filePath[ index : ] in fileExtensions:
#                return True;

            return False;

        allowedExtensions = [
            ".bsp",
            ".cfg",
            ".gmr",
            ".gsr",
            "_motd.txt"
        ];

        mapsDirectory: str = os.path.join( self.Workspace, "maps" );

        for fileName in os.listdir( mapsDirectory ):

            filePath = os.path.join( mapsDirectory, fileName );

            if isExtension( filePath, allowedExtensions ) is False:
                try:
                    os.remove( filePath );
                except:
                    pass;

        return True;

Cleanup();
