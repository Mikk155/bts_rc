# ===================================================================
# ===================================================================
# Purpose:
#   Formats scripts/maps/bts_rc/default_config.json
#   into a single compacted string literal in
# ===================================================================
# ===================================================================

import os;
import json;
import jsonschema;
from pathlib import Path;

from Tests.PyTest import PyTest

class CheckJSONValidation( PyTest ):

    m_DefaultConfig: Path = Path( PyTest.GetWorkspace(), "scripts", "maps", "bts_rc", "default_config.json" );

    def Build( self ) -> bool:

        parsed: dict = None;

        try:
            with open( self.m_DefaultConfig, "r" ) as fStream:
                parsed = json.load( fStream );

        except json.JSONDecodeError as e:
            self.Log( "{} > invalid JSON: scripts/maps/bts_rc/default_config.json at line {}:{}", e.msg, e.lineno, e.colno );
            return False;

        try:
            with open( os.path.join( self.Workspace, "docs", "schema.json" ), "r" ) as fStream:
                jsonschema.validate( instance=parsed, schema=json.load( fStream ) );
        except jsonschema.ValidationError as e:
            self.Log( "invalid JSON: scripts/maps/bts_rc/default_config.json at {}\n{}", e.json_path, e.message );
            return False;

        for script in self.Scripts:

            if not ( "const string __GetDefaultConfig__()" in script.Content ):
                continue;

            if self.Type == PyTest.BuildType.Release:
                script.Content = script.Content.replace( "scripts/maps/bts_rc/default_config.json", json.dumps( parsed, separators=( ",", ":" ) ) );
                return True;

            def sortRecursive( obj: dict | list ) -> dict | list:
                if isinstance( obj, dict ):
                    return { k: sortRecursive( obj[k] ) for k in sorted( obj ) };
                else:
                    return obj

            oldSerialized = json.dumps( parsed, indent=4 );
            newSerialized = json.dumps( sortRecursive(parsed), indent=4 );

            if( oldSerialized != newSerialized ):

                if self.Type == PyTest.BuildType.Local:
                    with open( self.m_DefaultConfig, "w" ) as fStream:
                        fStream.write( newSerialized + '\n' );
                    self.Log( "Sorted & formated {}", self.m_DefaultConfig.relative_to( PyTest.GetWorkspace() ) );
                elif self.Type == PyTest.BuildType.Check:
                    self.Log( "Un-formated {} Execute src/main.py to format files.", self.m_DefaultConfig.relative_to( PyTest.GetWorkspace() ) );
                return False;

        return True;

CheckJSONValidation();
