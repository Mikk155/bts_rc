import os;
from pathlib import Path;

modelsDirectory = os.path.abspath( os.path.join( os.path.dirname(__file__), "..", ".." ) );

for root, dirs, files in os.walk(modelsDirectory):

    for file in files:

        file = Path( os.path.join( root, file ) );

        if not file.is_file():
            continue;

        fileString = os.path.relpath( str( file ), modelsDirectory );

        if fileString.startswith( "models" ) \
        or fileString.startswith( "sound" ) \
        or fileString.startswith( "sprites" ):

            if fileString != fileString.lower():
                print( f"Not lowercased file {fileString}" );

            if ' ' in file.name:
                print( f"got a empty space at {fileString}" );
