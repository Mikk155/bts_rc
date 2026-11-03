# Credits

This project has two independent credit systems:

1. `docs/assets/credits.json` contains the contributor list used by the
   documentation tooling and the website.
2. `scripts/maps/bts_rc/credits.json` contains the captions displayed by the
   in-game `env_credits` entity.

Do not edit one file expecting the other system to change.

## Documentation and website credits

`docs/assets/credits.json` to add or
remove a contributor from the generated project credits. The file is a JSON
array with two supported entry formats:

```json
[
   "Contributor without a link",
]
```
> The first form stores only a display name.

```json
[
   [ "Contributor with a link", "https://example.com/profile" ]
]
```

> The second form stores a display name and a profile URL.

### Generated `AUTHORS.md`

`src/Tests/UpdateContributors.py` processes this file when running the local
build checks:

1. It sorts entries alphabetically, case-insensitively, using the name.
2. It preserves the sorted entries and writes the normalized list when its
   order differs from the source.
3. It writes the normalized JSON back to `docs/assets/credits.json`.
4. It generates `AUTHORS.md`.
5. Entries with URLs become Markdown links in `AUTHORS.md`; plain strings
   remain plain list items.

The maintainer table in `AUTHORS.md` is maintained separately by the generator.
Do not edit the generated contributor section manually. Run the normal project
tooling after changing the JSON so the generated files are updated. The
`Check` build type reports an error when the JSON or generated `AUTHORS.md` is
out of date.

### Website rendering

The website loads the same file as `assets/credits.json` from
`src/docs/src/scripts/contributors.ts`.

- A string is rendered as an additional credit without a profile.
- A two-item entry uses the first item as the display name and the second as
  the link.
- A valid GitHub URL is converted into a GitHub profile card, including the
  account avatar.
- A non-GitHub URL is shown as an additional linked credit.
- Invalid entries are ignored by the website loader.
- GitHub contributors obtained from the API and explicit credits are merged;
  explicit credits are marked as credits and sorted after API contributors.

The website may cache contributor data in the browser. Refresh or force a
reload when checking a recently changed list.
