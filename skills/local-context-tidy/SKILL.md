---
name: local-context-tidy
description: Audit and clean one .local_context/<feature_name>/ folder so CURRENT.md holds only current state, ARCHIVE.md holds the history verbatim, business rules sit in the optional BUSINESS.md, and IMPLEMENTATION_PLAN.md is coherent with git and reality. Run by the user as local-context-tidy [feature_name].
argument-hint: "[feature_name]"
disable-model-invocation: true
---

# local-context-tidy

Brings one `.local_context/<feature_name>/` back to its contract:

- **`CURRENT.md`** — only what is true **now**: state, invariants, open items, next step.
- **`ARCHIVE.md`** — dated history, append-only, newest first. Moved text goes in **verbatim**.
- **`IMPLEMENTATION_PLAN.md`** — every task's status backed by git or a measurement, § START HERE
  matching HEAD / remote / next task, every filed follow-up a task or an index row.
- **`BUSINESS.md`** *(optional)* — the feature's business rules only, no technical ones. Business
  rules found in CURRENT move here.

If the project's `CLAUDE.md` / `CLAUDE.local.md` defines its own `.local_context/` rules, read
them first; they win over this file, and their per-project constraints (who runs tests, never
push, never commit X) carry into everything below.

**Nothing is lost** is the whole point. These files are the only record of why things were done.
So: back up first, move text with `sed` / `cat` rather than retyping, and prove every move with
`cmp`. Only standard shell tools are used (`sed`, `grep`, `sort`, `comm`, `cat`, `tail`, `wc`,
`cmp`, `cp`), with flags that work in both GNU and BSD/macOS versions.

**Fence-aware heading rule.** Archived text is nested one level down, so its headings do not
collide with ARCHIVE's own `## <date>` entries. Headings inside ` ``` ` code fences are left alone:

```sh
sed '/^```/,/^```/!s/^#/##/' IN > OUT     # demote: every line starting with # outside fences
sed '/^```/,/^```/!s/^##/#/' IN > OUT     # promote back (round-trip check)
```

**Heading keys** of a file, for comparing sections (status suffixes ignored):

```sh
sed '/^```/,/^```/d' FILE | grep '^#' | sed -E 's/^#+ *//; s/ — .*| ✅.*| ⛔.*| ⏸.*//' | LC_ALL=C sort -u > KEYS
```

## 0 — Pick the folder

- The arguments name it (`tidy <feature_name>`, `clean the <feature_name>`) → use it. Match
  loosely (case, `-`/`_`, a unique prefix) and say which folder you matched. `<feature_name>` is a
  placeholder: never look for a folder named in an example.
- No argument → list the subfolders of `.local_context/` (project root: `git rev-parse
  --show-toplevel`, else cwd) with each one's `CURRENT.md` line count, and ask which one with
  `AskUserQuestion` (or a plain question if the agent has no such tool). Recommend the largest or most recently modified, and say why.
- `.local_context` may be a symlink (git worktrees). Resolve it and write to the real path.

## 1 — Back up

Copy the three files (and `BUSINESS.md`, if present) to the session scratchpad (or `/tmp/local-context-tidy-<date>/`) before
reading anything else. Say where. All later edits are made on scratch copies first, then
installed with `cp`, then `cmp`-checked.

## 2 — Audit, read-only (two subagents, in parallel)

The files are often thousands of lines; reading them into the main context is expensive. Delegate
to two `general-purpose` subagents, both told **read-only, never edit**:

1. **CURRENT audit.** Map every heading with line range and size. Classify each section: (a) live
   state — keep; (b) history / closed-task narrative / measurement logs — move; (c) stale or
   contradicted — says something no longer true (old HEAD, "next task" already done, wrong push
   state, old version, old gate figure); (d) business rule — what the feature must do for users,
   clients or the company, not how it is built — move to `BUSINESS.md`. For each (b), grep ARCHIVE for distinctive phrases, SHAs
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

1. Snapshot the **whole** pre-cut CURRENT into an ARCHIVE entry, verbatim (`<s>` = scratch dir):
   ```sh
   cp CURRENT.md <s>/src.md                  # a part only: sed -n 'A,Bp' FILE > <s>/src.md
   [ -z "$(tail -c1 <s>/src.md)" ] || echo >> <s>/src.md      # ensure a final newline
   sed '/^```/,/^```/!s/^#/##/' <s>/src.md > <s>/body.md
   sed '/^```/,/^```/!s/^##/#/' <s>/body.md | cmp - <s>/src.md   # round-trip: must print nothing
   { printf '## %s\n\n%s\n\n--- begin verbatim ---\n\n' "<date> — CURRENT.md cut: the whole pre-cut file, verbatim" "<why, counts>"
     cat <s>/body.md; printf -- '--- end verbatim ---\n\n'; } > <s>/current_entry.md
   sed -n '/^--- begin verbatim ---$/,/^--- end verbatim ---$/p' <s>/current_entry.md | sed '1,2d;$d' | cmp - <s>/body.md
   ```
   Both `cmp` must print nothing; otherwise stop and report. Keep it whole rather than
   de-duplicating against older entries: "already archived" is only a phrase match, and a partial
   match silently loses detail.
2. Build the new CURRENT in scratch: a rewritten header (state, HEAD, remote, gate, next steps —
   every value measured now, with the command that measured it), then the live sections copied
   **by line range with `sed -n 'A,Bp'`**, not retyped. Live facts buried in history sections get a short
   "Open items carried from closed tasks" section.
3. Business rules (class d) go to a scratch `BUSINESS.md` (from `local-context-new`'s template if
   the feature has none), copied **by line range with `sed -n 'A,Bp'`** under a theme heading, and
   leave the new CURRENT. Prove each copy: `sed -n 'A,Bp' <backup>/CURRENT.md | cmp - <the range in
   BUSINESS.md>`. A rule that contradicts one already in `BUSINESS.md` is not merged: ask which holds.
4. Fix every stale line in the kept text against the code / git, citing `file:line`. Where a kept
   section points at something that moved, point it at the archive entry.
5. Target: a file someone can act on without reading anything else. There is no line target, but
   if it is still over ~600 lines, look again for history.

## 5 — Fix the plan

1. If § START HERE is stale narrative, snapshot it (§ 4.1 with `sed -n 'A,Bp'`) into its own
   ARCHIVE entry and write a short current one: state, remote vs HEAD, next tasks in order, the
   rules, where the filed items live.
2. Apply the fixes as exact `old → new` replacements, **checking each `old` matches exactly once**
   (`grep -cF '<old>'` = 1) before replacing. Mark statuses; never delete a task. Add index rows for
   unindexed follow-ups; add a "commits the plan did not cite" section if the audit found any.
3. Prove no section was lost: heading keys of `<backup>/IMPLEMENTATION_PLAN.md` and of the scratch
   PLAN into two files, then `LC_ALL=C comm -23 <old keys> <new keys>` must print nothing.
4. Repoint references into CURRENT sections that moved. List them:
   `` grep -o '`CURRENT\.md` § [^|;,)*`]*' <PLAN> | sort -u ``, and compare each against the heading
   keys of the new CURRENT. Each one that no longer resolves becomes
   `` `ARCHIVE.md` (<date> CURRENT cut) § <same section> ``, applied as in step 2.

## 6 — Install and verify

1. Write a short dated ARCHIVE entry for this session (what was cut, what was fixed, the counts).
2. Prepend each new entry onto ARCHIVE, **newest first**, proving the old content is intact:
   ```sh
   cat <entry.md> ARCHIVE.md > <s>/ARCHIVE.md
   tail -c +$(( $(wc -c < <entry.md>) + 1 )) <s>/ARCHIVE.md | cmp - ARCHIVE.md   # must print nothing
   ```
3. `cp` the scratch CURRENT / PLAN / ARCHIVE (and BUSINESS, if touched) into place, `cmp` each
   against its scratch copy, `wc -l` each, and read back the top of each.
4. `git status --short` — the project tree must be unchanged (these files are gitignored).
   Never commit or push `.local_context/`.

## 7 — Tell the user

A few lines: line counts before → after, what was archived (and that it round-tripped), business
rules moved to `BUSINESS.md`, the plan fixes by kind, anything that needs their decision, and where the backups are (say whether they
survive the session).
