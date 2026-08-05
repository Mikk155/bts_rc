# ===================================================================
# ===================================================================
# Purpose:
#   Iterates over the models folder to report event sounds not precached
# ===================================================================
# ===================================================================
import os;
import re;
import json;

gpWorkspace: str = os.path.dirname( os.path.dirname( os.path.dirname( __file__ ) ) );
gpPrecaches: list[str] = [];

def extract_mdl_sounds( modelPath ) -> list | None:

    sounds = []
    try:

        with open( modelPath, 'rb' ) as f:

            data: bytes = f.read();

            if data.startswith( b'IDST' ):

                pattern = rb'[a-zA-Z0-9_\-\/]+\.(?:wav|ogg)';
                matches = re.findall(pattern, data);

                for match in matches:
                    soundPath = match.decode( 'utf-8', errors='ignore' ).strip();
                    soundPath = soundPath.lstrip('*)(!');
                    if soundPath and soundPath not in sounds and soundPath not in gpPrecaches:

                        # Remove this check to note sven vanilla sounds as well
                        if os.path.exists( os.path.join( os.path.dirname( gpWorkspace ), "svencoop", "sound", soundPath ) ):
                            gpPrecaches.append( soundPath );
                            continue;

                        sounds.append( soundPath );

    except Exception as e:
        print( f"Error {modelPath}: {e}");
        return None;

    return sounds;

modelsDirectory = os.path.join( gpWorkspace, "models" );

gpResults: dict = {};

modelsDirectory: str = os.path.abspath( modelsDirectory );

for root, _, files in os.walk(modelsDirectory):
    for file in files:
        if file.lower().endswith( ".mdl" ):
            fullPathModel: str = os.path.join( root, file );
            sounds: None | list[str] = extract_mdl_sounds( fullPathModel );
            if sounds is not None and len( sounds ) > 0:
                relativePath: str = os.path.relpath( fullPathModel, gpWorkspace ).replace( "\\", "/" );
                gpResults[ relativePath ] = sounds;
                print( f"{relativePath} -> {len(sounds)} sounds." );

if len(gpResults) > 0:

    outputJsonPath: str = os.path.join( os.path.dirname( __file__ ), "model_sound_event.json" );

    with open( outputJsonPath, 'w', encoding='utf-8' ) as fStream:
        json.dump( gpResults, fStream, indent=4, ensure_ascii=False );
        print( f"Sounds written to \"{outputJsonPath}\"" );
