// HTML Methods
import { copyCode } from "./scripts/copyCode.js";
import { initUISounds } from "./scripts/sounds.js";
import { initChangelog } from "./scripts/changelog.js";
import { initSlider } from "./scripts/background.js";
import { initContributors } from "./scripts/contributors.js";
import { initVersionRelease } from "./scripts/lastRelease.js";
import { initLanguages } from "./scripts/languages.js";
window.copyCode = copyCode;
document.addEventListener("DOMContentLoaded", async () => {
    try {
        // Async don't wait
        initSlider();
        // Wait these before initializing sounds/languages
        await initContributors();
        await initVersionRelease();
        await initChangelog();
    }
    catch (err) {
        console.error("Initialization error: ", err);
    }
    // Code block languages
    await initLanguages();
    // Hover sounds
    initUISounds();
});
