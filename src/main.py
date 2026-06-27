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
import Tests.ReleaseCheck;
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
                builder.Log( "Build failed." );
                result += 1;
            else:
                builder.Log( "Build success." );

        except Exception as e:
            builder.Log( f"throw an exception: {e}" )
            result += 1;

    return result;

if __name__ == "__main__":

    match PyBuilder.GetType():

        case PyBuilder.BuildType.Release:
            print( f"Formating map scripts for bts_rc as version {PyBuilder.GetTag()}" );

        case _:
            pass;

    result: int = Main();

    if result == 0:
        PyBuilder.WriteAllScripts();
        print( f"All done!" );
    else:
        print( f"{result} checks failed." );

    match PyBuilder.GetType():

        case PyBuilder.BuildType.Local:
            input( "Press enter to continue" );

        case PyBuilder.BuildType.Release:
            print( "Downloading map assets..." );

        case PyBuilder.BuildType.Check:
            pass;
        case _:
            pass;

    sys.exit( result );
