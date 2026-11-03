'''
Builders base
'''

from pathlib import Path;

global gpAngelScriptFiles;
gpAngelScriptFiles: list['AngelScriptSource'] = None;
global gpLogMessages;
gpLogMessages: list[str] = [];
global gpLogFooterMessages;
gpLogFooterMessages: list[str] = [];
global gpLogWebhook;
gpLogWebhook: str | None = None;

from enum import IntEnum, auto;
class BuildType( IntEnum ):
    '''Type of build'''
    Local = auto();
    '''Local build'''
    Release = auto();
    '''Github release.'''
    Check = auto();
    '''Github pull request check'''

class AngelScriptSource:
    '''Represents an angel script file in the project. Content is rewrited to the file when the script finish running'''
    Name: str;
    '''File name with no extension'''
    Content: str;
    '''File content'''
    AbsolutePath: Path;
    '''File absolute path'''
    Path: Path;
    '''File relative path'''

class Builder:

    @staticmethod
    def GetGithubUsername() -> str:
        return "Mikk155";

    @staticmethod
    def GetGithubRepository() -> str:
        return "bts_rc";

    @staticmethod
    def Type() -> BuildType:
        '''Return the build type'''
        from sys import argv;
        if "--release" in argv:
            return BuildType.Release;
        if "--check" in argv:
            return BuildType.Check;
        return BuildType.Local;

    @staticmethod
    def GetWebhook() -> str | None:
        '''Return the Discord webhook URL, if configured'''
        global gpLogWebhook;

        if gpLogWebhook is None:

            from sys import argv;
            if "-webhook" in argv:

                webhookIndex: int = argv.index( "-webhook" );

                if webhookIndex + 1 >= len( argv ) or not argv[ webhookIndex + 1 ]:
                    raise ValueError( "-webhook requires a valid URL." );

                gpLogWebhook = argv[ webhookIndex + 1 ];

        return gpLogWebhook;

    @staticmethod
    def Workspace() -> Path:
        """Return the absolute Path to the repository workspace"""
        from __main__ import gpWorkspace;
        return gpWorkspace;

    @staticmethod
    def Log( message: str, *args ) -> None:
        """Print a message to console using *args"""
        message = message.format( *args );

        if Builder.GetWebhook() is not None:
            gpLogMessages.append( message );

        print( message );

    @staticmethod
    def Scripts() -> list[AngelScriptSource]:
        '''Return a list containing all the angel script files on this project'''

        global gpAngelScriptFiles;
        if gpAngelScriptFiles is not None:
            return gpAngelScriptFiles;

        gpAngelScriptFiles = [];

        workspace: Path = Builder.Workspace();

        for path in Path(workspace, "scripts", "maps", "bts_rc" ).rglob( "*.as" ):

            if path.is_file():

                ascript = AngelScriptSource();
                ascript.AbsolutePath = path.absolute();
                ascript.Name = path.name[ : len( path.name ) - 3 ];
                ascript.Path = path.relative_to( workspace );

                with open( path, "r", encoding="utf-8" ) as fStream:
                    ascript.Content = fStream.read();

                gpAngelScriptFiles.append(ascript);

        return gpAngelScriptFiles;

class IBuilder:
    """Inherit from IBuilder and instantiate your class then Build will be called"""

    def Require( self ) -> list[str]:
        '''
            Return a list of module names required to run this test.
            If any of the modules in this list hasn't been a suscess this module's test will fail without calling Build.
            Return a empty list to represent "All" modules dependant.
        '''
        return None;

    def __init__( self ) -> None:
        from __main__ import gpBuilders;
        gpBuilders.append( self );

    def Build( self ) -> bool:
        raise Exception( f"Instance {self.Name} doesn't overrides the Build method!" );

    def ShouldBuild( self ) -> bool:
        return True;

    @property
    def Name( self ) -> str:
        """Get the name of your class module"""
        return self.__module__.removeprefix( "Tests." );

    def Log( self, message: str, *args ) -> None:
        """Print a message to console prefixed with your class moule name using *args"""
        message = message.format( *args );
        Builder.Log( f"[{self.Name}] {message}" );
        if Builder.GetWebhook() is not None:
            gpLogMessages[-1] = f"> [**{self.Name}**] ``{message}``";
