'''
### **Purpose:**
Check validation of AngelScript license headers.
'''

import os;

from Tests.PyTest import PyTest;

class UpdateLicenseHeaders( PyTest ):

    m_ModifiedFiles: list[str] = [];

    def ShouldBuild( self ) -> bool:

        licenseHeader: str;

        with open( os.path.join( self.Workspace, "LICENSE.txt" ), "r", encoding="utf-8" ) as fStream:

            lines: list[str] = fStream.readlines();

            for index, line in enumerate(lines):
                lines[index] = "*{}{}".format( "" if line == "" or line == "\n" else "   ", line );

            lines.insert(0, "/**\n" );
            lines.append( "**/\n\n" );

            licenseHeader = "".join( f"{line}" for line in lines );

            fStream.close();

        for script in self.Scripts:

            if not licenseHeader in script.Content:

                if script.Content.startswith( "/*" ):

                    hasNotice: int = script.Content.find( "Copyright" );

                    if hasNotice > -1:

                        closeComment: int = script.Content.find( "*/" );

                        if( hasNotice < closeComment ):

                            script.Content = script.Content[ closeComment + 2 : ];

                            while script.Content[0] == '\n' or script.Content[0] == ' ' or script.Content[0] == '\t':
                                script.Content = script.Content[1:];

                self.m_ModifiedFiles.append( script.Path );
                script.Content = licenseHeader + script.Content;

        return ( len( self.m_ModifiedFiles ) > 0 );

    def Build( self ) -> bool:

        match self.Type:

            case PyTest.BuildType.Check:
                self.Log( "AngelScript files without license headers! Execute src/main.py to format files." );
                return False;

            case _:
                for file in self.m_ModifiedFiles:
                    self.Log( "Updated license on file {}", file );

        return False;

UpdateLicenseHeaders();
