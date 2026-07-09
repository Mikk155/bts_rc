const sounds = {
    hover: new Audio("buttonrollover.wav"),
    click: new Audio("buttonclick.wav"),
    release: new Audio("buttonclickrelease.wav")
};
function playSound(sound) {
    sound.currentTime = 0;
    sound.play().catch(() => { });
}
export function initUISounds() {
    const elements = document.querySelectorAll("button, a[href]");
    elements.forEach(el => {
        el.addEventListener("mouseenter", () => {
            playSound(sounds.hover);
        });
        el.addEventListener("mousedown", () => {
            playSound(sounds.click);
        });
        el.addEventListener("mouseleave", () => {
            playSound(sounds.release);
        });
    });
}
