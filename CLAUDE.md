# CLAUDE.md

## Version bump before pushing to main

Every push to `main` that changes the plugin (anything under `skills/` or `.claude-plugin/`) must bump the version first.
Installed copies only refresh when the version changes; `claude plugin update` skips same-version releases.

- Bump `version` in both `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`, keeping them identical.
- Use semver: patch for fixes, minor for new or changed skills, major for breaking changes to the `.local_context/` folder contract.
- Include the bump in the same commit (or the same push) as the change.
