# ===================================================================
# ===================================================================
# Purpose:
#   Check validation of user-generated schema for website usage.
# ===================================================================
# ===================================================================
'''
### **Purpose:**
Update main JSON schema
'''

import json;
import os;
import shutil;
from pathlib import Path;

from Tests.Base import *;

class UpdateSchema( IBuilder ):

    m_SchemaPath: Path = Path( Builder.Workspace() ).parent.joinpath( "svencoop", "scripts", "maps", "store", "bts_rc_schema.json" );
    m_OldSchemaPath: Path = Path( Builder.Workspace(), "docs", "schema.json" );

    def ShouldBuild( self ) -> bool:

        if Builder.Type() != BuildType.Local:
            return False;

        if not self.m_SchemaPath.exists():
            return False;

        if self.m_OldSchemaPath.exists():
            with open( self.m_OldSchemaPath, "r", encoding="utf-8" ) as fOldSchema:
                with open( self.m_SchemaPath, "r", encoding="utf-8" ) as fNewSchema:
                    if json.load( fOldSchema ) == json.load( fNewSchema ):
                        return False;
        return True;

    def Build( self ) -> bool:

        with open( self.m_OldSchemaPath, "w", encoding="utf-8" ) as fOldSchema:
            with open( self.m_SchemaPath, "r", encoding="utf-8" ) as fNewSchema:
                json.dump( json.load( fNewSchema ), fp=fOldSchema, indent=0 );
                self.Log( "Updated {}", self.m_OldSchemaPath.relative_to( Builder.Workspace() ) );
                return True;

        return False;

UpdateSchema();
