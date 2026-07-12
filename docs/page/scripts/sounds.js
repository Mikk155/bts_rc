const sounds = {
    hover: new Audio("./assets/buttonrollover.wav"),
    click: new Audio("./assets/buttonclick.wav"),
    release: new Audio("./assets/buttonclickrelease.wav")
};
function playSound(sound) {
    sound.currentTime = 0;
    sound.play().catch(() => { });
}
export async function initUISounds() {
    function addPlaySounds(element) {
        element.addEventListener("mouseenter", () => { playSound(sounds.hover); });
        element.addEventListener("mousedown", () => { playSound(sounds.click); });
        element.addEventListener("mouseleave", () => { playSound(sounds.release); });
    }
    document.querySelectorAll("button").forEach(addPlaySounds);
    document.querySelectorAll("a[href]").forEach(addPlaySounds);
    document.querySelectorAll(".changelog-header").forEach(addPlaySounds);
}
