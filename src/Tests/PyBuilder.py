# ===================================================================
# ===================================================================
# Purpose:
#   Python validation class builder.
# ===================================================================
# ===================================================================

from enum import IntEnum, auto;

global gpAngelScriptFiles;
gpAngelScriptFiles: list['PyBuilder.AScript'] = None;

class PyBuilder:
    """Inherit from PyBuilder and instantiate your class then Build will be called"""

    m_Author = "Mikk155";
    m_Repository = "bts_rc";

    class BuildType( IntEnum ):
        Local = auto();
        '''Local build for whatever reason'''
        Release = auto();
        '''Github release. self.Tag is valid'''
        Check = auto();
        '''Github check'''

    @staticmethod
    def GetTag() -> str | None:
        '''If the Type is Release. this is the tag name that triggered the script in Github otherwise None'''
        import sys;
        if "+release" in sys.argv and len(sys.argv) > sys.argv.index( "+release" ):
            return sys.argv[ sys.argv.index( "+release" ) + 1 ];
        return None;

    @property
    def Tag(self) -> str | None:
        '''If the Type is Release. this is the tag name that triggered the script in Github otherwise None'''
        return PyBuilder.GetTag();

    @staticmethod
    def GetType() -> BuildType:
        '''Return the build type'''
        import sys;
        if "+release" in sys.argv:
            return PyBuilder.BuildType.Release;
        if "--check" in sys.argv:
            return PyBuilder.BuildType.Check;
        return PyBuilder.BuildType.Local;

    @property
    def Type(self) -> BuildType:
        '''Return the build type'''
        return PyBuilder.GetType();

    @staticmethod
    def GetWorkspace() -> str:
        """Return the absolute path to the current workspace repository"""
        from __main__ import gpWorkspace;
        return gpWorkspace;

    @property
    def Workspace(self) -> str:
        """Return the absolute path to the current workspace repository"""
        return PyBuilder.GetWorkspace();

    def __init__(self) -> None:
        from __main__ import gpBuilders;
        gpBuilders.append(self);

    def Build( self ) -> bool:
        raise Exception( f"Instance {self.Name} doesn't overrides the Build method!" );

    @property
    def Name( self ) -> str:
        """Get the name of your class module"""
        return self.__module__;

    def Log( self, message: str, *args ):
        """Print a message to console prefixed with your class moule name. using *args"""
        print( f"[{self.Name}] {message.format( *args ) }" );

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

        workspace = PyBuilder.GetWorkspace();

        for path in pathlib.Path( os.path.join( workspace, "scripts", "maps", "bts_rc" ) ).rglob( "*.as" ):

            if path.is_file():

                ascript = PyBuilder.AScript();
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
        return PyBuilder.GetScripts();

    @staticmethod
    def WriteAllScripts() -> int:

        for script in PyBuilder.GetScripts():

            content: str = None;
            with open( script.AbsolutePath, "r", encoding="utf-8" ) as fStream:
                content = fStream.read();
                fStream.close();

            if script.Content != content:

                with open( script.AbsolutePath, "w", encoding="utf-8" ) as fStream:
                    fStream.write( script.Content );
                    print( f"Updated {script.Path}" );
                    fStream.close();