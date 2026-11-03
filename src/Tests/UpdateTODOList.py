'''
### **Purpose:**

Checks the ``TODO.md`` file and update as needed.

Completed labels will be moved to the completed section and the progression bar ill be updated.
'''

import os;
import colorsys;

from Tests.Base import *;

class UpdateTODOList( IBuilder ):

    m_TODOPath: str = os.path.join( Builder.Workspace(), "TODO.md" );
    m_TODOCompletion: float = None;
    m_TODOContent: str;

    def ShouldBuild( self ) -> bool:

        if Builder.Type() == BuildType.Release:
            return False;

        with open( self.m_TODOPath, "r" ) as fStream:
            self.m_TODOContent = fStream.read();

        incompleted: int = self.m_TODOContent.count( "- [ ]" );
        completed: int = self.m_TODOContent.count( "- [x]" );

        total: int = incompleted + completed;
        self.m_TODOCompletion: float = float( ( completed / total ) * 100 );

        if f"progress/{self.m_TODOCompletion}" in self.m_TODOContent:
            return False;

        return True;


    def Build( self ) -> bool:

        if Builder.Type() == BuildType.Check:
            self.Log( "TODO.md were modified but never commited checks!" );
            return False;

        hue: float = ( self.m_TODOCompletion / 100.0 ) * 120.0

        r, g, b = colorsys.hls_to_rgb( hue / 360.0, 0.45, 0.90 );
        hex = f"{int( r * 255 ):02x}{int( g * 255 ):02x}{int( b * 255 ):02x}";

        def InjectContent( keyword: str, add: str ) -> str:

            start: str = f"<!--{keyword}-start-->";
            end: str = f"<!--{keyword}-end-->";

            startPos: int = self.m_TODOContent.find( start );
            endPos: int = self.m_TODOContent.find( end );

            if startPos == -1:
                raise Exception( f"Could not found \"{start}\" in TODO.md" );

            if endPos == -1:
                raise Exception( f"Could not found \"{end}\" in TODO.md" );

            return self.m_TODOContent[ 0 : startPos + len(start) ] + "\n" + add + "\n" + self.m_TODOContent[ endPos : ];

        self.m_TODOContent = InjectContent( "CompletionBar", f"> ![](https://geps.dev/progress/{self.m_TODOCompletion}?barColor={hex})" );

        contentLines: list[str] = self.m_TODOContent.split( "\n" );
        completedMove: list[str] = [];

        lastCompleted: bool = False;

        for index, line in enumerate( contentLines.copy() ):

            if( line == "<!--CompletedGoals-start-->" ):
                for completedLine in completedMove:
                    index += 1;
                    contentLines.insert( index, completedLine );
                break;

            if( line.startswith( "- [x]" ) or ( lastCompleted and ( line.startswith( "    " ) or line.startswith( "\t" ) ) ) ):
                contentLines[index] = None;
                lastCompleted = True;
                completedMove.append( line );
            else:
                lastCompleted = False;

        # Not sure why it adds empty lines on the end of the file. lazy hack for now
        while( contentLines[ len(contentLines) - 1 ] == "" ):
            contentLines.pop( len(contentLines) - 1 );

        with open( self.m_TODOPath, "w" ) as fStream:
            fStream.writelines( [ f"{line}\n" for line in contentLines if line is not None ] );

        return False;

UpdateTODOList();
