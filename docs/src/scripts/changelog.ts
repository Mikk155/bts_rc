function parseMarkdown( markdown : string ) : string
{
    const lines : string[] = markdown.split( "\n" );
    let html : string = "";

    let currentContent : string = "";
    let currentTitle : string = "";
    let inList : boolean = false;

    function flushBlock() : void
    {
        if( !currentTitle )
        {
            return;
        }

        if( inList )
        {
            currentContent += "</ul>";
            inList = false;
        }

        html += `
<div class="changelog-item">
    <div class="changelog-header">${currentTitle}</div>
    <div class="changelog-content">
        ${currentContent}
    </div>
</div>
`;

        currentContent = "";
        currentTitle = "";
    }

    for( const line of lines )
    {
        if( line.startsWith( "# " ) )
        {
            flushBlock();
            currentTitle = line.substring(2);
            continue;
        }

        if( line.startsWith( "- " ) )
        {
            if( !inList )
            {
                currentContent += "<ul>";
                inList = true;
            }

            currentContent += `<li>${inlineParse( line.substring(2) )}</li>`;
            continue;
        }
        else if( inList )
        {
            currentContent += "</ul>";
            inList = false;
        }

        if( line.trim() !== "" )
        {
            currentContent += `<p>${inlineParse( line )}</p>`;
        }
    }

    flushBlock();

    return html;
}

function inlineParse( text : string ) : string
{
    let parsed : string = text;

    parsed = parsed.replace( /\*\*(.*?)\*\*/g, "<b>$1</b>" );
    parsed = parsed.replace( /`(.*?)`/g, "<code>$1</code>" );

    return parsed;
}

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
        res = await fetch( "https://raw.githubusercontent.com/Mikk155/bts_rc/main/CHANGELOG.md" );
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

    const markdown : string = await res.text();

    container.innerHTML = parseMarkdown( markdown );

    const headers : NodeListOf<HTMLElement> = document.querySelectorAll( ".changelog-header" );

    headers.forEach( ( header : HTMLElement ) : void =>
    {
        header.addEventListener( "click", () : void =>
        {
            const next : Element | null = header.nextElementSibling;

            if( next instanceof HTMLElement )
            {
                next.classList.toggle( "open" );
            }
        } );
    } );
}