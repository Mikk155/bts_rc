'''
### **Purpose:**

Compact env_credit's credits.json AngelScript into a compacted literal strings.
'''

import json;
from pathlib import Path;

from Tests.PyTest import PyTest

class EnvCreditsUpdate( PyTest ):

    m_CreditsSchemaPath: Path = Path( PyTest.GetWorkspace(), "scripts", "maps", "bts_rc", "credits_schema.json" );
    m_CreditsPath: Path = Path( PyTest.GetWorkspace(), "scripts", "maps", "bts_rc", "credits.json" );

    def ShouldBuild( self ) -> bool:
        return ( self.Type == PyTest.BuildType.Release );

    def Build( self ) -> bool:

        parsed: dict;

        with open( self.m_CreditsPath, 'r' ) as fStream:
            parsed = json.load( fStream );

        for script in self.Scripts:

            if( "\"bts_rc/credits.json\"" in script.Content ):
                script.Content = script.Content.replace( "\"bts_rc/credits.json\"", "\"\"\"" + json.dumps( parsed, separators=( ",", ":" ) ) + "\"\"\"" );
                self.Log( "Shiped & compacted {} into {}", self.m_CreditsPath.relative_to( PyTest.GetWorkspace() ), script.Path );
                self.m_CreditsPath.unlink();
                self.m_CreditsSchemaPath.unlink();
                return True;

        return False;

EnvCreditsUpdate();
