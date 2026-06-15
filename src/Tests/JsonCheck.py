# ===================================================================
# ===================================================================
# Purpose:
#   Check deserialization of scripts/maps/bts_rc/config.json
# ===================================================================
# ===================================================================

from Tests.PyBuilder import PyBuilder;

class JsonCheck( PyBuilder ):

    def Build(self) -> bool:
        import os;
        import commentjson;
        configJson = os.path.join( self.Workspace, "scripts", "maps", "bts_rc", "config.json" );
        with open( configJson, "r", encoding="utf-8" ) as file:
            if commentjson.load( file ):
                self.Log( "Json config file propertly loads" );
                return True;
        return False;

JsonCheck();
