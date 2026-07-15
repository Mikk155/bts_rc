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

---

Lines prefixed with ``- `` will use the html equivalent to ``<li>`` in the website.

---

Lines prefixed with ``## `` will use the html equivalent to ``<h2>`` in the sebsite.

---

Lines prefixed with ``### `` will use the html equivalent to ``<h3>`` in the website.

---

Content surrounded by double \`\` will use the html equivalent to ``<code>`` in the website.

---

Content surrounded by double ``*`` will use the html equivalent to ``<b>`` in the website.

---

Lines without any prefix will use the html equivalent to ``<p>`` in the website.

---
