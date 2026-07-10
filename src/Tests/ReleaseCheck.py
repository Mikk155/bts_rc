# ===================================================================
# ===================================================================
# Purpose:
#   Check validation of g_ScriptsVersion & github latest release
#   If g_ScriptsVersion is newer than the last release it generates a release
# ===================================================================
# ===================================================================

import re;
import os;
import sys;
import requests;
from datetime import datetime;

from Tests.PyBuilder import PyBuilder

class ReleaseCheck( PyBuilder ):

    m_ProjectVersion: str = None;
    m_GithubData: dict = {
         "version": "",
         "previous_version": "",
         "abort": True
    };

    def IsGreaterSemantic( self, old: str, new: str ) -> bool:
        '''Return whatever the semantic version "new" is greater than "old"'''

        def toArrayInt( arr: list[str] ) -> None:
            '''Convert the given "arr" to int values'''
            for index, val in enumerate(arr):
                arr[index] = int(val);
            while len(arr) < 3:
                arr.append(0);

        old = old.split( '.' );
        toArrayInt(old);
        new = new.split( '.' );
        toArrayInt(new);

        if new[0] > old[0]:
            return True;
        if new[0] == old[0]:
            if new[1] > old[1]:
                return True;
            if new[1] == old[1]:
                if new[2] > old[2]:
                    return True;

        return False;

    def Build(self) -> bool:

        response: requests.Response = requests.get( f"https://api.github.com/repos/{self.m_Author}/{self.m_Repository}/releases/latest" );

        if response.status_code != 200:
            self.Log( "Failed to retrieve release data from Github" );
            return False;

        releaseData: dict = response.json();

        # Get the provided tag
        if self.Type == PyBuilder.BuildType.Release:

            self.m_GithubData[ "abort" ] = False;

        # HACK if we want to make actions trigger from releases rather than pushes this doesn't break compatibility.
        elif "--release" in sys.argv:

            # Make PyBuilder.GetType return Release
            sys.argv[ sys.argv.index( "--release" ) ] = "+release";
            lastTag: str = releaseData[ "tag_name" ];
            lastReleaseDate: str = releaseData[ "published_at" ];
            self.m_GithubData[ "previous_version" ] = lastTag;

            regexSemVer: re.Match[str] = None;

            # Find semantic version global variable in the project
            for script in self.Scripts:
                regexSemVer: re.Match[str] = re.search( r"g_ScriptsVersion\s*=\s*SemVer\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)", script.Content );
                if regexSemVer:
                    break;

            self.m_ProjectVersion = ".".join( regexSemVer.groups() );
            sys.argv.append( self.m_ProjectVersion ); # Set last release tag for PyBuilder.GetTag

            if lastTag == self.m_ProjectVersion:

                self.Log( "Project version has not changed. Skipping release." );

            elif self.IsGreaterSemantic( lastTag, self.m_ProjectVersion ) is False:

                self.Log( "Project version is lower than the last release at Github!." );
                return False;

            else:

                changelog: str = "";

                with open( os.path.join( self.Workspace, "docs", "page", "changelog.md" ), "r", encoding="utf-8" ) as fStream:

                    changelog = fStream.read();

                    end = len( changelog );

                    # Trim changelog till find the date of the latest release
                    dateReleased = datetime.fromisoformat( lastReleaseDate.replace( 'Z', '' ) );

                    matches = re.finditer( r'#\s+(\d{1,2})/(\d{1,2})/(\d{4})', changelog );

                    for match in matches:

                        dateFound = datetime( int( match.group(3) ), int( match.group(2) ), int( match.group(1) ) );

                        if dateFound <= dateReleased:
                            end = match.start();
                            break;

                    changelog = changelog[ : end ].strip().replace( "# ", "### " );

                with open( os.path.join( self.Workspace, "changelog.md" ), "w", encoding="utf-8" ) as fStream:
                    fStream.write( f"""# {self.m_Repository} map scripts [Version {self.m_ProjectVersion}](https://github.com/{self.m_Author}/{self.m_Repository}/tree/{self.m_ProjectVersion})

## ⚠️ Download map assets from [MEGA](https://mega.nz/folder/oYt1VYpB#Hy741Wp8-S7yFoWaeVFB4g).

## Git changes since [Version {lastTag}](https://github.com/{self.m_Author}/{self.m_Repository}/tree/{lastTag}) can be found [here](https://github.com/{self.m_Author}/{self.m_Repository}/compare/{self.m_ProjectVersion}...{lastTag}).

<details>
<summary>Changelog</summary>

{changelog}

</details>
""" );

                self.m_GithubData[ "abort" ] = False;

        self.m_GithubData[ "version" ] = self.Tag;
        self.m_GithubData[ "previous_version" ] = releaseData[ "tag_name" ];

        if self.Type == PyBuilder.BuildType.Release:
            with open( os.environ[ 'GITHUB_OUTPUT' ], 'a' ) as fStream:
                for key, value in self.m_GithubData.items():
                    print( f"{key}={value}", file=fStream );

        return True;

ReleaseCheck();
