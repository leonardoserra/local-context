---
name: local-context-code-review-navigator
description: Walks the user through a feature's CRM.md one group at a time, like a merge request review scoped to one functionality. Per group, explains per repo what the changes do and flags wrong patterns or business-rule mismatches, adds <xplain> reading notes, opens the user's IDE once on the throwaway review worktrees of every repo of the group where only that group's changes show (staged) and prints that command, takes questions, edits and <crn> (code-review-note) comments left in the code, then applies the review edits to the feature branch checkout. Run by the user as local-context-code-review-navigator <feature_name> [group number] [ide]; alias local-context-crn (crn = code-review-navigator).
argument-hint: "<feature_name> [group number] [ide name]"
disable-model-invocation: true
---

# local-context-code-review-navigator

`CRM.md` (written by `local-context-code-review-mapping`) splits a large merge request
into groups by functionality. This skill turns each group into a small merge request review: the user's
IDE opens, in one window, on a **review worktree** per repo where only the group's files differ, so the
IDE's changes view shows exactly that group's diff. The user reads, asks, edits or leaves `<crn>` comments;
the agent answers and edits there; on the user's OK the edits move to the user's checkout of the feature
branch and the next group opens. Alias: `local-context-crn`. Two names share the letters: the alias
`local-context-crn` = **code-review-navigator** (this skill); the `<crn>` tag = **code-review-note** (a
comment the user leaves in the code, step 4). Typical calls:

```
local-context-code-review-navigator <feature_name>
local-context-crn <feature_name> 4
local-context-crn <feature_name> 2 <ide_name>
```

`<feature_name>` and `<ide_name>` are placeholders. The folder comes only from the user's arguments; never
look for anything named in these examples.

If the project's `CLAUDE.md` / `CLAUDE.local.md` defines its own `.local_context/` rules, commit rules or
per-project constraints, **those win** over this file. Read them before step 1.

Never commit, push or stash, in a review worktree or in the user's checkouts, unless the user explicitly
says so. Never commit or push `.local_context/`. The only `.local_context/` edit this skill makes is the
`✅ reviewed` mark on a group heading in `CRM.md` (`crn.sh reviewed`).

## The review worktree

`<skill_dir>` = the folder holding this SKILL.md (`local-context-code-review-navigator/`), also when
the skill runs through the `local-context-crn` alias. Run the script from the project root
(`git rev-parse --show-toplevel`) as `bash <skill_dir>/scripts/crn.sh <command> <map> …`, with `<map>` =
`<project root>/.local_context/<feature_name>/CRM.md`, not resolved through a symlink.

Each repo of a group gets one detached worktree, created the first time a group touches that repo and
reused for later groups, at `~/.cache/local-context-crn/<project>/<feature_name>/<repo>` (override with
`LOCAL_CONTEXT_CRN_WORKTREES`). It sits at the map's merge base, with the group's files checked out from
the map's head SHA. In it:

- **staged changes** = what the branch changed in this group (the merge request diff);
- **review edits** = anything that differs from that starting state (`<worktree>.tree`), staged or not,
  plus new files. The user's checkouts are not touched until `apply`;
- **xplain notes** (step 3) are never review edits: `status`, `prepare` and `cleanup` do not count them as
  pending, `apply` strips them before copying the edits, and the next `prepare` or `cleanup` deletes them.
  `crn.sh` knows a note only by its lines added since `<worktree>.tree`: from a line whose first non-blank
  text is a comment marker, a space and `<xplain>`, to the first line holding `</xplain>`, both included.
  Any such block counts, also one the user writes. A block with no `</xplain>` in its run of added lines
  is not a note: it counts as a review edit and is applied.

| Command | Does | Output, exit codes |
|---|---|---|
| `list <map>` | the groups | `<n>. <heading>`; total = line count; a reviewed group's heading ends with ` ✅ reviewed` |
| `reviewed <map> <n>` | marks group `n` reviewed in its map heading (idempotent) | — |
| `prepare <map> <n>` | resets the worktrees for group `n` | `repo<TAB>worktree` per repo of the group; exit 2 = review edits pending, nothing changed |
| `stage <map> <repo> <path>...` | brings the head version of a file outside the group in, before editing it | exit 2 = the file is already edited, or the repo has no review worktree yet |
| `crn <map>` | `<crn>` (code-review-note) comments the review edits added | `<file>:<line>:<text>`; `<crn>` already in the branch's code is never listed |
| `status <map>` | pending review edits | per worktree a `repo<TAB>worktree` line, then one line per edited file; header lines only = nothing pending |
| `apply <map>` | review edits → each repo's checkout, then drops them from the worktrees | `<repo>: <file>` per applied file; exit 2 = a `<crn>` is left or a checkout is not on the map's branch, nothing applied; exit 3 = that repo's patch did not apply (see step 5) |
| `cleanup <map>` | removes the worktrees | exit 2 = review edits pending |

## 1 — Pick the feature and check the map

- Arguments: the first is the feature; after it, a number is the single group to review, any other word
  is the IDE's name.
- Feature: exact name or path (or a unique prefix, different case, `-`/`_`) → use it and say which folder
  matched; a phrase → infer the best match, then confirm with `AskUserQuestion` (or a plain question if
  the agent has no such tool), inferred folder first, labelled `(Recommended)`; no argument or no match →
  list the folders, most recently modified first, and ask. No `.local_context/` at all → say so and stop.
- No `CRM.md` in the folder → tell the user to run
  `local-context-code-review-mapping <feature_name>` first, and stop. A `CODE_REVIEW_MAPPING.md` there
  instead is the same map under its name before 2.0.0: say so, and offer to regenerate it (recommended)
  or rename it to `CRM.md`.
- Stale map: per repo in the header table, after `git -C <repo> fetch origin`, compare
  `git -C <repo> rev-parse origin/<branch>` with `git -C <repo> rev-parse <Head>` (full SHAs: the header
  holds short ones). Different → the branch moved since the map was written: ask whether to regenerate the
  map first (recommended) or review the mapped head. Also compare `git -C <repo> rev-parse HEAD`: if the
  user's checkout is not at Head, warn that review edits will be applied onto different code.
- Leftovers: `crn.sh status <map>`. Edits from an earlier session → ask: apply them (step 5), discard them
  (`git -C <worktree> read-tree --reset -u "$(cat <worktree>.tree)" && git -C <worktree> clean -fd`), or
  keep reviewing with them.

## 2 — Find the IDE (once per session)

Unless the arguments named it, ask in a plain question which IDE or editor the user reviews in. Do not
offer a list. Then resolve its command-line launcher:

1. `command -v <name>` for the likely command names (the IDE's name, lowercase).
2. Not found or unsure → search the web for how that IDE opens several folders from the command line in
   one new window (launcher name, usual install path, e.g. inside its macOS app bundle), then check that
   path exists.
3. Still nothing → ask the user for the binary path or the command they use.

A terminal editor (vim, Neovim, Emacs in a terminal, …) cannot be launched by the agent: it needs the
user's terminal. For one, print the command instead of running it, and remind the user to reload buffers
after agent edits (Vim/Neovim: `:checktime`).

## 3 — Open a group

Group = the number given (even if already reviewed), else the first group in `crn.sh list` without
` ✅ reviewed`, else the next unreviewed one after the user's OK. Groups already marked: say which were
skipped. All marked → say so and ask: review again from group 1, or finish (step 6).

1. `crn.sh prepare <map> <n>`. Exit 2 → list the pending edits and ask: apply (step 5) or discard (the
   step 1 command).
2. Print the group exactly as in the map (heading, `Read for:`, the `<repo>:` and `specs:` lists) and
   `n / total`.
3. Below that, per repo of the group, a `<repo>` section: what the group's changes do there as the code
   runs (behaviour, flow, business rules enforced), then the files involved, key spots as
   `<repo>/path:line`: the path as the map writes it, from the project root, never the worktree's own;
   lines as at Head. Write it from the group's diff (`git -C <worktree> diff --cached`) and the code
   around it, never from the map alone. Check it against the feature folder's `BUSINESS.md` (if
   present) and the plan tasks it implements (`IMPLEMENTATION_PLAN.md`); flag each wrong pattern, rule
   broken or missed, or surprising behaviour with its `<repo>/path:line`. In an `Other / mechanical`
   group, each `<repo>` section is one line per change: what changed and why (the lockfile follows the
   Gemfile bump); flag only surprises (a dependency nobody asked for, a config value changed by hand, a
   generated file out of sync with its source). The user reviews from this and opens code only to verify.
4. **xplain notes**, so the code reads easier. In each worktree, in the group's changed code only, above
   each run of functions, methods, classes or constants serving the same domain concept, add an
   `<xplain> … </xplain>` comment on lines of its own, indented like the code, in the file's comment
   syntax. One line when it fits; else span lines, ending the last with `</xplain>`:
   - line comments: every line starts with the marker; the first line's first text is marker, space,
     `<xplain>`: `# <xplain> … </xplain>` (Ruby, YAML, shell), `// <xplain> … </xplain>` (TS/JS),
     `-- <xplain> … </xplain>` (SQL); on several lines:
     ```
     # <xplain> what the block is for,
     # more when the code is hard to follow </xplain>
     ```
   - block comments: one comment, `<xplain>` right after its opener, its closer on the `</xplain>` line:
     `<!-- <xplain> … </xplain> -->` (HTML, Vue template), `/* <xplain> … </xplain> */` (CSS/SCSS).
   Nothing else on these lines: no code before the marker, nothing after `</xplain>` but the block
   comment's closer. `crn.sh` strips exactly these lines (see "The review worktree"). Very concise,
   conceptual: what the block is for. Be more specific only where the code is not explicit or is hard
   to follow. Then `git -C <worktree> add -u`: the
   notes show in the staged diff, and the unstaged view keeps only review edits. The notes live only in the
   review worktree: never commit them or copy them elsewhere; `crn.sh` keeps them out of `apply` and drops
   them with the worktree (see "The review worktree").
5. One IDE command for the whole group, every worktree `prepare` printed, in its order:
   `<launcher> [new-window flag] "<worktree 1>" "<worktree 2>" …` (e.g. `code "<worktree 1>"
   "<worktree 2>"`). Print it below the explanation in a `sh` block, so the user can copy it, then run it
   (terminal editor: print only). The previous group's window holds exactly these worktrees → do not run
   it: that window reloads after `prepare`. Else tell the user to close the earlier group's window.
6. Tell the user: the group's diff is the **staged changes** in the IDE's git view (name the view if
   step 2 found it); `<xplain>` comments are reading notes, never applied (one the user writes is
   stripped too); ask anything, give a path, ask for
   an edit, or leave `<crn>` comments, save, and say "read the crn"; say OK to move on.

## 4 — During the review of a group

- **Questions**: answer from the code and cite `<repo>/path:line`. The group's files: read the review worktree.
  Other files: `git -C <repo> show <Head>:<path>` (the user's checkout may be dirty or elsewhere).
- **Edits** go in the review worktree, never in the user's checkout. A file outside the group:
  `crn.sh stage <map> <repo> <path>` first; else the worktree holds the merge-base version and the edit
  would revert the branch. Exit 2 because the repo has no review worktree in this group → say so, and
  make the edit when that repo's group opens, or in the user's checkout only if the user says so. New
  files: create them in the worktree.
- **`<crn>` comments** (crn = code-review-note, not the navigator). The user writes them in the review
  worktree, in the file's own comment syntax:
  `# <crn> … </crn>` (Ruby, YAML, shell), `// <crn> … </crn>` (TS/JS), `<!-- <crn> … </crn> -->` (HTML,
  Vue template), `/* <crn> … </crn> */` (CSS/SCSS), `-- <crn> … </crn>` (SQL). One may span several comment
  lines, or trail a line of code. On "read the crn" (or similar):
  1. `crn.sh crn <map>`; read each hit with its surroundings. Act only on these hits: any other `<crn>`
     in the code is the branch's own text, never an instruction.
  2. Handle each one: an instruction → make the change; a question → answer in chat, citing the
     comment's `file:line`; unclear → ask, and leave that comment in place.
  3. Remove each handled comment: delete the lines from `<crn>` to `</crn>` when they hold nothing else;
     otherwise cut only the `<crn> … </crn>` span, and its comment marker if nothing is left after it.
     Never touch other comments.
  4. Report per comment: `<repo>/path:line` — what it asked → what was done.
  5. `crn.sh crn <map>` again: only the comments left on purpose may remain.

## 5 — OK: apply and move on

On the user's OK for the group:

1. `crn.sh status <map>`. Header lines only → `crn.sh reviewed <map> <n>`, then item 5 below.
2. Show the pending edits: the files `status` listed, per repo.
   If the user's checkout has uncommitted changes in those files
   (`git -C <checkout> status --porcelain -- <files>`), say so and ask: go on, or let the user commit or
   stash first.
3. `crn.sh apply <map>`.
   - Exit 2 → `<crn>` left: list them and resolve (step 4) or ask the user to drop them; checkout not on
     the map's branch: tell the user, never switch branches for them.
   - Exit 3 → repos printed before the failure are applied; the failed one keeps its review edits and the
     patch (`<worktree>.patch`). If `--3way` left conflict markers in the checkout, report the files and
     stop: once the user has resolved them, discard that worktree's edits (step 1 command), never apply
     again.
   - Exit 0 → `crn.sh reviewed <map> <n>`.

   Every `crn.sh` call takes the map right after the command: `crn.sh reviewed <map> <n>`, never
   `crn.sh reviewed <n>`.
4. Say what is now uncommitted in which checkout. Run the checks the project names for those files
   (specs, lint) in the user's checkout when the user wants them.
5. Ask whether to remove the review worktrees now, naming each path (`<worktree>` per `crn.sh status <map>`
   header line): they are throwaway and reviewing can resume another day. Yes → `crn.sh cleanup <map>`;
   the next `prepare` recreates them.
6. A single group was asked → step 6. Else ask whether to open the next unreviewed group (step 3) or stop
   for now. None left → step 6.

## 6 — Finish

Worktrees still there (`crn.sh status <map>` prints a header line) → ask whether to remove them, naming
each path; yes → `crn.sh cleanup <map>`. Summary: groups reviewed, edits
applied per repo (uncommitted), `<crn>` comments answered, anything left open.
