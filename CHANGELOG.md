# Changelog

All notable changes to this project are documented in this file.

## 1.1.0 - 2026-11-09

- Changed
  - `local-context-crn` now asks, after each group you approve, whether to remove the review worktrees, naming
    their paths (e.g. `~/.cache/local-context-crn/<project>/<feature>/<repo>`). Say yes when you stop for the
    day; the next group recreates them. It then asks whether to open the next group instead of opening it
    straight away. Before, removal was offered only after the last group.
  - Removing the review worktrees also removes the feature's now empty folder under `~/.cache/local-context-crn/`.
  - A `crn.sh` call with the map missing or out of place (e.g. `crn.sh reviewed 1`) now says the map always comes
    first. Before, it only printed "no map: 1".
  - The README examples use a Rust feature (`axum_migration`) and three Rust `<crn>` comments: two instructions
    and one question.

## 1.0.2 - 2026-11-09

- Changed
  - `local-context-crn` now remembers approved groups. On your OK for a group, its heading in
    `CODE_REVIEW_MAPPING.md` gets ` ✅ reviewed`. Run `local-context-crn <feature>` again later (the next day, say)
    and it starts at the first group not yet reviewed, skipping the marked ones. Before, it always started at
    group 1.
  - With every group marked, it says so and asks whether to review again from group 1 or finish. A group number
    (`local-context-crn <feature> 4`) still opens that group, reviewed or not.
  - Regenerating the map with `local-context-code-review-mapping` clears the marks: the branches moved, so the
    review starts over.

## 1.0.1 - 2026-11-09

- Changed
  - The README has a new guide, "Reviewing a large merge request": how to map a feature's changes with
    `local-context-code-review-mapping`, then review them group by group with `local-context-crn` (IDE choice,
    review worktrees, `<crn>` comments, applying edits on OK).

## 1.0.0 - 2026-11-09

- Changed
  - New skill `local-context-code-review-mapping-navigator` (alias `local-context-crn`), e.g.
    `/local-context:local-context-crn <feature>`, reviews a feature's `CODE_REVIEW_MAPPING.md` one group at a time.
    For each group it opens your IDE on a throwaway worktree per repo (under `~/.cache/local-context-crn/`) where
    only that group's changes show, as staged changes, so the IDE's changes view reads like a small merge request.
    It asks once which IDE you use and finds its command-line launcher: on PATH, else from the web, else it asks
    you for the path. With two repos in a group it opens two windows.
  - While you review, ask questions, ask for edits, or leave comments in the code such as
    `# <crn> use a better name for the const </crn>` and say "read the crn": each one is done or answered, then
    removed. Edits stay in the review worktree, next to the branch's staged changes, until you say OK. Only
    `<crn>` comments added during the review count; one already in the branch's code is ignored.
  - On OK the edits are applied to the feature branch checkout, uncommitted, and the next group opens. Give a
    group number (`local-context-crn <feature> 4`) to review only that group. The navigator never commits.
  - `local-context-code-review-mapping` now states how the map names repos: the path from the project root, and
    the root repo by its folder name. The navigator reads the map this way.

## 0.6.1 - 2026-11-09

- Changed
  - `local-context-code-review-mapping` now gives, for each group of the map, one command that opens all its backend
    files and one that opens all its frontend files at once (e.g. `code "/repo/app/models/a.rb" "/repo/spec/a_spec.rb"`).
    Specs open with the side they test. VS Code is the default; add `open with zed`, `cursor`, `finder` or `explorer`
    to the call to get commands for those instead. The commands are written in `CODE_REVIEW_MAPPING.md` and printed
    with every group at the end of the run.

## 0.6.0 - 2026-11-09

- Changed
  - New skill `local-context-code-review-mapping` (`/local-context:local-context-code-review-mapping <feature>`) writes
    `.local_context/<feature>/CODE_REVIEW_MAPPING.md`: a reading map of every file the feature's branches change,
    across a container repo and its submodules, grouped by functionality with backend and frontend files together and
    ordered for reading (foundations first). It checks that every changed file is mapped and lists files that sit in
    more than one group. It maps only; it does not review the code.
  - `CODE_REVIEW_MAPPING.md` is a new optional file of the folder contract. It is derived from the branches and
    regenerated on every run; `local-context-tidy` never reads, merges or deletes it.

## 0.5.2 - 2026-10-21

- Changed
  - Every skill now takes the feature folder only from your arguments. Before, `local-context-continue` could open
    `ruby_rails_upgrade` even when you named another folder or none, because the skill's own examples used that name.
    Other skills had the same risk with `report_mailing_list` and similar example names. All examples now use a
    `<feature_name>` placeholder.

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
