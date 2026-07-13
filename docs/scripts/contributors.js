export async function initContributors() {
    async function render(container, contributors) {
        container.innerHTML = "";
        const ordered = Array.from(contributors.values());
        ordered.sort((a, b) => {
            return b.contributions - a.contributions;
        });
        for (const user of ordered) {
            const el = document.createElement("a");
            el.href = user.html_url;
            el.target = "_blank";
            el.className = "contributor";
            el.innerHTML = `
                <img src="${user.avatar_url}" />
                <div>${user.login}</div>
                <div>${user.contributions} contributions</div>
            `;
            container.appendChild(el);
        }
        // credits.json
        try {
            const response = await fetch("assets/credits.json");
            if (response.ok) {
                const users = await response.json();
                if (Array.isArray(users)) {
                    for (const user of users) {
                        if (typeof user !== "string")
                            continue;
                        const element = document.createElement("li");
                        element.innerText = user;
                        container.appendChild(element);
                    }
                }
            }
        }
        catch (err) {
            console.warn("credits.json failed: ", err);
        }
    }
    async function loadFromCache(forceLoad = false) {
        const cached = localStorage.getItem("contributors_cache");
        if (!cached) {
            return false;
        }
        let parsed;
        try {
            parsed = JSON.parse(cached);
        }
        catch {
            return false;
        }
        if (!parsed || !Array.isArray(parsed.data)) {
            return false;
        }
        const container = document.getElementById("contributor_list");
        if (!container) {
            return false;
        }
        const isFresh = Date.now() - parsed.timestamp < (1000 * 60 * 5);
        if (forceLoad || isFresh) {
            const map = new Map(parsed.data);
            await render(container, map);
            return true;
        }
        return false;
    }
    if (await loadFromCache()) {
        return;
    }
    const contributors = new Map();
    let res;
    try {
        res = await fetch("https://api.github.com/repos/Mikk155/bts_rc/contributors");
    }
    catch (err) {
        console.error("Fetch failed: ", err);
        await loadFromCache(true);
        return;
    }
    if (!res.ok) {
        console.error("HTTP Error:", res.status);
        await loadFromCache(true);
        return;
    }
    const data = await res.json();
    if (!Array.isArray(data)) {
        console.error("Invalid response: ", data);
        await loadFromCache(true);
        return;
    }
    for (const user of data) {
        if (typeof user !== "object" || user === null || !("login" in user)) {
            continue;
        }
        const contributor = {
            login: String(user.login),
            avatar_url: String(user.avatar_url),
            html_url: String(user.html_url),
            contributions: Number(user.contributions)
        };
        contributors.set(contributor.login.toLowerCase(), contributor);
    }
    localStorage.setItem("contributors_cache", JSON.stringify({
        timestamp: Date.now(),
        data: Array.from(contributors.entries())
    }));
    const container = document.getElementById("contributor_list");
    if (!container) {
        console.warn("Container not found");
        return;
    }
    await render(container, contributors);
}
