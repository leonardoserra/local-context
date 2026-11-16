# Changelog

All notable changes to this project are documented in this file.

## 4.0.1 - 2026-11-16

- Changed
  - The code review worktree (`local-context-crn`) now shows every file at the reviewed branch head. Only the group's
    changes are staged, as before. Before, files outside the group stayed at the merge base, so a caller or helper the
    group depends on showed old code or was missing, and go-to-definition landed on stale code.
  - Editing a file outside the group no longer needs `crn.sh stage` first: it is already at head. `stage` is kept as a
    no-op for older callers.
  - The group explanation now names the code outside the group that the group calls or is called from, with
    `path:line`. Every cited line is checked against the review worktree before it is shown, and `<xplain>` notes are
    added first, so the line numbers match what the IDE shows.
  - `local-context-code-review-mapping` maps the fetched remote branch head, warns when the local checkout is
    elsewhere, and may add a `Context:` line per group listing that out-of-group code (at most 5 entries, each checked).
  - The README no longer carries per-version upgrade notes. They live in this file.

## 4.0.0 - 2026-11-16

- Changed
  - Each feature folder now records its layout in a `.icm` file: `true` for the ICM layout, `false` for the old flat
    layout. Before, only a kept flat folder had a marker, `.no_icm`. The skills read `.icm` and skip the layout check
    on every later run. `local-context-new` and `local-context-icm-migrate` write `true`. "Keep old layout" writes
    `false`.
  - A folder without `.icm` gets the layout check once, then `.icm` is written. A 3.x ICM folder gets `true` with no
    question. A 3.x `.no_icm` folder gets `false`, and its `.no_icm` is deleted. A `.no_icm` beside `_` folders with
    no flat file now becomes ICM silently. Before, it asked "Delete .no_icm" / "Keep it".
  - Delete `.icm` to be asked again. Before, it was `.no_icm`.
  - `.icm` = `false` next to a `_current/` folder (for example, an older install migrated it) sends the skill back to
    the layout check instead of reading flat files that are gone.
  - `local-context-tidy` still looks for flat files that an older install wrote into a `true` folder, and offers to
    fold them in. The other skills no longer inspect the folder.
  - Every agent install (Claude Code, Codex, …) must be updated to 4.0.0. A 3.x install does not read `.icm` and asks
    again about every folder kept on the old layout.
- Fix
  - The layout check no longer misses flat files when the shell is zsh. Its `ls -d F/_* F/*.md` aborted with "no
    matches found" and listed nothing, so a flat folder could be taken as ICM. It now uses `ls -A`.
  - `crn.sh` no longer suggests passing the same map path that was just reported missing. It now says "run
    local-context-code-review-mapping first" and suggests `_crm` or `CRM.md` only when that map exists.

## 3.1.0 - 2026-11-16

- Added
  - New skill `local-context-icm-migrate` migrates a flat pre-3.0.0 feature folder (`CURRENT.md`,
    `IMPLEMENTATION_PLAN.md`, `ARCHIVE.md`, `BUSINESS.md`, `CRM.md`) to the ICM layout without asking anything. It
    also migrates every folder the feature spans: the parent, sub-features and same-name folders in sibling repos and
    submodules. Run it from a skill's layout check or directly as `local-context-icm-migrate [feature_name]`.
  - The migration decides every unusual shape by fixed rules instead of stopping to ask:
    - Task headings with ids like `P3b` or out of order: files are numbered by position and the id stays in the title.
    - Any task status (✅, 📝, 🟡, ⏸, `done-uncommitted`, "superseded by …", or unknown text) moves into the plan
      table.
    - Wrapped `**Depends on**` lines move whole into the Depends on column.
    - Session logs, task outcomes and reference tables between tasks go to an archive entry, the task file or the
      closing part of the plan. They never become task rows.
    - Decision sections with other headings ("Decisions (<who>, <date>)", "Agreed", "Settled") become decision files.
    - A `BUSINESS.md` with no themes becomes `_business/STATE.md` with an empty themes table.
    - An `ARCHIVE.md` with no dated heading is kept whole.
  - Only a failed `cmp` proof stops a folder, and that folder is left untouched. The report names the proof and its
    output.
  - Pointers are rewritten inside each folder, and then across folders once all are migrated. References to a folder
    still on the flat layout are left as they are.
  - The migration ends with one report per run. It lists the pieces and proofs per folder, every rule-based decision,
    and the pointers changed or left. It also lists follow-ups: `STATE.md` files over the 80-line limit (run
    `local-context-tidy`) and lines in `CLAUDE.md` / `CLAUDE.local.md` / `AGENTS.md` that still name flat files.
    Those files are never edited.
- Changed
  - On a flat folder, every skill now asks one question: "Migrate (Recommended)" or "Keep old layout". It names every
    folder of the feature at once, not one question per folder. Migrate hands off to `local-context-icm-migrate`, then
    the skill goes on with its own work on the ICM layout. Keep still writes `.no_icm`.
  - Folders that mix flat files and `_` folders are still offered Migrate, which folds the flat files in. Keep stops
    the run there and writes nothing, as before.
  - `local-context-new/ICM_CONVERT.md` is deleted, not left as a stub. The migration rules now live in
    `local-context-icm-migrate/`, which an agent reads only when it migrates. `ICM.md` keeps a one-line pointer.

## 3.0.0 - 2026-11-16

- Changed
  - Feature folders now use the ICM layout (Interpretable Context Methodology). Each multi-part file is a `_` folder
    with one file per piece and a `STATE.md` index: `_current/` (with `_decisions/` and `_questions/`), `_business/`
    (one file per theme), `_implementation_plan/` (one file per task), `_archive/<YYYY_MM_DD>/<N>.md` and `_crm/` (one
    file per review group). Before, each was one growing file: `CURRENT.md`, `BUSINESS.md`, `IMPLEMENTATION_PLAN.md`,
    `ARCHIVE.md`, `CRM.md`. `local-context-new` creates every new folder this way.
  - Skills read the `STATE.md` indexes first and open only the pieces they need. On a large feature (about 25 tasks,
    30 decisions) this cuts tokens by 14–38% on `continue`, `business-questions` and `tidy`, and by about 20% on the
    navigator. A small feature costs about the same as 2.0.0.
  - Task status, the review mark (`✅ reviewed`) and question status now live only in the `STATE.md` tables. Before,
    they were suffixes on the headings.
  - The first time a skill opens a 2.0.0 flat folder, it asks once: "Convert (Recommended)" or "Keep old layout".
    Keep writes a `.no_icm` file and the skills keep using the flat files in that folder; delete `.no_icm` to be asked
    again. Convert makes no backup: every piece is proved with `cmp` against the flat file, the flat files are deleted
    only after every proof passes, and a failed proof leaves the folder untouched. Pointers in live files are
    rewritten to the new paths; archive entries are never edited, and `_archive/STATE.md` gets a line mapping the old
    file names to the new ones.
  - `local-context-tidy` also checks that every `STATE.md` index lists exactly the files in its folder and that its
    prose stays under 80 lines.
  - `crn.sh` takes `.local_context/<feature>/_crm` as the map, or `CRM.md` in a `.no_icm` folder. A wrong path now
    stops with "no map: …; this folder uses the ICM layout: pass …/_crm" or "not a map folder: …; pass …/_crm".
  - Every agent install (Claude Code, Codex, …) must be updated to 3.0.0 before use on a converted folder: an older
    install writes flat files next to the `_` folders. The skills spot such a mixed folder and offer to fold the flat
    files in.

## 2.0.0 - 2026-11-13

- Changed
  - The code review map is now `.local_context/<feature>/CRM.md`. Before, it was `CODE_REVIEW_MAPPING.md`. Running
    `local-context-code-review-mapping` again writes `CRM.md` and deletes the old file. Until then, the navigator stops
    with "no map: …CRM.md, only the pre-2.0.0 …/CODE_REVIEW_MAPPING.md: regenerate it
    (local-context-code-review-mapping) or rename it to CRM.md".
  - `local-context-code-review-mapping-navigator` is now `local-context-code-review-navigator`, so the `crn` alias
    matches its initials. The alias `local-context-crn` is unchanged.
  - Reading notes in review worktrees are now `<xplain>…</xplain>` comments that can span several lines (e.g.
    `# <xplain>` … `# </xplain>`). Before, each note was a single `XPLAIN: ...` line. `apply` still strips them, and
    notes alone still never count as pending edits. A note with no `</xplain>` is treated as a review edit.
  - Review worktrees left from 1.x still hold old `XPLAIN:` lines, and these now count as review edits. Discard them,
    or delete those lines before applying.

## 1.6.0 - 2026-11-13

- Changed
  - `local-context-code-review-mapping` splits a big group (around 10 files in one repo) into subgroups when its files
    hold ideas a reviewer can read apart (e.g. `Report templates / list query` and `Report templates / CSV export`).
    Each subgroup has its own files, specs and `open:` command, and sits next to its siblings. Files that form one idea
    stay one group. Before, a capability was always one group, however many files it held.

## 1.5.0 - 2026-11-11

- Changed
  - `local-context-crn` opens all of a group's worktrees in one IDE window (e.g. `code "<wt1>" "<wt2>"`). Before, it
    opened one window per repo.
  - Each group's explanation now ends with that IDE command in a `sh` block, so you can copy it and reopen the group.
  - In the review worktrees, `local-context-crn` adds a short `XPLAIN: <explanation>` comment above each run of
    functions, methods, classes or constants that share a domain concept. The notes exist only in the worktree:
    `apply` strips them before copying your edits to your checkout, they never count as pending edits, and
    `cleanup` deletes them with the worktree. A comment line you write as `XPLAIN: ...` during review is stripped too.
  - The docs now say it outright: the `local-context-crn` alias means code-review-navigator, and the `<crn>` tag means
    code-review-note.

## 1.4.0 - 2026-11-11

- Changed
  - `local-context-code-review-mapping` reviews lockfiles, generated files and config like any other change. When one
    domain's mechanical change is too big to follow mixed with the rest, it gets its own group (e.g.
    `Other / mechanical — dependencies`, `Other / mechanical — CI`). Before, everything mechanical went into a single
    `Other / mechanical` group. These groups still come last.
  - `local-context-crn` cites files as `<repo>/path:line`, the same paths the map lists, in its group explanation,
    its answers and its `<crn>` report. Before, it could cite paths relative to the review worktree, which matched
    neither the map nor your checkout.
  - In an `Other / mechanical` group, `local-context-crn` explains each change in one line, what changed and why
    (e.g. the lockfile follows the Gemfile bump). It flags only surprises: a dependency nobody asked for, a config
    value changed by hand, a generated file out of sync with its source.

## 1.3.0 - 2026-11-11

- Changed
  - `local-context-crn` now explains each group before you read it. Below the group's file lists, it writes one
    section per repo: what the group's changes do as the code runs (behaviour, flow, business rules), the files
    involved and key spots as `path:line`. It checks this against `BUSINESS.md` and `IMPLEMENTATION_PLAN.md` and
    flags wrong patterns, broken or missed rules and surprising behaviour, so you can review from the explanation
    and open the code only to verify.

## 1.2.0 - 2026-11-11

- Changed
  - `local-context-new` can now create a feature inside another one when you ask for it (e.g. a feature split into
    subtasks): `.local_context/<parent>/<sub_feature>/`. The parent's `CURRENT.md` keeps what the subtasks share.
    Folders stay flat unless you ask. `local-context-continue` accepts a `<parent>/<sub_feature>` path and reads the
    parent's `CURRENT.md` for the shared part.
  - A feature that spans several repos gets a folder of the same name in each repo, each holding only its own repo's
    scope. A fact is written once and cited elsewhere as `<path>/CURRENT.md:<line>` instead of being copied.
    `local-context-continue` keeps those pointers right when lines move.

## 1.1.1 - 2026-11-10

- Changed
  - `CODE_REVIEW_MAPPING.md` now lists each group's files under the repo's name (e.g. `api:`, `web:`), in the header
    table's order, and each `open:` command sits under a `# <repo>` comment. Before, the lists were labelled
    `backend:` and `frontend:`, which did not fit a library, an engine or a repo holding both. `local-context-crn`
    shows the same labels. Regenerate the map with `local-context-code-review-mapping` to get them.

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
