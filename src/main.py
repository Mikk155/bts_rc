# ===================================================================
# ===================================================================
# Purpose:
#   Generates documentation from the json schema validator
#   Automatically add license headers to new files
# ===================================================================
# ===================================================================

import os;
import sys;

gpBuilders: list['PyBuilder'] = [];
gpWorkspace: str = os.path.dirname( os.path.dirname( __file__ ) );

from Tests.PyBuilder import PyBuilder;

# Include checks here
import Tests.FGDCheck;
import Tests.LicenseCheck;
import Tests.DebugCheck;
import Tests.SchemaCheck;
import Tests.DependancyCheck;
import Tests.SerializedJsonCheck;
import Tests.SchemaUpdateCheck;

def Main() -> int:

    result = 0;

    for builder in gpBuilders:

        try:

            ok = builder.Build();

            if ok is False:
                print( f"{builder.Name}: Failed build." );
                result += 1;

        except Exception as e:
            builder.Log( f"throw an exception: {e}" )
            result += 1;

    if result != 0:
        print( f"{result} checks failed" );

    return result;

if __name__ == "__main__":

    result: int = Main();

    if result == 0:
        PyBuilder.WriteAllScripts();

    if PyBuilder.GetType() == PyBuilder.BuildType.Local:
        input( "Press enter to continue" );

    sys.exit( result );
