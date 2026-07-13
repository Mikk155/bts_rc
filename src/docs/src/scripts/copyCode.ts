// Copy to clipboard the nearest .terminal class
export function copyCode( button : HTMLButtonElement ) : void
{
    const container : Element | null = button.closest( ".terminal" );

    if( !container )
    {
        return;
    }

    const codeElement : Element | null = container.querySelector( "code" );

    if( !( codeElement instanceof HTMLElement ) )
    {
        return;
    }

    const code : string = codeElement.textContent ?? "";

    if( code.trim() === "" )
    {
        return;
    }

    navigator.clipboard.writeText( code )
    .then( () : void =>
    {
        const originalText : string = button.innerText;

        button.innerText = "✅ Copied";

        window.setTimeout( () : void =>
        {
            button.innerText = originalText;
        }, 1500 );
    })
    .catch( () : void =>
    {
        console.warn( "Clipboard write failed" );
    });
}
