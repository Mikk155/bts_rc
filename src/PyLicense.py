import os;
import pathlib;
from main import *

class PyLicense( PyBuilder ):

    def Build(self) -> bool:

        def loadLicense() -> str:
            licensePath: str = os.path.join( gpWorkspace, "LICENSE.txt" );
            with open( licensePath, "r", encoding="utf-8" ) as file:
                lines: list[str] = file.readlines();
                for index, line in enumerate(lines):
                    lines[index] = f"*   {line}";
                lines.insert(0, "/*" );
                lines.append( "*/\n\n" );
                return ''.join( f"{line}" for line in lines );
            print( "Error: Couldn't open {}".format( licensePath ) );
            sys.exit(1);

        license: str = loadLicense();
        scriptFilesPath: str = os.path.join( gpWorkspace, "scripts", "maps", "bts_rc" );

        for path in pathlib.Path( scriptFilesPath ).rglob( f"*.as" ):

            if not path.is_file():
                continue

            content: str = None;

            with open( path, "r", encoding="utf-8" ) as fStream:
                content: str = fStream.read()

            if not license in content:
                with open( path, "w", encoding="utf-8" ) as fStream:
                    fStream.write( license + content );
                    self.Log( "Updated license on file {}", path );

        return True;
