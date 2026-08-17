# ===================================================================
# ===================================================================
# Purpose:
#   Run a dedicated server to generate schema and check for errors.
# ===================================================================
# ===================================================================

import os;
import sys;
import time;
import subprocess;

from Tests.PyBuilder import PyBuilder;

class DedicatedServer( PyBuilder ):

    m_DedicatedServer: str = os.path.join( os.path.dirname( PyBuilder.GetWorkspace() ), "svends.exe" );

    def ShouldBuild(self) -> bool:
        return ( self.Type == PyBuilder.BuildType.Local \
            # -TODO idk linux for any contributor?
            and os.path.exists( self.m_DedicatedServer ) );

    def Build(self) -> bool:

        if sys.platform == "win32":
            import ctypes;
            kernel32 = ctypes.windll.kernel32
            modo_consola = kernel32.GetStdHandle(-11)
            kernel32.SetConsoleMode(modo_consola, 0x0007 | 0x0004)

        process = subprocess.Popen(
            [
                "-console",
                "+maxplayers", "1",
                "+map", "_server_start",
                "+developer", "1"
            ],
            executable = self.m_DedicatedServer,
            cwd = os.path.dirname( self.Workspace ),
            stdout = subprocess.PIPE,
            stderr = subprocess.STDOUT,
            text = True,
            bufsize = 1
        );

        buffer: list[str] = [ "" for _ in range(5) ];
        print( "== Running Sven Co-op dedicated server ===" );

        errorMessages: list[str] = [];
        criticalMessages: list[str] = [];

        lastLoadingChar = "/";
        printed: int = 0;

        def checkCloseServer( finished: bool = False ) -> bool:

            nonlocal errorMessages, criticalMessages;

            sys.stdout.write( f"\033[1A" );
            sys.stdout.write( f"\033[K\n" );
            sys.stdout.write( f"\033[1A" );
            sys.stdout.flush(); # Clean up the above print

            for line in criticalMessages:
                self.Log( line );

            for line in errorMessages:
                self.Log( line );

            return ( len(errorMessages) + len(criticalMessages) == 0 and finished );

        mapLoaded = False;
        mapLoaded = True;

        while( True ):

            if printed > 0:
                sys.stdout.write( f"\033[{printed}A" );
                for i in range(printed):
                    sys.stdout.write( f"\033[K\n" );
                sys.stdout.write( f"\033[{printed}A" );
                sys.stdout.flush();

            lastLoadingChar = "\\" if lastLoadingChar == "/" else "/";

            line: str | None = process.stdout.readline();

            if not line:

                if process.poll() is not None:
                    process = None;
                    return checkCloseServer( False );

#                time.sleep( 0.01 );
                continue;

            line = line.replace( '\r', '' ).replace( '\n', '' ).strip()

            lineLower: str = line.lower();

            if mapLoaded is False:
                if "maps/bts_rc_test_chamber.cfg" in lineLower:
                    mapLoaded = True;
                else:
                    sys.stdout.write( f"\033[K{lastLoadingChar}\n" );
                    sys.stdout.flush();
                    printed = 1;
                    continue;

            buffer.pop(0)
            buffer[0] = lastLoadingChar;
            buffer.append( line );

            for bufferLine in buffer:
                sys.stdout.write( f"\033[K\033[36m{bufferLine[:110]}\033[0m\n" )

            sys.stdout.flush();

            printed = len( buffer );

            if line.startswith( "[Critical]" ):
                criticalMessages.append( line );

            if lineLower.startswith( "[Error]" ):
                errorMessages.append( line );

            if "started map \"bts_rc_test_chamber\"" in lineLower:

                process.terminate();

                try:
                    process.kill();
                    process.wait(2);
                except Exception:
                    pass;

                return checkCloseServer( True );

        return False;

DedicatedServer();
