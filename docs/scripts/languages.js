// https://github.com/highlightjs/highlight.js/blob/main/SUPPORTED_LANGUAGES.md
export async function initLanguages() {
    if (window.hljs) {
        window.hljs.highlightAll();
        return;
    }
    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css";
    document.head.appendChild(link);
    const script = document.createElement("script");
    script.src = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js";
    script.onload = () => {
        if (window.hljs) {
            window.hljs.highlightAll();
        }
        else {
            console.warn("hljs not available after load");
        }
    };
    script.onerror = () => {
        console.error("Failed to load highlight.js");
    };
    document.head.appendChild(script);
}
