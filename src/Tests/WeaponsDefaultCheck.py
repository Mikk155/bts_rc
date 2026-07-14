# ===================================================================
# ===================================================================
# Purpose:
#   Formats scripts/maps/bts_rc/entities/weapons/default_config.json
#   into a single compacted string literal in
# ===================================================================
# ===================================================================

import os;
import json;

from Tests.PyBuilder import PyBuilder

class WeaponsDefaultCheck( PyBuilder ):

    def Build(self) -> bool:

        defaultWeaponConfig: str = os.path.join( self.Workspace, "scripts", "maps", "bts_rc", "entities", "weapons", "default_config.json" );

        parsed: dict = None;

        try:
            with open( defaultWeaponConfig, "r" ) as fStream:
                parsed = json.load( fStream );
    
        except json.JSONDecodeError as e:
            self.Log( "{} > invalid JSON: scripts/maps/bts_rc/entities/weapons/default_config.json at line {}:{}", e.msg, e.lineno, e.colno );
            return False;

        for script in self.Scripts:

            if not ( "const string __GetDefaultWeaponConfig__()" in script.Content ):
                continue;

            if self.Type == PyBuilder.BuildType.Release:

                script.Content = script.Content.replace( "scripts/maps/bts_rc/entities/weapons/default_config.json", json.dumps( parsed, separators=( ",", ":" ) ) );

            elif self.Type == PyBuilder.BuildType.Local:

                def sortRecursive( obj: dict | list ) -> dict | list:
                    if isinstance( obj, dict ):
                        return { k: sortRecursive( obj[k] ) for k in sorted( obj ) };
                    elif isinstance( obj, list ):
                        return [ sortRecursive( item ) for item in sorted( obj ) ];
                    else:
                        return obj

                oldSerialized = json.dumps( parsed, indent=4 );
                newSerialized = json.dumps( sortRecursive(parsed), indent=4 );

                if( oldSerialized != newSerialized ):
                    with open( defaultWeaponConfig, "w" ) as fStream:
                        fStream.write( newSerialized );

        return True;

WeaponsDefaultCheck();
