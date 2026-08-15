# ===================================================================
# ===================================================================
# Purpose:
#   Formats scripts/maps/bts_rc/default_config.json
#   into a single compacted string literal in
# ===================================================================
# ===================================================================

import os;
import json;

from Tests.PyBuilder import PyBuilder

class DefaultConfigCheck( PyBuilder ):

    m_DefaultConfig: str = os.path.join( PyBuilder.GetWorkspace(), "scripts", "maps", "bts_rc", "default_config.json" );

    def ShouldBuild(self) -> bool:
        return ( self.Type != PyBuilder.BuildType.Local or self.FileModified( self.m_DefaultConfig ) );

    def Build(self) -> bool:

        parsed: dict = None;

        try:
            with open( self.m_DefaultConfig, "r" ) as fStream:
                # lines: list[str] = fStream.readlines();
                # content: str = "";
                # for line in lines:
                #     if not line.strip().startswith( "//" ):
                #         content += line;
                # I prefer to sort the object more than comments.
                parsed = json.load( fStream );

        except json.JSONDecodeError as e:
            self.Log( "{} > invalid JSON: scripts/maps/bts_rc/default_config.json at line {}:{}", e.msg, e.lineno, e.colno );
            return False;

        for script in self.Scripts:

            if not ( "const string __GetDefaultConfig__()" in script.Content ):
                continue;

            if self.Type == PyBuilder.BuildType.Release:

                script.Content = script.Content.replace( "scripts/maps/bts_rc/default_config.json", json.dumps( parsed, separators=( ",", ":" ) ) );

            elif self.Type == PyBuilder.BuildType.Local:

                def sortRecursive( obj: dict | list ) -> dict | list:
                    if isinstance( obj, dict ):
                        return { k: sortRecursive( obj[k] ) for k in sorted( obj ) };
                    else:
                        return obj

                oldSerialized = json.dumps( parsed, indent=4 );
                newSerialized = json.dumps( sortRecursive(parsed), indent=4 );

                if( oldSerialized != newSerialized ):
                    with open( self.m_DefaultConfig, "w" ) as fStream:
                        fStream.write( newSerialized );

        return True;

DefaultConfigCheck();
