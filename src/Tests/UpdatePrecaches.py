'''
### **Purpose:**

#### Release:
Converts all of ``scripts/maps/bts_rc/assets.json`` into ``scripts/maps/bts_rc/util/Precache.as``

#### Check | Local:
Sorts precache list & finds duplicated precaches around the AS source code.
'''

import re;
from pathlib import Path;
import json;

from Tests.Base import *;

class UpdatePrecaches( IBuilder ):

    m_PrecachesPath: Path = Path( Builder.Workspace(), "scripts", "maps", "bts_rc", "assets.json" );
    m_PrecachesSorted: dict[str,list[str]];
    m_SortedContent: str = None;
    m_Duplicates: int = 0;
    m_DuplicateLocations: list[tuple[object,int,int,str]] = [];

    def __init__( self ) -> None:
        super().__init__();
        self.m_Duplicates = 0;
        self.m_DuplicateLocations = [];

    def ShouldBuild( self ) -> bool:

        content: str;
        with open( self.m_PrecachesPath, "r" ) as fStream:
            content = fStream.read();
            self.m_PrecachesSorted = json.loads( content );

        self.m_PrecachesSorted[ "PrecacheModel" ].sort();
        self.m_PrecachesSorted[ "PrecacheSound" ].sort();
        self.m_PrecachesSorted[ "PrecacheGeneric" ].sort();

        match Builder.Type():
            case BuildType.Release:
                return True;
            case BuildType.Local | BuildType.Check:

                self.m_Duplicates = 0;
                self.m_DuplicateLocations = [];
                self.m_SortedContent = json.dumps( self.m_PrecachesSorted, indent=4 );
                if content == self.m_SortedContent:
                    self.m_SortedContent = None;

                def findDuplicatedPrecaches( pattern: str, listName: str ) -> None:

                    listRef: list[str] = self.m_PrecachesSorted[ listName ];

                    for script in Builder.Scripts():

                        fullPattern: str = r'^(?!\s*//).*?' + pattern;

                        assetMatches = re.finditer( fullPattern, script.Content, re.M );

                        for match in assetMatches:
                            asset: str = match.group( 1 );

                            if asset in listRef:
                                callStart: int = match.start() + match.group( 0 ).find( "g_" );
                                line: int = script.Content.count( "\n", 0, callStart ) + 1;
                                column: int = callStart - script.Content.rfind( "\n", 0, callStart );
                                self.m_DuplicateLocations.append( ( script, line, column, asset ) );
                                self.m_Duplicates += 1;

                findDuplicatedPrecaches(
                    r'g_Game\.PrecacheModel\s*\(\s*"([^"]+)"\s*\)',
                    "PrecacheModel"
                );
                findDuplicatedPrecaches(
                    r'g_Game\.PrecacheGeneric\s*\(\s*"([^"]+)"\s*\)',
                    "PrecacheGeneric"
                );
                findDuplicatedPrecaches(
                    r'g_SoundSystem\.PrecacheSound\s*\(\s*"([^"]+)"\s*\)',
                    "PrecacheSound"
                );

                return ( self.m_SortedContent is not None or self.m_Duplicates != 0 );

        return False;

    def Build( self ) -> bool:

        match Builder.Type():

            case BuildType.Release:

                for script in Builder.Scripts():

                    start: int = script.Content.find( "<Precache start>" );

                    if start >= 0:

                        end: int = script.Content.find( "<Precache end>", start );

                        if end <= -1:
                            self.Log( "Could not find \"<Precache end>\" comment in angelscript files." );
                            return False;

                        script.Content = \
                        script.Content[ 0 : script.Content.rfind( "//", 0, start ) ] +\
                        "".join( f"        g_Game.PrecacheModel( \"{asset}\" );\n" for asset in self.m_PrecachesSorted[ "PrecacheModel" ] ) +\
                        "".join( f"        g_Game.PrecacheGeneric( \"{asset}\" );\n" for asset in self.m_PrecachesSorted[ "PrecacheGeneric" ] ) +\
                        "".join( f"        g_SoundSystem.PrecacheSound( \"{asset}\" );\n" for asset in self.m_PrecachesSorted[ "PrecacheSound" ] ) +\
                        script.Content[ end + 16 : ];

                        self.m_PrecachesPath.unlink();

                        return True;

                self.Log( "Could not find \"<Precache start>\" comment in angelscript files." );
                return False;

            case BuildType.Local:

                if( self.m_SortedContent is not None ):

                    with open( self.m_PrecachesPath, "w" ) as fStream:
                        fStream.write( self.m_SortedContent );
                        self.Log( "Sorted {} alphabetically", self.m_PrecachesPath.relative_to( Builder.Workspace() ) )

            case BuildType.Check:
                self.Log( "scripts/maps/bts_rc/assets.json were modified but never commited checks!" );

        if( self.m_Duplicates != 0 ):

            self.Log( "Found {} duplicated precaches that are declared in {}", self.m_Duplicates, self.m_PrecachesPath.relative_to( Builder.Workspace() ) );

            for script, line, column, asset in self.m_DuplicateLocations:
                self.Log( "L{}:{}: {} duplicated precache {}", line, column, script.Path, asset );

        return False;

UpdatePrecaches();
