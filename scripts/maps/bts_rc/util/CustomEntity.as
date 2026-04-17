/// Register a custom entity with the given classname. if internalName is empty we asume the class is named the same as the entity classname
bool CustomEntity( const string&in className, bool precacheEntity = false, const string&in internalName = String::EMPTY_STRING )
{
    g_CustomEntityFuncs.RegisterCustomEntity( internalName.IsEmpty() ? className : internalName, className );

    if( precacheEntity )
        g_Game.PrecacheOther( className );

    return true;
}
