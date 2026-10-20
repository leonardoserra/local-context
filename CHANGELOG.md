# Changelog

All notable changes to this project are documented in this file.

## 0.5.1 - 2026-10-20

- Changed
  - `local-context-continue` no longer uses caveman for commit messages, code comments, `.local_context` files or
    ticket comments: those stay plain prose, as caveman's own rules ask. Caveman is still offered for exploration and
    subagent prompts.
  - `local-context-business-questions` no longer names a specific Atlassian MCP call for reading ticket comments; it
    says comments often need a separate call in any MCP ticket tool.

## 0.5.0 - 2026-10-19

- Changed
  - New optional `BUSINESS.md` in `.local_context/<feature>/`: the feature's business rules only (scope, who gets or
    sees what, data, timing), whoever decided them. Created only when the work defines business behaviour, never for
    a pure bug fix or upgrade. A changed rule is replaced in place; the old wording goes to `ARCHIVE.md`.
  - `local-context-new` writes `BUSINESS.md` when the description states business rules; `local-context-continue`
    reads it and records business rules settled during a session there instead of in `CURRENT.md`.
  - `local-context-tidy` flags business rules in `CURRENT.md` and, after your go, moves them word for word into
    `BUSINESS.md` (checked with `cmp`).
  - `local-context-business-questions` no longer asks what the code, `BUSINESS.md` or the project docs (`README.md`,
    `DOCUMENTATION.md`, `CLAUDE.md`, `AGENTS.md`, …) already answer, to you or to the business; it cites the source
    instead. Every question it asks carries a recommended answer.
  - `local-context-business-questions` records answers in `BUSINESS.md`, with no split by who decided. Before, your own
    answers went to a "Positions taken by <user>" section of `CURRENT.md`; only technical positions stay there now.

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
