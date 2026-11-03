import os;
import sys;
import traceback;

gpBuilders: list['PyTest'] = [];
gpWorkspace: str = os.path.dirname( os.path.dirname( __file__ ) );

from Tests.PyTest import PyTest;

# Release check first to not waste time on other builders on failure
import Tests.ReleaseCheck;

# Include local builders here
import Tests.CleanWorkspace;
import Tests.UpdateContributors;
import Tests.UpdateTODOList;

# Include relevant check builders here. ordering matters.
import Tests.UpdatePrecaches;
import Tests.UpdateLicenseHeaders;
import Tests.CheckIConfigurableGetSchema;
# Mostly release builders.
import Tests.ToggleDebug;
import Tests.CompactScriptJSON;




#import Tests.DedicatedServer;
#import Tests.SchemaUpdateCheck;
#import Tests.DefaultConfigCheck;
#import Tests.DedicatedServerRelease;

def Main() -> tuple[int, int, int]:

    passes = 0;
    skips = 0;
    fails = 0;

    buildType: PyTest.BuildType = PyTest.GetType();
    builders: list[PyTest] = list( gpBuilders );
    completed: set[str] = set();
    releaseCheck = next(
        ( builder for builder in builders if isinstance( builder, Tests.ReleaseCheck.ReleaseCheck ) ),
        None
    );

    for index, builder in enumerate( builders ):

        try:

            if builder.ShouldBuild() is False:
                completed.add( builder.Name );
                skips += 1;
                continue;

            requirements: list[str] | None = builder.Require();

            if requirements is not None and len( requirements ) == 0:
                requirements = [ previous.Name for previous in builders[ : index ] ];

            missingRequirements: list[str] = [
                requirement for requirement in requirements
                if requirement not in completed
            ] if requirements is not None else [];

            if missingRequirements:
                builder.Log( "Build failed. Missing requirements: {}.", ", ".join( missingRequirements ) );
                fails += 1;
                if builder is releaseCheck and buildType == PyTest.BuildType.Release:
                    break;
                continue;

            if builder.Build() is False:
                builder.Log( "Build failed." );
                fails += 1;
                if builder is releaseCheck and buildType == PyTest.BuildType.Release:
                    break;
                continue;

            passes += 1;
            completed.add( builder.Name );
            builder.Log( "Build success." );

        except Exception:
            builder.Log( f"throw an exception:" );
            traceback.print_exc();
            fails += 1;

        if builder is releaseCheck and buildType == PyTest.BuildType.Release and builder.Name not in completed:
            break;

    return ( fails, passes, skips );

if __name__ == "__main__":

    buildType: PyTest.BuildType = PyTest.GetType();

    ( fails, passes, skips ) = Main();

    if fails == 0:
        PyTest.WriteAllScripts();

    total = passes + fails + skips;

    PyTest.Print( "All done." );
    PyTest.Print( "- Completed: {}", passes );
    PyTest.Print( "- Skiped: {}", skips );
    PyTest.Print( "- Failed: {}", fails );
    PyTest.Print( "- Total: {}", total );
    PyTest.Print( "- Completion: {}%", int( ( ( passes + skips ) / total ) * 100 ) );

    match buildType:

        case PyTest.BuildType.Local:
            PyTest.__SaveCache__();
        case PyTest.BuildType.Release:
            pass;
        case PyTest.BuildType.Check:
            PyTest.__SaveCache__();
            pass;
        case _:
            pass;

    if PyTest.GetType() == PyTest.BuildType.Release:
        PyTest.FlushLog();

    if sys.platform == "win32" and PyTest.GetType() == PyTest.BuildType.Local and "PROMPT" not in os.environ:
        input( "Press enter to continue." );

    sys.exit( fails );
