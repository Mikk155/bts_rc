import os;
import sys;

gpBuilders: list['PyBuilder'] = [];
gpWorkspace: str = os.path.dirname( os.path.dirname( __file__ ) );

from Tests.PyBuilder import PyBuilder;

# Include checks here
import Tests.CreditsCheck;
import Tests.ReleaseCheck;
import Tests.FGDCheck;
import Tests.LicenseCheck;
import Tests.DebugCheck;
import Tests.SchemaCheck;
import Tests.DependancyCheck;
import Tests.SerializedJsonCheck;
import Tests.SchemaUpdateCheck;
import Tests.WeaponsDefaultCheck;

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
            builder.Log( f"throw an exception: {e}" );
            result += 1;

    return result;

if __name__ == "__main__":

    match PyBuilder.GetType():

        case PyBuilder.BuildType.Release:
            print( f"Formating map scripts for bts_rc as version {PyBuilder.GetTag()}" );

        case PyBuilder.BuildType.Local:
            print( f"Creating Precache() method with list \"src/precaches.json\"" );

            precacheScript = os.path.join( gpWorkspace, "scripts", "maps", "bts_rc", "util", "Precache.as" );
            precacheJson = os.path.join( gpWorkspace, "src", "precaches.json" );

            oldContent = "";

            with open( precacheScript, "r" ) as fStream:
                oldContent = fStream.read();

            assets: dict[list[str]] = None;

            import json;
            try:
                with open( precacheJson, "r" ) as fStream:
                    assets = json.load( fStream );
            except Exception as e:
                input( f"Error: {e}" );
                sys.exit(1);

            PrecacheModel: list[str] = assets[ "PrecacheModel" ];
            PrecacheSound: list[str] = assets[ "PrecacheSound" ];
            PrecacheGeneric: list[str] = assets[ "PrecacheGeneric" ];
            PrecacheModel.sort();
            PrecacheSound.sort();
            PrecacheGeneric.sort();

            buffer = "// DO NOT MODIFY THIS FILE!\n// See: src/precaches.json and generate this file using src/main.py.\nvoid Precache()\n{\n"
            buffer += "".join( f"    g_Game.PrecacheModel( \"{asset}\" );\n" for asset in PrecacheModel );
            buffer += "".join( f"    g_Game.PrecacheGeneric( \"{asset}\" );\n" for asset in PrecacheGeneric );
            buffer += "".join( f"    g_SoundSystem.PrecacheSound( \"{asset}\" );\n" for asset in PrecacheSound );
            buffer += "}\n";

            if not buffer in oldContent: # not equal. has license header.
                with open( precacheScript, "w" ) as fStream:
                    fStream.write( buffer );
                with open( precacheJson, "w" ) as fStream:
                    fStream.write( json.dumps( assets, indent=4 ) ); # Sorted now

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
