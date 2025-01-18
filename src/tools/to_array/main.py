import os
import json

files: list[str] = json.load( open( "input.json", "r" ) )

new_files = []

for file in files:

    if not file in new_files:
        new_files.append( file )

new_files.sort()

open( "output.json", "w" ).write( json.dumps( new_files, indent= 4 ) )
