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
            builder.Log( f"throw an exception: {e}" );
            result += 1;

    return result;

if __name__ == "__main__":

    match PyBuilder.GetType():

        case PyBuilder.BuildType.Release:
            print( f"Formating map scripts for bts_rc as version {PyBuilder.GetTag()}" );

        case PyBuilder.BuildType.Local:
            print( f"Creating Precache() method with list \"src/precaches.json\"" );

            with open( os.path.join( gpWorkspace, "scripts", "maps", "bts_rc", "util", "Precache.as" ), "w" ) as fPrecaches:

                assets: dict[list[str]] = None;

                import json;
                try:
                    assets = json.load( open( os.path.join( gpWorkspace, "src", "precaches.json" ) ) );
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
                fPrecaches.write( buffer );

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
