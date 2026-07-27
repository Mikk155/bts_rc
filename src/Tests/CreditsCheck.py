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

    m_CreditsPath: str = os.path.join( PyBuilder.GetWorkspace(), "docs", "assets", "credits.json" );

    def ShouldBuild(self) -> bool:
        return self.FileModified( self.m_CreditsPath );

    def Build(self) -> bool:

        creditsList: list[str];

        with open( self.m_CreditsPath, "r" ) as fStream:
            creditsList = json.load( fStream );

        # Format object to ( ( name.lower(), index ), ... )
        creditsMap: list[tuple[str, int]] = [ ( user.lower() if isinstance( user, str ) else user[0].lower(), i ) for i, user in enumerate( creditsList ) ];

        creditsSorted: list[tuple[str, int]] = sorted( set( creditsMap ) );

        # Sortarray credits using the indexes ordering in the sorted tuple
        creditsFixed = [ creditsList[ index[1] ] for index in creditsSorted ];

        if creditsList != creditsFixed:
            # Update credits.json to be sorted in web
            with open( self.m_CreditsPath, "w" ) as fStream:
                content = json.dumps( creditsFixed, indent=4 );
                fStream.write( content );
                self.Log( "Updated and sorted {}", os.path.relpath( self.m_CreditsPath, self.Workspace ) );

        # Apply url markdown
        for i, contributor in enumerate(creditsFixed):
            if isinstance( contributor, list ):
                creditsFixed[i] = f"[{contributor[0]}]({contributor[1]})";

        authorsPath: str = os.path.join( self.Workspace, "AUTHORS.md" );

        with open( authorsPath, "w" ) as fStream:
            fStream.write( """# Project Maintainers

| RaptorSKA | Level design | [@RaptorSKA](https://github.com/RaptorSKA) |
|---|---|---|
| Mikk | Scripting | [@Mikk155](https://github.com/Mikk155) |

## Contributors
{}""".format( "".join( f"- {contributor}\n" for contributor in creditsFixed ) ) );
            self.Log( "Updated {}", os.path.relpath( authorsPath, self.Workspace ) );

        return True;

CreditsCheck();
