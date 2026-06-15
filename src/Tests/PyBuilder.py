# ===================================================================
# ===================================================================
# Purpose:
#   Python validation class builder.
# ===================================================================
# ===================================================================

class PyBuilder:
    """Inherit from PyBuilder and instantiate your class then Build will be called"""

    @property
    def Workspace(self) -> str:
        """Return the absolute path to the current workspace repository"""
        from __main__ import gpWorkspace;
        return gpWorkspace;

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
