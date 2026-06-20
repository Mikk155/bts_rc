# ===================================================================
# ===================================================================
# Purpose:
#   Download third party dependancies
# ===================================================================
# ===================================================================

import os;
import re;
import requests;
from pathlib import Path

from Tests.PyBuilder import PyBuilder;

class DependancyCheck( PyBuilder ):

    def Build(self) -> bool:

        self.Log( "Downloading third party scripts..." );

        includeRegex = re.compile( r'#include\s*"([^"]+)"' );

        for script in self.Scripts:

            scriptPath: Path = script.AbsolutePath.parent;

            for match in includeRegex.finditer( script.Content ):

                relativeInclude = match.group(1);

                ResolvedPath: Path = ( scriptPath / relativeInclude ).resolve();

                dependencyPath: Path = None;

                try:
                    dependencyPath: Path = ResolvedPath.relative_to( os.path.join( self.Workspace, "scripts", "mikk155" ) );
                except ValueError:
                    continue;

                scriptURL: str = f"https://raw.githubusercontent.com/Mikk155/Sven-Co-op/main/scripts/mikk155/{dependencyPath.as_posix()}.as"

                response: requests.Response = requests.get( scriptURL );

                if response.status_code != 200:
                    self.Log( f"Error downloading {dependencyPath} from {scriptURL} included by {script.Path}" );
                    return False;

                content: str = response.content.decode( "utf-8" ).replace( "\r\n", "\n" );

                if content is None:
                    self.Log( f"Failed to get content for {dependencyPath} from {scriptURL} included by {script.Path}" );
                    return False;

                os.makedirs( ResolvedPath.parent, exist_ok=True );

                destinationPath = f"{ResolvedPath}.as";

                if self.Type == PyBuilder.BuildType.Local and os.path.exists( destinationPath ):
                    with open( destinationPath, "r", encoding="utf-8") as f:
                        if f.read() == content:
                            self.Log( f"Skip: scripts\\mikk155\\{dependencyPath}.as" );
                            continue;

                self.Log( f"Downloading scripts\\mikk155\\{dependencyPath}.as" );

                with open( destinationPath, "w", newline="\n", encoding="utf-8" ) as f:
                    f.write( content );

        return True;

DependancyCheck();
