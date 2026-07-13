export async function initVersionRelease() {
    const CACHE_KEY = "last_release";
    const CACHE_TTL = 1000 * 60 * 5;
    function render(tagName) {
        const container = document.getElementById("release-notice");
        const popup = document.createElement("div");
        popup.className = "release-popup";
        popup.innerHTML = `
            🚀 New version <strong>${tagName}</strong>
            <button class="close">✖</button>
        `;
        popup.addEventListener("click", (e) => {
            const target = e.target;
            if (target.classList.contains("close")) {
                popup.remove();
                return;
            }
            window.open(`https://github.com/Mikk155/bts_rc/releases/tag/${tagName}`, "_blank");
        });
        container.appendChild(popup);
    }
    function getCache() {
        const raw = localStorage.getItem(CACHE_KEY);
        if (!raw)
            return null;
        try {
            return JSON.parse(raw);
        }
        catch {
            return null;
        }
    }
    function setCache(version) {
        const data = {
            timestamp: Date.now(),
            last_seen: version
        };
        localStorage.setItem(CACHE_KEY, JSON.stringify(data));
    }
    const cache = getCache();
    if (cache && Date.now() - cache.timestamp < CACHE_TTL) {
        return;
    }
    let latestTag = null;
    try {
        const res = await fetch("https://api.github.com/repos/Mikk155/bts_rc/tags");
        if (!res.ok)
            throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        if (!Array.isArray(data) || data.length === 0)
            throw new Error("Invalid response");
        latestTag = data[0].name;
    }
    catch (err) {
        console.error("Release fetch failed:", err);
        return;
    }
    if (!latestTag)
        return;
    if (!cache || cache.last_seen !== latestTag) {
        render(latestTag);
        setCache(latestTag);
    }
}
