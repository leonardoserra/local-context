# ICM formats

The one home of every format; read only the section you need. Write from here, never by copying an older file.
A piece never points back at its `STATE.md`.

## F: pieces

- Decision, `_current/_decisions/<NN>_<slug>.md`: `# <the decision, one line>`, an empty line,
  `<YYYY-MM-DD>, <who>. <what was decided and why, with evidence or ref>`.
  Row `| <N> | <file> | <decision> | <YYYY-MM-DD> | <who> |`.
- Question, `_current/_questions/<NN>_<slug>.md`: `# <the question, one line>`, an empty line, what it
  blocks, who answers it, what is known. Row `| <N> | <file> | <question> | open |`.
- Task, `_implementation_plan/<NN>_<slug>.md`: `### <N> — <title>`, an empty line, then
  `- **Repo**: <repo or path>`, `- **Anchors**: <file:line, or "to find">`,
  `- **Done when**: <observable, checkable condition>`; notes below as the work needs them. Dependencies
  live only in the row: `| <N> | <file> | <title> | <none or task numbers> | todo |`.
- Archive entry, `_archive/<YYYY_MM_DD>/<N>.md`: `## <YYYY-MM-DD> — <title>`, an empty line, the body.
  Row `| <YYYY_MM_DD>/<N>.md | <commits> | <title> |`.
- Business theme, `_business/<theme-slug>.md`: `## <theme>`, an empty line, bullets
  `- <the rule, in business language> — <YYYY-MM-DD>; <ref: ticket comment, doc, call — if any>`.
  Row `| <file> | <theme> | <rule count> | <YYYY-MM-DD> | <one line> |`.
- Review group, `_crm/<NN>_<slug>.md`: the group's `### ` section of the map, heading never marked.
  Row `| <n> | <file> | <heading without "### "> | todo |`.

## F: current

```markdown
# <feature_name> — CURRENT

State as of **<YYYY-MM-DD>**. Current state only; history is in `_archive/STATE.md`, the work list in
`_implementation_plan/STATE.md`, business rules (if any) in `_business/STATE.md`.

## Goal

<one paragraph: what this work is for and what "done" means>

## Scope

- In: <...>
- Out: <...>

## Where it stands

<nothing built yet / what exists today, with file:line where known>

## Decisions

`_current/_decisions/STATE.md`: one row per load-bearing decision, one file each.

## Open questions

`_current/_questions/STATE.md`: one row per question, one file each.

## RESUME HERE

Next: `_implementation_plan/01_<slug>.md`.
```

## F: decisions questions

```markdown
# <feature_name> — decisions

One file per row. Open a file only when it bears on the work.

| # | File | Decision | Date | Who |
|---|---|---|---|---|
```

Questions: title `open questions`, header `| # | File | Question | Status |` and `|---|---|---|---|`.

## F: plan

```markdown
# <feature_name> — IMPLEMENTATION_PLAN

## START HERE — <YYYY-MM-DD>

<one short paragraph: current state, the next task, anything blocking>

## Tasks

| # | File | Task | Depends on | Status |
|---|---|---|---|---|
| 1 | 01_<slug>.md | <task title> | none | todo |

## Blocked on a decision

<none | the question (`_current/_questions/NN_<slug>.md`), and who answers it>

## Verification commands

<commands that prove the work, e.g. test/lint/build>

## Do NOT do (YAGNI)

| Not doing | Why |
|---|---|
```

## F: archive

```markdown
# <feature_name> — ARCHIVE

Dated history, one entry per file, oldest first, append-only: an entry is never edited. Read the latest
rows with `tail -n 20`, then open only the entries needed.

| Entry | Commits | Title |
|---|---|---|
```

## F: business

```markdown
# <feature_name> — BUSINESS

Business rules as of **<YYYY-MM-DD>**: what this feature must do for users, clients and the company. No
technical rules (those are in `_current/`). A changed rule is replaced in its theme file; the old wording
goes to `_archive/`.

| File | Theme | Rules | Last changed | Summary |
|---|---|---|---|---|
```

## F: map

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
<repo>:
  - <repo>/path/to/file.rb
<other_repo>:
  - <other_repo>/path/to/file.vue
specs:
  - <repo>/spec/path/to/file_spec.rb

open:
```sh
# <repo>
code "<root>/<repo>/path/to/file.rb" "<root>/<repo>/spec/path/to/file_spec.rb"
# <other_repo>
code "<root>/<other_repo>/path/to/file.vue"
```

### Other / mechanical — lockfiles, generated files, config
  - <repo>/yarn.lock
````

## F: crm

The map's text above its first `### ` group (title, Generated line, repo table, Coverage, order note), as
`local-context-code-review-mapping` writes it, then:

```markdown
## Groups

| # | File | Group | Status |
|---|---|---|---|
```
