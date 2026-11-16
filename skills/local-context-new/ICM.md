# ICM layout of `.local_context/<feature>/`

ICM: Interpretable Context Methodology ([paper](https://arxiv.org/abs/2603.16021); reference
https://github.com/RinDig/Interpretable-Context-Methodology, read only if these files leave something unclear;
the idea, not a copy). Read down the layers, stop when you have enough: skill, this file, the indexes (one call:
`tail -n +1 F/_current/STATE.md F/_current/_*/STATE.md F/_implementation_plan/STATE.md F/_business/STATE.md 2>/dev/null`),
then only the pieces needed. `F` = the feature folder.

`_current/STATE.md` (state, § RESUME HERE) with `_decisions/`, `_questions/`; `_implementation_plan/` (a task
per file; next = the first `todo`/`doing` row whose Depends on rows are done); `_archive/YYYY_MM_DD/N.md` (N = 1
the day's oldest; index oldest first, read its `tail -n 20`); `_business/`, `_crm/`.

`STATE.md` routes (≤ 80 prose lines, `grep -vc '^|'`; not the archive's), points down, never back, and alone holds
status and task dependencies — plan: `todo`, `doing`, `done-uncommitted <date>`, `✅ DONE <date> (<sha>)`,
`⛔ CLOSED|ABANDONED|MOVED <why>`, `⛔ NOT scope`, `⏸ blocked`; groups: `todo`, `✅ reviewed`; questions: `open`,
`answered <date> → _current/_decisions/<file>`. Never rename a file; new: `<NN>_<slug>.md`, NN = highest + 1, two
digits. Pointers: paths from `F`. Cells: `|` → `/`; replace a row only after `grep -cF '<row>'` = 1. Read back
writes. Archive entries are never edited; replaced text goes verbatim into the session's entry.

Read only the section needed, next to this file: `sed -n '/^## <op>/,/^## /p' ICM_OPS.md` (decision add, question
add, question answer, plan add task, plan mark, archive add, archive find, business rule set);
`sed -n '/^## F: <name>/,/^## F: /p' ICM_FORMATS.md` (pieces: file and row shapes; current, decisions questions,
plan, archive, business, map, crm).

Flat layout found (`CURRENT.md`, …) → ICM_OPS.md § layout check: ask once, then `local-context-icm-migrate`.
