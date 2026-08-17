import os;
import sys;

gpBuilders: list['PyBuilder'] = [];
gpWorkspace: str = os.path.dirname( os.path.dirname( __file__ ) );

from Tests.PyBuilder import PyBuilder;

# Include checks here
import Tests.TodolistCheck;
import Tests.PrecacheCheck;
import Tests.CreditsCheck;
import Tests.ReleaseCheck;
import Tests.FGDCheck;
import Tests.LicenseCheck;
import Tests.DebugCheck;
import Tests.SchemaCheck;
import Tests.SerializedJsonCheck;
import Tests.DependancyCheck;
import Tests.DedicatedServer;
import Tests.SchemaUpdateCheck;
import Tests.DefaultConfigCheck;

def Exit( code_error: int = 0 ):

    print( f"return core: {code_error}" );

    if sys.platform == "win32" and PyBuilder.GetType() == PyBuilder.BuildType.Local and "PROMPT" not in os.environ:
        input( "Press enter to continue." );

    sys.exit( code_error );

def Main() -> tuple[int, int]:

    passes = 0;
    fails = 0;

    for builder in gpBuilders:

        try:

            if builder.ShouldBuild() is True:

                ok: bool = builder.Build();

                if ok is False:
                    builder.Log( "Build failed." );
                    fails += 1;
                    continue;

            passes += 1;
            builder.Log( "Build success." );

        except:
            import traceback;
            builder.Log( f"throw an exception:" );
            traceback.print_exc();
            fails += 1;

    return ( fails, passes );

if __name__ == "__main__":

    buildType: PyBuilder.BuildType = PyBuilder.GetType();

    match buildType:

        case PyBuilder.BuildType.Release:
            print( f"Formating map scripts for bts_rc as version {PyBuilder.GetTag()}" );

        case _:
            pass;

    ( fails, passes ) = Main();

    if fails == 0:
        PyBuilder.WriteAllScripts();
        print( f"{passes} checks passed." );
    else:
        print( f"{fails} of {fails + passes} checks failed." );
        Exit(1);

    match buildType:

        case PyBuilder.BuildType.Local:
            PyBuilder.__SaveCache__();
#            input( "Press enter to continue" );

        case PyBuilder.BuildType.Release:
            print( "Downloading map assets..." );

        case PyBuilder.BuildType.Check:
            pass;
        case _:
            pass;

    print( "All done!" );
    Exit(0);
