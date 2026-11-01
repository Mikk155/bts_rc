# ===================================================================
# ===================================================================
# Purpose:
#   Python validation class builder.
# ===================================================================
# ===================================================================

from enum import IntEnum, auto;

global gpCache;
gpCache: dict = None;
global gpAngelScriptFiles;
gpAngelScriptFiles: list['PyTest.AScript'] = None;
global gpLogMessages;
gpLogMessages: list[str] = [];
global gpLogFooterMessages;
gpLogFooterMessages: list[str] = [];
global gpLogWebhook;
gpLogWebhook: str | None = None;

class PyTest:
    """Inherit from PyTest and instantiate your class then Build will be called"""

    m_Author = "Mikk155";
    m_Repository = "bts_rc";

    class BuildType( IntEnum ):
        Local = auto();
        '''Local build for whatever reason'''
        Release = auto();
        '''Github release. self.Tag is valid'''
        Check = auto();
        '''Github check'''

    def Require(self) -> list[str]:
        '''
            Return a list of module names required to run this test.
            If any of the modules in this list hasn't been a suscess this module's test will fail without calling Build.
            Return a empty list to represent "All" modules dependant.
        '''
        return None;

    @staticmethod
    def GetTag() -> str | None:
        '''If the Type is Release. this is the tag name that triggered the script in Github otherwise None'''
        import sys;
        if "-release" in sys.argv and len(sys.argv) > sys.argv.index( "-release" ):
            return sys.argv[ sys.argv.index( "-release" ) + 1 ];
        return None;

    @staticmethod
    def GetCache() -> dict:
        '''Get a cache file'''
        import os;
        import json;
        cachePath: str = os.path.join( PyTest.GetWorkspace(), "src", "Tests", "cache.json" );

        global gpCache;
        if gpCache is not None:
            return gpCache;

        try:
            with open( cachePath, "r" ) as fStream:
                gpCache = json.loads( fStream.read() );
        except:
            gpCache = {};

        return gpCache;

    @staticmethod
    def __SaveCache__() -> dict:
        import os;
        import json;
        with open( os.path.join( PyTest.GetWorkspace(), "src", "Tests", "cache.json" ), "w" ) as fStream:
            content = json.dumps( PyTest.GetCache(), indent = 4 );
            fStream.write( content );

    @property
    def Tag(self) -> str | None:
        '''If the Type is Release. this is the tag name that triggered the script in Github otherwise None'''
        return PyTest.GetTag();

    @staticmethod
    def GetType() -> BuildType:
        '''Return the build type'''
        import sys;
        if "-release" in sys.argv:
            return PyTest.BuildType.Release;
        if "--check" in sys.argv:
            return PyTest.BuildType.Check;
        return PyTest.BuildType.Local;

    @staticmethod
    def GetWebhook() -> str | None:
        '''Return the Discord webhook URL, if configured'''
        global gpLogWebhook;

        if gpLogWebhook is None:

            import sys;
            if "-webhook" in sys.argv:

                webhookIndex: int = sys.argv.index( "-webhook" );

                if webhookIndex + 1 >= len( sys.argv ) or not sys.argv[ webhookIndex + 1 ]:
                    raise ValueError( "-webhook requires a valid URL." );

                gpLogWebhook = sys.argv[ webhookIndex + 1 ];

        return gpLogWebhook;

    @property
    def Type(self) -> BuildType:
        '''Return the build type'''
        return PyTest.GetType();

    @staticmethod
    def GetWorkspace() -> str:
        """Return the absolute path to the current workspace repository"""
        from __main__ import gpWorkspace;
        return gpWorkspace;

    @property
    def Workspace(self) -> str:
        """Return the absolute path to the current workspace repository"""
        return PyTest.GetWorkspace();

    def __init__(self) -> None:
        from __main__ import gpBuilders;
        gpBuilders.append(self);

    def Build( self ) -> bool:
        raise Exception( f"Instance {self.Name} doesn't overrides the Build method!" );

    def ShouldBuild( self ) -> bool:
        return True;

    def FileModified( self, path: str ) -> bool:
        '''Return whatever the given file has been modified'''

        cache = PyTest.GetCache();
        files: dict = cache.get( "modified", {} )

        from datetime import datetime, timedelta;
        from pathlib import Path;

        dateTime: datetime;

        path: Path = Path( path );

        dateTimeModified: datetime = datetime.fromtimestamp( path.stat().st_mtime ).replace( microsecond = 0 );

        import os;
        pathRelative: str = path.relative_to( os.path.dirname( self.Workspace ) ).as_posix();

        if not pathRelative in files:
            dateTime = dateTimeModified - timedelta( 1 );
        else:
            dateTime = datetime.strptime( files[ pathRelative ], "%Y-%m-%d %H:%M:%S" );

        if dateTime < dateTimeModified:
            files[ pathRelative ] = dateTimeModified.strftime( "%Y-%m-%d %H:%M:%S" );
            cache[ "modified" ] = files;
            return True;

        return False;

    @property
    def Name( self ) -> str:
        """Get the name of your class module"""
        return self.__module__.removeprefix( "Tests." );

    @staticmethod
    def Print( message: str, *args ) -> None:
        """Print a message to console using *args"""
        message = message.format( *args );

        if PyTest.GetWebhook() is not None:
            gpLogMessages.append( message );

        print( message );

    def Log( self, message: str, *args ) -> None:
        """Print a message to console prefixed with your class moule name using *args"""
        message = message.format( *args );
        PyTest.Print( f"[{self.Name}] {message}" );

        if PyTest.GetWebhook() is not None:
            gpLogMessages[-1] = f"> [**{self.Name}**] ``{message}``";

    @staticmethod
    def AddWebhookFooter( message: str ) -> None:
        """Append a final Markdown message to the configured Discord webhook"""
        if PyTest.GetWebhook() is not None:
            gpLogFooterMessages.append( message );

    @staticmethod
    def FlushLog() -> None:
        '''Send buffered log messages to the configured Discord webhook'''
        import requests;

        webhook = PyTest.GetWebhook();
        if webhook is None:
            return;

        messages = [
            message
            for message in ( *gpLogMessages, *gpLogFooterMessages )
            if message
        ];
        if not messages:
            return;

        chunks: list[str] = [];
        chunk: str = "";
        for message in messages:
            for line in message.splitlines() or [ " " ]:
                if len(line) > 2000:
                    if chunk:
                        chunks.append( chunk );
                        chunk = "";
                    chunks.extend( line[ offset: offset + 2000 ] for offset in range( 0, len( line ), 2000 ) );
                    continue;

                candidate = line if not chunk else f"{chunk}\n{line}";
                if len(candidate) > 2000:
                    chunks.append( chunk );
                    chunk = line;
                else:
                    chunk = candidate;

        if chunk:
            chunks.append( chunk );

        for content in chunks:
            try:
                response = requests.post(
                    webhook,
                    json={ "content": content },
                    timeout=15,
                );
            except requests.RequestException as error:
                print( f"Webhook request failed: {error}" );
                break;

            if response.status_code < 200 or response.status_code >= 300:
                print(
                    f"Webhook returned HTTP {response.status_code}: "
                    f"{response.text}"
                );
                break;

    class AScript:
        '''Represents an angel script file in the project. Content is rewrited to the file when the script finish running'''
        Name: str;
        '''File name with no extension'''
        Content: str;
        '''File content'''
        AbsolutePath: str;
        '''File absolute path'''
        Path: str;
        '''File relative path'''

    @staticmethod
    def GetScripts() -> list[AScript]:
        '''Return a list containing all the angel script files on this project'''

        global gpAngelScriptFiles;
        if gpAngelScriptFiles is not None:
            return gpAngelScriptFiles;

        gpAngelScriptFiles = [];

        import os;
        import pathlib;

        workspace = PyTest.GetWorkspace();

        for path in pathlib.Path( os.path.join( workspace, "scripts", "maps", "bts_rc" ) ).rglob( "*.as" ):

            if path.is_file():

                ascript = PyTest.AScript();
                ascript.AbsolutePath = path.absolute();
                ascript.Name = path.name[ : len( path.name ) - 3 ];
                ascript.Path = path.relative_to( workspace );

                with open( path, "r", encoding="utf-8" ) as fStream:
                    ascript.Content = fStream.read();
                    fStream.close();

                gpAngelScriptFiles.append(ascript);

        return gpAngelScriptFiles;

    @property
    def Scripts(self) -> list[AScript]:
        '''Return a list containing all the angel script files on this project'''
        return PyTest.GetScripts();

    @staticmethod
    def WriteAllScripts() -> int:

        import sys;
        if "--test" in sys.argv:
            print( "Various files may be overwriten now. Make sure you don't have unsaved changes!" );
            while True:
                userInput = input( "Write 1 to continue. 0 to avoid writing." );
                if userInput == "1":
                    break;
                elif userInput == "0":
                    print( "No files were writen." );
                    return;

        for script in PyTest.GetScripts():

            content: str = None;
            with open( script.AbsolutePath, "r", encoding="utf-8" ) as fStream:
                content = fStream.read();
                fStream.close();

            script.Content = script.Content.replace( '\t', "    " );

            if script.Content != content:

                with open( script.AbsolutePath, "w", encoding="utf-8" ) as fStream:
                    fStream.write( script.Content );
                    print( f"Updated {script.Path}" );
                    fStream.close();

        if PyTest.GetType() == PyTest.BuildType.Release:

            import os;
            import subprocess;

            toolPath: str = os.path.join(
                PyTest.GetWorkspace(),
                "scripts",
                "mikk155",
                "tools",
                "main.py",
            );
            testResult: subprocess.CompletedProcess = subprocess.run(
                [
                    sys.executable,
                    toolPath,
                    "-source",
                    "scripts/maps/bts_rc/main.as",
                    "-inline",
                    '["Server/chrono/v1","TextMenu/v1","Player/ChatColor","Player/GetUniqueID","Player/GiveItem","Entity/Create","String/Vector","String/bool"]',
                ],
                cwd=PyTest.GetWorkspace(),
                check=False,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            );

            for line in ( testResult.stdout or "" ).splitlines():
                PyTest.Print( line );

            if testResult.returncode != 0:
                raise RuntimeError(
                    f"Submodule packaging failed with exit code {testResult.returncode}."
                );
