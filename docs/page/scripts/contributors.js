export async function initContributors() {
    async function render(container, contributors) {
        container.innerHTML = "";
        let ordered = Array.from(contributors.values());
        ordered.sort((a, b) => b.contributions - a.contributions);
        ordered.forEach((user) => {
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
        });
        await fetch(`assets/credits.json`).then(async (response) => {
            if (response && response.ok) {
                const users = await response.json();
                for (const user of users) {
                    const element = document.createElement("li");
                    element.innerText = user;
                    container.appendChild(element);
                }
            }
        });
    }
    async function loadFromCache(forceLoad = false) {
        const cached = localStorage.getItem("contributors_cache");
        if (!cached)
            return false;
        const parsed = JSON.parse(cached);
        if (!parsed)
            return false;
        if (forceLoad || Date.now() - parsed.timestamp < (1000 * 60 * 5)) {
            await render(document.getElementById("contributor_list"), new Map(parsed.data));
            return true;
        }
        return false;
    }
    if (await loadFromCache())
        return;
    const contributors = new Map();
    const res = await fetch(`https://api.github.com/repos/Mikk155/bts_rc/contributors`);
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
        contributors.set(user.login.toLowerCase(), user);
    }
    localStorage.setItem("contributors_cache", JSON.stringify({ timestamp: Date.now(), data: Array.from(contributors.entries()) }));
    await render(document.getElementById("contributor_list"), contributors);
}
