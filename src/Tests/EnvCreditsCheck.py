'''
### **Purpose:**

Validate env_credit's credits.json with schema
'''

import json;
import jsonschema;

from Tests.Base import *;
from Tests.EnvCreditsUpdate import EnvCreditsUpdate;

class EnvCreditsCheck( EnvCreditsUpdate ):

    def ShouldBuild( self ) -> bool:
        return ( Builder.Type() != BuildType.Release );

    def Build( self ) -> bool:

        parsed: dict;

        try:
            with open( self.m_CreditsPath, "r" ) as fStream:
                parsed = json.load( fStream );
        except json.JSONDecodeError as e:
            self.Log( "{} > invalid JSON: {} at line {}:{}", self.m_CreditsPath.relative_to( Builder.Workspace() ), e.msg, e.lineno, e.colno );
            return False;

        try:
            with open( self.m_CreditsSchemaPath, "r" ) as fStream:
                jsonschema.validate( instance=parsed, schema=json.load( fStream ) );
        except jsonschema.ValidationError as e:
            self.Log( "invalid JSON: {} at {}\n{}", self.m_CreditsPath.relative_to( Builder.Workspace() ), e.json_path, e.message );
            return False;


        return True;

EnvCreditsCheck();
