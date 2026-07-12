function parseMarkdown(markdown) {
    const lines = markdown.split("\n");
    let html = "";
    let currentContent = "";
    let currentTitle = "";
    function flushBlock() {
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
    for (const line of lines) {
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
export async function initChangelog() {
    const container = document.getElementById("changelog");
    if (!container) {
        console.warn("Changelog container not found");
        return;
    }
    const res = await fetch("https://raw.githubusercontent.com/Mikk155/bts_rc/main/CHANGELOG.md");
    if (!res || !res.ok) {
        container.innerHTML = "Failed to fetch changelog";
        return;
    }
    const markdown = await res.text();
    container.innerHTML = parseMarkdown(markdown);
    const headers = document.querySelectorAll(".changelog-header");
    headers.forEach(header => {
        header.addEventListener("click", () => {
            const content = header.nextElementSibling;
            if (content) {
                content.classList.toggle("open");
            }
        });
    });
}
