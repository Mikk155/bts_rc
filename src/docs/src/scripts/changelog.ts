export async function initChangelog() : Promise<void>
{
    const container : HTMLElement | null = document.getElementById( "changelog" );

    if( !container )
    {
        console.warn( "Changelog container not found" );
        return;
    }

    let res : Response;

    try
    {
        res = await fetch( "../CHANGELOG.md" );
//        res = await fetch( "https://raw.githubusercontent.com/Mikk155/bts_rc/main/CHANGELOG.md" );
    }
    catch( err )
    {
        console.error( "Fetch failed:", err );
        container.innerHTML = "Failed to fetch changelog";
        return;
    }

    if( !res.ok )
    {
        container.innerHTML = "Failed to fetch changelog";
        return;
    }

    container.innerHTML = "";

    const lines : string[] = ( await res.text() )
        .replace( /\r/g, "" )
        .replace( /\t/g, "<pre>    </pre>" )
        .replace( "    ", "<pre>    </pre>" )
        .replace( /\*\*(.*?)\*\*/g, "<b>$1</b>" )
        .replace( /`(.*?)`/g, "<code>$1</code>" )
        .split( "\n" );

    function pushSection( title: string, elements: Array<HTMLElement>, container: HTMLElement ) : void
    {
        if( title === "" )
            return;

        let item: HTMLDivElement = document.createElement( "div" );
        item.className = "changelog-item";

        let header: HTMLDivElement = document.createElement( "div" );
        header.className = "changelog-header";
        header.innerText = title;
        header.addEventListener( "click", () : void =>
        {
            const next : Element | null = header.nextElementSibling;

            if( next instanceof HTMLElement )
            {
                next.classList.toggle( "open" );
            }
        } );

        let content: HTMLDivElement = document.createElement( "div" );
        content.className = "changelog-content";

        let ListElements: HTMLUListElement | null = null;

        for( const element of elements )
        {
            if( element instanceof HTMLLIElement )
            {
                if( !ListElements )
                    ListElements = document.createElement( "ul" );
                ListElements.appendChild( element );
                continue;
            }
            else
            {
                if( ListElements )
                    content.appendChild( ListElements );
                ListElements = null;
            }

            content.appendChild( element );
        }

        if( ListElements )
            content.appendChild( ListElements );

        item.appendChild( header );
        item.appendChild( content );
        container.appendChild( item );
    }

    let elements: Array<HTMLElement> = [];
    let title: string = "";

    for( const line of lines )
    {
        if( line.startsWith( "# " ) )
        {
            pushSection( title, elements, container );
            title = line.substring(2);
            elements = []; // how tf there's no "clear" method
            continue;
        }

        if( line.startsWith( "- " ) )
        {
            let element: HTMLLIElement = document.createElement( "li" );
            element.innerHTML = line.substring(2);
            elements.push( element );
            continue;
        }

        if( line.trim() === "" )
            continue;

        let element: HTMLParagraphElement = document.createElement( "p" );
        element.innerHTML = line;
        elements.push( element );
    }

    pushSection( title, elements, container );
}
