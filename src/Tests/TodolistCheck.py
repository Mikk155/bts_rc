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
        # -TODO Move completed-marked things on the bottom of the file
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

            return content[ 0 : startPos + len(start) ] + "\n" + add + content[ endPos - 2 : ];

        content = InjectContent( "CompletionBar", f"## Completion: ![](https://geps.dev/progress/{percent}?barColor={hex})", content );

        with open( self.m_TODOPath, "w" ) as fStream:
            fStream.write( content );

        return True;

TodolistCheck();
