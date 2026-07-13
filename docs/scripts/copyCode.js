// Copy to clipboard the nearest .terminal class
export function copyCode(button) {
    const container = button.closest(".terminal");
    if (!container) {
        return;
    }
    const codeElement = container.querySelector("code");
    if (!(codeElement instanceof HTMLElement)) {
        return;
    }
    const code = codeElement.textContent ?? "";
    if (code.trim() === "") {
        return;
    }
    navigator.clipboard.writeText(code)
        .then(() => {
        const originalText = button.innerText;
        button.innerText = "✅ Copied";
        window.setTimeout(() => {
            button.innerText = originalText;
        }, 1500);
    })
        .catch(() => {
        console.warn("Clipboard write failed");
    });
}
