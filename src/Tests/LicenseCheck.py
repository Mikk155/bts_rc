# ===================================================================
# ===================================================================
# Purpose:
#   Check validation of AngelScript license headers.
# ===================================================================
# ===================================================================

import os;

from Tests.PyBuilder import PyBuilder;

class LicenseCheck( PyBuilder ):

    def Build(self) -> bool:

        licenseHeader: str;

        with open( os.path.join( self.Workspace, "LICENSE.txt" ), "r", encoding="utf-8" ) as fStream:

            lines: list[str] = fStream.readlines();

            for index, line in enumerate(lines):
                lines[index] = f"*   {line}";

            lines.insert(0, "/**\n" );
            lines.append( "**/\n\n" );

            licenseHeader = "".join( f"{line}" for line in lines );

            fStream.close();

        for script in self.Scripts:

            if not licenseHeader in script.Content:

                if self.Type == PyBuilder.BuildType.Check:
                    self.Log( "AngelScript files without license headers! Execute src/main.py to format files." );
                    return False;

                if script.Content.startswith( "/*" ):

                    hasNotice: int = script.Content.find( "Copyright" );

                    if hasNotice > -1:

                        closeComment: int = script.Content.find( "*/" );

                        if( hasNotice < closeComment ):

                            script.Content = script.Content[ closeComment + 2 : ];

                            while script.Content[0] == '\n' or script.Content[0] == ' ' or script.Content[0] == '\t':
                                script.Content = script.Content[1:];

                self.Log( f"Updated license on file {script.Path}" );

                script.Content = licenseHeader + script.Content;

        self.Log( "All files contains license headers" );
        return True;

LicenseCheck();
