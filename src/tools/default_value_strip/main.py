import os
import json

read_map = open( os.path.join( os.path.dirname(__file__), "input.map" ), 'r' ).readlines();

keyvalues = json.load( open( os.path.join( os.path.dirname(__file__), "input.json" ), 'r' ) );

matched = 0;
matched_list = {}
skiped_lines = []
write_map: list = []

for line in read_map:

    add = True;

    for k, v in keyvalues.items():

        if line.startswith( '"{}" "{}"'.format( k, v ) ):

            add = False;
            matched_list[ k ] = matched_list.get( k, 0 ) + 1;
            matched += 1;
            skiped_lines.append(line)
            break;

    if add:

        write_map.append(line);

open( os.path.join( os.path.dirname(__file__), "output.map" ), 'w' ).writelines(write_map);

# This txt is just for storing all the skiped lines from the formating
open( os.path.join( os.path.dirname(__file__), "log_striped_lines.txt" ), 'w' ).writelines(skiped_lines);

for k, v in matched_list.items():
    value = keyvalues[k]
    print( f"Stripped {v} keyvalues \"{k}\" \"{value}\"" )

open( os.path.join( os.path.dirname(__file__), "log_striped_lines.json" ), 'w' ).write( json.dumps(matched_list, indent=4) );

print( "Stripped {} keyvalues in total".format( matched ) )
