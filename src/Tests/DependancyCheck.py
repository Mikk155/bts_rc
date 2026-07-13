# ===================================================================
# ===================================================================
# Purpose:
#   Download third party dependancies
# ===================================================================
# ===================================================================

import os;
import re;
import requests;
from pathlib import Path;

from Tests.PyBuilder import PyBuilder;

class DependancyCheck( PyBuilder ):

    m_IncludeRegex: re.Pattern[str] = re.compile( r'#include\s*"([^"]+)"' );

    def TryInstall( self, path: Path ) -> bool:
        '''Try to install include directives from the given file'''

        content: str = None;

        if not os.path.exists( path ):
            self.Log( "Non existent file {}", path.relative_to( self.Workspace ) );
            return False;

        with open( path, "r", encoding="utf-8") as fStream:
            content = fStream.read();

        mikkFolder = Path( os.path.join( self.Workspace, "scripts", "mikk155" ) );

        scriptPath: Path = path.parent;

        for match in self.m_IncludeRegex.finditer( content ):

            relativeInclude = match.group(1);

            ResolvedPath: Path = ( scriptPath / relativeInclude ).resolve();

            dependencyPath: Path = None;

            try:
                dependencyPath: Path = ResolvedPath.relative_to( mikkFolder );
            except ValueError:
                continue;

            scriptURL: str = f"https://raw.githubusercontent.com/Mikk155/Sven-Co-op/main/scripts/mikk155/{dependencyPath.as_posix()}.as";

            response: requests.Response = requests.get( scriptURL );

            if response.status_code != 200:
                self.Log( f"Error downloading {dependencyPath} from {scriptURL} included by {path.relative_to( self.Workspace )}" );
                return False;

            content: str = response.content.decode( "utf-8" ).replace( "\r\n", "\n" );

            if content is None:
                self.Log( f"Failed to get content for {dependencyPath} from {scriptURL} included by {path.relative_to( self.Workspace )}" );
                return False;

            os.makedirs( ResolvedPath.parent, exist_ok=True );

            destinationPath = f"{ResolvedPath}.as";

            upToDate = False;

            if self.Type == PyBuilder.BuildType.Local and os.path.exists( destinationPath ):
                with open( destinationPath, "r", encoding="utf-8") as f:
                    if f.read() == content:
                        self.Log( f"Skip up-to-date scripts\\mikk155\\{dependencyPath}.as" );
                        upToDate = True;

            if upToDate is False:

                self.Log( f"Downloading scripts\\mikk155\\{dependencyPath}.as" );

                with open( destinationPath, "w", newline="\n", encoding="utf-8" ) as f:
                    f.write( content );

            if self.TryInstall( Path( destinationPath ) ) is False:
                return False;

        return True;

    def Build(self) -> bool:

        self.Log( "Downloading third party scripts..." );

        mikkFolder = Path( os.path.join( self.Workspace, "scripts", "mikk155" ) );

        if mikkFolder.is_symlink():
            self.Log( "Ignoring dependancy scripts at path {} is a symlink file", mikkFolder.relative_to( self.Workspace ) );

        else:
            for script in self.Scripts:
                if self.TryInstall( script.AbsolutePath ) is False:
                    return False;

        return True;

DependancyCheck();
