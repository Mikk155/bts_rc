// Copy to clipboard the nearest .terminal class
export function copyCode( button: HTMLButtonElement ): void
{
    const container = button.closest( ".terminal" );
    const codeElement = container?.querySelector( "code" );

    const code: string | undefined = codeElement?.textContent ?? undefined;

    if( !code )
        return;

    navigator.clipboard.writeText( code ).then( () =>
    {
        const originalText = button.innerText;

        button.innerText = "✅ Copied";

        setTimeout( () => { button.innerText = originalText; }, 1500 );
    } ).catch( () =>
    {
        console.warn( "Clipboard write failed" );
    } );
}