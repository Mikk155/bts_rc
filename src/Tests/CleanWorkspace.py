'''
### **Purpose:**

Clean up garbage files generated from J.A.C.K for MEGA Sync.
'''

import os;
from pathlib import Path;

from Tests.PyTest import PyTest;

class CleanWorkspace( PyTest ):

    m_DeleteFiles: list[Path] = [];

    def ShouldBuild( self ) -> bool:

        if self.Type != PyTest.BuildType.Local:
            return False;

        mapsDirectory: Path = Path( self.Workspace, "maps" );

        allowedExtensions = [
            ".bsp",
            ".cfg",
            ".gmr",
            ".gsr",
            ".jmf",
            ".rmf"
        ];

        for fileName in os.listdir( mapsDirectory ):

            filePath: Path = Path( mapsDirectory, fileName );

            if filePath.is_file() and not filePath.suffix in allowedExtensions and not filePath.name.endswith( "_motd.txt" ):
                self.m_DeleteFiles.append( filePath );

        return ( len(self.m_DeleteFiles) > 0 );

    def Build( self ) -> bool:

        for file in self.m_DeleteFiles:
            self.Log( "Deleting file {}", file.relative_to( self.Workspace ).as_posix() );
            file.unlink();

        return True;

CleanWorkspace();
