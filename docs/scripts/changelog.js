export async function initChangelog() {
    const container = document.getElementById("changelog");
    if (!container) {
        console.warn("Changelog container not found");
        return;
    }
    let res;
    try {
        res = await fetch("../CHANGELOG.md");
        //        res = await fetch( "https://raw.githubusercontent.com/Mikk155/bts_rc/main/CHANGELOG.md" );
    }
    catch (err) {
        console.error("Fetch failed:", err);
        container.innerHTML = "Failed to fetch changelog";
        return;
    }
    if (!res.ok) {
        container.innerHTML = "Failed to fetch changelog";
        return;
    }
    container.innerHTML = "";
    const lines = (await res.text())
        .replace(/\r/g, "")
        .replace(/\t/g, "<pre>    </pre>")
        .replace("    ", "<pre>    </pre>")
        .replace(/\*\*(.*?)\*\*/g, "<b>$1</b>")
        .replace(/`(.*?)`/g, "<code>$1</code>")
        .split("\n");
    function pushSection(title, elements, container) {
        if (title === "")
            return;
        let item = document.createElement("div");
        item.className = "changelog-item";
        let header = document.createElement("div");
        header.className = "changelog-header";
        header.innerText = title;
        header.addEventListener("click", () => {
            const next = header.nextElementSibling;
            if (next instanceof HTMLElement) {
                next.classList.toggle("open");
            }
        });
        let content = document.createElement("div");
        content.className = "changelog-content";
        let ListElements = null;
        for (const element of elements) {
            if (element instanceof HTMLLIElement) {
                if (!ListElements)
                    ListElements = document.createElement("ul");
                ListElements.appendChild(element);
                continue;
            }
            else {
                if (ListElements)
                    content.appendChild(ListElements);
                ListElements = null;
            }
            content.appendChild(element);
        }
        if (ListElements)
            content.appendChild(ListElements);
        item.appendChild(header);
        item.appendChild(content);
        container.appendChild(item);
    }
    let elements = [];
    let title = "";
    for (const line of lines) {
        if (line.startsWith("# ")) {
            pushSection(title, elements, container);
            title = line.substring(2);
            elements = []; // how tf there's no "clear" method
            continue;
        }
        if (line.startsWith("- ")) {
            let element = document.createElement("li");
            element.innerHTML = line.substring(2);
            elements.push(element);
            continue;
        }
        if (line.startsWith("## ")) {
            let element = document.createElement("h2");
            element.innerHTML = line.substring(3);
            elements.push(element);
            continue;
        }
        if (line.startsWith("### ")) {
            let element = document.createElement("h3");
            element.innerHTML = line.substring(4);
            elements.push(element);
            continue;
        }
        if (line.trim() === "")
            continue;
        let element = document.createElement("p");
        element.innerHTML = line;
        elements.push(element);
    }
    pushSection(title, elements, container);
}
