# ===================================================================
# ===================================================================
# Purpose:
#   Creates precaches in a single file based on ../precaches.json
# ===================================================================
# ===================================================================

import os;
import json;

from Tests.PyBuilder import PyBuilder;

class PrecacheCheck( PyBuilder ):

    m_PrecachesPath: str = os.path.join( PyBuilder.GetWorkspace(), "src", "precaches.json" );

    def ShouldBuild(self) -> bool:
        return ( self.Type == PyBuilder.BuildType.Local and self.FileModified( self.m_PrecachesPath ) );

    def Build(self) -> bool:

        precacheScript = next( ( x for x in self.Scripts if x.Name == "Precache" ), None );

        assets: dict[list[str]] = None;

        with open( self.m_PrecachesPath, "r" ) as fStream:
            assets = json.load( fStream );

        PrecacheModel: list[str] = assets[ "PrecacheModel" ];
        PrecacheSound: list[str] = assets[ "PrecacheSound" ];
        PrecacheGeneric: list[str] = assets[ "PrecacheGeneric" ];
        PrecacheModel.sort();
        PrecacheSound.sort();
        PrecacheGeneric.sort();

        buffer = "// DO NOT MODIFY THIS FILE!\n// See: src/precaches.json and generate this file using src/main.py.\nvoid Precache()\n{\n"
        buffer += "".join( f"    g_Game.PrecacheModel( \"{asset}\" );\n" for asset in PrecacheModel );
        buffer += "".join( f"    g_Game.PrecacheGeneric( \"{asset}\" );\n" for asset in PrecacheGeneric );
        buffer += "".join( f"    g_SoundSystem.PrecacheSound( \"{asset}\" );\n" for asset in PrecacheSound );
        buffer += "}\n";

        if not buffer in precacheScript.Content: # not equal. has license header.
            precacheScript.Content = buffer;
            with open( self.m_PrecachesPath, "w" ) as fStream:
                fStream.write( json.dumps( assets, indent=4 ) ); # Sorted now

PrecacheCheck();
