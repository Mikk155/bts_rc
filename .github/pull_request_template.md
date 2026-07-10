## Description
Provide a clear description of the changes made and the rationale behind them.

## Related Issues
Links to any issues resolved or related:
- Closes # (issue number)
- Fixes # (issue number)

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Optimization / Refactor (improving codebase efficiency or structure)
- [ ] Documentation update (improving guides, wiki, or comments)

## Verification Performed
Describe the manual/automated testing conducted to verify your changes:
1. Steps taken to test (e.g. "Started map `bts_rc_test_chamber`, collected `GEAR_1`, and checked if MOTD reflected change").
2. Server/client console logs (if applicable).

## Checklist
- [ ] My code follows the code style guidelines of this project (Allman braces, spacing inside parentheses).
- [ ] I have run `python src/main.py` to ensure all script files have been validated.
- [ ] I have updated the documentation changelog ``docs/page/changelog.md`` if my changes brings a relevant update.
- [ ] I have checked ``svencoop/scripts/maps/store/bts_rc.log`` to see there is not any logger entry with ``Critical`` or ``Error`` level.
- [ ] I have updated ``g_ScriptsVersion`` at ``scripts/maps/bts_rc/util/utils.as`` according to [Semantic versioning](https://semver.org/)
