import { DEV } from "../main.js";

export async function initChangelog() : Promise<void>
{
    const container : HTMLElement | null = document.getElementById( "changelog" );

    if( !container )
    {
        console.warn( "Changelog container not found" );
        return;
    }

    const changelogContainer = container;

    let res : Response;

    try
    {
        if( DEV )
        {
            res = await fetch( "/__changelog.md" );
        }
        else
        {
            res = await fetch( "https://raw.githubusercontent.com/Mikk155/bts_rc/main/CHANGELOG.md" );
        }
    }
    catch( err )
    {
        console.error( "Fetch failed:", err );
        container.innerHTML = "Failed to fetch changelog";
        return;
    }

    if( !res.ok )
    {
        console.error( `Could not fetch changelog (${res.status}).` );
        container.textContent = "Failed to fetch changelog";
        return;
    }

    container.innerHTML = "";

    const lines : string[] = ( await res.text() )
        .replace( /\r/g, "" )
        .replace( /\*\*(.*?)\*\*/g, "<b>$1</b>" )
        .replace( /``(.*?)``/g, "<code class=\"terminal\">$1</code>" )
        .replace( /`(.*?)`/g, "<code>$1</code>" )
        .split( "\n" );

    function openChangelogFromHash() : void
    {
        const id = window.location.hash.slice( 1 );
        const item = document.getElementById( id );

        if( !item || !changelogContainer.contains( item ) )
        {
            return;
        }

        const header = item.querySelector<HTMLButtonElement>( ".changelog-header" );
        const content = item.querySelector<HTMLElement>( ".changelog-content" );

        if( !header || !content )
        {
            return;
        }

        content.classList.add( "open" );
        header.setAttribute( "aria-expanded", "true" );
        item.scrollIntoView( { behavior: "smooth", block: "start" } );
    }

    function changelogId( title: string ) : string | undefined
    {
        const match = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/.exec( title );

        if( !match )
        {
            return undefined;
        }

        const day = Number( match[ 1 ] );
        const month = Number( match[ 2 ] );
        const year = Number( match[ 3 ] );
        const date = new Date( year, month - 1, day );

        if( date.getFullYear() !== year
            || date.getMonth() !== month - 1
            || date.getDate() !== day )
        {
            return undefined;
        }

        return `changelog_${year}-${String( month ).padStart( 2, "0" )}-${String( day ).padStart( 2, "0" )}`;
    }

    function pushSection( title: string, elements: Array<HTMLElement>, container: HTMLElement ) : void
    {
        if( title === "" )
            return;

        let item: HTMLDivElement = document.createElement( "div" );
        item.className = "changelog-item";
        const id = changelogId( title );
        const sectionId = id
            ?? `changelog_section_${container.querySelectorAll( ".changelog-item" ).length + 1}`;

        if( id )
        {
            item.id = id;
        }

        let header: HTMLButtonElement = document.createElement( "button" );
        header.type = "button";
        header.className = "changelog-header";
        header.innerText = title;
        header.setAttribute( "aria-expanded", "false" );
        header.setAttribute( "aria-controls", `${sectionId}-content` );

        let content: HTMLDivElement = document.createElement( "div" );
        content.id = `${sectionId}-content`;
        content.className = "changelog-content";

        header.addEventListener( "click", () : void =>
        {
            const isOpen = !content.classList.contains( "open" );
            content.classList.toggle( "open", isOpen );
            header.setAttribute( "aria-expanded", String( isOpen ) );

            if( id )
            {
                window.history.replaceState(
                    null,
                    "",
                    `${window.location.pathname}${window.location.search}#${id}`
                );
            }
        } );

        let ListElements: HTMLUListElement | null = null;

        for( const element of elements )
        {
            if( element instanceof HTMLLIElement )
            {
                if( !ListElements )
                {
                    ListElements = document.createElement( "ul" );
                }

                ListElements.appendChild( element );

                continue;
            }
            else
            {
                if( ListElements )
                {
                    content.appendChild( ListElements );
                }

                ListElements = null;
            }

            content.appendChild( element );
        }

        if( ListElements )
        {
            content.appendChild( ListElements );
        }

        item.appendChild( header );
        item.appendChild( content );

        container.appendChild( item );
    }

    let elements: Array<HTMLElement> = [];
    let title: string = "";

    {
        let element: HTMLAnchorElement = document.createElement( "a" );
        element.href = "https://github.com/Mikk155/bts_rc/blob/main/CHANGELOG.md";
        element.target = "_blanc";
        element.innerText = "Full changelog in Markdown.";
        element.className = "changelog-header";
        element.style.display = "block";
        element.style.width = "max-content";
        element.style.margin = "0 auto";
        element.style.textAlign = "center";
        container.appendChild( element );
        container.appendChild( document.createElement( "br" ) );
    }

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

        if( line.startsWith( "## " ) )
        {
            let element: HTMLHeadingElement = document.createElement( "h2" );
            element.innerHTML = line.substring(3);
            elements.push( element );
            continue;
        }

        if( line.startsWith( "### " ) )
        {
            let element: HTMLHeadingElement = document.createElement( "h3" );
            element.innerHTML = line.substring(4);
            elements.push( element );
            continue;
        }

        if( line.trim() === "" )
            continue;

        let element: HTMLParagraphElement = document.createElement( "p" );

        if( line[0] == " " || line[0] == "\t" )
        {
            element.innerHTML = `<pre>${line}</pre>`;
        }
        else
        {
            element.innerHTML = line;
        }

        elements.push( element );
    }

    pushSection( title, elements, container );
    window.addEventListener( "hashchange", openChangelogFromHash );
    openChangelogFromHash();
}
