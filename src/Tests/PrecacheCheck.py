# ===================================================================
# ===================================================================
# Purpose:
#   Creates precaches in a single file based on ../precaches.json
# ===================================================================
# ===================================================================

import os;
import re;
import json;

from Tests.PyBuilder import PyBuilder;

class PrecacheCheck( PyBuilder ):

    m_PrecachesPath: str = os.path.join( PyBuilder.GetWorkspace(), "src", "precaches.json" );

    def Build(self) -> bool:

        precacheScript = next( ( x for x in self.Scripts if x.Name == "Precache" ), None );

        assets: dict[list[str]] = None;

        with open( self.m_PrecachesPath, "r" ) as fStream:
            assets = json.load( fStream );

        PrecacheModel: list[str] = assets[ "PrecacheModel" ];
        PrecacheSound: list[str] = assets[ "PrecacheSound" ];
        PrecacheGeneric: list[str] = assets[ "PrecacheGeneric" ];

        global results;
        results = 0;

        def ProcessAssets( pattern: str, listRef: list[str], prefix_to_comment: str ) -> None:

            PrecachedAssets: set[str] = set();

            for script in self.Scripts:

                if script is precacheScript:
                    continue;

                fullPattern: str = r'^(?!\s*//).*?' + pattern;

                assetMatches: list[str] = re.findall( fullPattern, script.Content, re.M );

                for match in assetMatches:
                    if match in listRef:
                        global results;
                        results += 1;
                        PrecachedAssets.add( match );

                for match in PrecachedAssets:
                    modifyPattern: str = rf'^(\s*)({prefix_to_comment}\s*\(\s*"{re.escape( match )}"\s*\);?)';
                    script.Content = re.sub(
                        modifyPattern,
                        r'\1// \2',
                        script.Content,
                        flags = re.M
                    );

        ProcessAssets( r'g_Game\.PrecacheModel\s*\(\s*"([^"]+)"\s*\)', PrecacheModel, 'g_Game.PrecacheModel' );
        ProcessAssets( r'g_Game\.PrecacheGeneric\s*\(\s*"([^"]+)"\s*\)', PrecacheGeneric, 'g_Game.PrecacheGeneric' );
        ProcessAssets( r'g_SoundSystem\.PrecacheSound\s*\(\s*"([^"]+)"\s*\)', PrecacheSound, 'g_SoundSystem.PrecacheSound' );

        if( results != 0 ):

            self.Log( f"Found {results} duplicated precaches that are declared in src/precaches.json" );

            if( self.Type != PyBuilder.BuildType.Local ):
                return False;

        if ( self.Type == PyBuilder.BuildType.Local and self.FileModified( self.m_PrecachesPath ) ):

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
