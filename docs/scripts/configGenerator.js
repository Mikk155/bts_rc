import Ajv2020, {} from "ajv/dist/2020.js";
const ajv = new Ajv2020({ allErrors: true });
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
        const response = await fetch("./schema.json");
        if (!response.ok) {
            throw new Error(`Could not load json schema (${response.status}).`);
        }
        const schema = await response.json();
        const validate = ajv.compile(schema);
        const rootProperties = schema.properties ?? {};
        const addedSections = new Map();
        selector.replaceChildren();
        const placeholder = document.createElement("option");
        placeholder.value = "";
        placeholder.textContent = "Select a section...";
        selector.appendChild(placeholder);
        for (const [name, property] of Object.entries(rootProperties)) {
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
            try {
                const config = {};
                for (const [name, section] of addedSections) {
                    const fields = sectionFields.get(section) ?? [];
                    config[name] = readObject(fields);
                }
                configOutput.value = JSON.stringify(config, null, 4);
                validateOutput();
            }
            catch (error) {
                const message = error instanceof Error ? error.message : String(error);
                configOutput.value = "";
                configStatus.textContent = message;
                configStatus.className = "config-status config-invalid";
            }
        }
        const sectionFields = new Map();
        addButton.addEventListener("click", () => {
            const name = selector.value;
            const property = rootProperties[name];
            if (!property || addedSections.has(name)) {
                return;
            }
            const resolved = resolveSchema(property, schema);
            const card = document.createElement("div");
            card.className = "config-section";
            const heading = document.createElement("h3");
            heading.textContent = resolved.title
                ? `${resolved.title} (${name})`
                : name;
            const removeButton = document.createElement("button");
            removeButton.type = "button";
            removeButton.className = "config-remove-section";
            removeButton.textContent = "Remove";
            removeButton.setAttribute("aria-label", `Remove section ${name}`);
            removeButton.addEventListener("click", () => {
                card.remove();
                addedSections.delete(name);
                sectionFields.delete(card);
                updateOutput();
            });
            const header = document.createElement("div");
            header.className = "config-section-header";
            header.append(heading, removeButton);
            card.appendChild(header);
            if (resolved.description) {
                const description = document.createElement("p");
                description.className = "config-description";
                description.textContent = resolved.description;
                card.appendChild(description);
            }
            const fieldsContainer = document.createElement("div");
            fieldsContainer.className = "config-fields";
            card.appendChild(fieldsContainer);
            const fields = buildFields(resolved, schema, fieldsContainer, updateOutput, false);
            sectionFields.set(card, fields);
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
        configStatus.textContent = `Could not initialize validator: ${message}`;
        configStatus.className = "config-status config-invalid";
        console.error("Configuration generator initialization error:", error);
    }
}
function buildFields(schema, rootSchema, container, onChange, forceInclude) {
    const fields = [];
    const required = new Set(schema.required ?? []);
    for (const [name, rawProperty] of Object.entries(schema.properties ?? {})) {
        const property = resolveSchema(rawProperty, rootSchema);
        const details = document.createElement("details");
        details.className = "config-property";
        const summary = document.createElement("summary");
        const include = document.createElement("input");
        include.type = "checkbox";
        include.checked = forceInclude || required.has(name);
        include.disabled = required.has(name);
        include.setAttribute("aria-label", `Include ${name}`);
        const title = document.createElement("span");
        title.className = "config-property-title";
        title.textContent = property.title && property.title !== name
            ? `${property.title} (${name})`
            : name;
        summary.append(include, title);
        details.appendChild(summary);
        if (property.description) {
            const description = document.createElement("p");
            description.className = "config-description";
            description.textContent = property.description;
            details.appendChild(description);
        }
        const controlContainer = document.createElement("div");
        controlContainer.className = "config-control";
        details.appendChild(controlContainer);
        const field = {
            name,
            schema: property,
            include,
            children: []
        };
        const type = schemaType(property);
        if (type === "object") {
            field.children = buildFields(property, rootSchema, controlContainer, onChange, false);
            if (property.additionalProperties
                && typeof property.additionalProperties === "object") {
                field.dynamicProperties = buildDynamicProperties(property.additionalProperties, rootSchema, controlContainer, onChange);
            }
        }
        else if (type === "array"
            && property.items
            && ["integer", "number", "string", "boolean"].includes(schemaType(property.items) ?? "")) {
            field.arrayItemSchema = property.items;
            field.arrayInputs = buildArrayInputs(property, controlContainer, onChange);
        }
        else {
            field.input = createInput(property, controlContainer, onChange);
        }
        controlContainer.hidden = !include.checked;
        details.open = include.checked;
        include.addEventListener("click", event => event.stopPropagation());
        include.addEventListener("change", () => {
            controlContainer.hidden = !include.checked;
            details.open = include.checked;
            onChange();
        });
        details.addEventListener("toggle", () => {
            if (!include.checked && details.open) {
                include.checked = true;
                controlContainer.hidden = false;
                onChange();
            }
        });
        container.appendChild(details);
        fields.push(field);
    }
    return fields;
}
function createInput(schema, container, onChange) {
    const type = schemaType(schema);
    let input;
    if (type === "array") {
        input = document.createElement("textarea");
        input.className = "config-array-input";
        input.rows = 3;
        input.value = JSON.stringify(initialArrayValue(schema), null, 2);
        input.placeholder = "[ ... ]";
        input.setAttribute("aria-label", "List values in JSON format");
    }
    else if (schema.enum) {
        const select = document.createElement("select");
        const emptyOption = document.createElement("option");
        emptyOption.value = "";
        emptyOption.textContent = "Select...";
        select.appendChild(emptyOption);
        for (const value of schema.enum) {
            const option = document.createElement("option");
            option.value = JSON.stringify(value);
            option.textContent = String(value);
            select.appendChild(option);
        }
        const initialValue = schema.default ?? schema.enum[0];
        if (initialValue !== undefined) {
            select.value = JSON.stringify(initialValue);
        }
        input = select;
    }
    else {
        const control = document.createElement("input");
        if (type === "boolean") {
            control.type = "checkbox";
            control.checked = schema.default === true;
        }
        else if (type === "integer" || type === "number") {
            control.type = "number";
            control.step = type === "integer" ? "1" : "any";
            control.value = typeof schema.default === "number"
                ? String(schema.default)
                : "";
            if (typeof schema.minimum === "number") {
                control.min = String(schema.minimum);
            }
            if (typeof schema.maximum === "number") {
                control.max = String(schema.maximum);
            }
        }
        else {
            control.type = "text";
            control.value = typeof schema.default === "string"
                ? schema.default
                : "";
        }
        input = control;
    }
    input.classList.add("config-value-input");
    input.addEventListener("input", onChange);
    input.addEventListener("change", onChange);
    container.appendChild(input);
    return input;
}
function readObject(fields) {
    const result = {};
    for (const field of fields) {
        if (!field.include.checked) {
            continue;
        }
        const type = schemaType(field.schema);
        if (type === "object") {
            const value = readObject(field.children);
            for (const dynamicField of field.dynamicProperties ?? []) {
                const key = dynamicField.keyInput?.value.trim();
                if (!key) {
                    throw new Error(`${field.name}: Fill the name of every dynamic property.`);
                }
                if (Object.prototype.hasOwnProperty.call(value, key)) {
                    throw new Error(`${field.name}: The property "${key}" is repeated.`);
                }
                Object.defineProperty(value, key, {
                    configurable: true,
                    enumerable: true,
                    value: readFieldValue(dynamicField),
                    writable: true
                });
            }
            result[field.name] = value;
            continue;
        }
        result[field.name] = readFieldValue(field);
    }
    return result;
}
function readFieldValue(field) {
    const fieldName = field.keyInput?.value.trim() || field.name;
    const arrayItemSchema = field.arrayItemSchema;
    if (field.arrayInputs && arrayItemSchema) {
        return field.arrayInputs.map((input, index) => {
            const type = schemaType(arrayItemSchema);
            if (type === "boolean") {
                return input.checked;
            }
            if (type === "integer" || type === "number") {
                if (input.value === "") {
                    throw new Error(`${fieldName}[${index}]: Input a number.`);
                }
                return Number(input.value);
            }
            return input.value;
        });
    }
    const input = field.input;
    if (!input) {
        return undefined;
    }
    if (input instanceof HTMLTextAreaElement) {
        try {
            return JSON.parse(input.value);
        }
        catch {
            throw new Error(`${fieldName}: The value must be a valid JSON.`);
        }
    }
    if (input instanceof HTMLSelectElement) {
        if (input.value === "") {
            throw new Error(`${fieldName}: Select a value.`);
        }
        return JSON.parse(input.value);
    }
    const type = schemaType(field.schema);
    if (type === "boolean") {
        return input.checked;
    }
    if (type === "integer" || type === "number") {
        if (input.value === "") {
            throw new Error(`${fieldName}: Input a number.`);
        }
        return Number(input.value);
    }
    return input.value;
}
function initialArrayValue(schema) {
    if (Array.isArray(schema.default)) {
        return schema.default;
    }
    const itemSchema = schema.items ?? {};
    const itemCount = schema.minItems ?? 0;
    return Array.from({ length: itemCount }, () => initialValue(itemSchema));
}
function buildArrayInputs(schema, container, onChange) {
    const rows = document.createElement("div");
    rows.className = "config-array-rows";
    const addButton = document.createElement("button");
    addButton.type = "button";
    addButton.className = "config-add-array-item";
    addButton.textContent = "Add value";
    const inputs = [];
    function updateButtons() {
        for (const removeButton of rows.querySelectorAll(".config-remove-array-item")) {
            removeButton.disabled = inputs.length <= (schema.minItems ?? 0);
        }
        addButton.disabled = typeof schema.maxItems === "number"
            && inputs.length >= schema.maxItems;
    }
    function addItem(value) {
        const row = document.createElement("div");
        row.className = "config-array-row";
        const input = document.createElement("input");
        const itemType = schemaType(schema.items ?? {});
        if (itemType === "integer" || itemType === "number") {
            input.type = "number";
            input.step = itemType === "integer" ? "1" : "any";
            if (typeof schema.items?.minimum === "number") {
                input.min = String(schema.items.minimum);
            }
            if (typeof schema.items?.maximum === "number") {
                input.max = String(schema.items.maximum);
            }
            if (typeof value === "number") {
                input.value = String(value);
            }
        }
        else if (itemType === "boolean") {
            input.type = "checkbox";
            input.checked = value === true;
        }
        else {
            input.type = "text";
            input.value = typeof value === "string" ? value : "";
        }
        input.setAttribute("aria-label", `Valor ${inputs.length + 1}`);
        input.addEventListener("input", onChange);
        input.addEventListener("change", onChange);
        const removeButton = document.createElement("button");
        removeButton.type = "button";
        removeButton.className = "config-remove-array-item";
        removeButton.textContent = "Remove";
        removeButton.addEventListener("click", () => {
            row.remove();
            inputs.splice(inputs.indexOf(input), 1);
            updateButtons();
            onChange();
        });
        row.append(input, removeButton);
        rows.appendChild(row);
        inputs.push(input);
        updateButtons();
    }
    for (const value of initialArrayValue(schema)) {
        addItem(value);
    }
    addButton.addEventListener("click", () => {
        addItem(initialValue(schema.items ?? {}));
        onChange();
    });
    container.append(rows, addButton);
    return inputs;
}
function buildDynamicProperties(schema, rootSchema, container, onChange) {
    const section = document.createElement("div");
    section.className = "config-dynamic-properties";
    const fields = [];
    const rows = document.createElement("div");
    const addButton = document.createElement("button");
    addButton.type = "button";
    addButton.textContent = "Add property";
    addButton.addEventListener("click", () => {
        const row = document.createElement("div");
        row.className = "config-dynamic-row";
        const keyInput = document.createElement("input");
        keyInput.type = "text";
        keyInput.placeholder = "Name";
        keyInput.setAttribute("aria-label", "Property name");
        keyInput.addEventListener("input", onChange);
        const valueContainer = document.createElement("div");
        valueContainer.className = "config-dynamic-value";
        const resolved = resolveSchema(schema, rootSchema);
        const field = {
            name: "",
            schema: resolved,
            include: document.createElement("input"),
            children: [],
            keyInput
        };
        field.include.checked = true;
        if (schemaType(resolved) === "array"
            && resolved.items
            && ["integer", "number", "string", "boolean"].includes(schemaType(resolved.items) ?? "")) {
            field.arrayItemSchema = resolved.items;
            field.arrayInputs = buildArrayInputs(resolved, valueContainer, onChange);
        }
        else {
            field.input = createInput(resolved, valueContainer, onChange);
        }
        const removeButton = document.createElement("button");
        removeButton.type = "button";
        removeButton.textContent = "Remove";
        removeButton.addEventListener("click", () => {
            row.remove();
            fields.splice(fields.indexOf(field), 1);
            onChange();
        });
        row.append(keyInput, valueContainer, removeButton);
        rows.appendChild(row);
        fields.push(field);
        onChange();
    });
    section.append(rows, addButton);
    container.appendChild(section);
    return fields;
}
function initialValue(schema) {
    if (schema.default !== undefined) {
        return schema.default;
    }
    if (schema.enum?.length) {
        return schema.enum[0];
    }
    switch (schemaType(schema)) {
        case "object": return {};
        case "array": return [];
        case "boolean": return false;
        case "integer":
        case "number":
            return typeof schema.minimum === "number" ? schema.minimum : 0;
        default: return "";
    }
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
function resolveSchema(schema, root, resolvedRefs = new Set()) {
    let result = { ...schema };
    if (typeof schema.$ref === "string" && schema.$ref.startsWith("#/")
        && !resolvedRefs.has(schema.$ref)) {
        const reference = resolvePointer(root, schema.$ref);
        if (reference) {
            const nextRefs = new Set(resolvedRefs);
            nextRefs.add(schema.$ref);
            result = mergeSchemas(resolveSchema(reference, root, nextRefs), result);
        }
    }
    for (const inherited of schema.allOf ?? []) {
        result = mergeSchemas(resolveSchema(inherited, root, resolvedRefs), result);
    }
    delete result.$ref;
    delete result.allOf;
    return result;
}
function resolvePointer(root, reference) {
    let current = root;
    for (const segment of reference.slice(2).split("/")) {
        const key = segment.replace(/~1/g, "/").replace(/~0/g, "~");
        if (typeof current !== "object" || current === null || !(key in current)) {
            return undefined;
        }
        current = current[key];
    }
    return typeof current === "object" && current !== null
        ? current
        : undefined;
}
function mergeSchemas(base, extra) {
    const merged = { ...base, ...extra };
    if (base.properties || extra.properties) {
        merged.properties = { ...base.properties, ...extra.properties };
    }
    if (base.required || extra.required) {
        merged.required = [...new Set([...(base.required ?? []), ...(extra.required ?? [])])];
    }
    return merged;
}
