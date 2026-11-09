---
name: local-context-code-review-mapping
description: For one feature in .local_context/<feature_name>/, write CODE_REVIEW_MAPPING.md — a reading map of every file the feature's branches change, grouped by functionality with backend and frontend files side by side, so a reviewer can read a merge request too large to review file by file one chunk at a time. Works across a container repo and its submodules. Maps, never reviews. Run by the user as local-context-code-review-mapping [feature_name | free text].
argument-hint: "[feature_name] or free text naming the feature (optionally branches, base, repos, opener: code | zed | finder | explorer)"
disable-model-invocation: true
---

# local-context-code-review-mapping

A feature's merge requests are often too large for a person to review file by file: the diff
lists files alphabetically or by directory, so the logic that links a migration, a controller and
a Vue view is spread across dozens of unrelated entries. This skill writes a **reading map**:
every changed file, grouped by the capability it implements, backend and frontend together, in
an order that lets the reviewer read one group and understand it without the rest.
Typical calls:

```
local-context-code-review-mapping <feature_name>
local-context-code-review-mapping <feature_name> — branches feature/<branch_name> in both repos, base develop
local-context-code-review-mapping <feature_name> — open with zed
```

`<feature_name>` and `<branch_name>` are placeholders. The folder comes only from the user's
arguments (step 1); never look for anything named in these examples.

Output: `.local_context/<feature_name>/CODE_REVIEW_MAPPING.md`, an optional file of the folder
contract. It is **derived**: it mirrors the branches as they are now, is regenerated from scratch
on every run, and is never edited by hand. The skill does not touch `CURRENT.md`,
`IMPLEMENTATION_PLAN.md`, `ARCHIVE.md` or `BUSINESS.md`.

It is a map, not a review: it never judges the code, flags bugs or suggests changes.

If the project's `CLAUDE.md` / `CLAUDE.local.md` defines its own `.local_context/` rules or
per-project constraints, **those win** over this file. Read them before step 2.

## 1 — Pick the feature

Same as `local-context-continue`: exact name or path (or a unique prefix, different case, `-`/`_`)
→ use it and say which folder matched; a phrase → infer the best match, then confirm with
`AskUserQuestion` (or a plain question if the agent has no such tool), inferred folder first,
labelled `(Recommended)`; no argument or no match → list the folders, most recently modified
first, and ask. No `.local_context/` at all → say so and stop.

Project root: `git rev-parse --show-toplevel`, else cwd. `.local_context` may be a symlink (git
worktrees): resolve it and write through it.

## 2 — Find the repos, branches and base

A feature can span several repos: a container repo with git submodules
(`git submodule status`), each with its own `.local_context/<feature_name>/`, and a feature branch
in some or all of them.

1. Read narrowly. In the root `CURRENT.md` and each subrepo's `CURRENT.md` for this feature, grep
   for what names repos, branches and merge requests, then read only those lines:
   `grep -nEi 'branch|merge request|MR|PR|base|develop|main|master|feature/' CURRENT.md`.
   Arguments the user gave (branches, base, repos) win over what the files say.
2. Check each candidate exists:
   `git -C <repo> branch -a --list '*<branch_name>*'`. A repo with no feature branch is not part
   of the map.
3. Base: what CURRENT or the arguments say; otherwise the repo's integration branch (`develop` if
   it exists, else the default branch: `git -C <repo> symbolic-ref --short refs/remotes/origin/HEAD`).
4. Anything still unknown or ambiguous (two candidate branches, no base, a repo CURRENT mentions
   but with no branch) → ask in one `AskUserQuestion` call, recommendation first with
   `(Recommended)`, one question per unknown. Never guess a branch: a wrong range maps the wrong
   files.

## 3 — List the changed files

Per repo:

```sh
git -C <repo> fetch origin
git -C <repo> diff --name-status origin/<base>...origin/<feature_branch>
git -C <repo> diff --stat=200 origin/<base>...origin/<feature_branch> | tail -1
git -C <repo> log --oneline origin/<base>..origin/<feature_branch>
```

- Three dots: the diff against the merge base, which is what the merge request shows.
- Compare the remote branches, as the merge request does. If the local feature branch is ahead
  (`git -C <repo> rev-list --count origin/<feature_branch>..<feature_branch>` is not 0), say so
  in the header: those commits are not in the map.
- Record for the header: merge base (`git -C <repo> merge-base origin/<base> origin/<feature_branch>`)
  and head SHA (`git -C <repo> rev-parse origin/<feature_branch>`), both short.
- Prefix every path with the repo's path from the project root (`<submodule>/app/...`,
  `<submodule>/src/...`), so each path opens from the root. Files of the root repo itself keep
  their plain path; a submodule pointer change in the root repo is one more file.
- Save the full prefixed list, one path per line, sorted, to the scratchpad: `<s>/changed.txt`
  (`<s>` = the session scratchpad, or `/tmp/local-context-code-review-mapping-<date>/`). For a
  rename, the new path counts; for a deletion, the old one.

## 4 — Group by functionality

Infer the groups from cheap signals, not from full diffs:

- the commit subjects from step 3;
- the plan's task titles (`grep -n '^#' IMPLEMENTATION_PLAN.md`): tasks often already name the
  capabilities;
- file names: the same noun on both sides (`report_template.rb`, `ReportTemplate.ts`,
  `reportTemplates` http mixin, `ReportTemplateForm.vue`);
- routes ↔ frontend calls: grep the changed frontend files for the endpoint paths the changed
  routes and controllers define;
- for a file whose role is still unclear, a targeted read: `git diff <range> -- <file> | head -80`.

**Large diff** (roughly over 40 files or 2,000 changed lines in total): delegate the grouping to
one `general-purpose` subagent, told **read-only, never edit**. Give it the repos, ranges,
`<s>/changed.txt`, the commit subjects, the plan's task titles and the rules of this section and
of section 5; ask for the map body in the section 5 format. Then run the coverage check (step 6)
yourself; never trust the subagent's own count.

Grouping rules:

- **By capability, never by directory or layer.** A group pairs the backend files (migration,
  model, query or service, controller, serializer, routes, jobs, rake tasks) with the frontend
  files (models, http mixins, store, components, views) that implement the same capability.
  `models/` or `controllers/` is never a group.
- **A group with only one side is fine**, e.g. a backend-only import job.
- **Specs sit with the code they test**, in the group's own `specs:` list, never in a test group.
- **A shared file** that several capabilities touch (a routes file, a model registry, a store
  index) goes in the group it mainly serves. If it serves several, list it in each and flag it
  (step 6).
- **Leftovers** — lockfiles, generated files, pure config, formatting-only edits, submodule
  pointers — go in a final `Other / mechanical` group. Never drop a file.

**Order of groups**, for reading:

1. Foundations: schema and migrations, shared data and infrastructure other groups depend on.
2. The capabilities that build on them, each after the ones it depends on.
3. Cross-cutting work: downloads and exports, configuration, docs.
4. `Other / mechanical`, last.

**Order inside a group**: data up, from storage to screen. Backend: migration, model, query or
service, controller, serializer, routes, jobs. Frontend: model, http mixin, store, component, view.

## 5 — Write the map

Write `.local_context/<feature_name>/CODE_REVIEW_MAPPING.md` (the root-level folder of the
feature; one map covers every repo). If the file exists, replace it whole: it is derived, and the
header SHAs show when it went stale.

````markdown
# <feature_name> — code review mapping

Generated <YYYY-MM-DD> by `local-context-code-review-mapping`. Derived from the branches below:
regenerate it, never edit it by hand.

| Repo | Branch | Base | Merge base | Head | Files |
|---|---|---|---|---|---|
| <repo> | <feature_branch> | <base> | <short sha> | <short sha> | <count> |

Coverage: <N> files mapped / <N> changed. In 2+ groups: <path> (<group>, <group>) | none.
Order inside each group: data up (migration, model, query, controller, serializer, routes, jobs;
frontend model, http mixin, store, component, view).

### <functionality name> — <purpose, one line>
Read for: <what to verify, one line — optional>
backend:
  - <repo>/path/to/backend/file.rb
frontend:
  - <repo>/path/to/frontend/file.vue
specs:
  - <repo>/spec/path/to/file_spec.rb

open:
```sh
# backend
code "<root>/<repo>/path/to/backend/file.rb" "<root>/<repo>/spec/path/to/file_spec.rb"
# frontend
code "<root>/<repo>/path/to/frontend/file.vue"
```

### Other / mechanical — lockfiles, generated files, config
  - <repo>/yarn.lock
````

- Omit an empty side (`frontend:` with nothing under it is not written).
- `open:` gives one command per side that opens all of that side's files at once. `<root>` is
  the absolute project root (`git rev-parse --show-toplevel`); quote every path. Specs go in the
  command of the side they test. Skip deleted files; a side left with no file gets no command.
  `Other / mechanical` gets no `open:` block. The opener comes from the arguments:
  - `code` (VS Code, default), `zed`, `cursor`: one command, all paths as arguments.
  - `finder` (macOS): `open -R "<path>" "<path>"` reveals the files in Finder.
  - `explorer` (Windows): Explorer takes one file per call, so chain
    `explorer /select,"<path>"` calls with ` & `.
  Build a side's command from its paths, e.g.
  `sed "s|^|\"$root/|; s|$|\"|" <paths> | paste -sd' ' - | sed 's/^/code /'`.
- Mark a deleted file `(deleted)` and a renamed one `(renamed from <old path>)` after its path.
- When the project has more than one backend or frontend repo, the repo prefix tells them apart;
  the side labels stay `backend:` / `frontend:`.
- `Read for:` is a pointer, not a finding: "the date window the query applies", not "this query is
  slow".
- Nothing else: no review, no diff excerpts, no summary of the code.

## 6 — Coverage check (mandatory)

Every changed file must appear in at least one group. Prove it, with `<map>` the written file:

```sh
grep -E '^  - ' <map> | sed -E 's/^  - //; s/ \((deleted|renamed from .*)\)$//' > <s>/mapped_all.txt
LC_ALL=C sort -u <s>/mapped_all.txt > <s>/mapped.txt
LC_ALL=C sort -u <s>/changed.txt > <s>/changed_sorted.txt
LC_ALL=C comm -23 <s>/changed_sorted.txt <s>/mapped.txt   # changed but not mapped: must print nothing
LC_ALL=C comm -13 <s>/changed_sorted.txt <s>/mapped.txt   # mapped but not changed (typo): must print nothing
LC_ALL=C sort <s>/mapped_all.txt | uniq -d               # in 2+ groups: list them in the header
```

Fix the map until both `comm` print nothing, then write the counts and the 2+ list into the
header (`wc -l < <s>/mapped.txt` and `wc -l < <s>/changed_sorted.txt`, which must be equal). Read
the file back and confirm it is complete.

Never commit or push `.local_context/`.

## 7 — Tell the user

A few lines: the map's path, the repos and ranges it covers, the number of groups, the coverage
line, files in 2+ groups, any local commits not in the map, and the first group to read.

Then print every group as in the map, in reading order: heading with its purpose, the backend,
frontend and specs lists, and its `open:` block (backend command, frontend command), so the user
can copy a command and open a whole side at once.
