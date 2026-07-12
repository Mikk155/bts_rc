// https://github.com/highlightjs/highlight.js/blob/main/SUPPORTED_LANGUAGES.md
export async function initLanguages(): Promise<void>
{
    const link = document.createElement( "link" );
    link.rel = "stylesheet";
    link.href = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css";
    document.head.appendChild(link);

    const script = document.createElement( "script" );
    script.src = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js";

    script.onload = () =>
    {
        // @ts-ignore
        hljs.highlightAll();
    };

    document.head.appendChild( script );
}
