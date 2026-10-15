---
name: tidy
description: Audit and clean one .local_context/<feature_name>/ folder so CURRENT.md holds only current state, ARCHIVE.md holds the history verbatim, and IMPLEMENTATION_PLAN.md is coherent with git and reality. Run by the user as /local-context:tidy [feature_name].
argument-hint: [feature_name]
disable-model-invocation: true
---

# local-context:tidy

Brings one `.local_context/<feature_name>/` back to its contract:

- **`CURRENT.md`** — only what is true **now**: state, invariants, open items, next step.
- **`ARCHIVE.md`** — dated history, append-only, newest first. Moved text goes in **verbatim**.
- **`IMPLEMENTATION_PLAN.md`** — every task's status backed by git or a measurement, § START HERE
  matching HEAD / remote / next task, every filed follow-up a task or an index row.

If the project's `CLAUDE.md` / `CLAUDE.local.md` defines its own `.local_context/` rules, read
them first; they win over this file, and their per-project constraints (who runs tests, never
push, never commit X) carry into everything below.

**Nothing is lost** is the whole point. These files are the only record of why things were done.
So: back up first, move by script rather than retyping, and prove every move before and after.

## 0 — Pick the folder

- `$ARGUMENTS` names it (`tidy ruby_rails_upgrade`, `clean the ruby_rails_upgrade`) → use it. Match
  loosely (case, `-`/`_`, a unique prefix) and say which folder you matched.
- No argument → list the subfolders of `.local_context/` (project root: `git rev-parse
  --show-toplevel`, else cwd) with each one's `CURRENT.md` line count, and ask which one with
  `AskUserQuestion`. Recommend the largest or most recently modified, and say why.
- `.local_context` may be a symlink (git worktrees). Resolve it and write to the real path.

## 1 — Back up

Copy the three files to the session scratchpad (or `/tmp/local-context-tidy-<date>/`) before
reading anything else. Say where. All later edits are made on scratch copies first, then
installed with `cp`, then `cmp`-checked.

## 2 — Audit, read-only (two subagents, in parallel)

The files are often thousands of lines; reading them into the main context is expensive. Delegate
to two `general-purpose` subagents, both told **read-only, never edit**:

1. **CURRENT audit.** Map every heading with line range and size. Classify each section: (a) live
   state — keep; (b) history / closed-task narrative / measurement logs — move; (c) stale or
   contradicted — says something no longer true (old HEAD, "next task" already done, wrong push
   state, old version, old gate figure). For each (b), grep ARCHIVE for distinctive phrases, SHAs
   and numbers: already there or NOT. List contradictions between CURRENT and PLAN on
   load-bearing values with both `file:line`. List live facts buried inside (b) sections.
2. **PLAN coherence.** From the top to the current point: every task has a status (DONE + sha,
   CLOSED, ABANDONED, MOVED, NOT scope); every cited SHA exists (`git cat-file -t`) and its subject
   matches the task; "owed" / "uncommitted" / "in flight" notes that later work resolved; Done-when
   lines never marked met; references to sections that do not exist; follow-ups filed but never
   scheduled or indexed; § START HERE vs reality (`git log`, `git ls-remote origin <branch>`);
   version / ladder tables contradicting the tasks; commits on the branch the plan never cites
   (`git log <base>..HEAD`); not-yet-started tasks whose prerequisites have since changed.

Give each agent the facts it cannot know (current HEAD, what is next). Ask for compact output:
`file:line | kind | problem | evidence`. When they return, **spot-check 2–3 findings yourself**
against git and the files before trusting the report.

## 3 — Report, then wait for go

Tell the user, briefly: how many CURRENT lines are live vs history, the contradictions, what is
unindexed or mis-statused in the plan, anything that is not this feature's work (e.g. an unrelated
commit on the branch). Propose the cut and the fixes, recommend, and **wait for an explicit go**
— this rewrites the files the user relies on.

## 4 — Cut CURRENT.md

1. Snapshot the **whole** pre-cut CURRENT into an ARCHIVE entry, verbatim:
   ```
   python3 ${CLAUDE_SKILL_DIR}/scripts/lc_tools.py snapshot CURRENT.md <scratch>/current_entry.md \
     --title "<date> — CURRENT.md cut: the whole pre-cut file, verbatim" --reason "<why, counts>"
   ```
   Keep it whole rather than de-duplicating against older entries: "already archived" is only a
   phrase match, and a partial match silently loses detail. The script refuses unless the entry
   round-trips exactly to the source.
2. Build the new CURRENT in scratch: a rewritten header (state, HEAD, remote, gate, next steps —
   every value measured now, with the command that measured it), then the live sections copied
   **by line range with a script**, not retyped. Live facts buried in history sections get a short
   "Open items carried from closed tasks" section.
3. Fix every stale line in the kept text against the code / git, citing `file:line`. Where a kept
   section points at something that moved, point it at the archive entry.
4. Target: a file someone can act on without reading anything else. There is no line target, but
   if it is still over ~600 lines, look again for history.

## 5 — Fix the plan

1. If § START HERE is stale narrative, snapshot it (`--lines A:B`) into its own ARCHIVE entry and
   write a short current one: state, remote vs HEAD, next tasks in order, the rules, where the
   filed items live.
2. Apply the fixes with a script of exact `old → new` replacements, **asserting each `old` matches
   exactly once**. Mark statuses; never delete a task. Add index rows for unindexed follow-ups; add
   a "commits the plan did not cite" section if the audit found any.
3. Prove no section was lost:
   `python3 ${CLAUDE_SKILL_DIR}/scripts/lc_tools.py headings <backup>/IMPLEMENTATION_PLAN.md <scratch>/PLAN.md`
   (exit 0 = none missing).
4. Repoint references into CURRENT sections that moved:
   `python3 ${CLAUDE_SKILL_DIR}/scripts/lc_tools.py refs <PLAN> <new CURRENT> --repoint "<date> CURRENT cut"`
   Run it without `--repoint` first and check that the list is right.

## 6 — Install and verify

1. Write a short dated ARCHIVE entry for this session (what was cut, what was fixed, the counts).
2. `lc_tools.py prepend` each new entry onto ARCHIVE, **newest first**. It refuses if the old
   content changed.
3. `cp` the scratch CURRENT / PLAN into place, `cmp` each against its scratch copy, `wc -l` all
   three, and read back the top of each.
4. `git status --short` — the project tree must be unchanged (these files are gitignored).
   Never commit or push `.local_context/`.

## 7 — Tell the user

A few lines: line counts before → after, what was archived (and that it round-tripped), the plan
fixes by kind, anything that needs their decision, and where the backups are (say whether they
survive the session).
