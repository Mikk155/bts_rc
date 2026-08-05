# ===================================================================
# ===================================================================
# Purpose:
#   Iterates over the asset folders to report unprecached sounds with metamod
#
#   Using:
#       Run bts_rc.bsp using metamod aslp plugin.
#       Use command "sv_report_precache 1"
#       Restart the game so it tracks precaches.
#       Run this script and it will generate a file containing unprecached assets.
# ===================================================================
# ===================================================================

import os;
import json;

gpWorkspace: str = os.path.dirname( os.path.dirname( os.path.dirname( __file__ ) ) );
gpPrecachedAssets: dict[str, int];

with open( os.path.join( os.path.dirname( gpWorkspace ), "svencoop", "maps", "bts_rc_precache.json" ), "r" ) as fStream:
    gpPrecachedAssets = json.load( fStream );

gpResults: list[str] = [];

gpAssets: list[str] = [
    "models",
    "sound",
    "sprites"
];

svenDirectory = os.path.join( os.path.dirname( gpWorkspace ), "svencoop" );

for assetFolder in gpAssets:

    assetDirectory: str = os.path.join( gpWorkspace, assetFolder );

    for root, _, files in os.walk( assetDirectory ):
        for file in files:
            fullAssetPath: str = os.path.join( root, file );
            relativePath: str = os.path.relpath( fullAssetPath, gpWorkspace );
            if not relativePath in gpPrecachedAssets:
                gpResults.append( relativePath );

if len(gpResults) > 0:

    outputJsonPath: str = os.path.join( os.path.dirname( __file__ ), "unused_assets.json" );

    with open( outputJsonPath, 'w', encoding='utf-8' ) as fStream:
        json.dump( gpResults, fStream, indent=4, ensure_ascii=False );
        print( f"Sounds written to \"{outputJsonPath}\"" );
