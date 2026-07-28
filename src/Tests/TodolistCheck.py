# ===================================================================
# ===================================================================
# Purpose:
#   Checks the credit file and update as needed
# ===================================================================
# ===================================================================

import os;
import colorsys;

from Tests.PyBuilder import PyBuilder;

class TodolistCheck( PyBuilder ):

    m_TODOPath: str = os.path.join( PyBuilder.GetWorkspace(), "TODO.md" );

    def ShouldBuild(self) -> bool:
        return ( self.Type == PyBuilder.BuildType.Local and self.FileModified( self.m_TODOPath ) );

    def Build(self) -> bool:

        content: str;

        with open( self.m_TODOPath, "r" ) as fStream:
            content = fStream.read();

        incompleted: int = content.count( "- [ ]" );
        completed: int = content.count( "- [x]" );

        total: int = incompleted + completed;
        percent: float = float( ( completed / total ) * 100 );

        hue: float = ( percent / 100.0 ) * 120.0

        r, g, b = colorsys.hls_to_rgb( hue / 360.0, 0.45, 0.90 );
        hex = f"{int( r * 255 ):02x}{int( g * 255 ):02x}{int( b * 255 ):02x}";

        def InjectContent( keyword: str, add: str, content: str ) -> str:

            start: str = f"<!--{keyword}-start-->";
            end: str = f"<!--{keyword}-end-->";

            startPos: int = content.find( start );
            endPos: int = content.find( end );

            if startPos == -1:
                raise Exception( f"Could not found \"{start}\" in TODO.md" );

            if endPos == -1:
                raise Exception( f"Could not found \"{end}\" in TODO.md" );

            return content[ 0 : startPos + len(start) ] + "\n" + add + "\n" + content[ endPos : ];

        content = InjectContent( "CompletionBar", f"> ![](https://geps.dev/progress/{percent}?barColor={hex})", content );

        contentLines: list[str] = content.split( "\n" );
        completedMove: list[str] = [];

        lastCompleted: bool = False;

        for index, line in enumerate( contentLines.copy() ):

            if( line == "<!--CompletedGoals-start-->" ):
                for completedLine in completedMove:
                    index += 1;
                    contentLines.insert( index, completedLine );
                break;

            if( line.startswith( "- [x]" ) or ( lastCompleted and line.startswith( "    > " ) ) ):
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

        return True;

TodolistCheck();
