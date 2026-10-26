import Ajv2020, {} from "ajv/dist/2020.js";
import { DEV } from "../main.js";
const ajv = new Ajv2020({ allErrors: true });
let defaultConfigPromise;
export async function initConfigGenerator() {
    const sections = document.getElementById("config-sections");
    const selector = document.getElementById("config-section-select");
    const addButton = document.getElementById("config-add-section");
    const output = document.getElementById("config-output");
    const status = document.getElementById("config-status");
    const validateButton = document.getElementById("config-validate");
    const downloadButton = document.getElementById("config-download");
    if (!(sections instanceof HTMLElement)
        || !(selector instanceof HTMLSelectElement)
        || !(addButton instanceof HTMLButtonElement)
        || !(output instanceof HTMLTextAreaElement)
        || !(status instanceof HTMLElement)
        || !(validateButton instanceof HTMLButtonElement)
        || !(downloadButton instanceof HTMLButtonElement)) {
        console.error("Configuration generator markup is incomplete.");
        return;
    }
    const configOutput = output;
    const configStatus = status;
    try {
        const [schemaResponse, defaultConfig] = await Promise.all([
            fetch("./schema.json"),
            loadDefaultConfig()
        ]);
        if (!schemaResponse.ok) {
            throw new Error(`Could not load json schema (${schemaResponse.status}).`);
        }
        const schema = await schemaResponse.json();
        const validate = ajv.compile(schema);
        const addedSections = new Map();
        const rootProperties = schema.properties ?? {};
        selector.replaceChildren();
        const placeholder = document.createElement("option");
        placeholder.value = "";
        placeholder.textContent = "Select a section...";
        selector.appendChild(placeholder);
        for (const [name, property] of Object.entries(rootProperties)) {
            if (name === "$schema"
                || !isConfigObject(defaultConfig[name])
                || schemaType(property) !== "object") {
                continue;
            }
            const option = document.createElement("option");
            option.value = name;
            option.textContent = property.title
                ? `${name} (${property.title})`
                : name;
            selector.appendChild(option);
        }
        function validateOutput() {
            try {
                const config = JSON.parse(configOutput.value);
                if (!validate(config)) {
                    const errors = (validate.errors ?? []).map(error => {
                        const path = error.instancePath || "/";
                        return `${path}: ${error.message ?? "Invalid value"}`;
                    });
                    configStatus.textContent = `Invalid configuration:\n${errors.join("\n")}`;
                    configStatus.className = "config-status config-invalid";
                    return false;
                }
                configStatus.textContent = "Valid configuration.";
                configStatus.className = "config-status config-valid";
                return true;
            }
            catch (error) {
                const message = error instanceof Error ? error.message : String(error);
                configStatus.textContent = `Invalid JSON: ${message}`;
                configStatus.className = "config-status config-invalid";
                return false;
            }
        }
        function updateOutput() {
            const config = {};
            for (const name of addedSections.keys()) {
                config[name] = defaultConfig[name];
            }
            configOutput.value = JSON.stringify(config, null, 4);
            validateOutput();
        }
        addButton.addEventListener("click", () => {
            const name = selector.value;
            const property = rootProperties[name];
            if (!property || !isConfigObject(defaultConfig[name])
                || addedSections.has(name)) {
                return;
            }
            const card = document.createElement("div");
            card.className = "config-section";
            const heading = document.createElement("h3");
            heading.textContent = property.title
                ? `${property.title} (${name})`
                : name;
            const removeButton = document.createElement("button");
            removeButton.type = "button";
            removeButton.className = "config-remove-section";
            removeButton.textContent = "Remove";
            removeButton.setAttribute("aria-label", `Remove section ${name}`);
            removeButton.addEventListener("click", () => {
                card.remove();
                addedSections.delete(name);
                updateOutput();
            });
            const header = document.createElement("div");
            header.className = "config-section-header";
            header.append(heading, removeButton);
            card.appendChild(header);
            if (property.description) {
                const description = document.createElement("p");
                description.className = "config-description";
                description.textContent = property.description;
                card.appendChild(description);
            }
            const defaults = document.createElement("p");
            defaults.className = "config-description";
            defaults.textContent = "Using all values from default_config.json.";
            card.appendChild(defaults);
            addedSections.set(name, card);
            sections.appendChild(card);
            selector.value = "";
            updateOutput();
        });
        configOutput.addEventListener("input", validateOutput);
        validateButton.addEventListener("click", validateOutput);
        downloadButton.addEventListener("click", () => {
            if (!validateOutput()) {
                return;
            }
            const file = new Blob([configOutput.value], { type: "application/json" });
            const url = URL.createObjectURL(file);
            const link = document.createElement("a");
            link.href = url;
            link.download = "bts_rc.json";
            document.body.appendChild(link);
            link.click();
            link.remove();
            window.setTimeout(() => URL.revokeObjectURL(url), 0);
        });
        validateOutput();
    }
    catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        configStatus.textContent = `Could not initialize configuration generator: ${message}`;
        configStatus.className = "config-status config-invalid";
        console.error("Configuration generator initialization error:", error);
    }
}
function loadDefaultConfig() {
    if (!defaultConfigPromise) {
        const path = DEV
            ? "/__default_config.json"
            : "https://raw.githubusercontent.com/Mikk155/bts_rc/main/scripts/maps/bts_rc/default_config.json";
        defaultConfigPromise = fetch(path).then(async (response) => {
            if (!response.ok) {
                throw new Error(`Could not load default configuration (${response.status}).`);
            }
            const config = await response.json();
            if (!isConfigObject(config)) {
                throw new Error("Default configuration must be a JSON object.");
            }
            return config;
        });
    }
    return defaultConfigPromise;
}
function isConfigObject(value) {
    return typeof value === "object" && value !== null && !Array.isArray(value);
}
function schemaType(schema) {
    if (typeof schema.type === "string") {
        return schema.type;
    }
    if (Array.isArray(schema.type)) {
        return schema.type.find(type => type !== "null");
    }
    return undefined;
}
