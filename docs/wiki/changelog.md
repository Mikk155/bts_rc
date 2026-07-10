When updating ``docs/changelog.md`` we abide by certain rules in order for the website to show proper body sections and github releases to show only-changes since last version.

---

A date time with the format: ``DAY/MONTH/YEAR`` must be provided using ``# `` as prefix.
Sample:
```markdown
# 25/4/2026
```
Regular Expresion:
```regex
"#\s+(\d{1,2})/(\d{1,2})/(\d{4})"
```

---

Lines prefixed with ``- `` will use the html equivalent to ``<li>`` in the website.

---

Lines without any prefix will use the html equivalent to ``<p>`` in the website.
