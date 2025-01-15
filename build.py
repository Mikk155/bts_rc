import os
import shutil
import zipfile

def copy_all( src_path, dest_path ) -> list[str]:

    src_path  = os.path.join( os.path.dirname( __file__ ), src_path );
    dest_path = os.path.join( os.path.dirname( __file__ ), dest_path );

    my_files: list[str] = [];

    for root, dirs, files in os.walk( src_path ):

        for file in files:

            src_file = os.path.join( root, file );

            src_rel = os.path.relpath( root, src_path );

            dest_folder = os.path.join( dest_path, src_rel );

            if not os.path.exists( dest_folder ):

                os.makedirs( dest_folder );

            dest_file = shutil.copy2( src_file, dest_folder );

            my_files.append( dest_file );

    return my_files;

def update_preprocessors( files: list[str] ) -> None:

    print( f"Updating preproccessors:" );

    for file in files:

        if os.path.exists( file ) and file.endswith( ".as" ):

            lines = open( file, 'r' ).read();

            if lines.find( "#if SERVER" ) != -1:

                print( file );

                lines = lines.replace( "#if SERVER", "#if DEVELOP" );

                open( file, 'w' ).write( lines );

def zip_folder( folder: str ) -> None:

    folder  = os.path.join( os.path.dirname( __file__ ), folder );

    print( f"Packing objects:" );

    with zipfile.ZipFile( f'{folder}.zip', 'w', zipfile.ZIP_DEFLATED) as zipf:

        for root, dirs, files in os.walk( folder ):

            for file in files:

                ruta_completa = os.path.join( root, file );

                ruta_relativa = os.path.relpath( ruta_completa, folder );

                print( ruta_relativa );

                zipf.write( ruta_completa, ruta_relativa );

        zipf.close();

copy_all( "scripts", "Debug\\scripts" );

releases = copy_all( "scripts", "Release\\scripts" );

update_preprocessors( releases );

zip_folder( "Release" );
zip_folder( "Debug" );
