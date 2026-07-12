import { initUISounds } from "./scripts/sounds.js";
import { initChangelog } from "./scripts/changelog.js";
import { initSlider } from "./scripts/background.js";
import { initContributors } from "./scripts/contributors.js";
import { initVersionRelease } from "./scripts/lastRelease.js";
// HTML Methods
import { copyCode } from "./scripts/copyCode.js";
window.copyCode = copyCode;
document.addEventListener("DOMContentLoaded", async () => {
    initSlider();
    await initContributors();
    await initVersionRelease();
    await initChangelog();
    // Hover sounds
    initUISounds();
});
