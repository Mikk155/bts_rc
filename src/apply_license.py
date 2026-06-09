# ===================================================================
# ===================================================================
# Purpose:
#   Apply license to all the script headers
# ===================================================================
# ===================================================================

import os;
import sys;
import pathlib;
from typing import LiteralString

gpWorkspace: LiteralString = os.path.dirname( os.path.dirname( __file__ ) );
'''Workspace directory'''

def Main() -> int:

    def loadLicense() -> str | None:

        licensePath: str = os.path.join( gpWorkspace, "LICENSE.txt" );

        if os.path.exists( licensePath ):

            with open( licensePath, "r", encoding="utf-8" ) as file:

                lines: list[str] = file.readlines();

                for index, line in enumerate(lines):
                        lines[index] = f"*   {line}";

                lines.insert(0, "/**\n" );
                lines.append( "**/\n\n" );

                return ''.join( f"{line}" for line in lines );

        input( "Error: Couldn't open {}".format( licensePath ) );

        return None;

    print( "Updating license headers..." );

    gpLicense: str = loadLicense();

    if gpLicense is None:
        return 1;

    scriptFilesPath: str = os.path.join( gpWorkspace, "scripts", "maps", "bts_rc" );

    for path in pathlib.Path( scriptFilesPath ).rglob( f"*.as" ):

        if not path.is_file():
            continue;

        content: str = None;

        with open( path, "r", encoding="utf-8" ) as fStream:

            content: str = fStream.read();

            if not gpLicense in content:

                if content.startswith( "/*" ):

                    hasNotice: int = content.find( "Copyright" );

                    if hasNotice > -1:

                        closeComment: int = content.find( "*/" );

                        if( hasNotice < closeComment ):

                            content = content[ closeComment + 2 : ];

                            while content[0] == '\n' or content[0] == ' ' or content[0] == '\t':
                                content = content[1:];

                fStream.close();

        if not gpLicense in content:

            with open( path, "w", encoding="utf-8" ) as fStream:

                fStream.write( gpLicense + content );
                print( "Updated license on file {}".format( os.path.relpath( path ) ) );
                fStream.close();

    input( "All done!" );

    return 0;

if __name__ == "__main__":
    exit( Main() );
