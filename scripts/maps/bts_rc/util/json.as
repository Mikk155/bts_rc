final class BTSJson
{
    dictionary @data;

    BTSJson@ FirstOrDefault( const string&in keyName )
    {
        if( this.data.exists( keyName ) )
            return BTSJson( cast<dictionary@>( this.data[ keyName ] ) );
        return BTSJson();
    }

    bool FirstOrDefault( const string&in keyName, bool value )
    {
        bool bvalue;
        if( this.data.get( keyName, bvalue ) )
            return bvalue;
        return value;
    }

    BTSJson() {}

    BTSJson( dictionary@&in data )
    {
        @this.data = data;
    }

    ~BTSJson()
    {
        this.data.clear();
    }
}
