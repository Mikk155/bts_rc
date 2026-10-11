import os;
import sys;

gpBuilders: list['PyTest'] = [];
gpWorkspace: str = os.path.dirname( os.path.dirname( __file__ ) );

from Tests.PyTest import PyTest;

# Include checks here
import Tests.TestChamberUpdate;
import Tests.TodolistCheck;
import Tests.PrecacheCheck;
import Tests.CreditsCheck;
import Tests.ReleaseCheck;
# import Tests.FGDCheck;
import Tests.LicenseCheck;
import Tests.DebugCheck;
import Tests.SchemaCheck;
import Tests.SerializedJsonCheck;
import Tests.DependancyCheck;
#import Tests.DedicatedServer;
import Tests.SchemaUpdateCheck;
import Tests.DefaultConfigCheck;
import Tests.Cleanup;
#import Tests.DedicatedServerRelease;

def Exit( code_error: int = 0 ):

    print( f"return core: {code_error}" );

    if sys.platform == "win32" and PyTest.GetType() == PyTest.BuildType.Local and "PROMPT" not in os.environ:
        input( "Press enter to continue." );

    sys.exit( code_error );

def Main() -> tuple[int, int]:

    passes = 0;
    fails = 0;

    builderCompletion: list[str] = [];

    for builder in gpBuilders:

        try:

            if builder.ShouldBuild() is False:
                builder.Log( "Build skipped." );
                builderCompletion.append( builder.Name );
                continue;

            ok: bool = True;

            requirements: list[str] = builder.Require();

            if requirements is not None:

                if len(requirements) == 0:
                    for b in gpBuilders:
                        if b.Name == builder.Name:
                            break;
                        requirements.append( b.Name );

                for require in requirements:
                    if not require in builderCompletion:
                        ok = False;

            if ok is True:
                ok = builder.Build();

            if ok is False:
                builder.Log( "Build failed." );
                fails += 1;
                continue;

            passes += 1;
            builderCompletion.append( builder.Name );
            builder.Log( "Build success." );

        except:
            import traceback;
            builder.Log( f"throw an exception:" );
            traceback.print_exc();
            fails += 1;

    return ( fails, passes );

if __name__ == "__main__":

    buildType: PyTest.BuildType = PyTest.GetType();

    match buildType:

        case PyTest.BuildType.Release:
            print( f"Formating map scripts for bts_rc as version {PyTest.GetTag()}" );

        case _:
            pass;

    ( fails, passes ) = Main();

    if fails == 0:
        PyTest.WriteAllScripts();
        print( f"{passes} checks passed." );
    else:
        print( f"{fails} of {fails + passes} checks failed." );
        Exit(1);

    match buildType:

        case PyTest.BuildType.Local:
            PyTest.__SaveCache__();
#            input( "Press enter to continue" );

        case PyTest.BuildType.Release:
            print( "Downloading map assets..." );

        case PyTest.BuildType.Check:
            pass;
        case _:
            pass;

    print( "All done!" );
    Exit(0);
