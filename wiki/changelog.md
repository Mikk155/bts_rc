# Rules
When updating ``CHANGELOG.md`` we abide by certain rules in order for the website to show proper body sections and github releases to show only-changes since last version.

---

A date time with the format: ``DAY/MONTH/YEAR`` must be provided using ``# `` as prefix.

Sample:
```markdown
# 25/4/2026
```

Regular Expresion used by Python builders to identify if the date time stamp should be applied to the generated release.
```regex
"#\s+(\d{1,2})/(\d{1,2})/(\d{4})"
```

---

# Releases formatting

Content driven to github release will remain as-is Markdown.

---

# Web site formatting

| Prefix | HTML Equivalent | Example | Short description |
|---|---|---|---|
| ``- `` | ``<li>`` | ``- Fixed func door not opening at dormitories`` | "List" lines prefixed with a dot |
| ``## `` | ``<h2>`` | ``## Map update`` | Header. medium size |
| ``### `` | ``<h2>`` | ``### Dormitories`` | Header. small size |
| \`\` | ``<code>`` | - Fixed \`\`monster_panthereye\`\` | Code block normally shown in green if not a recognized programing language |
| ``**`` | ``<b>`` | ``- Fixed **func_door** not opening at dormitories`` | Bold text |
| None | ``<p> | | Default text |
| ``\t`` or single spaces | ``<pre>`` | | Basically just keeps leading white spaces. |

Even though HTML elements are not fully supported in Release's Markdown. HTML elements will make their way into the pages.

You can even target ``css`` classes, use href or anything that can fit into the member ``innerHTML`` of the changelog's ``div``.

For more information visit how it's done in ``src/docs/src/scripts/changelog.ts``
