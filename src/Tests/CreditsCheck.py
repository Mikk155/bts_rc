# ===================================================================
# ===================================================================
# Purpose:
#   Checks the credit file and update as needed
# ===================================================================
# ===================================================================

import os;
import json;

from Tests.PyBuilder import PyBuilder;

class CreditsCheck( PyBuilder ):

    def Build(self) -> bool:

        creditsPath: str = os.path.join( self.Workspace, "docs", "assets", "credits.json" );

        creditsList: list[str];
        
        with open( creditsPath, "r" ) as fStream:
            creditsList = json.load( fStream );

        creditsFixed: list[str] = creditsList.copy();
        creditsFixed = sorted(set(creditsFixed));

        if( creditsFixed != creditsList ):

            with open( creditsPath, "w" ) as fStream:
                fStream.write( json.dumps( creditsFixed, indent = 4 ) );
                self.Log( "Updated and sorted {}", os.path.relpath( creditsPath, self.Workspace ) );

            authorsPath: str = os.path.join( self.Workspace, "AUTHORS.md" );

            with open( authorsPath, "w" ) as fStream:
                fStream.write( """# Project Maintainers

| RaptorSKA | Level design | [@RaptorSKA](https://github.com/RaptorSKA) |
|---|---|---|
| Mikk | Scripting | [@Mikk155](https://github.com/Mikk155) |

## Contributors
{}""".format( "".join( f"- {contributor}\n" for contributor in creditsFixed ) ) );
                self.Log( "Updated {}", os.path.relpath( authorsPath, self.Workspace ) );

            return False;

        return True;

CreditsCheck();
