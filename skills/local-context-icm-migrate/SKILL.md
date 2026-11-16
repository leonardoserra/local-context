---
name: local-context-icm-migrate
description: Migrate a flat pre-3.0.0 .local_context/<feature_name>/ folder (CURRENT.md, IMPLEMENTATION_PLAN.md, ARCHIVE.md, BUSINESS.md, CRM.md) to the ICM layout, together with every folder the feature spans, without asking anything — every piece cut with sed and proved with cmp, every unusual shape decided by fixed rules — and return one report. Run by the other local-context skills when the user picks Migrate in their layout check, or by the user as local-context-icm-migrate [feature_name].
argument-hint: "[feature_name or folder path]"
disable-model-invocation: true
---

# local-context-icm-migrate

Converts a flat feature folder `F`, and every folder its feature spans, to the ICM layout (`<n>/ICM.md`, `<n>` =
`<this skill folder>/../local-context-new`). **Autonomous**: it asks nothing and never pauses for a go. The calling
skill's layout check already put its one question; run directly, the call is the go. Every shape a file takes is
decided by the rules here and in `STEPS.md` (next to this file, by section: `sed -n '/^## <name>/,/^## /p' STEPS.md`;
§ helpers first, every worker): rules 1–4 § plan, 5 § current, 6 § business, 7 § archive, 8 § crm, 9 § pointers,
10 § across, the mixed case § fold.
Formats: `sed -n '/^## F: <name>/,/^## F: /p' <n>/ICM_FORMATS.md`; operations: `<n>/ICM_OPS.md` by section. The
project's `CLAUDE.md` / `CLAUDE.local.md` rules on writing `.local_context/` apply to what this skill writes: read
them first. Examples here are shapes (`P3b`, `<other repo>`, `<date>`), never values to match.

Flat set: `CURRENT.md`, `IMPLEMENTATION_PLAN.md`, `ARCHIVE.md`, `BUSINESS.md`, `CRM.md`, `CODE_REVIEW_MAPPING.md`.

## 0 — Scope and safety (rule 0)

- **Every folder the feature spans**, migrated in this run: `F`; its parent and sub-features; same-name feature
  folders in sibling repos and submodules of the project (`git submodule status`, `ls */.local_context/<feature>`,
  the root one). Per folder: flat files and no `_` folder → convert; flat files beside `_` folders → § fold;
  ICM → not migrated, its live files join § across; `.no_icm` → untouched. Repos = each folder's
  `git rev-parse --show-toplevel`; they serve the commit check (rule 7) and the qualifier list (rule 9).
- **One worker per folder.** Folders may run in parallel, one `general-purpose` subagent each, given: the folder,
  this file's and `STEPS.md`'s paths, the repo list, the qualifier list, today's date. The orchestrator (the agent
  running this skill) alone runs § across, and only after every folder is installed.
- **Proof first, install second.** Every piece is cut with `sed -n 'A,Bp'`, never retyped. Before any piece is
  moved, merged or reordered, `cat` all pieces in their original order and `cmp` the result against the source
  (after the documented stripping); only then assemble the new order. Every proof prints nothing.
- **The only reason to abort is a failed proof.** That folder is left untouched: nothing installed (`_` folders
  copied by a failed install are removed: they did not exist before), nothing deleted. The report names the proof
  and its output. A file's unusual shape is never a reason to stop: rules 1–8 decide it. Other folders go on.
- **Files outside the ICM set** (any other `*.md` in the folder: a separate plan, an API contract): not converted,
  moved or deleted; pointer rewrites (rules 9–10) still apply inside them.
- **No git writes.** Never `git add`, commit or push; `.local_context/` is never committed. `git cat-file` and
  `git rev-parse` only.
- **Project instruction files** (`CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.md`, `.claude/CLAUDE.md`) naming flat
  files are never edited: `grep -nE '(CURRENT|BUSINESS|ARCHIVE|IMPLEMENTATION_PLAN|CRM)\.md'` over those files in each repo;
  the report lists each `file:line`.

## 1 — Per folder (worker)

1. **Scratch**: `s=<scratchpad>/icm-<repo>-<folder path from .local_context, / → _>`, made with `mkdir "$s"`, not
   `-p`: it fails when the folder exists; then pick a new name, never reuse one. Every `_` folder is built in `$s/`.
2. **Cut and prove** each flat file present, in this order, each by its `STEPS.md` section: `archive` (none →
   `$s/_archive/STATE.md` as § archive says), `plan`, `current`, `business`, `crm`. Each writes its lines of
   `$s/anchors.tsv` (§ pointers) and its decisions to `$s/notes.md` (the report and the archive entry read it).
   A mixed folder: § fold instead.
3. **Install**, once every proof passed: `cp -R $s/_<x> F/ && diff -r $s/_<x> F/_<x>` per `_` folder.
4. **Pointers inside the folder**: § pointers.
5. **Return** to the orchestrator: installed yes/no, `$s`, `$s/notes.md`, the references § pointers left for
   § across, and any failed proof with its output.

## 2 — Pointers across folders (orchestrator)

After every worker returned: § across, over every installed folder. The flat files are still in place.

## 3 — Finish (orchestrator, rule 11)

Per installed folder:

1. **Over-limit `STATE.md`**: ICM_OPS.md § state check. Prose over the limit is not trimmed here; the report
   recommends `local-context-tidy`.
2. **One archive entry**, ICM_OPS.md § archive add, dated today, Commits `—`, title `converted to ICM`. Body, in the
   project's style for `.local_context` writing: per flat file the pieces made and the proofs passed; every rule
   2/4/5/6 decision (each stripped task status verbatim with its Status, unknown statuses, placed sections,
   theme-less `BUSINESS.md`); the files whose pointers changed; for § fold, its verbatim blocks.
3. **Delete the flat files** (the flat set only), now that install and both pointer passes succeeded:
   `rm F/<flat files>`. Files outside the ICM set stay (rule 0).

## Report

Returned to the calling skill, which tells the user:

- **Per folder:** installed yes/no; per flat file, the piece counts and the proofs passed.
- **Decisions taken under rules 2, 4, 5, 6**, one line each.
- **Pointers:** files changed; references left on purpose (quoted archive titles, historical wording, non-ICM
  targets, stale anchors).
- **Follow-ups for the user:** over-limit `STATE.md` files (→ `local-context-tidy`); project instruction files
  naming flat files (`file:line`).
- **Any aborted folder:** the failed proof and its output.
