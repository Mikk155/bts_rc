# ===================================================================
# ===================================================================
# Purpose:
#   Check validation of user-generated schema for website usage.
# ===================================================================
# ===================================================================

import os;
import shutil;
from pathlib import Path;

from Tests.PyBuilder import PyBuilder;

class SchemaUpdateCheck( PyBuilder ):

    def Build(self) -> bool:

        if self.Type != PyBuilder.BuildType.Local:
            return True;

        path: Path = Path( self.Workspace );
        path = path.parent;
        path = path.joinpath( "svencoop", "scripts", "maps", "store", "bts_rc_schema.json" );

        if os.path.exists( path ):

            ShouldUpdate = False;

            oldSchemaPath = Path( os.path.join( self.Workspace, "docs", "schema.json" ) );
            if os.path.exists( oldSchemaPath ):
                with open( oldSchemaPath, "r", encoding="utf-8" ) as fOldSchema:
                    with open( path, "r", encoding="utf-8" ) as fNewSchema:
                        if fOldSchema.read() != fNewSchema.read():
                            ShouldUpdate = True;
            else:
                ShouldUpdate = True;

            if ShouldUpdate:

                shutil.copyfile( path, oldSchemaPath );
                self.Log( f"Updated documentation's schema. make sure to commit the change." );
                return False;

        return True;

SchemaUpdateCheck();
