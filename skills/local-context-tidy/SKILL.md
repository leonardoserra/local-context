---
name: local-context-tidy
description: Audit and clean one .local_context/<feature_name>/ folder so the current state holds only what is true now, the archive holds the history verbatim, business rules sit in the business folder, the plan is coherent with git and reality, and every ICM STATE.md index matches its folder. Offers to convert a flat pre-3.0.0 folder to ICM first; a folder kept flat is tidied as before. Run by the user as local-context-tidy [feature_name].
argument-hint: "[feature_name]"
disable-model-invocation: true
---

# local-context-tidy

Brings one feature folder `F` back to its contract: the current state holds only what is true **now**; history
sits in the archive **verbatim**, entries never edited or merged; task statuses are backed by git or a
measurement; business rules live only in the business folder. `_crm/` and other files (`API.md`) are out of
scope: never read, moved or deleted.

The project's `CLAUDE.md` / `CLAUDE.local.md` rules on `.local_context/` win over this file, with their constraints
(who runs tests, never push, never commit X); read them first.

**Nothing is lost** is the whole point: these files are the only record of why things were done. Back up, move
text with `sed` / `cat` (never retype), prove every move with `cmp`; GNU- and BSD-safe flags only. The scripts named below are sections of `<n>/ICM_OPS.md`
(`sed -n '/^## <name>/,/^## /p'`), read when the step runs; `<s>` = scratch dir.

## 0 — Pick the folder

- Named in the arguments → use it, matched loosely (case, `-`/`_`, unique prefix); say which. Never look for a
  folder named in an example.
- No argument → list `.local_context/`'s folders (root: `git rev-parse --show-toplevel`, else cwd; names starting
  with `_` skipped) with each one's current-state line count; ask with `AskUserQuestion` (a plain question without
  it), recommending the largest or most recently modified, and why.
- `.local_context` may be a symlink (worktrees): resolve it, write to the real path.

**Layout check**, before reading `F` or another feature folder the run writes: `ls -d F/.no_icm F/_* F/*.md 2>/dev/null`;
`<n>` = `<this skill folder>/../local-context-new`. No flat file (`CURRENT`, `IMPLEMENTATION_PLAN`, `ARCHIVE`,
`BUSINESS`, `CRM`, `CODE_REVIEW_MAPPING` `.md`) and no `.no_icm` → ICM: read `<n>/ICM.md`. `.no_icm` and no `_`
folder → legacy: `sed -n '/^## legacy/,/^## /p' <n>/ICM_OPS.md`. Otherwise → `<n>/ICM_CONVERT.md` first.
A conversion runs first, with its own proofs; then tidy runs on the ICM folder.

## 1 — Back up

First of all, copy what this run may change to `<s>` (the session scratchpad, or
`/tmp/local-context-tidy-<date>/`): `cp -R` `_current/`, `_implementation_plan/`, `_business/`, and
`_archive/STATE.md` (legacy: the flat files). Say where. Edits go to scratch copies, then `cp` into place, then `cmp`.

## 2 — Audit, read-only (two subagents, in parallel)

Delegate to two `general-purpose` subagents told **read-only, never edit**; give each the paths it reads, what it
cannot know (current HEAD, what is next) and the plan status values from ICM.md. Ask for
`file:line | kind | problem | evidence`. Meanwhile run the `state check` (ICM only).

1. **Current state.** Map every heading of `_current/STATE.md` with line range and size. Class each section:
   (a) live — keep; (b) history, closed-task narrative, measurement logs — move; (c) stale or contradicted (old
   HEAD, "next task" already done, wrong push state, old version or gate figure); (d) business rule — what the
   feature must do for users, clients or the company — move to `_business/`; (e) a decision or open question as
   prose — move to its own file. For each (b), `archive find` its distinctive phrases, SHAs, numbers: there or
   NOT. An `open` question a decision answers. Contradictions with the plan on load-bearing values, both
   `file:line`. Live facts buried in (b). A `STATE.md` over 80 prose lines: what to move into pieces.
2. **Plan.** The plan index, then the task files, from the top to the current point: every task has a status; a
   task file with a status suffix, a `**Depends on**` line or a pointer back to its `STATE.md` (the row wins
   unless git proves it wrong; the line goes); every cited SHA exists (`git cat-file -t`) with a matching subject;
   "owed" / "uncommitted" / "in flight" notes later work resolved; Done-when lines never met; references to
   sections that do not exist; follow-ups never scheduled or indexed; § START HERE vs `git log` and
   `git ls-remote origin <branch>`; version tables contradicting the tasks; branch commits the plan never cites
   (`git log <base>..HEAD`); unstarted tasks whose prerequisites changed.

Spot-check 2–3 findings against git and the files before trusting the report.

## 3 — Report, then wait for go

Briefly: current-state lines live vs history, contradictions, what is unindexed or mis-statused, the state check,
anything not this feature's work. Propose the cut and the fixes, recommend, and
**wait for an explicit go** — this rewrites the files the user relies on.

## 4 — Cut the current state

1. `snapshot` the **whole** pre-cut `_current/STATE.md` into its own archive entry. Keep it whole rather than
   de-duplicate against older entries: "already archived" is only a phrase match.
2. Build the new one in scratch: a header measured now (state, HEAD, remote, gate, next steps, each with its
   command), then the live sections **by line range** (`sed -n 'A,Bp'`). Live facts from history sections go in a
   short "Open items carried from closed tasks" section.
3. (d) → `business rule set`; (e) → `decision add` / `question add` (legacy: § Decisions / § Open questions); all
   copied by line range, proved with `sed -n 'A,Bp' <backup> | cmp - <the range in the target>`. A rule that
   contradicts a recorded one is not merged: ask which holds.
4. Fix every stale kept line against the code / git, citing `file:line`; point what moved at the archive entry.
5. The result is actionable on its own; over 80 prose lines, look again for history.

## 5 — Fix the plan

1. A stale-narrative § START HERE: `snapshot` it (a part) into its own entry and write a short one: state, remote
   vs HEAD, next tasks in order, the rules, where the filed items live.
2. Fixes as exact `old → new` replacements, each `old` matching once (`grep -cF` = 1). Statuses: `plan mark`. Never
   delete a task, its file or its row. Unindexed follow-ups: `plan add task`; a task file with no row gets one; a row
   with no file is reported, never invented. Commits the plan never cites: a section in its `STATE.md`.
3. No section lost: `heading keys` of the backup plan and the scratch plan (FILE = `cat STATE.md [0-9]*.md` per side; legacy: `IMPLEMENTATION_PLAN.md`).
4. References into current-state sections that moved
   (`` grep -rhoE '`(_current/STATE|CURRENT)\.md` § [^|;,)*`]*' <plan files> | sort -u `` against the new heading
   keys) point at the snapshot entry, same section, with the N `archive add` will give it (legacy:
   `` `ARCHIVE.md` (<date> CURRENT cut) § <section> ``), applied as in step 2.

## 6 — Install and verify

1. A short session entry: what was cut and fixed, the counts.
2. `archive add` each new entry, oldest first: snapshots, then the session entry. Existing entries are never touched.
3. `cp` the scratch files into place; `cmp` each new or changed file against its scratch copy; `wc -l` each; read
   back the top of each. The `state check` (ICM only) prints nothing.
4. `git status --short`: the project tree is unchanged. Never commit or push `.local_context/`.

## 7 — Tell the user

A few lines: the conversion if any, line counts before → after, what was archived (round-tripped), what moved
where, the plan fixes by kind, the state check, what needs their decision, where the backups are (and whether they
survive the session).
