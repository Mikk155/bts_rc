# ===================================================================
# ===================================================================
# Purpose:
#   Check validation of AngelScript license headers
# ===================================================================
# ===================================================================

from Tests.PyBuilder import PyBuilder;

class LicenseCheck( PyBuilder ):

    def loadLicense(self) -> str | None:

        import os;
        licensePath: str = os.path.join( self.Workspace, "LICENSE.txt" );

        if os.path.exists( licensePath ):

            with open( licensePath, "r", encoding="utf-8" ) as file:

                lines: list[str] = file.readlines();

                for index, line in enumerate(lines):
                        lines[index] = f"*   {line}";

                lines.insert(0, "/**\n" );
                lines.append( "**/\n\n" );

                return "".join( f"{line}" for line in lines );

        self.Log( "Error: Couldn't open {}", licensePath );

        return None;

    def apply_license(self, local = False) -> int:

        gpLicense: str = self.loadLicense();

        if gpLicense is None:
            return False;

        result = 0;

        import os;
        import pathlib;

        scriptFilesPath: str = os.path.join( self.Workspace, "scripts", "maps", "bts_rc" );

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

                result += 1;

                if local:
                    print( f"Updated license on file {os.path.relpath( path )}" );

                with open( path, "w", encoding="utf-8" ) as fStream:

                    fStream.write( gpLicense + content );
                    fStream.close();

        return result;

    def Build(self) -> bool:
        licensedFiles = self.apply_license();
        if licensedFiles != 0:
            self.Log( "{} Unlicensed files. run src/apply_license.py to add headers!", licensedFiles );
            return False;
        self.Log( "All files contains license headers" );
        return True;

LicenseCheck();
