'''
### **Purpose:**

Compact env_credit's credits.json AngelScript into a compacted literal strings.
'''

import json;
from pathlib import Path;

from Tests.PyTest import PyTest

class ShipEnvCredits( PyTest ):

    def ShouldBuild( self ) -> bool:
        return ( self.Type == PyTest.BuildType.Release );

    def Build( self ) -> bool:

        path: Path = Path( PyTest.GetWorkspace(), "scripts", "maps", "bts_rc", "credits.json" );
        parsed: dict;

        with open( path, 'r' ) as fStream:
            parsed = json.load( fStream );

        for script in self.Scripts:

            if( "\"bts_rc/credits.json\"" in script.Content ):
                script.Content = script.Content.replace( "\"bts_rc/credits.json\"", "\"\"\"" + json.dumps( parsed, separators=( ",", ":" ) ) + "\"\"\"" );
                self.Log( "Shiped & compacted {} into {}", path.relative_to( PyTest.GetWorkspace() ), script.Path );
                path.unlink();
                return True;

        return False;

ShipEnvCredits();
