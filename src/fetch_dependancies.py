# ===================================================================
# ===================================================================
# Purpose:
#   fetch dependancy scripts and assets
# ===================================================================
# ===================================================================

import os;
import requests;
from typing import LiteralString

gpWorkspace: LiteralString = os.path.dirname( os.path.dirname( __file__ ) );
'''Workspace directory'''

gpScriptsFromMikk: tuple[str] = (
    "mikk155/meta_api/json/v2/fmt/ToArray.as",
    "mikk155/meta_api/json/v2.as",
    "mikk155/meta_api/json.as",
    "mikk155/Server/chrono.as",
    "mikk155/meta_api.as"
);

def Main() -> int:

    input( "Downloading third party scripts..." );

    for ScriptPath in gpScriptsFromMikk:

        scriptURL: str = f"https://raw.githubusercontent.com/Mikk155/Sven-Co-op/main/scripts/{ScriptPath}"

        destinationPath: str = os.path.join( gpWorkspace, "scripts", ScriptPath )

        os.makedirs( os.path.dirname( destinationPath ), exist_ok=True );

        response: requests.Response = requests.get( scriptURL );

        if response.status_code != 200:
            print( f"Error downloading {ScriptPath}" );
            return 1;

        content: str = response.content.decode( "utf-8" ).replace( "\r\n", "\n" );

        if os.path.exists( destinationPath ):
            with open( destinationPath, "r", encoding="utf-8") as f:
                if f.read() == content:
                    print( f"Skip: {ScriptPath}" );
                    continue;

        with open( destinationPath, "w", newline="\n", encoding="utf-8" ) as f:
            f.write( content );

        print( f"Downloaded: {ScriptPath}" );

    #input( "Downloading game assets..." );

    input( "All done!" );

    return 0;

if __name__ == "__main__":
    exit( Main() );
