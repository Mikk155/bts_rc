export async function initVersionRelease() : Promise<void>
{
    function render( tagName: string ): void
    {
        const container = document.getElementById( "release-notice" )!;

        const popup = document.createElement( "div" );
        popup.className = "release-popup";
        popup.innerText = `Version ${tagName} released!`;

        popup.addEventListener( "click", () =>
        {
            window.open( `https://github.com/Mikk155/bts_rc/releases/tag/${tagName}`, "_blank" );
            popup.remove();
        } );

        container.appendChild( popup );
    };

    const cached = localStorage.getItem( "last_release" );

    if( cached )
    {
        const parsed = JSON.parse( cached );

        if( parsed )
        {
            if( Date.now() - parsed.timestamp < ( 1000 * 60 * 5 ) )
            {
                render( parsed.tag_name );
                return;
            }
        }
    }

    const res = await fetch( `https://api.github.com/repos/Mikk155/bts_rc/tags` );

    if( !res.ok )
    {
        console.error( "HTTP Error:", res.status );
        return;
    }

    const data = await res.json();

    if( !Array.isArray( data ) )
    {
        console.error( "Invalid response: ", data );
        return;
    }

    const lastTag = data[0];

    render( lastTag.name );

    localStorage.setItem( "last_release", JSON.stringify( { timestamp: Date.now(), tag_name: lastTag.name } ));
}
