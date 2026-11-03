'''
### **Purpose:**

Compact env_credit's credits.json AngelScript into a compacted literal strings.
'''

import json;
from pathlib import Path;

from Tests.Base import *;

class EnvCreditsUpdate( IBuilder ):

    m_CreditsSchemaPath: Path = Path( Builder.Workspace(), "scripts", "maps", "bts_rc", "credits_schema.json" );
    m_CreditsPath: Path = Path( Builder.Workspace(), "scripts", "maps", "bts_rc", "credits.json" );

    def ShouldBuild( self ) -> bool:
        return ( Builder.Type() == BuildType.Release );

    def Build( self ) -> bool:

        parsed: dict;

        with open( self.m_CreditsPath, 'r' ) as fStream:
            parsed = json.load( fStream );

        for script in Builder.Scripts():

            if( "\"bts_rc/credits.json\"" in script.Content ):
                script.Content = script.Content.replace( "\"bts_rc/credits.json\"", "\"\"\"" + json.dumps( parsed, separators=( ",", ":" ) ) + "\"\"\"" );
                self.Log( "Shiped & compacted {} into {}", self.m_CreditsPath.relative_to( Builder.Workspace() ), script.Path );
                self.m_CreditsPath.unlink();
                self.m_CreditsSchemaPath.unlink();
                return True;

        return False;

EnvCreditsUpdate();
