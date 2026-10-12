import os;
from pathlib import Path;
import subprocess;

modelsDirectory = os.path.abspath( os.path.join( os.path.dirname(__file__), "..", "..", "models" ) );

for root, dirs, files in os.walk(modelsDirectory):

    modelFiles: list[Path] = [ Path( os.path.join( root, f ) ) for f in files if f.lower().endswith( ".mdl" ) ];

    for file in files:

        fileString = str( file );

        if not fileString.lower().endswith( "t.mdl" ):
            continue;

        find = fileString.rfind( "t.mdl" ) if "t.mdl" in fileString else fileString.rfind( "T.mdl" );
        modelNameSource: str = fileString[ 0 : find ] + ".mdl";

        if not os.path.exists( modelNameSource ):
            continue;

        print( f"Merging texture model of \"{os.path.relpath( modelNameSource, modelsDirectory)}\"" );

        command: list[str] = [ "modelguy.exe", "merge", modelNameSource ]

        try:
            subprocess.run( command, check=True, cwd=os.path.dirname(modelNameSource), text=True, capture_output=True );
        except subprocess.CalledProcessError as e:
            message = e.stdout + e.stderr;
            print( f"[ERROR] modelguy.exe {message}" );
            if "Model has no external textures or sequences!" in message:
                os.remove( str(file) );
                print( "Deleting...")
        except FileNotFoundError:
            print( f"[Error] modelguy.exe not found at \"{os.path.dirname(__file__)}\"" );
            exit(0);
