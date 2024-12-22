import os
import json

input_map: list[str] = open( os.path.join( os.path.dirname(__file__), "input.map" ), 'r' ).readlines();

skiped_lines: dict[int, str] = [];

in_entblock: bool = False;

entindex: int = 0

entity: dict[str,str] = {}

entities: dict[int,dict[str,str]] = {}

offset: int = 0

global index_offset;
index_offset: int = 0

def apply_key( line, value, old, new ) -> ( str | str ):

    match = False;

    if old in line:

        line = line.replace( old, new );
        value = new;
        match = True;

    return ( line if match else None, value );

def append_line( index: int, key: str, value: str ) -> int:

    entity[ key ] = value;

    input_map.insert( index, f"\"{key}\" \"{value}\"\n" );

    global index_offset;
    index_offset += 1;

    return index + 1;

for index, line in enumerate( input_map ):

    index += index_offset;

    if line.startswith( "}" ):

        if "$s_shuffle" in entity:

            entities[ entindex ] = {
                "start": offset,
                "entity": entity.copy(),
                "end": index,
            };

        entindex += 1;

        entity.clear()

        in_entblock = False;

    elif in_entblock:

        if line.startswith( "\"" ): # It's a entity and not a brush

            keyvalue = line[ 1: line.rfind( "\"" ) ].split( "\" \"" );

            if len(keyvalue) == 2:

                value = keyvalue[1];

                remap = {
                    "ActivateSurvival": "survival::activate",
                    "trigger_shuffle_position": "trigger_script",
                };

                for kr, vr in remap.items():

                    new_line, value = apply_key( line, value, kr, vr );

                    if new_line:

                        if kr == "trigger_shuffle_position":
                            index = append_line( index, "m_iszScriptFunctionName", "randomize::init" );
                            index = append_line( index, "spawnflags", "4" );

                        input_map[index] = new_line;

                        break;

                entity[ keyvalue[0] ] = keyvalue[1];

    elif line.startswith( "{" ):

        offset = index;

        in_entblock = True;

for index, item in reversed( list( entities.items() ) ):

    start: int = item[ "start" ];
    end: int = item[ "end" ];

    while end != start - 1:
    
        input_map.pop( end );

        end -= 1;

ent_file = []

for a, item in entities.items():
    ent_file.append( "{\n" );
    for k, v in item[ "entity" ].items():
        ent_file.append( f"\"{k}\" \"{v}\"\n" )
    ent_file.append( "}\n" );

open( os.path.join( os.path.dirname(__file__), "output.ent" ), 'w' ).writelines(ent_file);
open( os.path.join( os.path.dirname(__file__), "output.map" ), 'w' ).writelines(input_map);
open( os.path.join( os.path.dirname(__file__), "output.json" ), 'w' ).write( json.dumps( entities, indent=4) );
