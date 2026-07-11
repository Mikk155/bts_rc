function parseMarkdown( markdown: string ): string
{
    const lines: string[] = markdown.split( "\n" );
    let html: string = "";

    let currentContent: string = "";
    let currentTitle: string = "";

    function flushBlock(): void
    {
        if (!currentTitle)
            return;

        html += `
<div class="changelog-item">
    <div class="changelog-header">${currentTitle}</div>
    <div class="changelog-content">
        ${currentContent}
    </div>
</div>
`;
        currentContent = "";
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
            currentContent += `<li>${inlineParse(line.substring(2))}</li>`;
            continue;
        }

        if( line.trim() !== "" )
        {
            currentContent += `<p>${inlineParse(line)}</p>`;
        }
    }

    flushBlock();

    return html;
}

function inlineParse( text: string ): string
{
    text = text.replace(/\*\*(.*?)\*\*/g, "<b>$1</b>" );
    text = text.replace(/`(.*?)`/g, "<code>$1</code>" );
    return text;
}

export async function initChangelog(): Promise<void>
{
    const res: Response = await fetch( "./changelog.md" );
    const markdown: string = await res.text();

    const container = document.getElementById( "changelog" );

    if( !container )
    {
        console.warn( "Changelog container not found" );
        return;
    }

    container.innerHTML = parseMarkdown(markdown);

    const headers = document.querySelectorAll<HTMLElement>( ".changelog-header" );

    headers.forEach( header =>
    {
        header.addEventListener( "click", () =>
        {
            const content = header.nextElementSibling as HTMLElement | null;

            if( content )
            {
                content.classList.toggle( "open" );
            }
        });
    });
}