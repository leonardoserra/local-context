---
name: local-context-code-review-mapping
description: For one feature in .local_context/<feature_name>/, write the code review map (_crm/) — a reading map of every file the feature's branches change, grouped by functionality with each repo's files side by side, so a reviewer can read a merge request too large to review file by file one chunk at a time. Works across a container repo and its submodules. Run by the user as local-context-code-review-mapping [feature_name | free text].
argument-hint: "[feature_name] or free text naming the feature (optionally branches, base, repos, opener: code | zed | finder | explorer)"
disable-model-invocation: true
---

# local-context-code-review-mapping

A merge request too large to review file by file lists files by directory, so the logic linking a migration, a
controller and a Vue view is spread across unrelated entries. This skill writes a **reading map**: every changed file,
grouped by the capability it implements across repos, ordered so each group reads on its own. Typical calls:

```
local-context-code-review-mapping <feature_name>
local-context-code-review-mapping <feature_name> — branches feature/<branch_name> in both repos, base develop
```

`<feature_name>` and `<branch_name>` are placeholders: the folder comes only from the arguments.

Output: `.local_context/<feature_name>/_crm/` (legacy: `CRM.md`). It is **derived**: it mirrors the branches as they
are now, is regenerated from scratch on every run, and is never edited by hand. Nothing else in `.local_context/` is
written, apart from a migration accepted in the layout check.

It is a map, not a review: no judgement, bug flags, suggestions, diff excerpts or code summaries.

The project's `CLAUDE.md` / `CLAUDE.local.md` rules and constraints **win** over this file; read them before step 2.

## 1 — Pick the feature

As `local-context-continue` § 1: a name or path (any case, `-`/`_`, unique prefix) → use it, say which; a phrase →
infer, confirm with `AskUserQuestion` (or a plain question), inferred first, `(Recommended)`; nothing → folders by
recency (skip `_*`), ask. No `.local_context/` → say so, stop. Root: `git rev-parse --show-toplevel`, else cwd;
`.local_context` may be a symlink (worktrees): write through it.

**Layout check**, before reading `F`: `ls -d F/.no_icm F/_* F/*.md 2>/dev/null`. No flat file (`CURRENT`,
`IMPLEMENTATION_PLAN`, `ARCHIVE`, `BUSINESS`, `CRM`, `CODE_REVIEW_MAPPING` `.md`) and no `.no_icm` → ICM: the map is
`F/_crm`, current state and plan the `STATE.md` of `_current/`, `_implementation_plan/`. `.no_icm` and no `_` folder →
legacy: `F/CRM.md`, `CURRENT.md`, `IMPLEMENTATION_PLAN.md`. Otherwise →
`sed -n '/^## layout check/,/^## /p' <this skill folder>/../local-context-new/ICM_OPS.md` first: one question, migrate
(`local-context-icm-migrate`) or keep the old layout.

## 2 — Find the repos, branches and base

A feature can span a container repo and its submodules (`git submodule status`), each with its own
`.local_context/<feature_name>/` and maybe a feature branch.

1. Read narrowly. In the current state of the root folder and of each subrepo folder for this feature, grep for what
   names repos, branches and merge requests, then read only those lines:
   `grep -nEi 'branch|merge request|MR|PR|base|develop|main|master|feature/' _current/STATE.md`. The user's arguments
   (branches, base, repos) win over the files.
2. Check each candidate exists (`git -C <repo> branch -a --list '*<branch_name>*'`); a repo with no feature branch is
   not in the map.
3. Base: what the current state or the arguments say; otherwise the repo's integration branch (`develop` if it exists,
   else the default branch: `git -C <repo> symbolic-ref --short refs/remotes/origin/HEAD`).
4. Anything unknown or ambiguous (two candidate branches, no base, a mentioned repo with no branch) → one
   `AskUserQuestion` call, one question per unknown, recommendation first `(Recommended)`. Never guess a branch: a
   wrong range maps the wrong files.

## 3 — List the changed files

Per repo:

```sh
git -C <repo> fetch origin
git -C <repo> diff --name-status origin/<base>...origin/<feature_branch>
git -C <repo> diff --stat=200 origin/<base>...origin/<feature_branch> | tail -1
git -C <repo> log --oneline origin/<base>..origin/<feature_branch>
```

- Three dots: the diff against the merge base, as the merge request shows; remote branches, as it compares. A local
  branch ahead (`git -C <repo> rev-list --count origin/<feature_branch>..<feature_branch>` not 0) → say in the header
  that those commits are not in the map.
- Record for the header: merge base (`git -C <repo> merge-base origin/<base> origin/<feature_branch>`) and head SHA
  (`git -C <repo> rev-parse origin/<feature_branch>`), both short.
- Prefix every path with the repo's path from the project root (`<submodule>/app/...`), so each opens from the root.
  The root repo's files keep their plain path; a submodule pointer change is one more file.
- Save the full prefixed list, sorted, one path per line, to `<s>/changed.txt` (`<s>` = the session scratchpad, or
  `/tmp/local-context-code-review-mapping-<date>/`); a rename counts its new path, a deletion its old.

## 4 — Group by functionality

Infer the groups from cheap signals, not from full diffs:

- the commit subjects from step 3;
- the plan's task titles (its Tasks table; legacy `grep -n '^#'`): tasks often already name the capabilities;
- file names: the same noun in backend and frontend files (`report_template.rb`, `ReportTemplate.ts`,
  `reportTemplates` http mixin, `ReportTemplateForm.vue`);
- routes ↔ frontend calls: grep the changed frontend files for the endpoint paths the changed routes and controllers
  define;
- a file whose role is unclear: `git diff <range> -- <file> | head -80`.

**Large diff** (roughly over 40 files or 2,000 changed lines): delegate the grouping to one `general-purpose`
subagent, **read-only, never edit**, given the repos, ranges, `<s>/changed.txt`, the commit subjects, the task titles
and the rules of sections 4 and 5; ask for the map body in the section 5 format. Run the coverage check (step 6)
yourself; never trust its count.

Grouping rules:

- **By capability, never by directory or layer.** A group pairs the backend files (migration, model, query or service,
  controller, serializer, routes, jobs, rake tasks) with the frontend files (models, http mixins, store, components,
  views) of the same capability; `models/` is never a group.
- **A group may touch one repo only** (a backend-only import job).
- **Split a group that holds ideas readable apart.** Around 10 files in one repo is the signal to look. If they hold
  parts a reviewer can read and verify separately (the list query and the CSV export, the form and the permission
  check), make one subgroup per idea, each with its own files, specs and `open:` block; one idea read together stays
  one group. Never split by layer or count. Name subgroups `### <functionality name> / <idea> — <purpose, one line>`,
  as plain `###` groups next to each other: `local-context-code-review-navigator` counts every `###` heading as one
  group, and a `####` heading would merge its files into the group above.
- **Specs sit with the code they test**, in the group's own `specs:` list, never in a test group.
- **A shared file** (a routes file, a model registry, a store index) goes in the group it mainly serves; serving
  several, it is listed in each and flagged (step 6).
- **Leftovers** — lockfiles, generated files, pure config, formatting-only edits, submodule pointers — go in a final
  `Other / mechanical` group, reviewed like the rest; a domain too big to follow mixed gets its own
  (`Other / mechanical — dependencies`, `— CI`). Never drop a file.

**Order of groups**, for reading:

1. Foundations: schema, migrations, shared data and infrastructure others depend on.
2. The capabilities on top, each after those it depends on; a capability's subgroups together.
3. Cross-cutting work: downloads and exports, configuration, docs.
4. `Other / mechanical` group(s), last.

**Order inside a group**: data up, from storage to screen, as the map header's order line lists.

## 5 — Write the map

Write the map to `<s>/map.md`: one map covers every repo; it goes in the feature's root-level folder `F` after the
coverage check (step 6). Its shape, group row and `_crm/STATE.md`, one read (`<n>` =
`<this skill folder>/../local-context-new`): `sed -n '/^- Review group/,/Row/p;/^## F: map/,$p' <n>/ICM_FORMATS.md`.

- `<repo>` in the table is the repo's path from the project root (the first segment of its file paths); the root
  repo's is its folder name (`basename` of the root). The navigator reads the table this way.
- The navigator marks a group reviewed once approved; regenerating drops the marks (the branches moved, review again).
  A heading's `|` becomes `/`.
- A group's files go per repo under `<repo>:`, exactly as in the table and in its order, one list per repo even with
  server and client code; never a role label (`backend:`, `<repo> (backend):`); no empty repo.
- `open:`: one command per repo under a `# <repo>` comment, opening its `<repo>:` and `specs:` files at once. `<root>`
  = the absolute project root; quote every path; skip deleted files (a repo left with none gets no command).
  `Other / mechanical` groups get no `open:`. The opener comes from the arguments: `code` (default), `zed`, `cursor` —
  one command, all paths as arguments; `finder` (macOS) — `open -R "<path>" "<path>"`; `explorer` (Windows, one file
  per call) — `explorer /select,"<path>"` calls chained with ` & `. E.g.
  `sed "s|^|\"$root/|; s|$|\"|" <paths> | paste -sd' ' - | sed 's/^/code /'`.
- Mark a deleted file `(deleted)` and a renamed one `(renamed from <old path>)` after its path.
- `Read for:` is a pointer, not a finding: "the date window the query applies", not "this query is slow".

## 6 — Coverage check (mandatory)

Every changed file must appear in at least one group. Prove it:

```sh
grep -E '^  - ' <s>/map.md | sed -E 's/^  - //; s/ \((deleted|renamed from .*)\)$//' > <s>/mapped_all.txt
LC_ALL=C sort -u <s>/mapped_all.txt > <s>/mapped.txt
LC_ALL=C sort -u <s>/changed.txt > <s>/changed_sorted.txt
LC_ALL=C comm -23 <s>/changed_sorted.txt <s>/mapped.txt   # changed but not mapped: must print nothing
LC_ALL=C comm -13 <s>/changed_sorted.txt <s>/mapped.txt   # mapped but not changed (typo): must print nothing
LC_ALL=C sort <s>/mapped_all.txt | uniq -d               # in 2+ groups: list them in the header
```

Fix the map until both `comm` print nothing; write the counts (`wc -l` of `mapped.txt` and `changed_sorted.txt`,
equal) and the 2+ list into its header. Then install it whole, replacing any earlier map, and read it back:

- **Legacy**: `cp <s>/map.md F/CRM.md`; delete a pre-2.0.0 `CODE_REVIEW_MAPPING.md` there and say so.
- **ICM**: cut `<s>/map.md` with `sed -n 'A,Bp'`: the lines before the first `### ` → `<s>/chead.md`; each `### `
  section → `<s>/_crm/<NN>_<slug>.md`, NN = its group number. `<s>/groups.md` = `## Groups` and a row per group, as
  read in step 5. Delete a leftover `CRM.md` / `CODE_REVIEW_MAPPING.md`:
  ```sh
  rm -rf <s>/_crm && mkdir <s>/_crm          # before cutting the group files
  cat <s>/chead.md <group files, in order> | cmp - <s>/map.md
  cat <s>/chead.md <s>/groups.md > <s>/_crm/STATE.md
  crm=F/_crm; case $crm in */_crm) rm -rf "$crm" ;; *) false ;; esac && cp -R <s>/_crm "$crm" && diff -r <s>/_crm "$crm"
  ```

Never commit or push `.local_context/`.

## 7 — Tell the user

A few lines: the map's path, repos and ranges, group count, the coverage line, files in 2+ groups, local commits not
in the map, the first group to read. Then print every group as in the map, in reading order, `open:` block included,
so the user can copy a repo's command.
