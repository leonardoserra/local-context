# Changelog

All notable changes to this project are documented in this file.

## 0.2.0 - 2026-10-19

- Changed
  - New skill `/local-context:business-questions [feature | free text]`: checks where a feature really stands (docs
    against git, code and ticket), builds with you the list of decisions only the business can take, posts it bilingual
    on the ticket and records answers and positions in `.local_context`.

## 0.1.1 - 2026-10-16

- Fix
  - `continue` and `tidy` skill pages render on GitHub again: their `argument-hint` starting with `[` was read as a
    YAML list and broke the frontmatter.

## 0.1.0 - 2026-10-16

- Changed
  - First release: skills `new`, `continue`, `start` and `tidy` keep per-feature working memory in
    `.local_context/<feature>/` (`CURRENT.md`, `IMPLEMENTATION_PLAN.md`, `ARCHIVE.md`). The repo is its own plugin
    marketplace.
