# ===================================================================
# ===================================================================
# Purpose:
#   fetch dependancy scripts and assets
# ===================================================================
# ===================================================================

import os;
import sys;
import requests;

gpGithubAction: bool = ( "-github" in sys.argv );
"""Whatever this is been run by github workflows"""

gpWorkspace: str = os.path.dirname( os.path.dirname( __file__ ) );
"""Workspace directory"""

gpScriptsFromMikk: tuple[str] = (
    "mikk155/meta_api/json/v2/fmt/ToArray.as",
    "mikk155/meta_api/json/v2/schema.as",
    "mikk155/meta_api/json/v2.as",
    "mikk155/meta_api/json.as",
    "mikk155/Server/chrono.as",
    "mikk155/meta_api.as"
);

def Log( message: str, freeze: bool = False ) -> None:
    print(message);
    if( freeze and not gpGithubAction ):
        input();

def Main() -> int:

    Log( "Downloading third party scripts..." );

    gitLocalFolder = os.path.join( gpWorkspace, "..", "svencoop_addon", "scripts" )

    for ScriptPath in gpScriptsFromMikk:

        content: str = None;

        # Get local if available
        if os.path.exists( gitLocalFolder ):
            scriptFile = os.path.join( gitLocalFolder, ScriptPath );
            if os.path.exists( scriptFile ):
                with open( scriptFile, "r", encoding="utf-8") as f:
                    content = f.read();

        # Otherwise assume non-mikk user
        if content is None:

            scriptURL: str = f"https://raw.githubusercontent.com/Mikk155/Sven-Co-op/main/scripts/{ScriptPath}"

            response: requests.Response = requests.get( scriptURL );

            if response.status_code != 200:
                Log( f"Error downloading {ScriptPath}", True );
                return 1;

            content: str = response.content.decode( "utf-8" ).replace( "\r\n", "\n" );

        if content is None:
            Log( f"Failed to get content for {ScriptPath}", True )
            return 1;

        destinationPath: str = os.path.join( gpWorkspace, "scripts", ScriptPath )

        os.makedirs( os.path.dirname( destinationPath ), exist_ok=True );

        if os.path.exists( destinationPath ):
            with open( destinationPath, "r", encoding="utf-8") as f:
                if f.read() == content:
                    Log( f"Skip: {ScriptPath}" );
                    continue;

        with open( destinationPath, "w", newline="\n", encoding="utf-8" ) as f:
            f.write( content );

        Log( f"Downloaded: {ScriptPath}" );

    #Log( "Downloading game assets..." );

    Log( "All done!", True );

    return 0;

if __name__ == "__main__":
    sys.exit( Main() );
