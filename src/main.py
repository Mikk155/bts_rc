import sys;
from pathlib import Path;
import traceback;

gpBuilders: list['IBuilder'] = [];
gpWorkspace: Path = Path( __file__ ).absolute().parent.parent;

from Tests.Base import *;

# Release check first to not waste time on other builders on failure
import Tests.ReleaseCheck;
# Include Local builders here
import Tests.CleanWorkspace;
import Tests.UpdateContributors;
import Tests.UpdateTODOList;
import Tests.EnvCreditsCheck;

# Ordering matters here.
import Tests.UpdatePrecaches;
import Tests.UpdateLicenseHeaders;
import Tests.CheckIConfigurableGetSchema;
import Tests.UpdateSchema;
import Tests.CheckJSONValidation;
import Tests.EnvCreditsUpdate;
import Tests.ToggleDebug;
import Tests.CompactScriptJSON;

def Main() -> tuple[int, int, int]:

    passes = 0;
    skips = 0;
    fails = 0;

    buildType: BuildType = Builder.Type();

    if "--test" in sys.argv and buildType == BuildType.Release:
        print( "Various files may be overwriten now. Make sure you don't have unsaved changes!" );
        userInput = input( "Write 1 to continue.\n> " );
        if userInput != "1":
            print( "No action was made" );
            sys.exit(1);

    builders: list[IBuilder] = list( gpBuilders );
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
                if builder is releaseCheck and buildType == BuildType.Release:
                    break;
                continue;

            if builder.Build() is False:
                builder.Log( "Build failed." );
                fails += 1;
                if builder is releaseCheck and buildType == BuildType.Release:
                    break;
                continue;

            passes += 1;
            completed.add( builder.Name );
            builder.Log( "Build success." );

        except Exception:
            builder.Log( f"throw an exception:" );
            traceback.print_exc();
            fails += 1;

        if builder is releaseCheck and buildType == BuildType.Release and builder.Name not in completed:
            break;

    return ( fails, passes, skips );

if __name__ == "__main__":

    buildType: BuildType = Builder.Type();

    ( fails, passes, skips ) = Main();

    if fails == 0:

        for script in Builder.Scripts():

            content: str = None;
            with open( script.AbsolutePath, "r", encoding="utf-8" ) as fStream:
                content = fStream.read();

            script.Content = script.Content.replace( '\t', "    " );

            if script.Content != content:

                with open( script.AbsolutePath, "w", encoding="utf-8" ) as fStream:
                    fStream.write( script.Content );
                    Builder.Log( "Updated {}", script.Path );

        if Builder.Type() == BuildType.Release:

            from sys import executable;
            from json import dumps, load;
            from subprocess import run, PIPE, STDOUT, CompletedProcess;

            inlineFiles: str;

            with open( Path( Builder.Workspace(), ".github", "release_inline.json" ), 'r' ) as fStream:
                inlineFiles = dumps( load( fStream ), separators= ( ",", ":" ), indent=-1 );

            testResult: CompletedProcess = run(
                [
                    executable,
                    Path( Builder.Workspace(), "scripts", "mikk155", "tools", "main.py", ),
                    "-source", "scripts/maps/bts_rc/main.as",
                    "-inline", inlineFiles,
                ],
                cwd=Builder.Workspace(),
                check=False,
                stdout=PIPE,
                stderr=STDOUT,
                text=True,
            );

            for line in ( testResult.stdout or "" ).splitlines():
                Builder.Log( f"> {line}" );

            if testResult.returncode != 0:
                Builder.Log( "Submodule packaging failed with exit code {testResult.returncode}." );
                fails = testResult.returncode;

    total = passes + fails + skips;

    Builder.Log( "All done." );
    Builder.Log( "- Completed: {}", passes );
    Builder.Log( "- Skiped: {}", skips );
    Builder.Log( "- Total: {}", total );
    Builder.Log( "- Completion: {}%", int( ( ( passes + skips ) / total ) * 100 ) );
    Builder.Log( "- Failed: {}", fails );

    from os import environ;

    match buildType:

        case BuildType.Local:

            if sys.platform == "win32" and Builder.Type() == BuildType.Local and "PROMPT" not in environ and not "--githook" in sys.argv:
                input( "Press enter to continue." );

        case BuildType.Release:

            webhook: str | None = Builder.GetWebhook();

            if webhook is not None:

                messages: list[str] = [ m for m in ( *gpLogMessages, *gpLogFooterMessages ) if m ];

                if messages:

                    chunks: list[str] = [];
                    chunk: str = "";

                    for message in messages:
                        for line in message.splitlines() or [ " " ]:
                            if len(line) > 2000:
                                if chunk:
                                    chunks.append( chunk );
                                    chunk = "";
                                chunks.extend( line[ offset: offset + 2000 ] for offset in range( 0, len( line ), 2000 ) );
                                continue;

                            candidate = line if not chunk else f"{chunk}\n{line}";
                            if len(candidate) > 2000:
                                chunks.append( chunk );
                                chunk = line;
                            else:
                                chunk = candidate;

                    if chunk:
                        chunks.append( chunk );

                    import requests;

                    for content in chunks:
                        try:
                            response = requests.post(
                                webhook,
                                json={ "content": content },
                                timeout=15,
                            );
                        except requests.RequestException as error:
                            print( f"Webhook request failed: {error}" );
                            break;

                        if response.status_code < 200 or response.status_code >= 300:
                            print(
                                f"Webhook returned HTTP {response.status_code}: "
                                f"{response.text}"
                            );
                            break;

        case BuildType.Check:
            pass;
        case _:
            pass;

    sys.exit( fails );
