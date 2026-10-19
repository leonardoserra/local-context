# Changelog

All notable changes to this project are documented in this file.

## 0.4.0 - 2026-10-19

- Changed
  - No Python needed: `local-context-tidy` proves its moves with standard shell tools (`sed`, `cmp`, `comm`) instead of
    `lc_tools.py`. Archive entries keep the same format: headings nested one level down, code fences untouched.
  - `local-context-continue` and `local-context-business-questions` prepend to `ARCHIVE.md` with `cat` and prove the
    old content is intact with `cmp`, even when `local-context-tidy` is not installed.
- Removed
  - `skills/local-context-tidy/scripts/lc_tools.py`.

## 0.3.0 - 2026-10-19

- Changed
  - Skills renamed to `local-context-<name>`, so they stay unique in agents with no plugin namespace (e.g. `new`
    clashed with Codex's own `new`). Claude Code: `/local-context:new` → `/local-context:local-context-new`, and so on.
    `.local_context/` folders need no change.
  - Skills run in any Agent Skills agent (Codex, OpenCode, Hermes, OpenClaw, …): script paths are relative to the
    skill folder instead of Claude's `${CLAUDE_SKILL_DIR}`, and option prompts fall back to a plain question.
  - Codex never invokes the skills on its own (`agents/openai.yaml`), as Claude Code already did.
  - README explains how each agent calls the skills and how to install them with `npx skills add
    leonardoserra/local-context`.

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
