document.addEventListener( "DOMContentLoaded", () =>
{
} );

function playMap()
{
    window.open( "https://scmapdb.wikidot.com/map:blackmesa-training-simulation:resonance-cascade", "_blank" );
}

async function loadChangelog()
{
    const res = await fetch( "./changelog.md" );
    const md = await res.text();

    document.getElementById( "changelog" ).innerHTML = parseMarkdown(md);

    attachToggleEvents();
}

function parseMarkdown(md) {
    const lines = md.split("\n");
    let html = "";

    let currentContent = "";
    let currentTitle = "";

    function flushBlock() {
        if (!currentTitle) return;

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

    for (let line of lines) {

        if (line.startsWith("# ")) {
            flushBlock();
            currentTitle = line.substring(2);
            continue;
        }

        if (line.startsWith("- ")) {
            currentContent += `<li>${inlineParse(line.substring(2))}</li>`;
            continue;
        }

        if (line.trim() !== "") {
            currentContent += `<p>${inlineParse(line)}</p>`;
        }
    }

    flushBlock();

    return html;
}

function inlineParse(text) {
    text = text.replace(/\*\*(.*?)\*\*/g, "<b>$1</b>");
    text = text.replace(/`(.*?)`/g, "<code>$1</code>");
    return text;
}

function attachToggleEvents() {
    document.querySelectorAll(".changelog-header").forEach( header => {
        header.addEventListener("click", () => {
            const content = header.nextElementSibling;
            content.classList.toggle("open");
        });
    });
}

loadChangelog();
