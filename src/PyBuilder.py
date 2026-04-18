class PyBuilder:

    def __init__(self) -> None:
        pass;

    def Build( self ) -> bool:
        pass;

    @property
    def Name( self ) -> str:
        return self.__module__;

    def Log( self, message: str, *args ):
        print( f"[{self.Name}] {message.format( *args ) }" );
