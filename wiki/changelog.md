# Changelog Formatting Rules

The changelog has two consumers: GitHub Releases and the project website. Keep the date headings in the format below so the release builder can recognize them.

## Date headings

Start each dated section with `# ` followed by `DAY/MONTH/YEAR`. One- or two-digit days and months are accepted.

```markdown
# 25/4/2026
```

The builder matches date headings with:

```regex
#\s+(\d{1,2})/(\d{1,2})/(\d{4})
```

## GitHub Releases

Release notes use the changelog section content as Markdown.

## Website rendering

The website uses a small, purpose-built line parser; it does not render full Markdown.

| Input | Website behavior |
|---|---|
| `# ` | Starts a dated section and flushes the previous section. |
| `- ` | Creates a list item. Consecutive items are grouped in a list. |
| `## ` | Creates an `<h2>` heading. |
| `### ` | Creates an `<h3>` heading. |
| `**text**` | Replaced with `<b>text</b>`. |
| `` `text` `` | Replaced with an inline `<code>` element. |
| `` ``text`` `` | Replaced with `<code class="terminal">text</code>`. |
| Other non-empty lines | Added as paragraphs. |
| A line starting with a space or tab | Wrapped in `<pre>` to preserve leading whitespace. |

Blank lines are ignored. Fenced code blocks and other Markdown syntax are not interpreted by this renderer. Content is inserted as HTML, so only put trusted, intentional markup in the changelog.

The implementation is in `src/docs/src/scripts/changelog.ts`.
