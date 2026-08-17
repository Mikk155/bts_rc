# ===================================================================
# ===================================================================
# Purpose:
#   Run a dedicated server to generate schema and check for errors.
# ===================================================================
# ===================================================================

import os;
import subprocess;
import time;

from Tests.PyBuilder import PyBuilder;

class DedicatedServer( PyBuilder ):

    m_DedicatedServer: str = os.path.join( os.path.dirname( PyBuilder.GetWorkspace() ), "svends.exe" );

    def ShouldBuild(self) -> bool:
        return ( self.Type == PyBuilder.BuildType.Local \
            # -TODO idk linux for any contributor?
            and os.path.exists( self.m_DedicatedServer ) );

    def Build(self) -> bool:

        gameLogPath: str = os.path.join( os.path.dirname( self.Workspace ), "svencoop", "scripts", "maps", "store", "bts_rc.log" );

        if os.path.exists( gameLogPath ):
                os.remove( gameLogPath )

        process = subprocess.Popen(
            [
                "-console",
                "+maxplayers", "1",
                "+map", "_server_start",
                "+developer", "1"
            ],
            executable = self.m_DedicatedServer,
            cwd = os.path.dirname( self.Workspace )
        );

        errorMessages: list[str] = [];
        criticalMessages: list[str] = [];

        while( True ):

            if process.poll() is not None:
                return False;

            if( not os.path.exists( gameLogPath ) ):
                time.sleep( 0.5 );
                continue;

            if( not self.FileModified( gameLogPath ) ):
                time.sleep( 0.5 );
                continue;

            with open( gameLogPath, "r", errors="ignore" ) as fStream:
                lines: list[str] = fStream.readlines();

                for line in lines:
                    lineLower = line.lower();

                    if lineLower.startswith( "[critical]" ):
                        criticalMessages.append( line );

                    if lineLower.startswith( "[error]" ):
                        errorMessages.append( line );

                process.terminate();

                try:
                    process.wait( timeout = 5 );
                except subprocess.TimeoutExpired:
                    process.kill();

                for line in criticalMessages:
                    self.Log( line );

                for line in errorMessages:
                    self.Log( line );

                break;

        return ( len(errorMessages) + len(criticalMessages) == 0 );

DedicatedServer();
